// Settings screen (track D2).
//
// Every control calls one SettingsCubit method. The cubit saves at once, so
// each test checks two places: the cubit state the app reads, and
// `app.settingsRepo.stored`, which is what would survive a restart.
import 'package:dailo/core/keys.dart';
import 'package:dailo/core/routes.dart';
import 'package:dailo/domain/entities/app_settings.dart';
import 'package:dailo/domain/entities/network.dart';
import 'package:dailo/presentation/screens/home/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/harness.dart';

/// Scrolls [key] into view, taps it and waits for the screen to settle.
Future<void> tapKey(WidgetTester tester, Key key) async {
  expect(find.byKey(key), findsOneWidget, reason: 'nothing on screen has $key');
  await tester.ensureVisible(find.byKey(key));
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

/// The Switch under [key], whether the key sits on the Switch itself or on a
/// list tile around it.
/// Matches any text input that hides what is typed, like a password or PIN.
final hiddenInput = find.byWidgetPredicate(
  (widget) => widget is EditableText && widget.obscureText,
);

bool switchValue(WidgetTester tester, Key key) {
  expect(find.byKey(key), findsOneWidget, reason: 'nothing on screen has $key');
  final found = find.descendant(
    of: find.byKey(key),
    matching: find.byType(Switch),
    matchRoot: true,
  );
  return tester.widget<Switch>(found).value;
}

bool chipSelected(WidgetTester tester, Key key) {
  expect(find.byKey(key), findsOneWidget, reason: 'nothing on screen has $key');
  final found = find.descendant(
    of: find.byKey(key),
    matching: find.byType(ChoiceChip),
    matchRoot: true,
  );
  return tester.widget<ChoiceChip>(found).selected;
}

void main() {
  late TestApp app;

  setUp(() => app = TestApp());

  Future<void> showSettings(WidgetTester tester) async {
    await app.pumpScreen(tester, const SettingsScreen());
    await tester.pumpAndSettle();
  }

  testWidgets('has no password or PIN field', (tester) async {
    await showSettings(tester);

    // The screen is really there, and nothing on it hides typed text.
    expect(find.byKey(K.settingsSignOut), findsOneWidget);
    expect(hiddenInput, findsNothing);
  });

  group('profile card', () {
    testWidgets('shows the name and email of the signed-in user', (
      tester,
    ) async {
      await showSettings(tester);

      expect(find.textContaining('Aline Mukamana'), findsWidgets);
      expect(find.textContaining('aline@example.com'), findsWidgets);
    });

    testWidgets('Edit profile opens the profile form', (tester) async {
      await showSettings(tester);

      await tapKey(tester, K.settingsEditProfile);

      expect(find.text('route:${Routes.editProfile}'), findsOneWidget);
    });
  });

  group('preferences', () {
    testWidgets('start from the saved values', (tester) async {
      await showSettings(tester);

      expect(switchValue(tester, K.settingsDark), isFalse);
      expect(switchValue(tester, K.settingsFeeWarning), isTrue);
      expect(chipSelected(tester, K.settingsNetworkMtn), isTrue);
      expect(chipSelected(tester, K.settingsNetworkAirtel), isFalse);
      expect(chipSelected(tester, K.settingsLanguageEnglish), isTrue);
      expect(chipSelected(tester, K.settingsLanguageKinyarwanda), isFalse);
    });

    testWidgets('the dark mode switch turns dark mode on and saves it', (
      tester,
    ) async {
      await showSettings(tester);

      await tapKey(tester, K.settingsDark);

      expect(app.settingsCubit.state.settings.darkMode, isTrue);
      expect(app.settingsRepo.stored.darkMode, isTrue);
      expect(switchValue(tester, K.settingsDark), isTrue);
      // Only that one preference changed.
      expect(app.settingsRepo.stored, const AppSettings(darkMode: true));
    });

    testWidgets('the fee warning switch turns the warning off and saves it', (
      tester,
    ) async {
      await showSettings(tester);

      await tapKey(tester, K.settingsFeeWarning);

      expect(app.settingsCubit.state.settings.feeWarning, isFalse);
      expect(app.settingsRepo.stored.feeWarning, isFalse);
      expect(switchValue(tester, K.settingsFeeWarning), isFalse);
      expect(app.settingsRepo.stored, const AppSettings(feeWarning: false));
    });

    testWidgets('choosing Airtel saves it as the default network', (
      tester,
    ) async {
      await showSettings(tester);

      await tapKey(tester, K.settingsNetworkAirtel);

      expect(app.settingsRepo.stored.defaultNetwork, Network.airtel);
      expect(app.settingsCubit.state.settings.defaultNetwork, Network.airtel);
      expect(chipSelected(tester, K.settingsNetworkAirtel), isTrue);
      expect(chipSelected(tester, K.settingsNetworkMtn), isFalse);
    });

    testWidgets('choosing Ikinyarwanda saves it as the language', (
      tester,
    ) async {
      await showSettings(tester);

      await tapKey(tester, K.settingsLanguageKinyarwanda);

      expect(app.settingsRepo.stored.language, AppLanguage.kinyarwanda);
      expect(
        app.settingsCubit.state.settings.language,
        AppLanguage.kinyarwanda,
      );
      expect(chipSelected(tester, K.settingsLanguageKinyarwanda), isTrue);
      expect(chipSelected(tester, K.settingsLanguageEnglish), isFalse);
    });
  });

  group('signing out', () {
    testWidgets('asks first and does nothing until the user answers', (
      tester,
    ) async {
      await showSettings(tester);

      await tapKey(tester, K.settingsSignOut);

      expect(find.byKey(K.confirmYes), findsOneWidget);
      expect(find.byKey(K.confirmNo), findsOneWidget);
      expect(app.auth.calls, isNot(contains('signOut')));
    });

    testWidgets('No closes the dialog and keeps the user signed in', (
      tester,
    ) async {
      await showSettings(tester);
      await tapKey(tester, K.settingsSignOut);

      await tapKey(tester, K.confirmNo);

      expect(find.byKey(K.confirmYes), findsNothing);
      expect(app.auth.calls, isNot(contains('signOut')));
      expect(app.auth.session, isNotNull);
    });

    testWidgets('Yes signs the user out', (tester) async {
      await showSettings(tester);
      await tapKey(tester, K.settingsSignOut);

      await tapKey(tester, K.confirmYes);

      expect(app.auth.calls, contains('signOut'));
      expect(app.auth.session, isNull);
    });
  });
}