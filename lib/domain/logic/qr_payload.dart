import 'phone_number.dart';

/// Every DailO payment code starts with this text.
const String _prefix = 'dailo:pay?';

/// The name and number carried by a DailO payment QR code.
class QrContact {
  const QrContact({required this.name, required this.phone});

  final String name;
  final String phone;
}

/// Builds the text stored in a payment QR code:
/// `dailo:pay?p=<phone>&n=<name>`.
String encodeQr({required String name, required String phone}) {
  final safePhone = Uri.encodeComponent(phone);
  final safeName = Uri.encodeComponent(name);
  return '${_prefix}p=$safePhone&n=$safeName';
}

/// Reads a scanned QR code. Returns null when it is not a DailO payment
/// code or its number is not a valid Rwandan mobile number.
QrContact? decodeQr(String raw) {
  if (!raw.startsWith(_prefix)) return null;

  final String phoneText;
  final String name;
  try {
    final values = _readValues(raw.substring(_prefix.length));
    phoneText = values['p'] ?? '';
    name = values['n'] ?? '';
  } on FormatException {
    return null; // A broken %-escape means the code is not ours.
  }

  final phone = normalisePhone(phoneText);
  if (phone == null) return null;
  return QrContact(name: name, phone: phone);
}

/// Splits `p=...&n=...` into a map of decoded values.
///
/// Uri.decodeComponent is used instead of the query decoder because the query
/// decoder turns a plain `+` into a space, which would damage `+250...`.
Map<String, String> _readValues(String query) {
  final values = <String, String>{};
  for (final pair in query.split('&')) {
    final equalsAt = pair.indexOf('=');
    if (equalsAt == -1) continue;
    final key = pair.substring(0, equalsAt);
    final value = pair.substring(equalsAt + 1);
    values[key] = Uri.decodeComponent(value);
  }
  return values;
}
