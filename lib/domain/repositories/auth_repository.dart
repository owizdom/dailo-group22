import '../entities/auth_session.dart';

/// Sign-up, sign-in and sign-out. Implemented with Firebase Authentication.
/// Every method throws [AuthFailure] on a known problem.
abstract class AuthRepository {
  /// Emits the current session, then again on every sign-in and sign-out.
  /// Emits null when nobody is signed in.
  Stream<AuthSession?> sessionChanges();

  /// Creates the account and the `users/{uid}` profile, then sends the
  /// verification email.
  Future<void> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  });

  Future<void> signIn(String email, String password);

  /// Opens Google's account picker. Creates the profile on first sign-in.
  Future<void> signInWithGoogle();

  Future<void> sendVerificationEmail();

  /// Asks Firebase again and returns whether the email is now verified.
  Future<bool> reloadVerified();

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();
}
