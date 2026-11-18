import 'dart:async';

import 'package:dailo/domain/entities/auth_session.dart';
import 'package:dailo/domain/repositories/auth_failure.dart';
import 'package:dailo/domain/repositories/auth_repository.dart';

/// An [AuthRepository] that lives in memory.
///
/// - Set [failWith] to make the next call throw that [AuthFailure].
/// - [calls] records the name of every method called, in order.
/// - [session] is who is signed in now; change it with [emit].
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AuthSession? initial}) : session = initial;

  static const uid = 'u1';

  AuthSession? session;
  AuthFailure? failWith;

  /// What [reloadVerified] should answer.
  bool verifiedAfterReload = false;

  final List<String> calls = [];
  final _controller = StreamController<AuthSession?>.broadcast();

  /// Signs someone in or out from a test.
  void emit(AuthSession? value) {
    session = value;
    _controller.add(value);
  }

  void _maybeFail() {
    final failure = failWith;
    if (failure != null) {
      failWith = null;
      throw failure;
    }
  }

  @override
  Stream<AuthSession?> sessionChanges() async* {
    yield session;
    yield* _controller.stream;
  }

  @override
  Future<void> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    calls.add('signUp');
    _maybeFail();
    emit(AuthSession(uid: uid, email: email, emailVerified: false));
  }

  @override
  Future<void> signIn(String email, String password) async {
    calls.add('signIn');
    _maybeFail();
    emit(AuthSession(uid: uid, email: email, emailVerified: true));
  }

  @override
  Future<void> signInWithGoogle() async {
    calls.add('signInWithGoogle');
    _maybeFail();
    emit(
      const AuthSession(
        uid: uid,
        email: 'google.user@example.com',
        emailVerified: true,
      ),
    );
  }

  @override
  Future<void> sendVerificationEmail() async {
    calls.add('sendVerificationEmail');
    _maybeFail();
  }

  @override
  Future<bool> reloadVerified() async {
    calls.add('reloadVerified');
    _maybeFail();
    final current = session;
    if (verifiedAfterReload && current != null) {
      emit(
        AuthSession(
          uid: current.uid,
          email: current.email,
          emailVerified: true,
        ),
      );
    }
    return verifiedAfterReload;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    calls.add('sendPasswordReset');
    _maybeFail();
  }

  @override
  Future<void> signOut() async {
    calls.add('signOut');
    _maybeFail();
    emit(null);
  }
}
