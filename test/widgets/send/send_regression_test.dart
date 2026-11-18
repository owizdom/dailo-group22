import 'package:dailo/core/keys.dart';
import 'package:dailo/domain/entities/app_settings.dart';
import 'package:dailo/domain/entities/network.dart';
import 'package:dailo/presentation/cubits/send_money_cubit.dart';
import 'package:dailo/presentation/screens/history/buy_airtime_screen.dart';
import 'package:dailo/presentation/screens/history/buy_data_screen.dart';
import 'package:dailo/presentation/screens/send/payment_result_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/harness.dart';
import '../../fakes/samples.dart';
import 'screen_test_helpers.dart';

// The key the implementer adds for the "follow these menu steps" panel.
const _steps = Key('ussd.steps');

void main() {
  group('defect 1: airtime for a number typed with prefix and spaces', () {
    testWidgets('the stored record holds 0788123456', (tester) async {
      final app = TestApp();
      await showScreenAbovePage(tester, app, const BuyAirtimeScreen());
      final before = recordIds(app);
      await enterIn(tester, K.airtimeAmount, '500');
      await enterIn(tester, K.airtimePhone, '+250 788 123 456');

      await press(tester, K.airtimeBuy);

      final added = recordsAddedSince(app, before);
      expect(added, hasLength(1));
      expect(added.single.counterpartyPhone, '0788123456');
    });
  });

  group('defect 4: the menu steps show when only the root menu is dialled', () {
    testWidgets('Buy Airtime shows the steps after buying', (tester) async {
      final app = TestApp();
      await showScreenAbovePage(tester, app, const BuyAirtimeScreen());
      await enterIn(tester, K.airtimeAmount, '500');

      await press(tester, K.airtimeBuy);

      expect(find.byKey(K.resultYes), findsOneWidget);
      expect(find.byKey(_steps), findsOneWidget);
    });

    testWidgets('Buy Data shows the steps after buying', (tester) async {
      final app = TestApp();
      await showScreenAbovePage(tester, app, const BuyDataScreen());
      await enterIn(tester, K.dataAmount, '1000');

      await press(tester, K.dataBuy);

      expect(find.byKey(K.resultYes), findsOneWidget);
      expect(find.byKey(_steps), findsOneWidget);
    });

    Future<TestApp> awaiting(WidgetTester tester, TestApp app) async {
      await app.bind();
      app.sendCubit.start();
      app.sendCubit.chooseRecipient(sampleRecipients().first);
      app.sendCubit.setAmount(10000);
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

    testWidgets('a chained MTN to MTN code shows no steps', (tester) async {
      await awaiting(tester, TestApp());

      expect(find.byKey(K.resultYes), findsOneWidget);
      expect(find.byKey(_steps), findsNothing);
    });

    testWidgets('paying from Airtel (root menu) shows the steps', (
      tester,
    ) async {
      await awaiting(
        tester,
        TestApp(settings: const AppSettings(defaultNetwork: Network.airtel)),
      );

      expect(find.byKey(K.resultYes), findsOneWidget);
      expect(find.byKey(_steps), findsOneWidget);
    });
  });
}
