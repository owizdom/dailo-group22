import '../entities/network.dart';

/// The smallest and largest amounts the MTN tariff covers.
const int minAmount = 1;
const int maxAmount = 10000000;

/// A suggestion shown on the amount screen: sending [cheaperAmount] instead
/// would cost [saving] francs less in fees.
class BandHint {
  const BandHint({required this.cheaperAmount, required this.saving});

  final int cheaperAmount;
  final int saving;
}

/// One row of MTN's published tariff: amounts from [low] to [high] francs
/// cost [onNet] when the money stays on MTN and [offNet] when it leaves MTN.
class _FeeBand {
  const _FeeBand(this.low, this.high, this.onNet, this.offNet);

  final int low;
  final int high;
  final int onNet;
  final int offNet;
}

/// MTN's tariff in francs, cheapest band first.
const List<_FeeBand> _fees = [
  _FeeBand(1, 1000, 20, 100),
  _FeeBand(1001, 10000, 100, 200),
  _FeeBand(10001, 150000, 250, 350),
  _FeeBand(150001, 2000000, 1500, 1600),
  _FeeBand(2000001, 5000000, 3000, 3000),
  _FeeBand(5000001, 10000000, 5000, 5000),
];

/// The band that [amount] falls into. [amount] must be inside the tariff.
_FeeBand _bandFor(int amount) {
  return _fees.firstWhere((band) => amount <= band.high);
}

/// On-net means the money starts and stays on the same network.
int _feeInBand(_FeeBand band, {required Network from, required Network to}) {
  if (from == to) return band.onNet;
  return band.offNet;
}

/// Whether DailO knows the fee table for payments made from [from].
/// Only MTN's published table is built in.
bool isFeeKnown(Network from) => from == Network.mtn;

/// The fee for sending [amount] francs, from MTN's published tariff.
///
/// On-net (MTN to MTN) and off-net (MTN to another network) have separate
/// columns. Throws [ArgumentError] when [amount] is outside
/// [minAmount]..[maxAmount].
///
/// Throws [UnsupportedError] when [isFeeKnown] is false for [from], because
/// showing a guessed fee would mislead the user. Check [isFeeKnown] first.
int feeFor(int amount, {required Network from, required Network to}) {
  if (amount < minAmount || amount > maxAmount) {
    throw ArgumentError.value(
      amount,
      'amount',
      'must be between $minAmount and $maxAmount',
    );
  }
  if (!isFeeKnown(from)) {
    throw UnsupportedError('The fee table for ${from.label} is not known.');
  }
  return _feeInBand(_bandFor(amount), from: from, to: to);
}

/// Returns a hint when [amount] sits just above a fee band edge
/// (no more than 10% above it), otherwise null.
BandHint? bandHint(int amount, {required Network from, required Network to}) {
  if (!isFeeKnown(from)) return null;
  if (amount < minAmount || amount > maxAmount) return null;

  final bandIndex = _fees.indexOf(_bandFor(amount));
  if (bandIndex == 0) return null; // No cheaper band below the first one.

  final cheaperBand = _fees[bandIndex - 1];
  final edge = cheaperBand.high;

  // "No more than 10% above the edge", worked out in whole francs
  // (amount <= edge * 1.1) so no rounding can creep in.
  if (amount * 10 > edge * 11) return null;

  final saving =
      _feeInBand(_fees[bandIndex], from: from, to: to) -
      _feeInBand(cheaperBand, from: from, to: to);
  return BandHint(cheaperAmount: edge, saving: saving);
}
