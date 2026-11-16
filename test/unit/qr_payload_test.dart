import 'package:dailo/domain/logic/qr_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('encodeQr', () {
    test('starts with dailo:pay?', () {
      final raw = encodeQr(name: 'Uwase Diane', phone: '0788452310');
      expect(raw, startsWith('dailo:pay?'));
    });

    test('carries the phone number as p=', () {
      final raw = encodeQr(name: 'Uwase Diane', phone: '0788452310');
      expect(raw, contains('p=0788452310'));
    });
  });

  group('decodeQr after encodeQr', () {
    // Names with characters that mean something inside a link must survive.
    const names = [
      'Uwase Diane',
      'Zoé & Co = 1',
      "Jean d'Arc",
      'A&B=C',
      'Ngabo #1 100%',
      'Mukandayisenga Marie Claudine',
    ];

    for (final name in names) {
      test('returns the same name and phone for "$name"', () {
        final raw = encodeQr(name: name, phone: '0788452310');
        final contact = decodeQr(raw);
        expect(contact, isNotNull);
        expect(contact!.name, name);
        expect(contact.phone, '0788452310');
      });
    }

    test('works for an Airtel number', () {
      final contact = decodeQr(encodeQr(name: 'Eric', phone: '0731112223'));
      expect(contact, isNotNull);
      expect(contact!.phone, '0731112223');
    });
  });

  group('decodeQr, codes written by hand', () {
    test('reads a plain dailo:pay link', () {
      final contact = decodeQr('dailo:pay?p=0788452310&n=Diane');
      expect(contact, isNotNull);
      expect(contact!.name, 'Diane');
      expect(contact.phone, '0788452310');
    });

    test('reads a name with a percent-encoded space', () {
      final contact = decodeQr('dailo:pay?p=0788452310&n=Uwase%20Diane');
      expect(contact, isNotNull);
      expect(contact!.name, 'Uwase Diane');
    });

    test('turns a +250 number into the 07 form (percent-encoded plus)', () {
      final contact = decodeQr('dailo:pay?p=%2B250788452310&n=Diane');
      expect(contact, isNotNull);
      expect(contact!.phone, '0788452310');
    });

    test('turns a +250 number into the 07 form (plain plus)', () {
      final contact = decodeQr('dailo:pay?p=+250788452310&n=Diane');
      expect(contact, isNotNull);
      expect(contact!.phone, '0788452310');
    });
  });

  group('decodeQr, codes that are not for DailO', () {
    test('a web link gives null', () {
      expect(decodeQr('https://example.com'), isNull);
    });

    test('an empty string gives null', () {
      expect(decodeQr(''), isNull);
    });

    test('a number that is not a Rwandan mobile gives null', () {
      expect(decodeQr('dailo:pay?p=123&n=x'), isNull);
    });

    test('plain text gives null', () {
      expect(decodeQr('hello world'), isNull);
    });
  });
}
