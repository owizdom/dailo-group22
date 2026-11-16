/// The mobile money operators DailO can dial.
enum Network {
  mtn('mtn', 'MTN'),
  airtel('airtel', 'Airtel');

  const Network(this.wire, this.label);

  /// The value stored in Firestore and SharedPreferences.
  final String wire;

  /// The name shown on screen.
  final String label;

  /// Reads a stored value. Unknown or missing values fall back to MTN,
  /// which holds most mobile money accounts in Rwanda.
  static Network fromWire(Object? value) {
    return Network.values.firstWhere(
      (network) => network.wire == value,
      orElse: () => Network.mtn,
    );
  }
}
