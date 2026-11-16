import 'package:dailo/domain/entities/network.dart';
import 'package:dailo/domain/logic/fee_table.dart';
import 'package:flutter_test/flutter_test.dart';

/// One row of MTN's published tariff: amounts from [low] to [high] cost
/// [onNet] when the money stays on MTN and [offNet] when it leaves MTN.
class _Band {
  const _Band(this.low, this.high, this.onNet, this.offNet);

  final int low;
  final int high;
  final int onNet;
  final int offNet;
}

const _bands = [
  _Band(1, 1000, 20, 100),
  _Band(1001, 10000, 100, 200),
  _Band(10001, 150000, 250, 350),
  _Band(150001, 2000000, 1500, 1600),
  _Band(2000001, 5000000, 3000, 3000),
  _Band(5000001, 10000000, 5000, 5000),
];

/// Dart's UnimplementedError is itself an UnsupportedError, so the plain
/// `throwsUnsupportedError` matcher would pass on code nobody has written.
/// This one only accepts a deliberate UnsupportedError.
final _throwsDeliberateUnsupportedError = throwsA(
  allOf(isA<UnsupportedError>(), isNot(isA<UnimplementedError>())),
);

void main() {
  group('feeFor, MTN to MTN (on-net)', () {
    for (final band in _bands) {
      test('${band.low} Frw costs ${band.onNet} (bottom of the band)', () {
        expect(
          feeFor(band.low, from: Network.mtn, to: Network.mtn),
          band.onNet,
        );
      });
      test('${band.high} Frw costs ${band.onNet} (top of the band)', () {
        expect(
          feeFor(band.high, from: Network.mtn, to: Network.mtn),
          band.onNet,
        );
      });
    }

    test('an amount in the middle of a band gets that band\'s fee', () {
      expect(feeFor(5000, from: Network.mtn, to: Network.mtn), 100);
      expect(feeFor(75000, from: Network.mtn, to: Network.mtn), 250);
    });
  });

  group('feeFor, MTN to Airtel (off-net)', () {
    for (final band in _bands) {
      test('${band.low} Frw costs ${band.offNet} (bottom of the band)', () {
        expect(
          feeFor(band.low, from: Network.mtn, to: Network.airtel),
          band.offNet,
        );
      });
      test('${band.high} Frw costs ${band.offNet} (top of the band)', () {
        expect(
          feeFor(band.high, from: Network.mtn, to: Network.airtel),
          band.offNet,
        );
      });
    }
  });

  group('feeFor, amounts outside the tariff', () {
    test('0 Frw throws ArgumentError', () {
      expect(
        () => feeFor(0, from: Network.mtn, to: Network.mtn),
        throwsArgumentError,
      );
    });

    test('a negative amount throws ArgumentError', () {
      expect(
        () => feeFor(-1, from: Network.mtn, to: Network.mtn),
        throwsArgumentError,
      );
    });

    test('10,000,001 Frw throws ArgumentError', () {
      expect(
        () => feeFor(10000001, from: Network.mtn, to: Network.mtn),
        throwsArgumentError,
      );
    });

    test('off-net follows the same range', () {
      expect(
        () => feeFor(0, from: Network.mtn, to: Network.airtel),
        throwsArgumentError,
      );
      expect(
        () => feeFor(10000001, from: Network.mtn, to: Network.airtel),
        throwsArgumentError,
      );
    });
  });

  group('Airtel as the paying network', () {
    test('isFeeKnown is true for MTN', () {
      expect(isFeeKnown(Network.mtn), isTrue);
    });

    test('isFeeKnown is false for Airtel', () {
      expect(isFeeKnown(Network.airtel), isFalse);
    });

    // DailO only has MTN's table, so asking for an Airtel fee is a mistake
    // the caller should have avoided by checking isFeeKnown first.
    test('feeFor from Airtel throws UnsupportedError', () {
      expect(
        () => feeFor(1000, from: Network.airtel, to: Network.mtn),
        _throwsDeliberateUnsupportedError,
      );
      expect(
        () => feeFor(1000, from: Network.airtel, to: Network.airtel),
        _throwsDeliberateUnsupportedError,
      );
    });
  });

  group('bandHint, MTN to MTN', () {
    test('10,500 suggests 10,000 and a saving of 150', () {
      final hint = bandHint(10500, from: Network.mtn, to: Network.mtn);
      expect(hint, isNotNull);
      expect(hint!.cheaperAmount, 10000);
      expect(hint.saving, 150);
    });

    test('1,050 suggests 1,000 and a saving of 80', () {
      final hint = bandHint(1050, from: Network.mtn, to: Network.mtn);
      expect(hint, isNotNull);
      expect(hint!.cheaperAmount, 1000);
      expect(hint.saving, 80);
    });

    test('10,000 is already at the edge, so no hint', () {
      expect(bandHint(10000, from: Network.mtn, to: Network.mtn), isNull);
    });

    // The edge is the top of the cheaper band, so 11,000 is exactly 10% above.
    test('11,000 is exactly 10% above the edge and still gets a hint', () {
      final hint = bandHint(11000, from: Network.mtn, to: Network.mtn);
      expect(hint, isNotNull);
      expect(hint!.cheaperAmount, 10000);
    });

    test('11,001 is more than 10% above the edge, so no hint', () {
      expect(bandHint(11001, from: Network.mtn, to: Network.mtn), isNull);
    });

    test('the same 10% rule holds at the 1,000 edge', () {
      expect(bandHint(1100, from: Network.mtn, to: Network.mtn), isNotNull);
      expect(bandHint(1101, from: Network.mtn, to: Network.mtn), isNull);
    });

    test('one franc over an edge gets a hint', () {
      final hint = bandHint(1001, from: Network.mtn, to: Network.mtn);
      expect(hint, isNotNull);
      expect(hint!.cheaperAmount, 1000);
      expect(hint.saving, 80);
    });

    test('the saving is the difference between the two band fees', () {
      // 165,000 is 10% over 150,000. Fees are 1,500 and 250.
      final hint = bandHint(165000, from: Network.mtn, to: Network.mtn);
      expect(hint, isNotNull);
      expect(hint!.cheaperAmount, 150000);
      expect(hint.saving, 1250);
    });

    test('500 is in the first band, so there is no cheaper band', () {
      expect(bandHint(500, from: Network.mtn, to: Network.mtn), isNull);
    });
  });

  group('bandHint, other cases', () {
    test('off-net uses the off-net fees (350 minus 200 is 150)', () {
      final hint = bandHint(10500, from: Network.mtn, to: Network.airtel);
      expect(hint, isNotNull);
      expect(hint!.cheaperAmount, 10000);
      expect(hint.saving, 150);
    });

    test('no hint when the paying network is Airtel', () {
      expect(bandHint(10500, from: Network.airtel, to: Network.mtn), isNull);
    });
  });

  group('limits', () {
    test('minAmount is 1', () {
      expect(minAmount, 1);
    });

    test('maxAmount is 10,000,000', () {
      expect(maxAmount, 10000000);
    });
  });
}
