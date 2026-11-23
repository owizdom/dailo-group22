// Whole-app flows: the real DailoApp, with the real cubits and the real
// screens, over the in-memory fakes. No harness page stands in for a route
// here, so a tap that should open History really opens History.
//
// Covers: which first screen shows for each sign-in state, signing in and
// out, going into a screen and back, the saved theme and language, AT23
// (preferences survive a relaunch) and AT14 (two widgets, one state).
//
// Screens owned by other tracks (History, Send Money, Recipients) are used
// here as destinations, so these flows go green once those screens exist.
import 'package:dailo/app.dart';
import 'package:dailo/core/keys.dart';
import 'package:dailo/core/l10n/app_strings.dart';
import 'package:dailo/domain/entities/app_settings.dart';
import 'package:dailo/domain/entities/network.dart';
import 'package:dailo/domain/entities/recipient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/harness.dart';
import '../fakes/samples.dart';

/// Scrolls [key] into view, taps it and waits for the screen to settle.
Future<void> tapKey(WidgetTester tester, Key key) async {
  expect(find.byKey(key), findsOneWidget, reason: 'nothing on screen has $key');
  await tester.ensureVisible(find.byKey(key));
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

/// Types into the field with [key].
Future<void> typeInto(WidgetTester tester, Key key, String text) async {
  expect(find.byKey(key), findsOneWidget, reason: 'nothing on screen has $key');
  await tester.enterText(find.byKey(key), text);
  await tester.pump();
}

/// Starts the whole app on a normal phone and waits for the first screen.
///
/// Pass a [key] to start a second, separate copy of the app later in the
/// same test: a new key makes Flutter throw the old copy away.
Future<void> launch(WidgetTester tester, TestApp app, {Key? key}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(DailoApp(key: key, dependencies: app.dependencies));
  await tester.pumpAndSettle();
}

/// The brightness of the theme Home is drawn with.
Brightness homeBrightness(WidgetTester tester) {
  expect(find.byKey(K.homeSend), findsOneWidget, reason: 'Home is not showing');
  return Theme.of(tester.element(find.byKey(K.homeSend))).brightness;
}

/// Whether the Send Money tile on Home carries the Send Money label of
/// [language].
Finder sendLabel(AppLanguage language) {
  return find.descendant(
    of: find.byKey(K.homeSend),
    matching: find.text(AppStrings(language).sendMoney),
  );
}

void main() {
  group('the first screen follows the sign-in state', () {
    testWidgets('signed out: Sign In shows, and signing in lands on Home', (
      tester,
    ) async {
      final app = TestApp(session: null);
      await launch(tester, app);
      expect(find.byKey(K.signInSubmit), findsOneWidget);
      expect(find.byKey(K.homeSend), findsNothing);

      await typeInto(tester, K.signInEmail, 'aline@example.com');
      await typeInto(tester, K.signInPassword, 'secret123');
      await tapKey(tester, K.signInSubmit);

      expect(find.byKey(K.homeSend), findsOneWidget);
      expect(find.byKey(K.signInSubmit), findsNothing);
      expect(app.auth.calls, contains('signIn'));
    });

    testWidgets('already signed in: Home shows straight away', (tester) async {
      // The session is restored by Firebase when the app restarts, so this
      // is "auth state kept after restart".
      final app = TestApp();
      await launch(tester, app);

      expect(find.byKey(K.homeSend), findsOneWidget);
      expect(find.byKey(K.signInSubmit), findsNothing);
      // Nobody typed a password: the session came from the stream.
      expect(app.auth.calls, isNot(contains('signIn')));
    });

    testWidgets('email not verified: Verify shows, then Home once it is', (
      tester,
    ) async {
      final app = TestApp(session: unverifiedSession);
      await launch(tester, app);
      expect(find.byKey(K.verifyCheck), findsOneWidget);
      expect(find.byKey(K.homeSend), findsNothing);

      app.auth.verifiedAfterReload = true;
      await tapKey(tester, K.verifyCheck);

      expect(find.byKey(K.homeSend), findsOneWidget);
      expect(find.byKey(K.verifyCheck), findsNothing);
    });

    testWidgets('signing up as a new user leads to the Verify screen', (
      tester,
    ) async {
      final app = TestApp(session: null);
      await launch(tester, app);
      await tapKey(tester, K.signInToSignUp);
      await typeInto(tester, K.signUpFirstName, 'Aline');
      await typeInto(tester, K.signUpLastName, 'Mukamana');
      await tapKey(tester, K.signUpContinue);

      await typeInto(tester, K.signUpEmail, 'aline@example.com');
      await typeInto(tester, K.signUpPhone, '0788123456');
      await typeInto(tester, K.signUpPassword, 'secret123');
      await typeInto(tester, K.signUpConfirm, 'secret123');
      await tapKey(tester, K.signUpTerms);
      await tapKey(tester, K.signUpSubmit);

      // The fake signs the new account up unverified.
      expect(find.byKey(K.verifyCheck), findsOneWidget);
      expect(find.byKey(K.signUpSubmit), findsNothing);
      expect(find.byKey(K.homeSend), findsNothing);
    });

    testWidgets('the sign-in link on step 1 of sign-up goes back to Sign In', (
      tester,
    ) async {
      final app = TestApp(session: null);
      await launch(tester, app);
      await tapKey(tester, K.signInToSignUp);
      expect(find.byKey(K.signUpContinue), findsOneWidget);

      await tapKey(tester, K.signUpToSignIn);

      expect(find.byKey(K.signInSubmit), findsOneWidget);
      expect(find.byKey(K.signUpContinue), findsNothing);
    });
  });

  group('moving around while signed in', () {
    testWidgets('signing out from Settings returns to Sign In', (tester) async {
      final app = TestApp();
      await launch(tester, app);
      await tapKey(tester, K.homeSettings);
      expect(find.byKey(K.settingsSignOut), findsOneWidget);

      await tapKey(tester, K.settingsSignOut);
      await tapKey(tester, K.confirmYes);

      expect(app.auth.calls, contains('signOut'));
      expect(find.byKey(K.signInSubmit), findsOneWidget);
      // Neither Home nor the Settings page is left underneath.
      expect(find.byKey(K.homeSend, skipOffstage: false), findsNothing);
      expect(find.byKey(K.settingsSignOut, skipOffstage: false), findsNothing);
    });

    testWidgets('a real screen opens from Home and Back returns to Home', (
      tester,
    ) async {
      final app = TestApp();
      await launch(tester, app);

      await tapKey(tester, K.homeSeeMore);
      expect(find.byKey(K.historySearch), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back).first);
      await tester.pumpAndSettle();

      expect(find.byKey(K.homeSend), findsOneWidget);
      expect(find.byKey(K.historySearch), findsNothing);
    });
  });

  group('the saved preferences are applied', () {
    testWidgets('dark mode saved: the app starts dark', (tester) async {
      final app = TestApp(settings: const AppSettings(darkMode: true));
      await launch(tester, app);

      expect(homeBrightness(tester), Brightness.dark);
    });

    testWidgets('no saved preference: the app starts light', (tester) async {
      final app = TestApp();
      await launch(tester, app);

      expect(homeBrightness(tester), Brightness.light);
    });

    testWidgets('Kinyarwanda saved: Home speaks Kinyarwanda', (tester) async {
      final app = TestApp(
        settings: const AppSettings(language: AppLanguage.kinyarwanda),
      );
      await launch(tester, app);

      expect(sendLabel(AppLanguage.kinyarwanda), findsOneWidget);
      expect(
        find.text(AppStrings(AppLanguage.english).sendMoney),
        findsNothing,
      );
    });

    testWidgets('English by default: Home speaks English', (tester) async {
      final app = TestApp();
      await launch(tester, app);

      expect(sendLabel(AppLanguage.english), findsOneWidget);
      expect(
        find.text(AppStrings(AppLanguage.kinyarwanda).sendMoney),
        findsNothing,
      );
    });

    testWidgets('a change in Settings applies at once, without a restart', (
      tester,
    ) async {
      final app = TestApp();
      await launch(tester, app);
      await tapKey(tester, K.homeSettings);

      await tapKey(tester, K.settingsDark);

      expect(
        Theme.of(tester.element(find.byKey(K.settingsDark))).brightness,
        Brightness.dark,
      );
    });
  });

  group('AT23: preferences survive a relaunch', () {
    testWidgets('a second copy of the app starts dark and in Kinyarwanda', (
      tester,
    ) async {
      final app = TestApp();
      await launch(tester, app, key: const Key('first launch'));
      await tapKey(tester, K.homeSettings);
      await tapKey(tester, K.settingsDark);
      await tapKey(tester, K.settingsLanguageKinyarwanda);
      // What the first copy saved, which is all a relaunch has to go on.
      expect(app.settingsRepo.stored.darkMode, isTrue);
      expect(app.settingsRepo.stored.language, AppLanguage.kinyarwanda);

      // Throw the first copy away and start a new one over the same stores.
      await tester.pumpWidget(
        DailoApp(key: UniqueKey(), dependencies: app.dependencies),
      );
      await tester.pumpAndSettle();

      // Still signed in, so Home shows rather than Sign In.
      expect(find.byKey(K.homeSend), findsOneWidget);
      expect(homeBrightness(tester), Brightness.dark);
      expect(sendLabel(AppLanguage.kinyarwanda), findsOneWidget);
      expect(
        find.text(AppStrings(AppLanguage.english).sendMoney),
        findsNothing,
      );
    });
  });

  group('AT14: two widgets, one state', () {
    testWidgets('Send Money and the recipients list show the same people', (
      tester,
    ) async {
      final app = TestApp();
      await launch(tester, app);

      await tapKey(tester, K.homeSend);
      expect(find.byKey(K.recipientTile('r1')), findsOneWidget);

      await tapKey(tester, K.sendViewAll);
      expect(find.byKey(K.recipientTile('r1')), findsOneWidget);
    });

    testWidgets('a recipient saved while Send Money is open appears there', (
      tester,
    ) async {
      final app = TestApp();
      await launch(tester, app);
      await tapKey(tester, K.homeSend);
      expect(find.byKey(K.recipientTile('new1')), findsNothing);

      // No pull to refresh: the repository pushes the change to the cubit
      // and the list rebuilds.
      await app.recipientRepo.add(
        'u1',
        Recipient(
          id: '',
          name: 'Chantal Uwera',
          phone: '0788111222',
          network: Network.mtn,
          createdAt: day3.add(const Duration(days: 1)),
          updatedAt: day3.add(const Duration(days: 1)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(K.recipientTile('new1')), findsOneWidget);
    });
  });
}
