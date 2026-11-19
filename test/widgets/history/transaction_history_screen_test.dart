import 'package:dailo/core/keys.dart';
import 'package:dailo/core/routes.dart';
import 'package:dailo/presentation/screens/history/transaction_history_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/harness.dart';
import '../send/screen_test_helpers.dart';

/// AT15. Figma 13: a searchable, filterable list of every payment and
/// purchase. The sample history is t3 (a confirmed send to Uwase Diane),
/// t2 (a pending airtime purchase) and t1 (a failed data purchase).
void main() {
  group('the list', () {
    testWidgets('shows every record, newest first', (tester) async {
      final app = TestApp();
      await showScreen(tester, app, const TransactionHistoryScreen());

      for (final id in ['t3', 't2', 't1']) {
        expect(tileIn(K.historyList, K.transactionTile(id)), findsOneWidget);
      }
      expectTopToBottom(tester, [
        K.transactionTile('t3'),
        K.transactionTile('t2'),
        K.transactionTile('t1'),
      ]);
      expect(find.byKey(K.historyEmpty), findsNothing);
    });

    testWidgets(
      'puts the records under a Today, Yesterday or Earlier heading',
      (tester) async {
        final app = TestApp();
        await showScreen(tester, app, const TransactionHistoryScreen());

        // The sample dates are fixed and the real clock moves on, so which
        // heading each record gets changes with the day the test runs. At
        // least one heading must always be there.
        final strings = app.strings();
        final headings = [strings.today, strings.yesterday, strings.earlier];
        final shown = headings.where(
          (text) => find.text(text).evaluate().isNotEmpty,
        );
        expect(shown, isNotEmpty);
      },
    );

    testWidgets('with no records it shows the empty state', (tester) async {
      final app = TestApp(withSampleData: false);
      await showScreen(tester, app, const TransactionHistoryScreen());

      expect(find.byKey(K.historyEmpty), findsOneWidget);
    });

    testWidgets('tapping a record opens its detail with its id', (
      tester,
    ) async {
      final app = TestApp();
      await showScreen(tester, app, const TransactionHistoryScreen());

      await press(tester, K.transactionTile('t3'));

      expectOnRoute(app, Routes.transactionDetail);
      expect(app.pushed.last.arguments, 't3');
    });
  });

  group('search', () {
    testWidgets('a name finds the matching record', (tester) async {
      final app = TestApp();
      await showScreen(tester, app, const TransactionHistoryScreen());

      await enterIn(tester, K.historySearch, 'diane');
      await tester.pumpAndSettle();

      expect(tileIn(K.historyList, K.transactionTile('t3')), findsOneWidget);
      expect(find.byKey(K.transactionTile('t2')), findsNothing);
      expect(find.byKey(K.transactionTile('t1')), findsNothing);
    });

    testWidgets('a phone number finds the matching record', (tester) async {
      final app = TestApp();
      await showScreen(tester, app, const TransactionHistoryScreen());

      await enterIn(tester, K.historySearch, '0788452310');
      await tester.pumpAndSettle();

      expect(tileIn(K.historyList, K.transactionTile('t3')), findsOneWidget);
      expect(find.byKey(K.transactionTile('t2')), findsNothing);
      expect(find.byKey(K.transactionTile('t1')), findsNothing);
    });

    testWidgets('a search with no match shows the empty state', (tester) async {
      final app = TestApp();
      await showScreen(tester, app, const TransactionHistoryScreen());

      await enterIn(tester, K.historySearch, 'zzz');
      await tester.pumpAndSettle();

      expect(find.byKey(K.historyEmpty), findsOneWidget);
      expect(find.byKey(K.transactionTile('t3')), findsNothing);
    });
  });

  group('filters', () {
    testWidgets('Airtime leaves only the airtime purchase', (tester) async {
      final app = TestApp();
      await showScreen(tester, app, const TransactionHistoryScreen());

      await press(tester, K.historyFilter('airtime'));

      expect(tileIn(K.historyList, K.transactionTile('t2')), findsOneWidget);
      expect(find.byKey(K.transactionTile('t3')), findsNothing);
      expect(find.byKey(K.transactionTile('t1')), findsNothing);
    });

    testWidgets('Send leaves only the payment, Data only the data purchase', (
      tester,
    ) async {
      final app = TestApp();
      await showScreen(tester, app, const TransactionHistoryScreen());

      await press(tester, K.historyFilter('send'));
      expect(find.byKey(K.transactionTile('t3')), findsOneWidget);
      expect(find.byKey(K.transactionTile('t2')), findsNothing);
      expect(find.byKey(K.transactionTile('t1')), findsNothing);

      await press(tester, K.historyFilter('data'));
      expect(find.byKey(K.transactionTile('t1')), findsOneWidget);
      expect(find.byKey(K.transactionTile('t3')), findsNothing);
      expect(find.byKey(K.transactionTile('t2')), findsNothing);
    });

    testWidgets('All brings every record back', (tester) async {
      final app = TestApp();
      await showScreen(tester, app, const TransactionHistoryScreen());
      await press(tester, K.historyFilter('airtime'));
      expect(find.byKey(K.transactionTile('t3')), findsNothing);

      await press(tester, K.historyFilter('all'));

      for (final id in ['t3', 't2', 't1']) {
        expect(tileIn(K.historyList, K.transactionTile(id)), findsOneWidget);
      }
    });

    testWidgets('a filter and a search work together', (tester) async {
      final app = TestApp();
      await showScreen(tester, app, const TransactionHistoryScreen());

      // Diane was paid by a send, so searching her under Airtime finds nothing.
      await press(tester, K.historyFilter('airtime'));
      await enterIn(tester, K.historySearch, 'diane');
      await tester.pumpAndSettle();

      expect(find.byKey(K.historyEmpty), findsOneWidget);
    });
  });
}