import '../entities/network.dart';

/// The operator's root menu. Used when a chained code is not available.
const String rootMenuCode = '*182#';

/// The code that starts a send-money session with the number and amount
/// already filled in. The operator then shows the name and asks for the PIN.
///
/// The PIN is never part of a code built here.
String sendMoneyCode(
  String phone,
  int amount, {
  required Network from,
  required Network to,
}) {
  // Only MTN's chained code has been verified. Anything else starts at the
  // root menu and the app shows the steps to follow.
  if (from != Network.mtn) return rootMenuCode;

  final destination = to == Network.mtn ? '1' : '2';
  return '*182*1*$destination*$phone*$amount#';
}

/// The code that buys [amount] francs of airtime, for the user's own line
/// or for [forPhone].
String airtimeCode(int amount, {String? forPhone, required Network network}) {
  // Not verified yet: replaced once the real code is read off a live session.
  return rootMenuCode;
}

/// The code that opens the operator's data bundle menu.
String dataMenuCode(Network network) {
  // Not verified yet: replaced once the real code is read off a live session.
  return rootMenuCode;
}
