import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/entities/network.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.settings = const AppSettings(),
    this.loaded = false,
  });

  final AppSettings settings;

  /// False until the saved values have been read from the phone.
  final bool loaded;

  @override
  List<Object?> get props => [settings, loaded];
}

/// The four preferences saved with SharedPreferences: theme, default
/// network, fee warning and language. Every setter saves straight away, so
/// the value is still there after the app is closed and opened again.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this.repository) : super(const SettingsState());

  final SettingsRepository repository;

  /// Reads the saved values. Called once before the first screen.
  Future<void> load() async {
    final settings = await repository.load();
    emit(SettingsState(settings: settings, loaded: true));
  }

  Future<void> setDarkMode(bool value) =>
      _change(state.settings.copyWith(darkMode: value));

  Future<void> setDefaultNetwork(Network value) =>
      _change(state.settings.copyWith(defaultNetwork: value));

  Future<void> setFeeWarning(bool value) =>
      _change(state.settings.copyWith(feeWarning: value));

  Future<void> setLanguage(AppLanguage value) =>
      _change(state.settings.copyWith(language: value));

  /// Shows the new settings straight away, then saves them.
  Future<void> _change(AppSettings settings) {
    emit(SettingsState(settings: settings, loaded: state.loaded));
    return repository.save(settings);
  }
}
