import 'package:dailo/domain/entities/network.dart';
import 'package:dailo/domain/logic/phone_number.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalisePhone, accepted forms', () {
    // Every way a person might type or paste the same number.
    const forms = {
      'local': '0788123456',
      'with +250': '+250788123456',
      'with 250': '250788123456',
      'with spaces': '078 812 3456',
      'with dashes': '078-812-3456',
      'with spaces around it': ' 0788123456 ',
    };

    for (final entry in forms.entries) {
      test('${entry.key} becomes 0788123456', () {
        expect(normalisePhone(entry.value), '0788123456');
      });
    }

    test('all four valid prefixes are accepted', () {
      expect(normalisePhone('0721234567'), '0721234567');
      expect(normalisePhone('0731234567'), '0731234567');
      expect(normalisePhone('0781234567'), '0781234567');
      expect(normalisePhone('0791234567'), '0791234567');
    });

    test('the country prefix works for Airtel numbers too', () {
      expect(normalisePhone('+250731112223'), '0731112223');
    });
  });

  group('normalisePhone, rejected input', () {
    const rejected = {
      'a prefix that is not 072, 073, 078 or 079': '0755555555',
      'too short (9 digits)': '078812345',
      'too long (11 digits)': '07881234567',
      'an empty string': '',
      'letters': 'abc',
      'a Kenyan number': '+254788123456',
    };

    for (final entry in rejected.entries) {
      test('returns null for ${entry.key}', () {
        expect(normalisePhone(entry.value), isNull);
      });
    }
  });

  group('networkOf', () {
    test('078 and 079 are MTN', () {
      expect(networkOf('0788123456'), Network.mtn);
      expect(networkOf('0791234567'), Network.mtn);
    });

    test('072 and 073 are Airtel', () {
      expect(networkOf('0721234567'), Network.airtel);
      expect(networkOf('0731234567'), Network.airtel);
    });

    test('an unknown prefix gives null', () {
      expect(networkOf('0755555555'), isNull);
    });

    test('text that is not a number gives null', () {
      expect(networkOf('abc'), isNull);
    });
  });

  group('prettyPhone', () {
    test('groups a normalised number as 078 845 2310', () {
      expect(prettyPhone('0788452310'), '078 845 2310');
    });

    test('returns anything that is not 10 digits unchanged', () {
      expect(prettyPhone('078845231'), '078845231');
      expect(prettyPhone('07884523101'), '07884523101');
      expect(prettyPhone('+250788452310'), '+250788452310');
      expect(prettyPhone(''), '');
    });
  });
}
