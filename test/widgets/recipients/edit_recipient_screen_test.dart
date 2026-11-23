import 'package:dailo/core/keys.dart';
import 'package:dailo/core/validators.dart';
import 'package:dailo/domain/entities/network.dart';
import 'package:dailo/domain/entities/recipient.dart';
import 'package:dailo/presentation/screens/recipients/edit_recipient_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/harness.dart';
import '../../fakes/samples.dart';
import '../send/screen_test_helpers.dart';

/// Figma 11. Adds a recipient, or edits one when the screen is given it.
void main() {
  Recipient stored(TestApp app, String id) {
    return app.recipientRepo.items.firstWhere((item) => item.id == id);
  }

  Future<void> fillAndSave(
    WidgetTester tester, {
    required String name,
    required String phone,
  }) async {
    await enterIn(tester, K.editName, name);
    await enterIn(tester, K.editPhone, phone);
    await press(tester, K.editSave);
  }

  group('adding a recipient', () {
    testWidgets('saving an empty form shows both required messages', (
      tester,
    ) async {
      final app = TestApp();
      await showScreenAbovePage(tester, app, const EditRecipientScreen());

      await press(tester, K.editSave);

      final required = app.strings().fieldError(FieldError.required);
      expect(find.text(required), findsNWidgets(2));
      expect(app.recipientRepo.items, hasLength(3));
    });

    testWidgets('no error shows before the first save', (tester) async {
      final app = TestApp();
      await showScreenAbovePage(tester, app, const EditRecipientScreen());

      // The form is there, and it has said nothing yet.
      expect(find.byKey(K.editName), findsOneWidget);
      expect(find.byKey(K.editPhone), findsOneWidget);
      final required = app.strings().fieldError(FieldError.required);
      expect(find.text(required), findsNothing);
    });

    testWidgets('after a failed save an error clears while the user types', (
      tester,
    ) async {
      final app = TestApp();
      await showScreenAbovePage(tester, app, const EditRecipientScreen());
      await press(tester, K.editSave);
      final required = app.strings().fieldError(FieldError.required);
      expect(find.text(required), findsNWidgets(2));

      await enterIn(tester, K.editName, 'New Person');

      expect(find.text(required), findsOneWidget);
    });

    testWidgets('a phone number that is not Rwandan shows invalid phone', (
      tester,
    ) async {
      final app = TestApp();
      await showScreenAbovePage(tester, app, const EditRecipientScreen());

      await fillAndSave(tester, name: 'New Person', phone: '123');

      final invalid = app.strings().fieldError(FieldError.invalidPhone);
      expect(find.text(invalid), findsOneWidget);
      expect(app.recipientRepo.items, hasLength(3));
    });

    testWidgets('a valid name and number are saved, then the screen closes', (
      tester,
    ) async {
      final app = TestApp();
      await showScreenAbovePage(tester, app, const EditRecipientScreen());

      await fillAndSave(tester, name: 'New Person', phone: '+250788111222');

      expect(app.recipientRepo.items, hasLength(4));
      final added = app.recipientRepo.items.firstWhere(
        (item) => item.name == 'New Person',
      );
      // Stored in the 07XXXXXXXX form whatever way it was typed.
      expect(added.phone, '0788111222');
      expect(find.byKey(K.editSave), findsNothing);
      expect(find.byKey(basePageKey), findsOneWidget);
    });

    testWidgets('a number that is already saved adds nothing and says so', (
      tester,
    ) async {
      final app = TestApp();
      await showScreenAbovePage(tester, app, const EditRecipientScreen());

      // 0788452310 is Uwase Diane.
      await fillAndSave(tester, name: 'Someone Else', phone: '0788452310');

      expect(app.recipientRepo.items, hasLength(3));
      expectSnack();
      // The screen stays so the user can fix the number.
      expect(find.byKey(K.editSave), findsOneWidget);
    });

    testWidgets('a failed save shows a snack and stays on the screen', (
      tester,
    ) async {
      final app = TestApp();
      await showScreenAbovePage(tester, app, const EditRecipientScreen());
      app.recipientRepo.failNext = true;

      await fillAndSave(tester, name: 'New Person', phone: '0788111222');

      expect(app.recipientRepo.items, hasLength(3));
      expectSnack();
      expect(find.byKey(K.editSave), findsOneWidget);
    });
  });

  group('editing a recipient', () {
    // Jean Bosco, 0791234567, on MTN.
    Widget jeanScreen() =>
        EditRecipientScreen(recipient: sampleRecipients()[1]);

    testWidgets('the fields start with the saved name and number', (
      tester,
    ) async {
      final app = TestApp();
      await showScreenAbovePage(tester, app, jeanScreen());

      expect(fieldText(tester, K.editName), 'Jean Bosco');
      final digits = fieldText(
        tester,
        K.editPhone,
      ).replaceAll(RegExp(r'\D'), '');
      expect(digits, '0791234567');
    });

    testWidgets('a changed name is saved on the same recipient', (
      tester,
    ) async {
      final app = TestApp();
      await showScreenAbovePage(tester, app, jeanScreen());

      await enterIn(tester, K.editName, 'Jean Claude');
      await press(tester, K.editSave);

      expect(app.recipientRepo.items, hasLength(3));
      expect(stored(app, 'r2').name, 'Jean Claude');
      expect(stored(app, 'r2').phone, '0791234567');
      expect(find.byKey(K.editSave), findsNothing);
      expect(find.byKey(basePageKey), findsOneWidget);
    });

    testWidgets('a new number from another network changes the network', (
      tester,
    ) async {
      final app = TestApp();
      await showScreenAbovePage(tester, app, jeanScreen());

      await enterIn(tester, K.editPhone, '0731000111');
      await press(tester, K.editSave);

      expect(stored(app, 'r2').phone, '0731000111');
      expect(stored(app, 'r2').network, Network.airtel);
    });
  });
}
