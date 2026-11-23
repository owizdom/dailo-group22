// AT12 (sign-up half): the two sign-up screens.
//
// Step 1 (SignUpNameScreen) asks for the names and passes them on as a Dart
// record. Step 2 (SignUpDetailsScreen) asks for email, phone, password and
// the terms, and only then calls AuthCubit.signUp.
import 'package:dailo/core/keys.dart';
import 'package:dailo/core/l10n/app_strings.dart';
import 'package:dailo/core/routes.dart';
import 'package:dailo/core/validators.dart';
import 'package:dailo/domain/repositories/auth_failure.dart';
import 'package:dailo/presentation/screens/auth/sign_up_details_screen.dart';
import 'package:dailo/presentation/screens/auth/sign_up_name_screen.dart';
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

/// Whether the terms checkbox is ticked.
bool termsTicked(WidgetTester tester) {
  expect(
    find.byKey(K.signUpTerms),
    findsOneWidget,
    reason: 'no terms checkbox',
  );
  final found = find.descendant(
    of: find.byKey(K.signUpTerms),
    matching: find.byType(Checkbox),
    matchRoot: true,
  );
  return tester.widget<Checkbox>(found).value ?? false;
}

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

  group('SignUpNameScreen', () {
    Future<void> showScreen(WidgetTester tester) async {
      await app.pumpScreen(tester, const SignUpNameScreen());
      await tester.pumpAndSettle();
    }

    testWidgets('shows no error before the first submit', (tester) async {
      await showScreen(tester);

      // The form is really there, so "no error" is not just a blank page.
      expect(find.byKey(K.signUpContinue), findsOneWidget);

      for (final error in FieldError.values) {
        expect(find.text(strings.fieldError(error)), findsNothing);
      }
    });

    testWidgets('an empty continue asks for both names and goes nowhere', (
      tester,
    ) async {
      await showScreen(tester);

      await tapKey(tester, K.signUpContinue);

      final required = strings.fieldError(FieldError.required);
      expect(errorIn(K.signUpFirstName, required), findsOneWidget);
      expect(errorIn(K.signUpLastName, required), findsOneWidget);
      expect(app.pushed, isEmpty);
    });

    testWidgets('a one-letter name is too short', (tester) async {
      await showScreen(tester);
      await typeInto(tester, K.signUpFirstName, 'A');
      await typeInto(tester, K.signUpLastName, 'Mukamana');

      await tapKey(tester, K.signUpContinue);

      expect(
        errorIn(K.signUpFirstName, strings.fieldError(FieldError.nameTooShort)),
        findsOneWidget,
      );
      expect(
        errorIn(K.signUpLastName, strings.fieldError(FieldError.nameTooShort)),
        findsNothing,
      );
      expect(app.pushed, isEmpty);
    });

    testWidgets('valid names go to step 2 as a trimmed record', (tester) async {
      await showScreen(tester);
      // Spaces around the names are typed on purpose: they must be trimmed.
      await typeInto(tester, K.signUpFirstName, '  Aline ');
      await typeInto(tester, K.signUpLastName, ' Mukamana  ');

      await tapKey(tester, K.signUpContinue);

      expect(find.text('route:${Routes.signUpDetails}'), findsOneWidget);
      expect(app.pushed.last.name, Routes.signUpDetails);
      expect(app.pushed.last.arguments, (
        firstName: 'Aline',
        lastName: 'Mukamana',
      ));
    });

    testWidgets('the Google button signs in with Google', (tester) async {
      await showScreen(tester);

      await tapKey(tester, K.signUpGoogle);

      expect(app.auth.calls, contains('signInWithGoogle'));
    });

    testWidgets('with nothing to go back to, the sign-in link opens Sign In', (
      tester,
    ) async {
      // The harness shows this screen as the first page, so it cannot pop.
      await showScreen(tester);

      await tapKey(tester, K.signUpToSignIn);

      expect(find.text('route:${Routes.signIn}'), findsOneWidget);
    });
  });

  group('SignUpDetailsScreen', () {
    Future<void> showScreen(WidgetTester tester) async {
      await app.pumpScreen(
        tester,
        const SignUpDetailsScreen(firstName: 'Aline', lastName: 'Mukamana'),
      );
      await tester.pumpAndSettle();
    }

    /// Fills the four text fields. Anything not passed is valid.
    Future<void> fill(
      WidgetTester tester, {
      String email = 'aline@example.com',
      String phone = '0788123456',
      String password = 'secret123',
      String? confirm,
    }) async {
      await typeInto(tester, K.signUpEmail, email);
      await typeInto(tester, K.signUpPhone, phone);
      await typeInto(tester, K.signUpPassword, password);
      await typeInto(tester, K.signUpConfirm, confirm ?? password);
    }

    testWidgets('shows no error before the first submit', (tester) async {
      await showScreen(tester);

      // The form is really there, so "no error" is not just a blank page.
      expect(find.byKey(K.signUpSubmit), findsOneWidget);

      for (final error in FieldError.values) {
        expect(find.text(strings.fieldError(error)), findsNothing);
      }
    });

    testWidgets('an empty submit marks every field and does not sign up', (
      tester,
    ) async {
      await showScreen(tester);

      await tapKey(tester, K.signUpSubmit);

      final required = strings.fieldError(FieldError.required);
      for (final field in [
        K.signUpEmail,
        K.signUpPhone,
        K.signUpPassword,
        K.signUpConfirm,
      ]) {
        expect(errorIn(field, required), findsOneWidget, reason: '$field');
      }
      expect(app.auth.calls, isNot(contains('signUp')));
    });

    testWidgets('both password fields are hidden while typing', (tester) async {
      await showScreen(tester);

      expect(isObscured(tester, K.signUpPassword), isTrue);
      expect(isObscured(tester, K.signUpConfirm), isTrue);
      expect(isObscured(tester, K.signUpEmail), isFalse);
    });

    testWidgets('a confirmation that differs from the password is named', (
      tester,
    ) async {
      await showScreen(tester);
      await fill(tester, confirm: 'secret124');
      await tapKey(tester, K.signUpTerms);

      await tapKey(tester, K.signUpSubmit);

      expect(
        errorIn(
          K.signUpConfirm,
          strings.fieldError(FieldError.passwordMismatch),
        ),
        findsOneWidget,
      );
      expect(app.auth.calls, isNot(contains('signUp')));
    });

    testWidgets('a weak password is named', (tester) async {
      await showScreen(tester);
      // Short and without a digit. The confirmation matches, so only the
      // strength is wrong.
      await fill(tester, password: 'abc');
      await tapKey(tester, K.signUpTerms);

      await tapKey(tester, K.signUpSubmit);

      expect(
        errorIn(K.signUpPassword, strings.fieldError(FieldError.weakPassword)),
        findsOneWidget,
      );
      expect(app.auth.calls, isNot(contains('signUp')));
    });

    testWidgets('a phone number that is not Rwandan is named', (tester) async {
      await showScreen(tester);
      await fill(tester, phone: '12345');
      await tapKey(tester, K.signUpTerms);

      await tapKey(tester, K.signUpSubmit);

      expect(
        errorIn(K.signUpPhone, strings.fieldError(FieldError.invalidPhone)),
        findsOneWidget,
      );
      expect(app.auth.calls, isNot(contains('signUp')));
    });

    testWidgets('ticking the terms box checks it', (tester) async {
      await showScreen(tester);
      expect(termsTicked(tester), isFalse);

      await tapKey(tester, K.signUpTerms);

      expect(termsTicked(tester), isTrue);
    });

    testWidgets('a valid form with the terms unticked is refused', (
      tester,
    ) async {
      await showScreen(tester);
      await fill(tester);

      await tapKey(tester, K.signUpSubmit);

      expect(
        find.text(strings.fieldError(FieldError.termsNotAccepted)),
        findsOneWidget,
      );
      expect(app.auth.calls, isNot(contains('signUp')));
    });

    testWidgets('a valid form with the terms ticked signs up', (tester) async {
      await showScreen(tester);
      await fill(tester);
      await tapKey(tester, K.signUpTerms);

      await tapKey(tester, K.signUpSubmit);

      expect(app.auth.calls, contains('signUp'));
      // The fake signs in as the email the screen sent.
      expect(app.auth.session?.email, 'aline@example.com');
      expect(
        find.text(strings.fieldError(FieldError.termsNotAccepted)),
        findsNothing,
      );
    });

    testWidgets('an email that is already registered shows its message', (
      tester,
    ) async {
      await showScreen(tester);
      app.auth.failWith = const AuthFailure(AuthFailureCode.emailInUse);
      await fill(tester);
      await tapKey(tester, K.signUpTerms);

      await tapKey(tester, K.signUpSubmit);

      expect(
        find.text(strings.authError(AuthFailureCode.emailInUse)),
        findsOneWidget,
      );
      expect(app.auth.session, isNull);
    });
  });
}
