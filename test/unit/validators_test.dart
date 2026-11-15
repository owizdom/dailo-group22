import 'package:dailo/core/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateEmail', () {
    test('null, empty and blank are required', () {
      expect(validateEmail(null), FieldError.required);
      expect(validateEmail(''), FieldError.required);
      expect(validateEmail('   '), FieldError.required);
    });

    test('text that is not shaped like an email is invalid', () {
      expect(validateEmail('abc'), FieldError.invalidEmail);
      expect(validateEmail('a@b'), FieldError.invalidEmail);
      expect(validateEmail('a@b.'), FieldError.invalidEmail);
    });

    test('a normal email passes', () {
      expect(validateEmail('name@example.com'), isNull);
    });

    test('spaces around a good email are ignored', () {
      expect(validateEmail(' name@example.com '), isNull);
    });
  });

  group('validatePassword (sign up)', () {
    test('null and empty are required', () {
      expect(validatePassword(null), FieldError.required);
      expect(validatePassword(''), FieldError.required);
    });

    test('shorter than 8 characters is weak', () {
      expect(validatePassword('short1'), FieldError.weakPassword);
    });

    test('7 characters is still weak even with a letter and a digit', () {
      const password = 'abcdef1';
      expect(password.length, 7);
      expect(validatePassword(password), FieldError.weakPassword);
    });

    test('letters only is weak', () {
      expect(validatePassword('allletters'), FieldError.weakPassword);
    });

    test('digits only is weak', () {
      expect(validatePassword('12345678'), FieldError.weakPassword);
    });

    test('8 characters with a letter and a digit passes', () {
      expect(validatePassword('abcd1234'), isNull);
    });
  });

  group('validateSignInPassword', () {
    test('null and empty are required', () {
      expect(validateSignInPassword(null), FieldError.required);
      expect(validateSignInPassword(''), FieldError.required);
    });

    // Strength was checked at sign up, so any typed password is accepted here.
    test('any typed password passes', () {
      expect(validateSignInPassword('x'), isNull);
    });
  });

  group('validateConfirmPassword', () {
    test('null and empty are required', () {
      expect(validateConfirmPassword(null, 'abcd1234'), FieldError.required);
      expect(validateConfirmPassword('', 'abcd1234'), FieldError.required);
    });

    test('a different password is a mismatch', () {
      expect(
        validateConfirmPassword('abcd1235', 'abcd1234'),
        FieldError.passwordMismatch,
      );
    });

    test('the same password passes', () {
      expect(validateConfirmPassword('abcd1234', 'abcd1234'), isNull);
    });
  });

  group('validateName', () {
    test('null, empty and blank are required', () {
      expect(validateName(null), FieldError.required);
      expect(validateName(''), FieldError.required);
      expect(validateName('  '), FieldError.required);
    });

    test('1 character is too short', () {
      expect(validateName('A'), FieldError.nameTooShort);
    });

    test('31 characters is too long', () {
      final name = 'a' * 31;
      expect(name.length, 31);
      expect(validateName(name), FieldError.nameTooLong);
    });

    test('2 characters passes', () {
      expect(validateName('Al'), isNull);
    });

    test('length is counted after trimming', () {
      expect(validateName(' Al '), isNull);
    });

    test('30 characters passes', () {
      final name = 'a' * 30;
      expect(name.length, 30);
      expect(validateName(name), isNull);
    });
  });

  group('validatePhone', () {
    test('null and empty are required', () {
      expect(validatePhone(null), FieldError.required);
      expect(validatePhone(''), FieldError.required);
    });

    test('a short number is invalid', () {
      expect(validatePhone('123'), FieldError.invalidPhone);
    });

    test('a local number passes', () {
      expect(validatePhone('0788123456'), isNull);
    });

    test('a +250 number with spaces passes', () {
      expect(validatePhone('+250 788 123 456'), isNull);
    });
  });

  group('validateAmount', () {
    test('null and empty are required', () {
      expect(validateAmount(null), FieldError.required);
      expect(validateAmount(''), FieldError.required);
    });

    test('zero, letters and negatives are invalid', () {
      expect(validateAmount('0'), FieldError.invalidAmount);
      expect(validateAmount('abc'), FieldError.invalidAmount);
      expect(validateAmount('-5'), FieldError.invalidAmount);
      expect(validateAmount('12a'), FieldError.invalidAmount);
    });

    test('commas and spaces are allowed', () {
      expect(validateAmount('10,500'), isNull);
      expect(validateAmount('1 000'), isNull);
    });

    test('1 Frw passes', () {
      expect(validateAmount('1'), isNull);
    });

    test('10,000,001 is too large', () {
      expect(validateAmount('10000001'), FieldError.amountTooLarge);
    });

    test('10,000,000 passes', () {
      expect(validateAmount('10000000'), isNull);
    });
  });

  group('validateFeedback', () {
    test('null and empty are required', () {
      expect(validateFeedback(null), FieldError.required);
      expect(validateFeedback(''), FieldError.required);
    });

    test('9 characters is too short', () {
      const message = 'too short';
      expect(message.length, 9);
      expect(validateFeedback(message), FieldError.messageTooShort);
    });

    test('10 characters passes', () {
      final message = 'a' * 10;
      expect(message.length, 10);
      expect(validateFeedback(message), isNull);
    });
  });

  group('parseAmount', () {
    test('reads digits with a comma', () {
      expect(parseAmount('10,500'), 10500);
    });

    test('reads digits with spaces', () {
      expect(parseAmount(' 1 000 '), 1000);
    });

    test('an empty field gives null', () {
      expect(parseAmount(''), isNull);
    });

    test('a letter among the digits gives null', () {
      expect(parseAmount('12a'), isNull);
    });

    test('a minus sign gives null', () {
      expect(parseAmount('-5'), isNull);
    });
  });
}
