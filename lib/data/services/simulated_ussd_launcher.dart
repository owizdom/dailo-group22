import '../../domain/services/ussd_launcher.dart';

/// Stands in for the phone dialer on an emulator, which has no SIM.
/// It always reports the code as launched and remembers what was dialled.
class SimulatedUssdLauncher implements UssdLauncher {
  final List<String> dialled = [];

  @override
  Future<UssdOutcome> run(String code) async {
    dialled.add(code);
    return UssdOutcome.launched;
  }
}
