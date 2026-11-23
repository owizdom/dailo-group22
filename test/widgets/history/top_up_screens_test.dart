import 'package:dailo/core/keys.dart';
import 'package:dailo/core/validators.dart';
import 'package:dailo/domain/entities/transaction_record.dart';
import 'package:dailo/domain/services/ussd_launcher.dart';
import 'package:dailo/presentation/screens/history/buy_airtime_screen.dart';
import 'package:dailo/presentation/screens/history/buy_data_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/harness.dart';
import '../send/screen_test_helpers.dart';

/// Buy Airtime and Buy Data. Both save the purchase as pending, dial the
/// operator's code, then ask the user what happened.
void main() {
  /// Shows [screen] one route above a base page, so the screen can pop when
  /// the purchase is finished.
  Future<TestApp> showTopUp(WidgetTester tester, Widget screen) async {
    final app = TestApp();
    await showScreenAbovePage(tester, app, screen);
    return app;
  }

  void expectThreeAnswers() {
    expect(find.byKey(K.resultYes), findsOneWidget);
    expect(find.byKey(K.resultNo), findsOneWidget);
    expect(find.byKey(K.resultNotSure), findsOneWidget);
  }

  void expectNoAnswers() {
    expect(find.byKey(K.resultYes), findsNothing);
    expect(find.byKey(K.resultNo), findsNothing);
    expect(find.byKey(K.resultNotSure), findsNothing);
  }

  group('BuyAirtimeScreen', () {
    testWidgets('an empty amount shows the required message and buys nothing', (
      tester,
    ) async {
      final app = await showTopUp(tester, const BuyAirtimeScreen());
      final before = recordIds(app);

      await press(tester, K.airtimeBuy);

      final required = app.strings().fieldError(FieldError.required);
      expect(find.text(required), findsOneWidget);
      expect(recordsAddedSince(app, before), isEmpty);
      expect(app.launcher.codes, isEmpty);
    });

    testWidgets('an amount saves a pending record, dials once and asks', (
      tester,
    ) async {
      final app = await showTopUp(tester, const BuyAirtimeScreen());
      final before = recordIds(app);
      await enterIn(tester, K.airtimeAmount, '500');

      await press(tester, K.airtimeBuy);

      final added = recordsAddedSince(app, before);
      expect(added, hasLength(1));
      expect(added.single.type, TxType.airtime);
      expect(added.single.amount, 500);
      expect(added.single.status, TxStatus.pending);
      expect(app.launcher.codes, hasLength(1));
      expectThreeAnswers();
    });

    for (final (answer, status) in [
      (K.resultYes, TxStatus.success),
      (K.resultNo, TxStatus.failed),
      (K.resultNotSure, TxStatus.pending),
    ]) {
      testWidgets(
        'the answer ${status.name} is saved, then the screen closes',
        (tester) async {
          final app = await showTopUp(tester, const BuyAirtimeScreen());
          final before = recordIds(app);
          await enterIn(tester, K.airtimeAmount, '500');
          await press(tester, K.airtimeBuy);

          await press(tester, answer);

          expect(recordsAddedSince(app, before).single.status, status);
          // A snack says what was saved, the cubit is ready for the next
          // purchase, and the screen went back to the page below.
          expectSnack();
          expect(app.topUpCubit.state.awaitingResult, isFalse);
          expect(find.byKey(K.airtimeBuy), findsNothing);
          expect(find.byKey(basePageKey), findsOneWidget);
        },
      );
    }

    testWidgets('a bad number for someone else shows invalid phone', (
      tester,
    ) async {
      final app = await showTopUp(tester, const BuyAirtimeScreen());
      final before = recordIds(app);
      await enterIn(tester, K.airtimeAmount, '500');
      await enterIn(tester, K.airtimePhone, '123');

      await press(tester, K.airtimeBuy);

      final invalid = app.strings().fieldError(FieldError.invalidPhone);
      expect(find.text(invalid), findsOneWidget);
      expect(recordsAddedSince(app, before), isEmpty);
      expect(app.launcher.codes, isEmpty);
    });

    testWidgets('a valid number for someone else is stored on the record', (
      tester,
    ) async {
      final app = await showTopUp(tester, const BuyAirtimeScreen());
      final before = recordIds(app);
      await enterIn(tester, K.airtimeAmount, '500');
      await enterIn(tester, K.airtimePhone, '0788111222');

      await press(tester, K.airtimeBuy);

      final added = recordsAddedSince(app, before);
      expect(added, hasLength(1));
      expect(added.single.counterpartyPhone, '0788111222');
    });

    testWidgets('with no SIM it shows the notice and does not ask', (
      tester,
    ) async {
      final app = await showTopUp(tester, const BuyAirtimeScreen());
      app.launcher.outcome = UssdOutcome.noSim;
      await enterIn(tester, K.airtimeAmount, '500');

      await press(tester, K.airtimeBuy);

      expect(find.byKey(K.reviewProblem), findsOneWidget);
      expectNoAnswers();
    });
  });

  group('BuyDataScreen', () {
    testWidgets('an empty amount shows the required message and buys nothing', (
      tester,
    ) async {
      final app = await showTopUp(tester, const BuyDataScreen());
      final before = recordIds(app);

      await press(tester, K.dataBuy);

      final required = app.strings().fieldError(FieldError.required);
      expect(find.text(required), findsOneWidget);
      expect(recordsAddedSince(app, before), isEmpty);
      expect(app.launcher.codes, isEmpty);
    });

    testWidgets('a price saves a pending data record, dials and asks', (
      tester,
    ) async {
      final app = await showTopUp(tester, const BuyDataScreen());
      final before = recordIds(app);
      await enterIn(tester, K.dataAmount, '1000');

      await press(tester, K.dataBuy);

      final added = recordsAddedSince(app, before);
      expect(added, hasLength(1));
      expect(added.single.type, TxType.data);
      expect(added.single.amount, 1000);
      expect(added.single.status, TxStatus.pending);
      expect(app.launcher.codes, hasLength(1));
      expectThreeAnswers();
    });

    testWidgets('Yes saves the purchase as confirmed and closes the screen', (
      tester,
    ) async {
      final app = await showTopUp(tester, const BuyDataScreen());
      final before = recordIds(app);
      await enterIn(tester, K.dataAmount, '1000');
      await press(tester, K.dataBuy);

      await press(tester, K.resultYes);

      expect(recordsAddedSince(app, before).single.status, TxStatus.success);
      expect(find.byKey(K.dataBuy), findsNothing);
      expect(find.byKey(basePageKey), findsOneWidget);
    });

    testWidgets('with no SIM it shows the notice and does not ask', (
      tester,
    ) async {
      final app = await showTopUp(tester, const BuyDataScreen());
      app.launcher.outcome = UssdOutcome.noSim;
      await enterIn(tester, K.dataAmount, '1000');

      await press(tester, K.dataBuy);

      expect(find.byKey(K.reviewProblem), findsOneWidget);
      expectNoAnswers();
    });
  });
}
