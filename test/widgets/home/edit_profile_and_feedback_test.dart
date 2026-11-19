// Edit profile and Feedback screens (track D2).
//
// Both screens are opened on top of another page, because that is how the
// app reaches them and because a successful save or send pops the screen.
// Failures keep the screen, and the fakes tell us what was (not) stored:
//   - `app.profileRepo.user` is the stored profile
//   - `app.feedbackRepo.sent` is every note that reached the repository
import 'package:dailo/core/keys.dart';
import 'package:dailo/core/l10n/app_strings.dart';
import 'package:dailo/core/validators.dart';
import 'package:dailo/domain/entities/network.dart';
import 'package:dailo/presentation/screens/home/edit_profile_screen.dart';
import 'package:dailo/presentation/screens/home/feedback_screen.dart';
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

/// What the field with [key] is showing.
String fieldText(WidgetTester tester, Key key) {
  expect(find.byKey(key), findsOneWidget, reason: 'nothing on screen has $key');
  final input = find.descendant(
    of: find.byKey(key),
    matching: find.byType(EditableText),
  );
  return tester.widget<EditableText>(input).controller.text;
}

/// Matches any text input that hides what is typed, like a password or PIN.
final hiddenInput = find.byWidgetPredicate(
  (widget) => widget is EditableText && widget.obscureText,
);

/// A first page whose only button opens [screen] on top of it.
class Opener extends StatelessWidget {
  const Opener({super.key, required this.screen});

  static const openKey = Key('test.open');

  final Widget screen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          key: openKey,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => screen),
          ),
          child: const Text('open'),
        ),
      ),
    );
  }
}

