/// What happened when DailO asked the phone to dial a USSD code.
enum UssdOutcome {
  /// The phone accepted the code and opened the operator's dialog.
  launched,

  /// The user refused the phone-call permission.
  permissionDenied,

  /// The phone has no SIM that can dial.
  noSim,

  /// This device cannot dial USSD codes at all.
  unsupported,
}

/// Dials a USSD code. The Android implementation uses a method channel;
/// tests and the emulator use a simulated one.
abstract class UssdLauncher {
  Future<UssdOutcome> run(String code);
}
