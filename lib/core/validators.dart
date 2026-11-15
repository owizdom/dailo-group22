import '../domain/logic/fee_table.dart';
import '../domain/logic/phone_number.dart';

/// Why a form field was rejected. The screen turns each value into a polite
/// message in the user's language with `AppStrings.fieldError`.
enum FieldError {
  required,
  invalidEmail,
  weakPassword,
  passwordMismatch,
  nameTooShort,
  nameTooLong,
  invalidPhone,
  invalidAmount,
  amountTooLarge,
  messageTooShort,
  messageTooLong,
  termsNotAccepted,
}

/// Required, and shaped like `name@example.com`.
FieldError? validateEmail(String? value) {
  if (_isBlank(value)) return FieldError.required;
  final looksLikeEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!looksLikeEmail.hasMatch(value!.trim())) return FieldError.invalidEmail;
  return null;
}

/// True for null, empty and spaces-only text.
bool _isBlank(String? value) => value == null || value.trim().isEmpty;

/// Required, at least 8 characters, with at least one letter and one digit.
FieldError? validatePassword(String? value) {
  if (value == null || value.isEmpty) return FieldError.required;
  final hasLetter = RegExp(r'[A-Za-z]').hasMatch(value);
  final hasDigit = RegExp(r'[0-9]').hasMatch(value);
  if (value.length < 8 || !hasLetter || !hasDigit) {
    return FieldError.weakPassword;
  }
  return null;
}

/// Sign-in only checks that a password was typed. Its strength was checked
/// when the account was created.
FieldError? validateSignInPassword(String? value) {
  if (value == null || value.isEmpty) return FieldError.required;
  return null;
}

/// Required, and equal to [password].
FieldError? validateConfirmPassword(String? value, String password) {
  if (value == null || value.isEmpty) return FieldError.required;
  if (value != password) return FieldError.passwordMismatch;
  return null;
}

/// Required, 2 to 30 characters after trimming.
FieldError? validateName(String? value) {
  if (_isBlank(value)) return FieldError.required;
  final length = value!.trim().length;
  if (length < 2) return FieldError.nameTooShort;
  if (length > 30) return FieldError.nameTooLong;
  return null;
}

/// Required, and a valid Rwandan mobile number in any accepted form.
FieldError? validatePhone(String? value) {
  if (_isBlank(value)) return FieldError.required;
  if (normalisePhone(value!) == null) return FieldError.invalidPhone;
  return null;
}

/// Required, digits only (commas and spaces allowed), between 1 and
/// 10,000,000 francs.
FieldError? validateAmount(String? value) {
  if (_isBlank(value)) return FieldError.required;
  final amount = parseAmount(value!);
  if (amount == null || amount < minAmount) return FieldError.invalidAmount;
  if (amount > maxAmount) return FieldError.amountTooLarge;
  return null;
}

/// The longest feedback message the server accepts (see firestore.rules).
const int maxFeedbackLength = 2000;

/// Required, 10 to 2,000 characters after trimming.
FieldError? validateFeedback(String? value) {
  if (_isBlank(value)) return FieldError.required;
  final length = value!.trim().length;
  if (length < 10) return FieldError.messageTooShort;
  if (length > maxFeedbackLength) return FieldError.messageTooLong;
  return null;
}

/// Reads the digits out of an amount field: `"10,500"` gives 10500.
/// Returns null when there are no digits or anything else was typed.
int? parseAmount(String value) {
  final digits = value.replaceAll(RegExp(r'[,\s]'), '');
  if (!RegExp(r'^\d+$').hasMatch(digits)) return null;
  return int.tryParse(digits);
}
