/// Every sign-in problem the app shows its own message for.
enum AuthFailureCode {
  invalidEmail,
  wrongCredentials,
  emailInUse,
  weakPassword,
  userDisabled,
  tooManyRequests,
  network,
  googleCancelled,
  unknown,
}

/// Thrown by [AuthRepository] so the rest of the app never sees a Firebase
/// exception type.
class AuthFailure implements Exception {
  const AuthFailure(this.code);

  final AuthFailureCode code;

  @override
  String toString() => 'AuthFailure(${code.name})';
}

/// Maps a Firebase Authentication error code such as `wrong-password`
/// to the app's own [AuthFailureCode].
AuthFailureCode authFailureCodeFrom(String firebaseCode) {
  switch (firebaseCode) {
    case 'invalid-email':
      return AuthFailureCode.invalidEmail;
    // Firebase uses several texts for "email or password is wrong". The user
    // gets one message so the app does not reveal which accounts exist.
    case 'wrong-password':
    case 'user-not-found':
    case 'invalid-credential':
    case 'INVALID_LOGIN_CREDENTIALS':
      return AuthFailureCode.wrongCredentials;
    case 'email-already-in-use':
      return AuthFailureCode.emailInUse;
    case 'weak-password':
      return AuthFailureCode.weakPassword;
    case 'user-disabled':
      return AuthFailureCode.userDisabled;
    case 'too-many-requests':
      return AuthFailureCode.tooManyRequests;
    case 'network-request-failed':
      return AuthFailureCode.network;
    case 'canceled':
    case 'cancelled':
    case 'sign_in_canceled':
      return AuthFailureCode.googleCancelled;
    default:
      return AuthFailureCode.unknown;
  }
}
