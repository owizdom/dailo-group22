import '../entities/app_settings.dart';

/// Saves and restores the on-device preferences.
abstract class SettingsRepository {
  Future<AppSettings> load();

  Future<void> save(AppSettings settings);
}
