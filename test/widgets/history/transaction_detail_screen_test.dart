import 'package:dailo/core/formatters.dart';
import 'package:dailo/core/keys.dart';
import 'package:dailo/domain/entities/transaction_record.dart';
import 'package:dailo/presentation/screens/history/transaction_detail_screen.dart';
import 'package:dailo/presentation/widgets/common/empty_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/harness.dart';
import '../../fakes/samples.dart';
import '../send/screen_test_helpers.dart';

/// One record in full, with actions to correct its result or delete it.
/// The sample records are t3 (confirmed send to Uwase Diane), t2 (pending
/// airtime) and t1 (failed data).
void main() {
  /// Shows the detail of [id] one route above a base page, so Delete can pop.
  Future<TestApp> showDetail(WidgetTester tester, String id) async {
    final app = TestApp();
    await showScreenAbovePage(
      tester,
      app,
      TransactionDetailScreen(recordId: id),
    );
    return app;
  }

  group('what is shown', () {
    testWidgets('every part of a payment', (tester) async {
      await showDetail(tester, 't3');

      expect(find.textContaining('Uwase Diane'), findsWidgets);
      expect(find.textContaining('078 845 2310'), findsWidgets);
      expect(find.textContaining('10,000 Frw'), findsWidgets);
      expect(find.textContaining('100 Frw'), findsWidgets);
      expect(find.textContaining('10,100 Frw'), findsWidgets);
      expect(find.textContaining('Tomatoes, Tuesday'), findsWidgets);
      expect(find.textContaining(formatDate(day3)), findsWidgets);
      expect(find.byKey(K.detailStatus), findsOneWidget);
    });

    testWidgets('a pending record says it is not confirmed', (tester) async {
      final app = await showDetail(tester, 't2');

      expect(
        textOf(tester, K.detailStatus),
        app.strings().txStatus(TxStatus.pending),
      );
    });

    testWidgets('a record that does not exist shows the empty state', (
      tester,
    ) async {
      await showDetail(tester, 'missing');

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.byKey(K.detailStatus), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('correcting the result', () {
    testWidgets('Mark as confirmed changes a pending record to success', (
      tester,
    ) async {
      final app = await showDetail(tester, 't2');

      await press(tester, K.detailMarkSuccess);

      expect(recordWith(app, 't2').status, TxStatus.success);
      expect(
        textOf(tester, K.detailStatus),
        app.strings().txStatus(TxStatus.success),
      );
      // Already success, so the button is no longer offered.
      expect(find.byKey(K.detailMarkSuccess), findsNothing);
    });

    testWidgets('Mark as failed changes a pending record to failed', (
      tester,
    ) async {
      final app = await showDetail(tester, 't2');

      await press(tester, K.detailMarkFailed);

      expect(recordWith(app, 't2').status, TxStatus.failed);
      expect(
        textOf(tester, K.detailStatus),
        app.strings().txStatus(TxStatus.failed),
      );
      expect(find.byKey(K.detailMarkFailed), findsNothing);
    });

    testWidgets('a confirmed record cannot be marked confirmed again', (
      tester,
    ) async {
      await showDetail(tester, 't3');

      expect(find.byKey(K.detailStatus), findsOneWidget);
      expect(find.byKey(K.detailMarkSuccess), findsNothing);
      expect(find.byKey(K.detailMarkFailed), findsOneWidget);
    });

    testWidgets('a failed record cannot be marked failed again', (
      tester,
    ) async {
      await showDetail(tester, 't1');

      expect(find.byKey(K.detailStatus), findsOneWidget);
      expect(find.byKey(K.detailMarkFailed), findsNothing);
      expect(find.byKey(K.detailMarkSuccess), findsOneWidget);
    });
  });

  group('Delete', () {
    testWidgets('asks first, and No keeps the record', (tester) async {
      final app = await showDetail(tester, 't2');

      await press(tester, K.detailDelete);
      expect(find.byKey(K.confirmYes), findsOneWidget);
      expect(app.transactionRepo.items, hasLength(3));

      await press(tester, K.confirmNo);

      expect(app.transactionRepo.items, hasLength(3));
      expect(find.byKey(K.detailStatus), findsOneWidget);
    });

    testWidgets('Yes removes the record and closes the screen', (tester) async {
      final app = await showDetail(tester, 't2');

      await press(tester, K.detailDelete);
      await press(tester, K.confirmYes);

      expect(app.transactionRepo.items.map((r) => r.id), isNot(contains('t2')));
      expect(app.transactionRepo.items, hasLength(2));
      expect(find.byKey(K.detailDelete), findsNothing);
      expect(find.byKey(basePageKey), findsOneWidget);
    });
  });
}
