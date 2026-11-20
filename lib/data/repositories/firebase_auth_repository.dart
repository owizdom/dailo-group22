import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/network.dart';
import '../../domain/logic/phone_number.dart';
import '../../domain/repositories/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';

/// [AuthRepository] backed by Firebase Authentication and Google Sign-In.
/// No Firebase exception type leaves this class: every failure is an
/// [AuthFailure].
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _injectedAuth = auth,
       _injectedFirestore = firestore,
       _injectedGoogle = googleSignIn;

  final FirebaseAuth? _injectedAuth;
  final FirebaseFirestore? _injectedFirestore;
  final GoogleSignIn? _injectedGoogle;

  // Looked up on first use so the object can be built before Firebase starts.
  late final FirebaseAuth _auth = _injectedAuth ?? FirebaseAuth.instance;
  late final FirebaseFirestore _db =
      _injectedFirestore ?? FirebaseFirestore.instance;
  late final GoogleSignIn _google = _injectedGoogle ?? GoogleSignIn.instance;

  /// google_sign_in 7 must be initialised exactly once before any other call.
  /// The Android server client id is read from google-services.json.
  late final Future<void> _googleReady = _google.initialize();

  @override
  Stream<AuthSession?> sessionChanges() {
    // userChanges (not authStateChanges) also fires after `reload()`, so the
    // app sees the moment the email becomes verified.
    return _auth.userChanges().map((user) {
      if (user == null) return null;
      return AuthSession(
        uid: user.uid,
        email: user.email ?? '',
        emailVerified: user.emailVerified,
      );
    });
  }

  @override
  Future<void> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) {
    return _translateErrors(() async {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;
      await user.updateDisplayName('$firstName $lastName'.trim());
      await _tryWriteSignUpProfile(
        user: user,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
      await user.sendEmailVerification();
    });
  }

  @override
  Future<void> signIn(String email, String password) {
    return _translateErrors(() async {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _repairProfileAfterSignIn(result.user!);
    });
  }

  @override
  Future<void> signInWithGoogle() {
    return _translateErrors(() async {
      await _googleReady;
      final account = await _google.authenticate();
      final credential = GoogleAuthProvider.credential(
        idToken: account.authentication.idToken,
      );
      final result = await _auth.signInWithCredential(credential);
      await _repairProfileAfterSignIn(result.user!);
    });
  }

  @override
  Future<void> sendVerificationEmail() {
    return _translateErrors(() => _auth.currentUser!.sendEmailVerification());
  }

  @override
  Future<bool> reloadVerified() {
    return _translateErrors(() async {
      final user = _auth.currentUser!;
      await user.reload();
      final verified = _auth.currentUser!.emailVerified;
      // The security rules read `email_verified` from the ID token, and the
      // cached token keeps saying "not verified" for up to an hour. Without a
      // forced refresh every write is refused right after the user verifies.
      if (verified) await _auth.currentUser!.getIdToken(true);
      return verified;
    });
  }

  @override
  Future<void> sendPasswordReset(String email) {
    return _translateErrors(() => _auth.sendPasswordResetEmail(email: email));
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleReady;
      await _google.signOut();
    } catch (_) {
      // The user may never have used Google. Firebase sign-out still runs.
    }
    await _translateErrors(_auth.signOut);
  }

  /// Runs [action] and turns every error into an [AuthFailure].
  Future<T> _translateErrors<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthFailure {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(authFailureCodeFrom(e.code));
    } on GoogleSignInException catch (e) {
      final cancelled = e.code == GoogleSignInExceptionCode.canceled;
      throw AuthFailure(
        cancelled ? AuthFailureCode.googleCancelled : AuthFailureCode.unknown,
      );
    } catch (_) {
      throw const AuthFailure(AuthFailureCode.unknown);
    }
  }

  /// Sign-up step: writes the profile from the new account. A failure is
  /// swallowed because the account already exists; the next sign-in repairs
  /// the profile and the verification email must still be sent.
  Future<void> _tryWriteSignUpProfile({
    required User user,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    try {
      await _writeProfile(
        uid: user.uid,
        firstName: firstName,
        lastName: lastName,
        // Firebase lowercases addresses and the rules compare against the
        // token email, so store the user's own email, not the typed text.
        email: user.email ?? '',
        phone: phone,
        network: networkOf(phone) ?? Network.mtn,
      );
    } catch (_) {
      // See above: sign-up still succeeds.
    }
  }

  /// Sign-in step, after every successful sign-in (email and Google). A failed
  /// repair must not fail a sign-in that worked; it is retried next time.
  Future<void> _repairProfileAfterSignIn(User user) async {
    try {
      await _createProfileIfMissing(user);
    } catch (_) {
      // Retried on the next sign-in.
    }
  }

  /// Creates `users/{uid}` if absent, naming it from the display name.
  Future<void> _createProfileIfMissing(User user) async {
    final doc = _db.collection('users').doc(user.uid);
    if ((await doc.get()).exists) return;
    // The display name is one string (set at sign-up or by Google), so
    // split it at the first space.
    final name = (user.displayName ?? '').trim();
    final space = name.indexOf(' ');
    await _writeProfile(
      uid: user.uid,
      firstName: space < 0 ? name : name.substring(0, space),
      lastName: space < 0 ? '' : name.substring(space + 1),
      email: user.email ?? '',
      phone: '',
      network: Network.mtn,
    );
  }

  Future<void> _writeProfile({
    required String uid,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required Network network,
  }) {
    final now = DateTime.now();
    final profile = AppUser(
      uid: uid,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      network: network,
      createdAt: now,
      updatedAt: now,
    );
    return _db.collection('users').doc(uid).set(profile.toMap());
  }
}
