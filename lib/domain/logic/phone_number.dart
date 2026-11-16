import '../entities/network.dart';

/// Cleans a Rwandan mobile number into the `07XXXXXXXX` form.
///
/// Accepts spaces, dashes and the `+250` or `250` country prefix.
/// Returns null when the result is not a valid Rwandan mobile number.
String? normalisePhone(String input) {
  var digits = input.replaceAll(RegExp(r'[\s-]'), '');

  // Swap the country code for the leading 0 of the local form.
  if (digits.startsWith('+250')) {
    digits = '0${digits.substring(4)}';
  } else if (digits.startsWith('250')) {
    digits = '0${digits.substring(3)}';
  }

  final isTenDigits = RegExp(r'^\d{10}$').hasMatch(digits);
  if (!isTenDigits) return null;
  if (networkOf(digits) == null) return null;
  return digits;
}

/// The operator a normalised number belongs to: 078 and 079 are MTN,
/// 072 and 073 are Airtel. Returns null for anything else.
Network? networkOf(String phone) {
  if (phone.startsWith('078') || phone.startsWith('079')) return Network.mtn;
  if (phone.startsWith('072') || phone.startsWith('073')) return Network.airtel;
  return null;
}

/// Formats a normalised number for reading: `078 845 2310`.
/// Returns the input unchanged when it is not 10 digits.
String prettyPhone(String phone) {
  final isTenDigits = RegExp(r'^\d{10}$').hasMatch(phone);
  if (!isTenDigits) return phone;
  return '${phone.substring(0, 3)} ${phone.substring(3, 6)} '
      '${phone.substring(6)}';
}
