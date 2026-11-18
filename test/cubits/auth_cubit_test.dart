import 'package:dailo/domain/entities/auth_session.dart';
import 'package:dailo/domain/repositories/auth_failure.dart';
import 'package:dailo/presentation/cubits/auth_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_auth_repository.dart';
import '../fakes/samples.dart';
import 'support.dart';

/// An auth repository whose sign-in fails with an error that is not an
/// [AuthFailure], the way an unexpected bug or plugin error would.
class _BrokenAuthRepository extends FakeAuthRepository {
  _BrokenAuthRepository() : super(initial: null);

  @override
  Future<void> signIn(String email, String password) async {
    throw Exception('boom');
  }
}

void main() {
  late FakeAuthRepository auth;
  late AuthCubit cubit;

  /// Builds the cubit over a fake whose current session is [session], then
  /// waits for that first session to reach the cubit.
  Future<void> startWith(AuthSession? session) async {
    auth = FakeAuthRepository(initial: session);
    cubit = AuthCubit(auth);
    await settle();
  }

  tearDown(() => cubit.close());

  group('following the session', () {
    test('no session means signed out', () async {
      await startWith(null);

      expect(cubit.state.status, AuthStatus.signedOut);
      expect(cubit.state.session, isNull);
    });

    test('a verified session means signed in', () async {
      await startWith(verifiedSession);

      expect(cubit.state.status, AuthStatus.signedIn);
      expect(cubit.state.session, verifiedSession);
      expect(cubit.state.uid, 'u1');
    });

    test('an unverified session means needs verification', () async {
      await startWith(unverifiedSession);

      expect(cubit.state.status, AuthStatus.needsVerification);
      expect(cubit.state.session, unverifiedSession);
    });

    test(
      'a change made outside the cubit signs a signed-in user out',
      () async {
        await startWith(verifiedSession);

        auth.emit(null);
        await settle();

        expect(cubit.state.status, AuthStatus.signedOut);
        expect(cubit.state.session, isNull);
      },
    );
  });

  group('signIn', () {
    test('shows busy, then signs in', () async {
      await startWith(null);
      final states = record(cubit);

      await cubit.signIn('aline@example.com', 'secret123');
      await settle();

      expect(states.first.busy, isTrue);
      expect(cubit.state.status, AuthStatus.signedIn);
      expect(cubit.state.busy, isFalse);
      expect(cubit.state.session?.email, 'aline@example.com');
      expect(auth.calls, contains('signIn'));
    });

    test('a wrong password reports the error and stays signed out', () async {
      await startWith(null);
      final states = record(cubit);
      auth.failWith = const AuthFailure(AuthFailureCode.wrongCredentials);

      await cubit.signIn('aline@example.com', 'wrong');
      await settle();

      final failed = states.firstWhere((state) => state.error != null);
      expect(failed.error, AuthFailureCode.wrongCredentials);
      expect(failed.busy, isFalse);
      expect(failed.status, AuthStatus.signedOut);
      expect(cubit.state.status, AuthStatus.signedOut);
    });

    test('the error is shown for one state only', () async {
      await startWith(null);
      final states = record(cubit);
      auth.failWith = const AuthFailure(AuthFailureCode.wrongCredentials);
      await cubit.signIn('aline@example.com', 'wrong');
      await settle();
      final failedAt = states.indexWhere((state) => state.error != null);

      // The fake only fails once, so this second attempt succeeds.
      await cubit.signIn('aline@example.com', 'secret123');
      await settle();

      expect(states.length, greaterThan(failedAt + 1));
      expect(states[failedAt + 1].error, isNull);
      expect(cubit.state.error, isNull);
    });
  });

  group('failure codes', () {
    for (final code in AuthFailureCode.values) {
      test('${code.name} reaches state.error unchanged', () async {
        await startWith(null);
        final states = record(cubit);
        auth.failWith = AuthFailure(code);

        await cubit.signIn('aline@example.com', 'secret123');
        await settle();

        final errors = states
            .map((state) => state.error)
            .whereType<AuthFailureCode>();
        expect(errors, [code]);
      });
    }

    test('an error that is not an AuthFailure becomes unknown', () async {
      auth = _BrokenAuthRepository();
      cubit = AuthCubit(auth);
      await settle();
      final states = record(cubit);

      await cubit.signIn('aline@example.com', 'secret123');
      await settle();

      final errors = states
          .map((state) => state.error)
          .whereType<AuthFailureCode>();
      expect(errors, [AuthFailureCode.unknown]);
      expect(cubit.state.busy, isFalse);
    });

    test('sign-up, Google and reset report failures too', () async {
      await startWith(null);
      final states = record(cubit);

      auth.failWith = const AuthFailure(AuthFailureCode.emailInUse);
      await cubit.signUp(
        firstName: 'Aline',
        lastName: 'Mukamana',
        email: 'aline@example.com',
        phone: '0788000001',
        password: 'secret123',
      );
      auth.failWith = const AuthFailure(AuthFailureCode.googleCancelled);
      await cubit.signInWithGoogle();
      auth.failWith = const AuthFailure(AuthFailureCode.network);
      await cubit.sendPasswordReset('aline@example.com');
      await settle();

      final errors = states
          .map((state) => state.error)
          .whereType<AuthFailureCode>();
      expect(errors, [
        AuthFailureCode.emailInUse,
        AuthFailureCode.googleCancelled,
        AuthFailureCode.network,
      ]);
    });
  });

  group('signUp', () {
    test(
      'creates the account and waits for the email to be verified',
      () async {
        await startWith(null);

        await cubit.signUp(
          firstName: 'Aline',
          lastName: 'Mukamana',
          email: 'aline@example.com',
          phone: '0788000001',
          password: 'secret123',
        );
        await settle();

        expect(cubit.state.status, AuthStatus.needsVerification);
        expect(cubit.state.busy, isFalse);
        expect(cubit.state.session?.email, 'aline@example.com');
        expect(auth.calls, contains('signUp'));
      },
    );
  });

  group('signInWithGoogle', () {
    test('signs in with a Google account', () async {
      await startWith(null);

      await cubit.signInWithGoogle();
      await settle();

      expect(cubit.state.status, AuthStatus.signedIn);
      expect(cubit.state.busy, isFalse);
      expect(auth.calls, contains('signInWithGoogle'));
    });
  });

  group('verification', () {
    test('resendVerification says the email was sent', () async {
      await startWith(unverifiedSession);
      final states = record(cubit);

      await cubit.resendVerification();
      await settle();

      expect(
        states.map((state) => state.notice),
        contains(AuthNotice.verificationSent),
      );
      expect(auth.calls, contains('sendVerificationEmail'));
      expect(cubit.state.status, AuthStatus.needsVerification);
    });

    test('checkVerified signs in once the email is verified', () async {
      await startWith(unverifiedSession);
      auth.verifiedAfterReload = true;

      await cubit.checkVerified();
      await settle();

      expect(cubit.state.status, AuthStatus.signedIn);
      expect(cubit.state.session?.emailVerified, isTrue);
      expect(auth.calls, contains('reloadVerified'));
    });

    test('checkVerified says so when the email is still unverified', () async {
      await startWith(unverifiedSession);
      auth.verifiedAfterReload = false;
      final states = record(cubit);

      await cubit.checkVerified();
      await settle();

      expect(
        states.map((state) => state.notice),
        contains(AuthNotice.stillUnverified),
      );
      expect(cubit.state.status, AuthStatus.needsVerification);
    });
  });

  group('sendPasswordReset', () {
    test('says the reset email was sent', () async {
      await startWith(null);
      final states = record(cubit);

      await cubit.sendPasswordReset('aline@example.com');
      await settle();

      expect(
        states.map((state) => state.notice),
        contains(AuthNotice.resetSent),
      );
      expect(auth.calls, contains('sendPasswordReset'));
    });
  });

  group('signOut', () {
    test('ends signed out with no session and no uid', () async {
      await startWith(verifiedSession);

      await cubit.signOut();
      await settle();

      expect(cubit.state.status, AuthStatus.signedOut);
      expect(cubit.state.session, isNull);
      expect(cubit.state.uid, isNull);
      expect(auth.calls, contains('signOut'));
    });
  });
}
