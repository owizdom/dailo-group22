import 'package:dailo/core/keys.dart';
import 'package:dailo/core/routes.dart';
import 'package:dailo/domain/entities/transaction_record.dart';
import 'package:dailo/presentation/cubits/send_money_cubit.dart';
import 'package:dailo/presentation/screens/send/payment_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/harness.dart';
import '../../fakes/samples.dart';
import 'screen_test_helpers.dart';

/// Figma 16. After the phone's USSD dialog closes the screen asks what the
/// operator said, because DailO cannot read the answer itself. Then it shows
/// the receipt.
void main() {
  /// A payment of 10,000 to Diane that was confirmed on Review, so the phone
  /// has dialled and the cubit waits for the user's answer.
  Future<TestApp> showResult(WidgetTester tester) async {
    final app = TestApp();
    await app.bind();
    app.sendCubit.start();
    app.sendCubit.chooseRecipient(sampleRecipients().first);
    app.sendCubit.setAmount(10000);
    app.sendCubit.setComment('Tomatoes, Tuesday');
    app.sendCubit.toReview();
    await app.sendCubit.confirm();
    expect(app.sendCubit.state.step, SendStep.awaitingResult);
    await showScreenAbovePage(
      tester,
      app,
      const PaymentResultScreen(),
      bindFirst: false,
    );
    return app;
  }

  /// The record this payment wrote when it was confirmed.
  TransactionRecord paymentRecord(TestApp app) {
    return recordWith(app, app.sendCubit.state.recordId!);
  }

  group('the question', () {
    testWidgets('offers three answers and no receipt yet', (tester) async {
      await showResult(tester);

      expect(find.byKey(K.resultYes), findsOneWidget);
      expect(find.byKey(K.resultNo), findsOneWidget);
      expect(find.byKey(K.resultNotSure), findsOneWidget);
      expect(find.byKey(K.resultStatus), findsNothing);
    });

    testWidgets('the system back button counts as "not sure"', (tester) async {
      final app = await showResult(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(app.sendCubit.state.step, SendStep.done);
      expect(app.sendCubit.state.result, TxStatus.pending);
      expect(
        textOf(tester, K.resultStatus),
        app.strings().txStatus(TxStatus.pending),
      );
    });
  });

  group('answering', () {
    for (final (answer, status) in [
      (K.resultYes, TxStatus.success),
      (K.resultNo, TxStatus.failed),
      (K.resultNotSure, TxStatus.pending),
    ]) {
      testWidgets('${status.name} is saved and shown on the receipt', (
        tester,
      ) async {
        final app = await showResult(tester);

        await press(tester, answer);

        expect(paymentRecord(app).status, status);
        expect(app.sendCubit.state.step, SendStep.done);
        expect(textOf(tester, K.resultStatus), app.strings().txStatus(status));
        // The question is replaced by the receipt.
        expect(find.byKey(K.resultYes), findsNothing);
        expect(find.byKey(K.resultNo), findsNothing);
        expect(find.byKey(K.resultNotSure), findsNothing);
      });
    }

    testWidgets('the receipt shows the amount and who was paid', (
      tester,
    ) async {
      await showResult(tester);

      await press(tester, K.resultYes);

      expect(find.textContaining('10,000 Frw'), findsWidgets);
      expect(find.textContaining('Uwase Diane'), findsWidgets);
    });
  });

  group('after the receipt', () {
    testWidgets('Done resets the payment and goes back to the first page', (
      tester,
    ) async {
      final app = await showResult(tester);
      await press(tester, K.resultYes);

      await press(tester, K.resultDone);

      expect(app.sendCubit.state.step, SendStep.recipient);
      expect(app.sendCubit.state.recipient, isNull);
      expect(find.byKey(K.resultDone), findsNothing);
      expect(find.byKey(basePageKey), findsOneWidget);
    });

    testWidgets('Pay again starts a new payment to the same person', (
      tester,
    ) async {
      final app = await showResult(tester);
      await press(tester, K.resultYes);

      await press(tester, K.resultPayAgain);

      expect(app.sendCubit.state.step, SendStep.amount);
      expect(app.sendCubit.state.recipient?.id, 'r1');
      expectOnRoute(app, Routes.amount);
      // Replaced, not pushed: the receipt is gone from the stack.
      expect(find.byKey(K.resultPayAgain, skipOffstage: false), findsNothing);
    });

    // Found in review: Pay again pushed a second Amount screen on top of the
    // first, so Back from it landed on a duplicate instead of Send Money.
    testWidgets('Pay again goes back to the Amount screen underneath', (
      tester,
    ) async {
      final app = await showResult(tester);
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      // The real stack: Send Money, Amount, then the receipt above them.
      navigator.pop();
      await tester.pumpAndSettle();
      navigator.pushNamed(Routes.amount);
      await tester.pumpAndSettle();
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => const PaymentResultScreen()),
      );
      await tester.pumpAndSettle();
      await press(tester, K.resultYes);

      await press(tester, K.resultPayAgain);

      expect(app.sendCubit.state.step, SendStep.amount);
      expect(
        find.text('route:${Routes.amount}', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.byKey(basePageKey, skipOffstage: false), findsOneWidget);
    });
  });
}
