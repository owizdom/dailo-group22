// Home screen (track D2) and the first half of AT14: one state, two widgets.
//
// Home does not keep its own copy of the transactions. It reads the same
// TransactionsCubit every other screen reads, so a record written through
// the repository shows up here with no refresh button.
import 'package:dailo/core/keys.dart';
import 'package:dailo/core/routes.dart';
import 'package:dailo/domain/entities/network.dart';
import 'package:dailo/domain/entities/transaction_record.dart';
import 'package:dailo/presentation/cubits/send_money_cubit.dart';
import 'package:dailo/presentation/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/harness.dart';
import '../../fakes/samples.dart';

/// A phone tall enough to build the whole Home page at once, so a test about
/// what the list contains is not about what has scrolled into view.
const tallPhone = Size(390, 1400);

/// Scrolls [key] into view, taps it and waits for the screen to settle.
Future<void> tapKey(WidgetTester tester, Key key) async {
  expect(find.byKey(key), findsOneWidget, reason: 'nothing on screen has $key');
  await tester.ensureVisible(find.byKey(key));
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

/// A confirmed send to a new person, made at [at].
TransactionRecord sendRecord(DateTime at) => TransactionRecord(
  id: '',
  type: TxType.send,
  counterpartyName: 'Chantal Uwera',
  counterpartyPhone: '0788111222',
  network: Network.mtn,
  amount: 2500,
  fee: 100,
  status: TxStatus.success,
  createdAt: at,
  updatedAt: at,
);

/// Matches any transaction tile, whatever its id.
Finder anyTransactionTile() {
  return find.byWidgetPredicate(
    (widget) => widget.key.toString().contains('tx.tile.'),
  );
}

void main() {
  late TestApp app;

  Future<void> showHome(WidgetTester tester, {Size? size}) async {
    await app.pumpScreen(
      tester,
      const HomeScreen(),
      size: size ?? const Size(390, 844),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('has no password or PIN field', (tester) async {
    app = TestApp();
    await showHome(tester);

    // The screen is really there, and nothing on it hides typed text.
    expect(find.byKey(K.homeSend), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is EditableText && widget.obscureText,
      ),
      findsNothing,
    );
  });

  group('recent transactions', () {
    testWidgets('list the saved records, newest first', (tester) async {
      app = TestApp();
      await showHome(tester, size: tallPhone);

      final list = find.byKey(K.homeRecentList);
      expect(list, findsOneWidget);
      for (final id in ['t3', 't2', 't1']) {
        expect(
          find.descendant(
            of: list,
            matching: find.byKey(K.transactionTile(id)),
          ),
          findsOneWidget,
          reason: 'tile $id',
        );
      }
      expect(find.byKey(K.homeRecentEmpty), findsNothing);

      double top(String id) =>
          tester.getTopLeft(find.byKey(K.transactionTile(id))).dy;
      expect(top('t3'), lessThan(top('t2')));
      expect(top('t2'), lessThan(top('t1')));
    });

    testWidgets('show an empty state instead of the list when there are none', (
      tester,
    ) async {
      app = TestApp(withSampleData: false);
      await showHome(tester, size: tallPhone);

      expect(find.byKey(K.homeRecentEmpty), findsOneWidget);
      expect(find.byKey(K.homeRecentList), findsNothing);
      expect(anyTransactionTile(), findsNothing);
    });

    testWidgets('stop at the five newest records', (tester) async {
      app = TestApp();
      // Three newer records join the three samples. The repository names
      // them tx1, tx2 and tx3 and keeps the newest first.
      for (var hour = 1; hour <= 3; hour++) {
        await app.transactionRepo.add(
          'u1',
          sendRecord(day3.add(Duration(hours: hour))),
        );
      }
      await showHome(tester, size: tallPhone);

      expect(anyTransactionTile(), findsNWidgets(5));
      for (final id in ['tx3', 'tx2', 'tx1', 't3', 't2']) {
        expect(find.byKey(K.transactionTile(id)), findsOneWidget, reason: id);
      }
      expect(find.byKey(K.transactionTile('t1')), findsNothing);
    });

    testWidgets('a record added while Home is open appears without a refresh', (
      tester,
    ) async {
      app = TestApp();
      await showHome(tester, size: tallPhone);
      expect(find.byKey(K.transactionTile('tx1')), findsNothing);

      await app.transactionRepo.add(
        'u1',
        sendRecord(day3.add(const Duration(hours: 5))),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(K.transactionTile('tx1')), findsOneWidget);
      expect(find.byKey(K.homeRecentEmpty), findsNothing);
    });

    testWidgets('tapping a record opens its detail with the record id', (
      tester,
    ) async {
      app = TestApp();
      await showHome(tester);

      await tapKey(tester, K.transactionTile('t3'));

      expect(find.text('route:${Routes.transactionDetail}'), findsOneWidget);
      expect(app.pushed.last.name, Routes.transactionDetail);
      expect(app.pushed.last.arguments, 't3');
    });
  });

  group('navigation', () {
    // Each control and the one route it must open.
    final destinations = <(String, Key, String)>[
      ('QR code tile', K.homeQr, Routes.generateQr),
      ('Buy Airtime tile', K.homeAirtime, Routes.buyAirtime),
      ('Buy Data tile', K.homeData, Routes.buyData),
      ('See more link', K.homeSeeMore, Routes.history),
      ('Settings icon', K.homeSettings, Routes.settings),
      ('Feedback link', K.homeFeedback, Routes.feedback),
    ];

    for (final (name, key, route) in destinations) {
      testWidgets('the $name opens $route', (tester) async {
        app = TestApp();
        await showHome(tester);

        await tapKey(tester, key);

        expect(find.text('route:$route'), findsOneWidget);
        expect(app.pushed.map((settings) => settings.name), [route]);
      });
    }

    testWidgets('the Send Money tile starts a fresh payment and opens it', (
      tester,
    ) async {
      app = TestApp();
      await showHome(tester);
      // Leave a payment half done, to prove that Home resets it.
      app.sendCubit.chooseRecipient(app.recipientRepo.items.first);
      expect(app.sendCubit.state.step, SendStep.amount);

      await tapKey(tester, K.homeSend);

      expect(app.sendCubit.state.step, SendStep.recipient);
      expect(app.sendCubit.state.recipient, isNull);
      expect(find.text('route:${Routes.sendMoney}'), findsOneWidget);
    });
  });
}
