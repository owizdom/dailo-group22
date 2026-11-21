import 'package:dailo/core/keys.dart';
import 'package:dailo/core/routes.dart';
import 'package:dailo/domain/entities/transaction_record.dart';
import 'package:dailo/domain/services/ussd_launcher.dart';
import 'package:dailo/presentation/cubits/send_money_cubit.dart';
import 'package:dailo/presentation/screens/send/review_payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/harness.dart';
import '../../fakes/samples.dart';
import 'screen_test_helpers.dart';

/// AT13, second half. Figma 15: name, amount, fee and total before the
/// phone dials.
void main() {
  /// A payment of 10,000 to Diane with a comment, ready to be reviewed.
  Future<void> prepareReview(TestApp app) async {
    await app.bind();
    app.sendCubit.start();
    app.sendCubit.chooseRecipient(sampleRecipients().first);
    app.sendCubit.setAmount(10000);
    app.sendCubit.setComment('Tomatoes, Tuesday');
    app.sendCubit.toReview();
  }

  /// Shows Review one route above a base page, so Edit and Cancel can pop.
  Future<TestApp> showReview(WidgetTester tester) async {
    final app = TestApp();
    await prepareReview(app);
    await showScreenAbovePage(
      tester,
      app,
      const ReviewPaymentScreen(),
      bindFirst: false,
    );
    return app;
  }

  group('what is shown', () {
    testWidgets('the name, amount, fee, total and comment of the payment', (
      tester,
    ) async {
      await showReview(tester);

      expect(textOf(tester, K.reviewName), 'Uwase Diane');
      expect(textOf(tester, K.reviewAmount), '10,000 Frw');
      expect(textOf(tester, K.reviewFee), '100 Frw');
      expect(textOf(tester, K.reviewTotal), '10,100 Frw');
      expect(find.text('Tomatoes, Tuesday'), findsOneWidget);
    });

    testWidgets('the network and the number, written for reading', (
      tester,
    ) async {
      await showReview(tester);

      final phone = textOf(tester, K.reviewPhone);
      expect(phone, contains('MTN'));
      expect(phone, contains('078 845 2310'));
    });

    testWidgets('no problem notice before anything went wrong', (tester) async {
      await showReview(tester);

      // The screen is built, and it has no notice yet.
      expect(find.byKey(K.reviewConfirm), findsOneWidget);
      expect(find.byKey(K.reviewProblem), findsNothing);
    });

    testWidgets('has no field to type in, so no PIN field', (tester) async {
      await showReview(tester);

      // The screen is built (it has its button) but nothing can be typed in.
      expect(find.byKey(K.reviewConfirm), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(EditableText), findsNothing);
      expectNoPinField(tester);
    });
  });

  group('Confirm', () {
    testWidgets('saves a pending record and dials the chained code', (
      tester,
    ) async {
      final app = await showReview(tester);
      final before = recordIds(app);

      await press(tester, K.reviewConfirm);

      expect(app.launcher.codes, ['*182*1*1*0788452310*10000#']);
      final added = recordsAddedSince(app, before);
      expect(added, hasLength(1));
      expect(added.single.status, TxStatus.pending);
      expect(added.single.amount, 10000);
      expect(app.sendCubit.state.step, SendStep.awaitingResult);
    });

    testWidgets('replaces Review with the payment result', (tester) async {
      final app = await showReview(tester);

      await press(tester, K.reviewConfirm);

      expectOnRoute(app, Routes.paymentResult);
      // Replaced, not pushed: Back from the result must not return to Review.
      expect(find.byKey(K.reviewConfirm, skipOffstage: false), findsNothing);
    });
  });

  group('when the phone cannot dial', () {
    for (final outcome in [UssdOutcome.permissionDenied, UssdOutcome.noSim]) {
      testWidgets('$outcome keeps every detail and shows the notice', (
        tester,
      ) async {
        final app = await showReview(tester);
        app.launcher.outcome = outcome;

        await press(tester, K.reviewConfirm);

        expect(find.byKey(K.reviewProblem), findsOneWidget);
        expectNothingPushed(app);
        expect(app.sendCubit.state.step, SendStep.review);
        expect(app.sendCubit.state.launchProblem, outcome);
        expect(textOf(tester, K.reviewName), 'Uwase Diane');
        expect(textOf(tester, K.reviewAmount), '10,000 Frw');
        expect(textOf(tester, K.reviewTotal), '10,100 Frw');
      });
    }
  });

  group('Edit amount and Cancel', () {
    testWidgets('Edit amount puts the cubit back on the amount step', (
      tester,
    ) async {
      final app = await showReview(tester);

      await press(tester, K.reviewEdit);

      expect(app.sendCubit.state.step, SendStep.amount);
      // Every detail is kept for the amount screen to show again.
      expect(app.sendCubit.state.amount, 10000);
      expect(app.sendCubit.state.recipient?.id, 'r1');
      // And the screen went back to the page below.
      expect(find.byKey(K.reviewEdit), findsNothing);
      expect(find.byKey(basePageKey), findsOneWidget);
    });

    testWidgets('Cancel throws the payment away and goes back to the start', (
      tester,
    ) async {
      final app = await showReview(tester);

      await press(tester, K.reviewCancel);

      expect(app.sendCubit.state.step, SendStep.recipient);
      expect(app.sendCubit.state.recipient, isNull);
      expect(app.sendCubit.state.amount, 0);
      expect(find.byKey(K.reviewCancel), findsNothing);
      expect(find.byKey(basePageKey), findsOneWidget);
    });
  });
}
