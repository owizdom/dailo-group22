import '../../domain/entities/app_settings.dart';

/// The base every group of strings builds on.
///
/// Each string is written once with both languages side by side:
/// `String get save => t('Save', 'Bika');`
abstract class StringsBase {
  const StringsBase(this.language);

  final AppLanguage language;

  /// Picks the English or the Kinyarwanda text for the current language.
  String t(String english, String kinyarwanda) {
    return language == AppLanguage.kinyarwanda ? kinyarwanda : english;
  }
}
