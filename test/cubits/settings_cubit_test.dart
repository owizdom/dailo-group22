import 'package:dailo/domain/entities/app_settings.dart';
import 'package:dailo/domain/entities/network.dart';
import 'package:dailo/presentation/cubits/settings_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/in_memory_repositories.dart';

void main() {
  late InMemorySettingsRepository repo;
  late SettingsCubit cubit;

  setUp(() {
    repo = InMemorySettingsRepository();
    cubit = SettingsCubit(repo);
  });

  tearDown(() => cubit.close());

  group('load', () {
    test('reads the stored settings and marks the state loaded', () async {
      repo.stored = const AppSettings(
        darkMode: true,
        defaultNetwork: Network.airtel,
        feeWarning: false,
        language: AppLanguage.kinyarwanda,
      );

      expect(cubit.state.loaded, isFalse);

      await cubit.load();

      expect(cubit.state.loaded, isTrue);
      expect(cubit.state.settings, repo.stored);
    });

    test('an empty store gives the defaults', () async {
      await cubit.load();

      expect(cubit.state.loaded, isTrue);
      expect(cubit.state.settings, const AppSettings());
    });
  });

  group('setters change the state and save once each', () {
    setUp(() async {
      await cubit.load();
    });

    test('setDarkMode', () async {
      await cubit.setDarkMode(true);

      expect(cubit.state.settings.darkMode, isTrue);
      expect(repo.saves, 1);
      expect(repo.stored.darkMode, isTrue);
    });

    test('setDefaultNetwork', () async {
      await cubit.setDefaultNetwork(Network.airtel);

      expect(cubit.state.settings.defaultNetwork, Network.airtel);
      expect(repo.saves, 1);
      expect(repo.stored.defaultNetwork, Network.airtel);
    });

    test('setFeeWarning', () async {
      await cubit.setFeeWarning(false);

      expect(cubit.state.settings.feeWarning, isFalse);
      expect(repo.saves, 1);
      expect(repo.stored.feeWarning, isFalse);
    });

    test('setLanguage', () async {
      await cubit.setLanguage(AppLanguage.kinyarwanda);

      expect(cubit.state.settings.language, AppLanguage.kinyarwanda);
      expect(repo.saves, 1);
      expect(repo.stored.language, AppLanguage.kinyarwanda);
    });

    test('one change leaves the other three settings alone', () async {
      await cubit.setDarkMode(true);

      expect(cubit.state.settings.defaultNetwork, Network.mtn);
      expect(cubit.state.settings.feeWarning, isTrue);
      expect(cubit.state.settings.language, AppLanguage.english);
    });

    test('each setter adds one save', () async {
      await cubit.setDarkMode(true);
      await cubit.setDefaultNetwork(Network.airtel);
      await cubit.setFeeWarning(false);
      await cubit.setLanguage(AppLanguage.kinyarwanda);

      expect(repo.saves, 4);
    });
  });

  group('restored on relaunch', () {
    test('a fresh cubit over the same store has all four values', () async {
      await cubit.load();
      await cubit.setDarkMode(true);
      await cubit.setDefaultNetwork(Network.airtel);
      await cubit.setFeeWarning(false);
      await cubit.setLanguage(AppLanguage.kinyarwanda);

      final relaunched = SettingsCubit(repo);
      addTearDown(relaunched.close);
      await relaunched.load();

      final settings = relaunched.state.settings;
      expect(relaunched.state.loaded, isTrue);
      expect(settings.darkMode, isTrue);
      expect(settings.defaultNetwork, Network.airtel);
      expect(settings.feeWarning, isFalse);
      expect(settings.language, AppLanguage.kinyarwanda);
    });
  });
}
