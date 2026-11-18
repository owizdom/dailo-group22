// Verify email and Forgot password screens (track D1).
//
// Neither screen has a string getter yet, so a snack is recognised by its
// type rather than by its words. Where two snacks must say different things
// the test reads their text and compares them to each other.
import 'package:dailo/core/keys.dart';
import 'package:dailo/core/l10n/app_strings.dart';
import 'package:dailo/core/validators.dart';
import 'package:dailo/presentation/cubits/auth_cubit.dart';
import 'package:dailo/presentation/screens/auth/forgot_password_screen.dart';
import 'package:dailo/presentation/screens/auth/verify_email_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/harness.dart';
import '../../fakes/samples.dart';

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

/// Finds [message] when it is the error shown under the field with [field].
Finder errorIn(Key field, String message) =>
    find.descendant(of: find.byKey(field), matching: find.text(message));

/// The words in the snack bar now showing.
String snackText(WidgetTester tester) {
  final text = find.descendant(
    of: find.byType(SnackBar),
    matching: find.byType(Text),
  );
  return tester.widget<Text>(text.first).data!;
}

void main() {
  group('VerifyEmailScreen', () {
    late TestApp app;

    setUp(() => app = TestApp(session: unverifiedSession));

    Future<void> showScreen(WidgetTester tester) async {
      // Start the cubit and let it read the session before the screen is
      // built, the way the real app does when it decides to show this page.
      final auth = app.authCubit;
      await app.bind();
      await tester.pump();
      expect(auth.state.status, AuthStatus.needsVerification);
      await app.pumpScreen(tester, const VerifyEmailScreen(), bindFirst: false);
      await tester.pumpAndSettle();
    }

    testWidgets('shows the address the link was sent to', (tester) async {
      await showScreen(tester);

      expect(find.textContaining('aline@example.com'), findsWidgets);
    });

    testWidgets('Resend sends the email again and says so', (tester) async {
      await showScreen(tester);

      await tapKey(tester, K.verifyResend);

      expect(app.auth.calls, contains('sendVerificationEmail'));
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('"I have verified" while still unverified checks and says so', (
      tester,
    ) async {
      await showScreen(tester);
      app.auth.verifiedAfterReload = false;

      await tapKey(tester, K.verifyCheck);

      expect(app.auth.calls, contains('reloadVerified'));
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('the sent and still-unverified snacks say different things', (
      tester,
    ) async {
      await showScreen(tester);

      await tapKey(tester, K.verifyResend);
      final sentText = snackText(tester);
      await tapKey(tester, K.verifyCheck);
      final stillUnverifiedText = snackText(tester);

      expect(sentText, isNotEmpty);
      expect(stillUnverifiedText, isNotEmpty);
      expect(stillUnverifiedText, isNot(sentText));
    });

    testWidgets('Sign out signs the user out', (tester) async {
      await showScreen(tester);

      await tapKey(tester, K.verifySignOut);

      expect(app.auth.calls, contains('signOut'));
      expect(app.auth.session, isNull);
    });
  });

  group('ForgotPasswordScreen', () {
    late TestApp app;
    late AppStrings strings;

    setUp(() {
      app = TestApp(session: null);
      strings = app.strings();
    });

    Future<void> showScreen(WidgetTester tester) async {
      await app.pumpScreen(tester, const ForgotPasswordScreen());
      await tester.pumpAndSettle();
    }

    testWidgets('shows no error before the first submit', (tester) async {
      await showScreen(tester);

      // The form is really there, so "no error" is not just a blank page.
      expect(find.byKey(K.forgotSubmit), findsOneWidget);
      for (final error in FieldError.values) {
        expect(find.text(strings.fieldError(error)), findsNothing);
      }
    });

    testWidgets('an empty submit asks for the email and sends nothing', (
      tester,
    ) async {
      await showScreen(tester);

      await tapKey(tester, K.forgotSubmit);

      expect(
        errorIn(K.forgotEmail, strings.fieldError(FieldError.required)),
        findsOneWidget,
      );
      expect(app.auth.calls, isNot(contains('sendPasswordReset')));
    });

    testWidgets('a malformed email is named and sends nothing', (tester) async {
      await showScreen(tester);
      await typeInto(tester, K.forgotEmail, 'abc');

      await tapKey(tester, K.forgotSubmit);

      expect(
        errorIn(K.forgotEmail, strings.fieldError(FieldError.invalidEmail)),
        findsOneWidget,
      );
      expect(app.auth.calls, isNot(contains('sendPasswordReset')));
    });

    testWidgets('a valid email sends the reset and stays on the screen', (
      tester,
    ) async {
      await showScreen(tester);
      await typeInto(tester, K.forgotEmail, 'aline@example.com');

      await tapKey(tester, K.forgotSubmit);

      expect(app.auth.calls, contains('sendPasswordReset'));
      expect(find.byType(SnackBar), findsOneWidget);
      // The user stays to read the message: nothing was pushed or popped.
      expect(app.pushed, isEmpty);
      expect(find.byKey(K.forgotSubmit), findsOneWidget);
    });
  });
}
