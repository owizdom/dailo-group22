import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/entities/network.dart';
import '../../domain/repositories/settings_repository.dart';

/// [SettingsRepository] backed by SharedPreferences. One key per setting:
/// `darkMode`, `defaultNetwork`, `feeWarning`, `language`.
class PrefsSettingsRepository implements SettingsRepository {
  static const _darkModeKey = 'darkMode';
  static const _defaultNetworkKey = 'defaultNetwork';
  static const _feeWarningKey = 'feeWarning';
  static const _languageKey = 'language';

  @override
  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    const defaults = AppSettings();
    // Each key is read on its own, so one bad key never discards the others.
    // `get` returns the raw value (`getBool` would throw on a wrong kind), and
    // `fromWire` / `fromCode` fall back for unknown text.
    return AppSettings(
      darkMode: _asBool(prefs.get(_darkModeKey)) ?? defaults.darkMode,
      defaultNetwork: Network.fromWire(prefs.get(_defaultNetworkKey)),
      feeWarning: _asBool(prefs.get(_feeWarningKey)) ?? defaults.feeWarning,
      language: AppLanguage.fromCode(prefs.get(_languageKey)),
    );
  }

  bool? _asBool(Object? value) => value is bool ? value : null;

  @override
  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, settings.darkMode);
    await prefs.setString(_defaultNetworkKey, settings.defaultNetwork.wire);
    await prefs.setBool(_feeWarningKey, settings.feeWarning);
    await prefs.setString(_languageKey, settings.language.code);
  }
}
