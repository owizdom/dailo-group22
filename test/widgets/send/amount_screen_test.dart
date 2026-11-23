import 'package:dailo/core/formatters.dart';
import 'package:dailo/core/keys.dart';
import 'package:dailo/core/routes.dart';
import 'package:dailo/core/validators.dart';
import 'package:dailo/domain/entities/app_settings.dart';
import 'package:dailo/domain/entities/network.dart';
import 'package:dailo/presentation/cubits/send_money_cubit.dart';
import 'package:dailo/presentation/screens/send/amount_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/harness.dart';
import '../../fakes/samples.dart';
import 'screen_test_helpers.dart';

/// AT13, first half. Figma 14: amount, quick amounts, live fee and total,
/// fee band warning, comment.
void main() {
  /// The payment is paid to Diane (r1) from the user's default network, and
  /// the send cubit is already on the amount step, as after Send Money.
  Future<TestApp> showAmount(WidgetTester tester, {TestApp? app}) async {
    final testApp = app ?? TestApp();
    await testApp.bind();
    testApp.sendCubit.start();
    testApp.sendCubit.chooseRecipient(sampleRecipients().first);
    await showScreen(tester, testApp, const AmountScreen(), bindFirst: false);
    return testApp;
  }

  group('the recipient card', () {
    testWidgets('shows who is being paid', (tester) async {
      await showAmount(tester);

      final card = find.byKey(K.amountRecipient);
      expect(card, findsOneWidget);
      expect(
        find.descendant(of: card, matching: find.text('Uwase Diane')),
        findsOneWidget,
      );
    });
  });

  group('fee and total follow the amount', () {
    testWidgets('10,500 costs 250 and offers a cheaper amount', (tester) async {
      await showAmount(tester);

      await enterIn(tester, K.amountField, '10500');

      expect(textOf(tester, K.amountFee), formatFrw(250));
      expect(textOf(tester, K.amountFee), '250 Frw');
      expect(textOf(tester, K.amountTotal), formatFrw(10750));
      expect(textOf(tester, K.amountTotal), '10,750 Frw');
      expect(find.byKey(K.amountHint), findsOneWidget);
      expect(find.byKey(K.amountHintApply), findsOneWidget);
    });

    testWidgets('10,000 costs 100 and offers no hint', (tester) async {
      await showAmount(tester);

      await enterIn(tester, K.amountField, '10000');

      expect(textOf(tester, K.amountFee), formatFrw(100));
      expect(textOf(tester, K.amountFee), '100 Frw');
      expect(textOf(tester, K.amountTotal), formatFrw(10100));
      expect(textOf(tester, K.amountTotal), '10,100 Frw');
      expect(find.byKey(K.amountHint), findsNothing);
    });

    testWidgets('changing the amount updates the fee, total and hint', (
      tester,
    ) async {
      await showAmount(tester);

      await enterIn(tester, K.amountField, '10500');
      expect(textOf(tester, K.amountFee), '250 Frw');
      expect(find.byKey(K.amountHint), findsOneWidget);

      await enterIn(tester, K.amountField, '10000');
      expect(textOf(tester, K.amountFee), '100 Frw');
      expect(textOf(tester, K.amountTotal), '10,100 Frw');
      expect(find.byKey(K.amountHint), findsNothing);
    });

    testWidgets('with the fee warning off, 10,500 shows no hint', (
      tester,
    ) async {
      final app = TestApp(settings: const AppSettings(feeWarning: false));
      await showAmount(tester, app: app);

      await enterIn(tester, K.amountField, '10500');

      expect(find.byKey(K.amountHint), findsNothing);
      // The fee itself is still shown; only the advice is switched off.
      expect(textOf(tester, K.amountFee), '250 Frw');
    });

    testWidgets('an unknown fee table says the network shows the fee', (
      tester,
    ) async {
      // Only MTN's table is built in, so paying from Airtel has no known fee.
      final app = TestApp(
        settings: const AppSettings(defaultNetwork: Network.airtel),
      );
      await showAmount(tester, app: app);

      await enterIn(tester, K.amountField, '10500');

      final state = app.sendCubit.state;
      expect(
        state.feeKnown,
        isFalse,
        reason: 'the cubit should not know the fee',
      );
      // The screen must not pass a made-up number off as the fee.
      expect(textOf(tester, K.amountFee), isNot(formatFrw(state.fee)));
      expect(textOf(tester, K.amountFee), isNotEmpty);
    });
  });

  group('the cheaper amount hint', () {
    testWidgets('Change to the cheaper amount fills the field and the fee', (
      tester,
    ) async {
      final app = await showAmount(tester);
      await enterIn(tester, K.amountField, '10500');

      await press(tester, K.amountHintApply);

      expect(fieldText(tester, K.amountField), anyOf('10,000', '10000'));
      expect(app.sendCubit.state.amount, 10000);
      expect(textOf(tester, K.amountFee), '100 Frw');
      expect(find.byKey(K.amountHint), findsNothing);
    });
  });

  group('quick amounts', () {
    testWidgets('a chip puts its amount in the field and the cubit', (
      tester,
    ) async {
      final app = await showAmount(tester);

      for (final value in [500, 1000, 5000]) {
        await press(tester, K.amountChip(value));

        expect(app.sendCubit.state.amount, value);
        final typed = fieldText(tester, K.amountField).replaceAll(',', '');
        expect(typed, '$value');
      }
    });

    testWidgets('the 5,000 chip shows a fee of 100', (tester) async {
      await showAmount(tester);

      await press(tester, K.amountChip(5000));

      expect(textOf(tester, K.amountFee), formatFrw(100));
      expect(textOf(tester, K.amountFee), '100 Frw');
      expect(textOf(tester, K.amountTotal), '5,100 Frw');
    });
  });

  group('the comment', () {
    testWidgets('what is typed is kept in the cubit', (tester) async {
      final app = await showAmount(tester);

      await enterIn(tester, K.amountComment, 'Tomatoes, Tuesday');

      expect(app.sendCubit.state.comment, 'Tomatoes, Tuesday');
    });
  });

  group('Review', () {
    testWidgets('an empty amount shows the required message and stays', (
      tester,
    ) async {
      final app = await showAmount(tester);

      await press(tester, K.amountReview);

      final required = app.strings().fieldError(FieldError.required);
      expect(find.text(required), findsOneWidget);
      expectNothingPushed(app);
      expect(app.sendCubit.state.step, SendStep.amount);
    });

    testWidgets('a valid amount moves the cubit to review and opens Review', (
      tester,
    ) async {
      final app = await showAmount(tester);
      await enterIn(tester, K.amountField, '10000');

      await press(tester, K.amountReview);

      expectOnRoute(app, Routes.review);
      expect(app.sendCubit.state.step, SendStep.review);
      expect(app.sendCubit.state.amount, 10000);
    });
  });

  group('no PIN', () {
    testWidgets('only the amount and the comment can be typed in', (
      tester,
    ) async {
      await showAmount(tester);

      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.byKey(K.amountField), findsOneWidget);
      expect(find.byKey(K.amountComment), findsOneWidget);
      expectNoPinField(tester);
    });
  });
}
