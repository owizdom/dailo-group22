import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';

/// Where the user is in the sign-in journey. The app shows a different
/// first screen for each value.
enum AuthStatus {
  /// Firebase has not answered yet. The app shows a loading screen.
  unknown,
  signedOut,

  /// Signed in with an email that has not been verified yet.
  needsVerification,
  signedIn,
}

/// A one-off confirmation to show in a snack bar.
enum AuthNotice { verificationSent, resetSent, stillUnverified }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.session,
    this.busy = false,
    this.error,
    this.notice,
  });

  final AuthStatus status;
  final AuthSession? session;

  /// True while a request is running. Buttons show a spinner and ignore taps.
  final bool busy;

  /// Set for one state only, then cleared by the next change.
  final AuthFailureCode? error;

  /// Set for one state only, then cleared by the next change.
  final AuthNotice? notice;

  String? get uid => session?.uid;

  /// [error] and [notice] are one-off messages: every copy drops them unless
  /// a new one is passed in.
  AuthState copyWith({
    AuthStatus? status,
    AuthSession? session,
    bool clearSession = false,
    bool? busy,
    AuthFailureCode? error,
    AuthNotice? notice,
  }) {
    return AuthState(
      status: status ?? this.status,
      session: clearSession ? null : (session ?? this.session),
      busy: busy ?? this.busy,
      error: error,
      notice: notice,
    );
  }

  @override
  List<Object?> get props => [status, session, busy, error, notice];
}

/// Owns sign-up, sign-in, verification, password reset and sign-out.
///
/// The constructor starts listening to [AuthRepository.sessionChanges], so
/// the state follows Firebase: null becomes [AuthStatus.signedOut], an
/// unverified session becomes [AuthStatus.needsVerification], a verified one
/// becomes [AuthStatus.signedIn]. That is also how the session survives an
/// app restart.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this.repository) : super(const AuthState()) {
    _sessions = repository.sessionChanges().listen(_onSession);
  }

  final AuthRepository repository;
  late final StreamSubscription<AuthSession?> _sessions;

  Future<void> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) => _run(
    () => repository.signUp(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      password: password,
    ),
  );

  Future<void> signIn(String email, String password) =>
      _run(() => repository.signIn(email, password));

  Future<void> signInWithGoogle() => _run(repository.signInWithGoogle);

  /// Sends the verification email again and emits
  /// [AuthNotice.verificationSent].
  Future<void> resendVerification() => _run(
    repository.sendVerificationEmail,
    noticeFor: (_) => AuthNotice.verificationSent,
  );

  /// Asks Firebase whether the email is verified now. Moves to
  /// [AuthStatus.signedIn] when it is, otherwise emits
  /// [AuthNotice.stillUnverified].
  Future<void> checkVerified() => _run(
    repository.reloadVerified,
    // When verified, the repository reports a new session and
    // [_onSession] moves the state on.
    noticeFor: (verified) => verified ? null : AuthNotice.stillUnverified,
  );

  /// Emits [AuthNotice.resetSent] on success.
  Future<void> sendPasswordReset(String email) => _run(
    () => repository.sendPasswordReset(email),
    noticeFor: (_) => AuthNotice.resetSent,
  );

  Future<void> signOut() => _run(repository.signOut);

  @override
  Future<void> close() async {
    await _sessions.cancel();
    return super.close();
  }

  /// Follows Firebase: the session decides which first screen is shown.
  void _onSession(AuthSession? session) {
    if (session == null) {
      emit(state.copyWith(status: AuthStatus.signedOut, clearSession: true));
      return;
    }
    final status = session.emailVerified
        ? AuthStatus.signedIn
        : AuthStatus.needsVerification;
    emit(state.copyWith(status: status, session: session));
  }

  /// Runs one repository call with the busy flag on. A failure becomes
  /// [AuthState.error]; a success may become a notice.
  Future<void> _run<T>(
    Future<T> Function() action, {
    AuthNotice? Function(T result)? noticeFor,
  }) async {
    emit(state.copyWith(busy: true));
    try {
      final result = await action();
      emit(state.copyWith(busy: false, notice: noticeFor?.call(result)));
    } on AuthFailure catch (failure) {
      emit(state.copyWith(busy: false, error: failure.code));
    } catch (_) {
      // Anything else is a bug or a plugin error. The user sees one message.
      emit(state.copyWith(busy: false, error: AuthFailureCode.unknown));
    }
  }
}
