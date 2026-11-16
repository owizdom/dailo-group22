import 'package:equatable/equatable.dart';

import 'network.dart';

/// The languages the app can show.
enum AppLanguage {
  english('en', 'English'),
  kinyarwanda('rw', 'Ikinyarwanda');

  const AppLanguage(this.code, this.label);

  /// Language code, also the value saved in SharedPreferences.
  final String code;
  final String label;

  static AppLanguage fromCode(Object? value) {
    return AppLanguage.values.firstWhere(
      (language) => language.code == value,
      orElse: () => AppLanguage.english,
    );
  }
}

/// The preferences kept on the phone with SharedPreferences.
/// They are restored every time the app starts.
class AppSettings extends Equatable {
  const AppSettings({
    this.darkMode = false,
    this.defaultNetwork = Network.mtn,
    this.feeWarning = true,
    this.language = AppLanguage.english,
  });

  final bool darkMode;

  /// The network of the SIM the user pays from.
  final Network defaultNetwork;

  /// Whether the amount screen warns when a slightly smaller amount
  /// would cost a lower fee.
  final bool feeWarning;
  final AppLanguage language;

  AppSettings copyWith({
    bool? darkMode,
    Network? defaultNetwork,
    bool? feeWarning,
    AppLanguage? language,
  }) {
    return AppSettings(
      darkMode: darkMode ?? this.darkMode,
      defaultNetwork: defaultNetwork ?? this.defaultNetwork,
      feeWarning: feeWarning ?? this.feeWarning,
      language: language ?? this.language,
    );
  }

  @override
  List<Object?> get props => [darkMode, defaultNetwork, feeWarning, language];
}
