/// Turns a stored date into a [DateTime].
///
/// Firestore returns its own Timestamp type. The domain layer must not import
/// Firestore, so this accepts a DateTime, anything with a `toDate()` method,
/// or milliseconds since epoch. Anything else gives [fallback].
DateTime readDate(Object? value, {required DateTime fallback}) {
  return readDateOrNull(value) ?? fallback;
}

/// Same as [readDate] but keeps a missing value as null.
DateTime? readDateOrNull(Object? value) {
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return _readThroughToDate(value);
}

/// Calls `value.toDate()` when the object has one, such as a Firestore
/// Timestamp. Returns null for anything without that method.
DateTime? _readThroughToDate(Object? value) {
  if (value == null) return null;
  try {
    final date = (value as dynamic).toDate();
    if (date is DateTime) return date;
  } on NoSuchMethodError {
    // The object has no toDate(), so it is not a date.
  }
  return null;
}
