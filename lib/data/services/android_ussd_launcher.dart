import 'package:flutter/services.dart';

import '../../domain/services/ussd_launcher.dart';

/// Dials a USSD code through the Kotlin method channel `dailo/ussd`
/// in `MainActivity`.
class AndroidUssdLauncher implements UssdLauncher {
  static const _channel = MethodChannel('dailo/ussd');

  @override
  Future<UssdOutcome> run(String code) async {
    try {
      final reply = await _channel.invokeMethod<String>('dial', {'code': code});
      return _outcomeFrom(reply);
    } on PlatformException {
      return UssdOutcome.unsupported;
    } on MissingPluginException {
      // No Kotlin side is listening, for example on a desktop build.
      return UssdOutcome.unsupported;
    }
  }

  /// The Kotlin side answers with the name of an outcome.
  UssdOutcome _outcomeFrom(String? reply) {
    return UssdOutcome.values.firstWhere(
      (outcome) => outcome.name == reply,
      orElse: () => UssdOutcome.unsupported,
    );
  }
}