void main() {
  late TestApp app;
  late AppStrings strings;

  setUp(() {
    app = TestApp();
    strings = app.strings();
  });

  /// Shows [screen] on top of the [Opener] page, as the app does.
  Future<void> openScreen(WidgetTester tester, Widget screen) async {
    await app.pumpScreen(tester, Opener(screen: screen));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Opener.openKey));
    await tester.pumpAndSettle();
  }

  /// True when the screen has closed and the first page is showing again.
  void expectClosed(Key screenKey) {
    expect(find.byKey(screenKey), findsNothing);
    expect(find.byKey(Opener.openKey), findsOneWidget);
  }

  group('EditProfileScreen', () {
    Future<void> openProfile(WidgetTester tester) =>
        openScreen(tester, const EditProfileScreen());

    testWidgets('shows no error before the first submit', (tester) async {
      await openProfile(tester);

      // The form is really there, so "no error" is not just a blank page.
      expect(find.byKey(K.profileSave), findsOneWidget);
      for (final error in FieldError.values) {
        expect(find.text(strings.fieldError(error)), findsNothing);
      }
    });

    testWidgets('has no password or PIN field', (tester) async {
      await openProfile(tester);

      expect(find.byKey(K.profileSave), findsOneWidget);
      expect(hiddenInput, findsNothing);
    });

    testWidgets('starts filled with the current profile', (tester) async {
      await openProfile(tester);

      expect(fieldText(tester, K.profileFirstName), 'Aline');
      expect(fieldText(tester, K.profileLastName), 'Mukamana');
      // The number may be shown with spaces; the digits are what matter.
      expect(
        fieldText(tester, K.profilePhone).replaceAll(' ', ''),
        '0788000001',
      );
    });

    testWidgets('a cleared first name is refused and nothing is saved', (
      tester,
    ) async {
      await openProfile(tester);
      await typeInto(tester, K.profileFirstName, '');

      await tapKey(tester, K.profileSave);

      expect(
        errorIn(K.profileFirstName, strings.fieldError(FieldError.required)),
        findsOneWidget,
      );
      expect(app.profileRepo.user, sampleUser());
      expect(find.byKey(K.profileSave), findsOneWidget);
    });

    testWidgets('a phone number that is not Rwandan is named', (tester) async {
      await openProfile(tester);
      await typeInto(tester, K.profilePhone, '12345');

      await tapKey(tester, K.profileSave);

      expect(
        errorIn(K.profilePhone, strings.fieldError(FieldError.invalidPhone)),
        findsOneWidget,
      );
      expect(app.profileRepo.user, sampleUser());
    });

    testWidgets('valid changes are saved, announced, and close the screen', (
      tester,
    ) async {
      await openProfile(tester);
      await typeInto(tester, K.profileFirstName, 'Alinette');
      // The international form must be stored as 07XXXXXXXX.
      await typeInto(tester, K.profilePhone, '+250788123456');

      await tapKey(tester, K.profileSave);

      final saved = app.profileRepo.user!;
      expect(saved.firstName, 'Alinette');
      expect(saved.lastName, 'Mukamana');
      expect(saved.phone, '0788123456');
      expect(saved.email, 'aline@example.com');
      expect(find.byType(SnackBar), findsOneWidget);
      expectClosed(K.profileSave);
    });

    testWidgets('an Airtel number moves the profile to the Airtel network', (
      tester,
    ) async {
      await openProfile(tester);
      expect(app.profileRepo.user!.network, Network.mtn);
      await typeInto(tester, K.profilePhone, '0731234567');

      await tapKey(tester, K.profileSave);

      expect(app.profileRepo.user!.phone, '0731234567');
      expect(app.profileRepo.user!.network, Network.airtel);
    });

    testWidgets('a rejected save says so, keeps the screen and the profile', (
      tester,
    ) async {
      await openProfile(tester);
      await typeInto(tester, K.profileFirstName, 'Alinette');
      app.profileRepo.failNext = true;

      await tapKey(tester, K.profileSave);

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byKey(K.profileSave), findsOneWidget);
      expect(app.profileRepo.user, sampleUser());
    });
  });

  group('FeedbackScreen', () {
    Future<void> openFeedback(WidgetTester tester) =>
        openScreen(tester, const FeedbackScreen());

    testWidgets('shows no error before the first submit', (tester) async {
      await openFeedback(tester);

      // The form is really there, so "no error" is not just a blank page.
      expect(find.byKey(K.feedbackSubmit), findsOneWidget);
      for (final error in FieldError.values) {
        expect(find.text(strings.fieldError(error)), findsNothing);
      }
    });

    testWidgets('has no password or PIN field', (tester) async {
      await openFeedback(tester);

      expect(find.byKey(K.feedbackSubmit), findsOneWidget);
      expect(hiddenInput, findsNothing);
    });

    testWidgets('offers five stars', (tester) async {
      await openFeedback(tester);

      for (var rating = 1; rating <= 5; rating++) {
        expect(find.byKey(K.feedbackStar(rating)), findsOneWidget);
      }
    });

    testWidgets('an empty submit asks for a message and sends nothing', (
      tester,
    ) async {
      await openFeedback(tester);

      await tapKey(tester, K.feedbackSubmit);

      expect(
        errorIn(K.feedbackMessage, strings.fieldError(FieldError.required)),
        findsOneWidget,
      );
      expect(app.feedbackRepo.sent, isEmpty);
    });

    testWidgets('a message under ten letters is too short', (tester) async {
      await openFeedback(tester);
      await typeInto(tester, K.feedbackMessage, 'too short');

      await tapKey(tester, K.feedbackSubmit);

      expect(
        errorIn(
          K.feedbackMessage,
          strings.fieldError(FieldError.messageTooShort),
        ),
        findsOneWidget,
      );
      expect(app.feedbackRepo.sent, isEmpty);
    });

    testWidgets('without touching the stars the rating is 5', (tester) async {
      await openFeedback(tester);
      await typeInto(tester, K.feedbackMessage, 'The app is clear and fast.');

      await tapKey(tester, K.feedbackSubmit);

      expect(app.feedbackRepo.sent.single.rating, 5);
    });

    testWidgets(
      'the chosen stars and trimmed message are sent, then it closes',
      (tester) async {
        await openFeedback(tester);
        await tapKey(tester, K.feedbackStar(3));
        // Spaces around the message are typed on purpose: they must be trimmed.
        await typeInto(
          tester,
          K.feedbackMessage,
          '  The app is clear and fast.  ',
        );

        await tapKey(tester, K.feedbackSubmit);

        expect(app.feedbackRepo.sent, hasLength(1));
        expect(app.feedbackRepo.sent.single.rating, 3);
        expect(
          app.feedbackRepo.sent.single.message,
          'The app is clear and fast.',
        );
        expect(find.byType(SnackBar), findsOneWidget);
        expectClosed(K.feedbackSubmit);
      },
    );

    testWidgets(
      'a rejected send stores nothing, says so and keeps the screen',
      (tester) async {
        await openFeedback(tester);
        await typeInto(tester, K.feedbackMessage, 'The app is clear and fast.');
        app.feedbackRepo.failNext = true;

        await tapKey(tester, K.feedbackSubmit);

        expect(app.feedbackRepo.sent, isEmpty);
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.byKey(K.feedbackSubmit), findsOneWidget);
      },
    );
  });
}