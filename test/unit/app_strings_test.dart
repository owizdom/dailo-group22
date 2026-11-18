import 'package:dailo/core/l10n/app_strings.dart';
import 'package:dailo/core/validators.dart';
import 'package:dailo/domain/entities/app_settings.dart';
import 'package:dailo/domain/entities/transaction_record.dart';
import 'package:dailo/domain/repositories/auth_failure.dart';
import 'package:dailo/domain/services/ussd_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const english = AppStrings(AppLanguage.english);
  const kinyarwanda = AppStrings(AppLanguage.kinyarwanda);

  group('every message exists in both languages', () {
    for (final error in FieldError.values) {
      test('fieldError(${error.name}) is not empty', () {
        expect(english.fieldError(error), isNotEmpty);
        expect(kinyarwanda.fieldError(error), isNotEmpty);
      });
    }

    for (final code in AuthFailureCode.values) {
      test('authError(${code.name}) is not empty', () {
        expect(english.authError(code), isNotEmpty);
        expect(kinyarwanda.authError(code), isNotEmpty);
      });
    }
  });

  group('the two languages are really different', () {
    // A copy-pasted English message in the Kinyarwanda column would pass the
    // "not empty" check, so compare the two.
    for (final error in FieldError.values) {
      test('fieldError(${error.name}) differs between languages', () {
        expect(kinyarwanda.fieldError(error), isNot(english.fieldError(error)));
      });
    }
  });

  group('t()', () {
    test('returns the English text in English', () {
      expect(english.t('a', 'b'), 'a');
    });

    test('returns the Kinyarwanda text in Kinyarwanda', () {
      expect(kinyarwanda.t('a', 'b'), 'b');
    });
  });

  group('transaction labels', () {
    for (final language in AppLanguage.values) {
      final strings = AppStrings(language);

      for (final status in TxStatus.values) {
        test('txStatus(${status.name}) is not empty in ${language.code}', () {
          expect(strings.txStatus(status), isNotEmpty);
        });
      }

      for (final type in TxType.values) {
        test('txType(${type.name}) is not empty in ${language.code}', () {
          expect(strings.txType(type), isNotEmpty);
        });
      }
    }
  });

  group('launchProblem', () {
    const problems = [
      UssdOutcome.permissionDenied,
      UssdOutcome.noSim,
      UssdOutcome.unsupported,
    ];

    for (final outcome in problems) {
      test('${outcome.name} explains itself in both languages', () {
        expect(english.launchProblem(outcome), isNotEmpty);
        expect(kinyarwanda.launchProblem(outcome), isNotEmpty);
      });
    }
  });
}
