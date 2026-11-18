import 'package:dailo/core/keys.dart';
import 'package:dailo/core/routes.dart';
import 'package:dailo/core/validators.dart';
import 'package:dailo/domain/entities/network.dart';
import 'package:dailo/domain/entities/recipient.dart';
import 'package:dailo/presentation/screens/send/send_money_screen.dart';
import 'package:dailo/presentation/widgets/common/recipient_tile.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/harness.dart';
import '../../fakes/samples.dart';
import 'screen_test_helpers.dart';

/// Figma 6. Type a number, scan a code, or pick from Recents and Favorites.
void main() {
  group('typing a number', () {
    testWidgets('an empty number shows the required message and goes nowhere', (
      tester,
    ) async {
      final app = TestApp();
      await showScreen(tester, app, const SendMoneyScreen());

      await press(tester, K.sendContinue);

      final required = app.strings().fieldError(FieldError.required);
      expect(find.text(required), findsOneWidget);
      expectNothingPushed(app);
      expect(app.sendCubit.state.recipient, isNull);
    });

    testWidgets('a number that is too short shows the invalid phone message', (
      tester,
    ) async {
      final app = TestApp();
      await showScreen(tester, app, const SendMoneyScreen());

      await enterIn(tester, K.sendPhone, '123');
      await press(tester, K.sendContinue);

      final invalid = app.strings().fieldError(FieldError.invalidPhone);
      expect(find.text(invalid), findsOneWidget);
      expectNothingPushed(app);
      expect(app.sendCubit.state.recipient, isNull);
    });

    testWidgets('a valid number is chosen and the amount screen opens', (
      tester,
    ) async {
      final app = TestApp();
      await showScreen(tester, app, const SendMoneyScreen());

      await enterIn(tester, K.sendPhone, '0788111222');
      await press(tester, K.sendContinue);

      expectOnRoute(app, Routes.amount);
      expect(app.sendCubit.state.recipient?.phone, '0788111222');
    });
  });

  group('other ways in', () {
    testWidgets('the scan button opens the QR scanner', (tester) async {
      final app = TestApp();
      await showScreen(tester, app, const SendMoneyScreen());

      await press(tester, K.sendScan);

      expectOnRoute(app, Routes.scanQr);
    });

    testWidgets('View all opens the full recipients list', (tester) async {
      final app = TestApp();
      await showScreen(tester, app, const SendMoneyScreen());

      await press(tester, K.sendViewAll);

      expectOnRoute(app, Routes.recipients);
    });
  });

  group('Recents and Favorites tabs', () {
    testWidgets('Recents is the default tab and lists every recipient', (
      tester,
    ) async {
      final app = TestApp();
      await showScreen(tester, app, const SendMoneyScreen());

      for (final id in ['r1', 'r2', 'r3']) {
        expect(tileIn(K.sendList, K.recipientTile(id)), findsOneWidget);
      }
      // Most recently paid first: Diane, then Jean, then Eric (never paid).
      expectTopToBottom(tester, [
        K.recipientTile('r1'),
        K.recipientTile('r2'),
        K.recipientTile('r3'),
      ]);
    });

    testWidgets('the Favorites tab keeps only the favourite', (tester) async {
      final app = TestApp();
      await showScreen(tester, app, const SendMoneyScreen());

      await press(tester, K.sendTabFavorites);

      expect(tileIn(K.sendList, K.recipientTile('r1')), findsOneWidget);
      expect(find.byKey(K.recipientTile('r2')), findsNothing);
      expect(find.byKey(K.recipientTile('r3')), findsNothing);
    });

    testWidgets('going back to Recents shows everyone again', (tester) async {
      final app = TestApp();
      await showScreen(tester, app, const SendMoneyScreen());

      await press(tester, K.sendTabFavorites);
      await press(tester, K.sendTabRecents);

      for (final id in ['r1', 'r2', 'r3']) {
        expect(tileIn(K.sendList, K.recipientTile(id)), findsOneWidget);
      }
    });

    testWidgets('the list shows at most five recipients', (tester) async {
      final app = TestApp();
      // Three more saved people make six in total.
      for (var i = 1; i <= 3; i++) {
        app.recipientRepo.items.add(
          Recipient(
            id: 'extra$i',
            name: 'Extra Person $i',
            phone: '078800000$i',
            network: Network.mtn,
            createdAt: day1,
            updatedAt: day1,
          ),
        );
      }
      await showScreen(tester, app, const SendMoneyScreen());

      final tiles = find.descendant(
        of: find.byKey(K.sendList),
        matching: find.byType(RecipientTile),
      );
      expect(tiles, findsNWidgets(5));
    });

    testWidgets('with nobody saved the list shows the empty state', (
      tester,
    ) async {
      final app = TestApp(withSampleData: false);
      await showScreen(tester, app, const SendMoneyScreen());

      expect(find.byKey(K.sendListEmpty), findsOneWidget);
      expect(find.byType(RecipientTile), findsNothing);
    });
  });

  group('picking a saved recipient', () {
    testWidgets('tapping a tile chooses that recipient and opens Amount', (
      tester,
    ) async {
      final app = TestApp();
      await showScreen(tester, app, const SendMoneyScreen());

      await press(tester, K.recipientTile('r2'));

      expectOnRoute(app, Routes.amount);
      expect(app.sendCubit.state.recipient?.id, 'r2');
    });
  });

  group('one state, many widgets', () {
    testWidgets(
      'a recipient saved while the screen shows appears in the list',
      (tester) async {
        final app = TestApp();
        await showScreen(tester, app, const SendMoneyScreen());

        final newId = await app.recipientRepo.add(
          'u1',
          Recipient(
            id: '',
            name: 'New Person',
            phone: '0788333444',
            network: Network.mtn,
            createdAt: day3,
            updatedAt: day3,
          ),
        );
        await tester.pumpAndSettle();

        expect(tileIn(K.sendList, K.recipientTile(newId)), findsOneWidget);
      },
    );
  });
}
