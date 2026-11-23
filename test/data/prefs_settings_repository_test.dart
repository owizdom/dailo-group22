import 'package:dailo/data/repositories/prefs_settings_repository.dart';
import 'package:dailo/domain/entities/app_settings.dart';
import 'package:dailo/domain/entities/network.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const changed = AppSettings(
    darkMode: true,
    defaultNetwork: Network.airtel,
    feeWarning: false,
    language: AppLanguage.kinyarwanda,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('load', () {
    test('an empty store gives the defaults', () async {
      final settings = await PrefsSettingsRepository().load();

      expect(settings, const AppSettings());
    });
  });

  group('save', () {
    test('a new repository instance loads the same four values', () async {
      await PrefsSettingsRepository().save(changed);

      final settings = await PrefsSettingsRepository().load();

      expect(settings.darkMode, isTrue);
      expect(settings.defaultNetwork, Network.airtel);
      expect(settings.feeWarning, isFalse);
      expect(settings.language, AppLanguage.kinyarwanda);
    });

    test('stores exactly four keys, one per setting', () async {
      await PrefsSettingsRepository().save(changed);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), {
        'darkMode',
        'defaultNetwork',
        'feeWarning',
        'language',
      });
    });

    test(
      'stores the wire value of the network and the language code',
      () async {
        await PrefsSettingsRepository().save(changed);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.get('darkMode'), true);
        expect(prefs.get('feeWarning'), false);
        expect(prefs.get('defaultNetwork'), 'airtel');
        expect(prefs.get('language'), 'rw');
      },
    );

    test('saving again replaces the earlier values', () async {
      final repo = PrefsSettingsRepository();
      await repo.save(changed);

      await repo.save(const AppSettings());

      expect(await PrefsSettingsRepository().load(), const AppSettings());
    });
  });

  group('garbage in the store', () {
    test('values of the wrong kind load as the defaults', () async {
      SharedPreferences.setMockInitialValues({
        'darkMode': 'maybe',
        'defaultNetwork': 'xyz',
        'feeWarning': 42,
        'language': 'klingon',
      });

      final settings = await PrefsSettingsRepository().load();

      expect(settings, const AppSettings());
    });

    test('a bad network does not discard the other settings', () async {
      SharedPreferences.setMockInitialValues({
        'darkMode': true,
        'defaultNetwork': 'xyz',
        'feeWarning': false,
        'language': 'rw',
      });

      final settings = await PrefsSettingsRepository().load();

      expect(settings.defaultNetwork, Network.mtn);
      expect(settings.darkMode, isTrue);
      expect(settings.feeWarning, isFalse);
      expect(settings.language, AppLanguage.kinyarwanda);
    });
  });
}
