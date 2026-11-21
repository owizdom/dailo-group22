import 'package:dailo/core/keys.dart';
import 'package:dailo/core/routes.dart';
import 'package:dailo/core/theme.dart';
import 'package:dailo/domain/entities/recipient.dart';
import 'package:dailo/presentation/cubits/send_money_cubit.dart';
import 'package:dailo/presentation/screens/recipients/recipients_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/harness.dart';
import '../../fakes/samples.dart';
import '../send/screen_test_helpers.dart';

/// AT14. Figma 9, 10, 12: a searchable list with edit, favourite and delete.
void main() {
  Recipient stored(TestApp app, String id) {
    return app.recipientRepo.items.firstWhere((item) => item.id == id);
  }

  /// Opens the three-dot menu of recipient [id] and chooses [item].
  Future<void> chooseFromMenu(WidgetTester tester, String id, Key item) async {
    await press(tester, K.recipientMenu(id));
    await press(tester, item);
  }

  group('the list', () {
    testWidgets('shows every saved recipient, most recently paid first', (
      tester,
    ) async {
      final app = TestApp();
      await showScreen(tester, app, const RecipientsScreen());

      for (final id in ['r1', 'r2', 'r3']) {
        expect(tileIn(K.recipientsList, K.recipientTile(id)), findsOneWidget);
      }
      expectTopToBottom(tester, [
        K.recipientTile('r1'),
        K.recipientTile('r2'),
        K.recipientTile('r3'),
      ]);
    });

    testWidgets('with nobody saved it shows the empty state', (tester) async {
      final app = TestApp(withSampleData: false);
      await showScreen(tester, app, const RecipientsScreen());

      expect(find.byKey(K.recipientsEmpty), findsOneWidget);
    });
  });

  group('search', () {
    testWidgets('a name narrows the list to its match', (tester) async {
      final app = TestApp();
      await showScreen(tester, app, const RecipientsScreen());

      await enterIn(tester, K.recipientsSearch, 'diane');
      await tester.pumpAndSettle();

      expect(tileIn(K.recipientsList, K.recipientTile('r1')), findsOneWidget);
      expect(find.byKey(K.recipientTile('r2')), findsNothing);
      expect(find.byKey(K.recipientTile('r3')), findsNothing);
    });

    testWidgets('a search with no match shows the empty state', (tester) async {
      final app = TestApp();
      await showScreen(tester, app, const RecipientsScreen());

      await enterIn(tester, K.recipientsSearch, 'zzz');
      await tester.pumpAndSettle();

      expect(find.byKey(K.recipientsEmpty), findsOneWidget);
      expect(find.byKey(K.recipientTile('r1')), findsNothing);
    });

    testWidgets('clearing the search brings everyone back', (tester) async {
      final app = TestApp();
      await showScreen(tester, app, const RecipientsScreen());
      await enterIn(tester, K.recipientsSearch, 'zzz');
      await tester.pumpAndSettle();

      await enterIn(tester, K.recipientsSearch, '');
      await tester.pumpAndSettle();

      expect(find.byKey(K.recipientsEmpty), findsNothing);
      for (final id in ['r1', 'r2', 'r3']) {
        expect(find.byKey(K.recipientTile(id)), findsOneWidget);
      }
    });
  });

  group('the three-dot menu', () {
    testWidgets('Favorite makes a recipient a favourite', (tester) async {
      final app = TestApp();
      await showScreen(tester, app, const RecipientsScreen());
      expect(stored(app, 'r2').isFavorite, isFalse);

      await chooseFromMenu(tester, 'r2', K.recipientFavorite);

      expect(stored(app, 'r2').isFavorite, isTrue);
    });

    testWidgets('Favorite on a favourite takes the star away', (tester) async {
      final app = TestApp();
      await showScreen(tester, app, const RecipientsScreen());
      expect(stored(app, 'r1').isFavorite, isTrue);

      await chooseFromMenu(tester, 'r1', K.recipientFavorite);

      expect(stored(app, 'r1').isFavorite, isFalse);
    });

    testWidgets('Edit opens the edit screen with that recipient', (
      tester,
    ) async {
      final app = TestApp();
      await showScreen(tester, app, const RecipientsScreen());

      await chooseFromMenu(tester, 'r2', K.recipientEdit);

      expectOnRoute(app, Routes.editRecipient);
      expect(
        app.pushed.last.arguments,
        isA<Recipient>().having((r) => r.id, 'id', 'r2'),
      );
    });
  });

  group('Delete', () {
    testWidgets('asks first, and No keeps the recipient', (tester) async {
      final app = TestApp();
      await showScreen(tester, app, const RecipientsScreen());

      await chooseFromMenu(tester, 'r2', K.recipientDelete);

      // The dialog is up and nothing has been deleted yet.
      expect(find.byKey(K.confirmYes), findsOneWidget);
      expect(find.byKey(K.confirmNo), findsOneWidget);
      expect(app.recipientRepo.items, hasLength(3));

      await press(tester, K.confirmNo);

      expect(find.byKey(K.confirmYes), findsNothing);
      expect(app.recipientRepo.items, hasLength(3));
      expect(find.byKey(K.recipientTile('r2')), findsOneWidget);
    });

    testWidgets('Yes deletes it and the tile goes without a refresh', (
      tester,
    ) async {
      final app = TestApp();
      await showScreen(tester, app, const RecipientsScreen());

      await chooseFromMenu(tester, 'r2', K.recipientDelete);
      await press(tester, K.confirmYes);

      expect(app.recipientRepo.items, hasLength(2));
      expect(app.recipientRepo.items.map((r) => r.id), isNot(contains('r2')));
      expect(find.byKey(K.recipientTile('r2')), findsNothing);
      expect(find.byKey(K.recipientTile('r1')), findsOneWidget);
      expect(find.byKey(K.recipientTile('r3')), findsOneWidget);
      // The deleted message is shown, and it is not an error.
      expectSnack();
      final snack = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snack.backgroundColor, isNull);
    });

    testWidgets('a failed delete shows an error snack and keeps the tile', (
      tester,
    ) async {
      final app = TestApp();
      await showScreen(tester, app, const RecipientsScreen());
      app.recipientRepo.failNext = true;

      await chooseFromMenu(tester, 'r2', K.recipientDelete);
      await press(tester, K.confirmYes);

      expect(app.recipientRepo.items, hasLength(3));
      expect(find.byKey(K.recipientTile('r2')), findsOneWidget);
      expectSnack();
      final snack = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snack.backgroundColor, buildLightTheme().colorScheme.error);
    });
  });

  group('navigation', () {
    testWidgets('Add opens the edit screen with no recipient', (tester) async {
      final app = TestApp();
      await showScreen(tester, app, const RecipientsScreen());

      await press(tester, K.recipientsAdd);

      expectOnRoute(app, Routes.editRecipient);
      expect(app.pushed.last.arguments, isNull);
    });

    testWidgets('tapping a tile starts a payment to that recipient', (
      tester,
    ) async {
      final app = TestApp();
      await showScreen(tester, app, const RecipientsScreen());

      await press(tester, K.recipientTile('r1'));

      expectOnRoute(app, Routes.amount);
      expect(app.sendCubit.state.recipient?.id, 'r1');
      expect(app.sendCubit.state.step, SendStep.amount);
    });

    testWidgets('a new payment drops the details of an earlier one', (
      tester,
    ) async {
      final app = TestApp();
      await app.bind();
      // Left over from a payment that was never finished.
      app.sendCubit.chooseRecipient(sampleRecipients().last);
      app.sendCubit.setAmount(500);
      await showScreen(tester, app, const RecipientsScreen(), bindFirst: false);

      await press(tester, K.recipientTile('r1'));

      expect(app.sendCubit.state.recipient?.id, 'r1');
      expect(app.sendCubit.state.amount, 0);
    });
  });
}
