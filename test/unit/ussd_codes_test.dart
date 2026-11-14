import 'package:dailo/domain/entities/network.dart';
import 'package:dailo/domain/logic/ussd_codes.dart';
import 'package:flutter_test/flutter_test.dart';

/// A USSD code is made only of digits, stars and one closing hash.
final _ussdShape = RegExp(r'^\*[0-9*]*#$');

/// Every code the app can build, for the checks that apply to all of them.
List<String> _everyCode() {
  final codes = <String>[rootMenuCode];
  for (final from in Network.values) {
    for (final to in Network.values) {
      codes.add(sendMoneyCode('0788452310', 10000, from: from, to: to));
    }
  }
  for (final network in Network.values) {
    codes.add(airtimeCode(500, network: network));
    codes.add(airtimeCode(500, forPhone: '0788452310', network: network));
    codes.add(dataMenuCode(network));
  }
  return codes;
}

void main() {
  group('rootMenuCode', () {
    test('is *182#', () {
      expect(rootMenuCode, '*182#');
    });
  });

  group('sendMoneyCode', () {
    test('MTN to MTN is *182*1*1*<phone>*<amount>#', () {
      expect(
        sendMoneyCode('0788452310', 10000, from: Network.mtn, to: Network.mtn),
        '*182*1*1*0788452310*10000#',
      );
    });

    test('MTN to another network is *182*1*2*<phone>*<amount>#', () {
      expect(
        sendMoneyCode(
          '0731112223',
          10000,
          from: Network.mtn,
          to: Network.airtel,
        ),
        '*182*1*2*0731112223*10000#',
      );
    });

    // No chained code has been verified for Airtel, so the user starts at the
    // root menu and DailO shows the steps to follow.
    test('paying from Airtel falls back to the root menu', () {
      expect(
        sendMoneyCode(
          '0788452310',
          10000,
          from: Network.airtel,
          to: Network.mtn,
        ),
        rootMenuCode,
      );
      expect(
        sendMoneyCode(
          '0731112223',
          10000,
          from: Network.airtel,
          to: Network.airtel,
        ),
        rootMenuCode,
      );
    });

    test('the amount is written without commas', () {
      expect(
        sendMoneyCode('0788452310', 1500, from: Network.mtn, to: Network.mtn),
        '*182*1*1*0788452310*1500#',
      );
    });
  });

  group('airtime and data codes', () {
    test('airtime for your own line looks like a USSD code', () {
      expect(airtimeCode(500, network: Network.mtn), matches(_ussdShape));
    });

    test('airtime for another number looks like a USSD code', () {
      expect(
        airtimeCode(500, forPhone: '0788452310', network: Network.mtn),
        matches(_ussdShape),
      );
    });

    test('the MTN data menu code looks like a USSD code', () {
      expect(dataMenuCode(Network.mtn), matches(_ussdShape));
    });

    test('the Airtel data menu code looks like a USSD code', () {
      expect(dataMenuCode(Network.airtel), matches(_ussdShape));
    });
  });

  group('no PIN in any code', () {
    // The MoMo PIN is typed only in the phone's own USSD dialog, so no code
    // may carry a word such as PIN or a placeholder such as <pin>.
    test('no code contains a letter', () {
      final codes = _everyCode();
      expect(codes, isNotEmpty);
      for (final code in codes) {
        expect(code, isNot(matches(RegExp(r'[A-Za-z]'))), reason: code);
      }
    });

    test('every code starts with * and ends with #', () {
      for (final code in _everyCode()) {
        expect(code, matches(_ussdShape), reason: code);
      }
    });
  });
}
