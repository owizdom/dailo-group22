import 'package:dailo/domain/repositories/auth_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('authFailureCodeFrom', () {
    // Each Firebase error text on the left becomes the app's own code on the
    // right. Several Firebase texts can mean the same thing to the user.
    const mapping = {
      'invalid-email': AuthFailureCode.invalidEmail,
      'wrong-password': AuthFailureCode.wrongCredentials,
      'user-not-found': AuthFailureCode.wrongCredentials,
      'invalid-credential': AuthFailureCode.wrongCredentials,
      'INVALID_LOGIN_CREDENTIALS': AuthFailureCode.wrongCredentials,
      'email-already-in-use': AuthFailureCode.emailInUse,
      'weak-password': AuthFailureCode.weakPassword,
      'user-disabled': AuthFailureCode.userDisabled,
      'too-many-requests': AuthFailureCode.tooManyRequests,
      'network-request-failed': AuthFailureCode.network,
      'canceled': AuthFailureCode.googleCancelled,
      'cancelled': AuthFailureCode.googleCancelled,
      'sign_in_canceled': AuthFailureCode.googleCancelled,
    };

    for (final entry in mapping.entries) {
      test('${entry.key} gives ${entry.value.name}', () {
        expect(authFailureCodeFrom(entry.key), entry.value);
      });
    }

    test('a code the app does not know gives unknown', () {
      expect(
        authFailureCodeFrom('operation-not-allowed'),
        AuthFailureCode.unknown,
      );
      expect(authFailureCodeFrom('something-new'), AuthFailureCode.unknown);
    });

    test('an empty code gives unknown', () {
      expect(authFailureCodeFrom(''), AuthFailureCode.unknown);
    });
  });
}
