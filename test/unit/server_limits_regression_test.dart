import 'package:dailo/core/l10n/app_strings.dart';
import 'package:dailo/core/validators.dart';
import 'package:dailo/domain/entities/app_settings.dart';
import 'package:dailo/domain/entities/recipient.dart';
import 'package:flutter_test/flutter_test.dart';

// Found by the verifier: the security rules refuse feedback longer than
// 2,000 characters and recipient names longer than 60, but the app let both
// through. The app must stop them before the server has to.
void main() {
  test('feedback of 2,000 characters is accepted, 2,001 is not', () {
    expect(validateFeedback('a' * 2000), isNull);
    expect(validateFeedback('a' * 2001), FieldError.messageTooLong);
  });

  test('the too-long message has text in both languages', () {
    for (final language in AppLanguage.values) {
      expect(
        AppStrings(language).fieldError(FieldError.messageTooLong),
        isNotEmpty,
      );
    }
  });

  test('the name limit matches the server rule', () {
    expect(Recipient.maxNameLength, 60);
  });
}
