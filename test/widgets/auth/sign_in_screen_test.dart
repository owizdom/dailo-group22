// AT12 (sign-in half): the Sign In screen.
//
// What these tests pin down, from contracts/screens.md:
//   - no error shows before the first submit, then the form validates
//   - an error clears while the user types, without another submit
//   - a valid form calls the cubit, a failure shows its message in a snack
//   - the Google, Forgot password and Sign up controls do their one job
//
// The real AuthCubit runs over FakeAuthRepository, so `app.auth.calls` tells
// us which repository methods the screen caused.
import 'package:dailo/core/keys.dart';
import 'package:dailo/core/l10n/app_strings.dart';
import 'package:dailo/core/routes.dart';
import 'package:dailo/core/validators.dart';
import 'package:dailo/domain/repositories/auth_failure.dart';
import 'package:dailo/presentation/screens/auth/sign_in_screen.dart';
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

/// Types into the field with [key].
Future<void> typeInto(WidgetTester tester, Key key, String text) async {
  expect(find.byKey(key), findsOneWidget, reason: 'nothing on screen has $key');
  await tester.enterText(find.byKey(key), text);
  await tester.pump();
}

/// Finds [message] when it is the error shown under the field with [field].
Finder errorIn(Key field, String message) =>
    find.descendant(of: find.byKey(field), matching: find.text(message));

/// True when the field with [field] hides what is typed.
bool isObscured(WidgetTester tester, Key field) {
  expect(
    find.byKey(field),
    findsOneWidget,
    reason: 'nothing on screen has $field',
  );
  final input = find.descendant(
    of: find.byKey(field),
    matching: find.byType(EditableText),
  );
  return tester.widget<EditableText>(input).obscureText;
}

void main() {
  late TestApp app;
  late AppStrings strings;

  setUp(() {
    app = TestApp(session: null);
    strings = app.strings();
  });

  Future<void> showScreen(WidgetTester tester) async {
    await app.pumpScreen(tester, const SignInScreen());
    await tester.pumpAndSettle();
  }

  Future<void> fillValid(WidgetTester tester) async {
    await typeInto(tester, K.signInEmail, 'aline@example.com');
    await typeInto(tester, K.signInPassword, 'secret123');
  }

  group('validation', () {
    testWidgets('shows no error before the first submit', (tester) async {
      await showScreen(tester);

      // The form is really there, so "no error" is not just a blank page.
      expect(find.byKey(K.signInSubmit), findsOneWidget);
      for (final error in FieldError.values) {
        expect(
          find.text(strings.fieldError(error)),
          findsNothing,
          reason: 'an untouched form must not show ${error.name}',
        );
      }
    });

    testWidgets('an empty submit asks for both fields and calls nothing', (
      tester,
    ) async {
      await showScreen(tester);

      await tapKey(tester, K.signInSubmit);

      final required = strings.fieldError(FieldError.required);
      expect(errorIn(K.signInEmail, required), findsOneWidget);
      expect(errorIn(K.signInPassword, required), findsOneWidget);
      expect(app.auth.calls, isNot(contains('signIn')));
    });

    testWidgets('typing a valid email clears its error without a new submit', (
      tester,
    ) async {
      await showScreen(tester);
      await tapKey(tester, K.signInSubmit);
      final required = strings.fieldError(FieldError.required);
      expect(errorIn(K.signInEmail, required), findsOneWidget);

      await typeInto(tester, K.signInEmail, 'aline@example.com');

      expect(errorIn(K.signInEmail, required), findsNothing);
      // The other field was not touched, so its error stays.
      expect(errorIn(K.signInPassword, required), findsOneWidget);
    });

    testWidgets('a malformed email is named and nothing is sent', (
      tester,
    ) async {
      await showScreen(tester);
      await typeInto(tester, K.signInEmail, 'abc');
      await typeInto(tester, K.signInPassword, 'secret123');

      await tapKey(tester, K.signInSubmit);

      expect(
        errorIn(K.signInEmail, strings.fieldError(FieldError.invalidEmail)),
        findsOneWidget,
      );
      expect(app.auth.calls, isNot(contains('signIn')));
    });

    testWidgets('the password is hidden while typing', (tester) async {
      await showScreen(tester);

      expect(isObscured(tester, K.signInPassword), isTrue);
      expect(isObscured(tester, K.signInEmail), isFalse);
    });
  });

  group('signing in', () {
    testWidgets('a valid form calls signIn with the typed email', (
      tester,
    ) async {
      await showScreen(tester);
      await fillValid(tester);

      await tapKey(tester, K.signInSubmit);

      expect(app.auth.calls, contains('signIn'));
      // The fake signs in as whoever the screen asked for.
      expect(app.auth.session?.email, 'aline@example.com');
    });

    testWidgets('a failure is shown as a message and keeps the form', (
      tester,
    ) async {
      await showScreen(tester);
      app.auth.failWith = const AuthFailure(AuthFailureCode.wrongCredentials);
      await fillValid(tester);

      await tapKey(tester, K.signInSubmit);

      expect(
        find.text(strings.authError(AuthFailureCode.wrongCredentials)),
        findsOneWidget,
      );
      expect(app.auth.session, isNull);
      expect(find.byKey(K.signInSubmit), findsOneWidget);
    });
  });

  group('other ways in', () {
    testWidgets('the Google button signs in with Google', (tester) async {
      await showScreen(tester);

      await tapKey(tester, K.signInGoogle);

      expect(app.auth.calls, contains('signInWithGoogle'));
    });

    testWidgets('Forgot password opens the reset screen', (tester) async {
      await showScreen(tester);

      await tapKey(tester, K.signInForgot);

      expect(find.text('route:${Routes.forgotPassword}'), findsOneWidget);
    });

    testWidgets('the sign-up link opens the first sign-up step', (
      tester,
    ) async {
      await showScreen(tester);

      await tapKey(tester, K.signInToSignUp);

      expect(find.text('route:${Routes.signUpName}'), findsOneWidget);
    });
  });
}
