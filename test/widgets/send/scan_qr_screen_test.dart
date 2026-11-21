import 'package:dailo/core/keys.dart';
import 'package:dailo/core/routes.dart';
import 'package:dailo/domain/logic/qr_payload.dart';
import 'package:dailo/presentation/screens/send/scan_qr_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/harness.dart';
import 'screen_test_helpers.dart';

/// Figma 7. The camera is replaced by a fake that hands the screen the text
/// of a "scanned" code, so no camera or plugin is needed.
void main() {
  const fakeScanner = Key('fakeScanner');
  late void Function(String raw) scan;

  /// The screen under test. The builder keeps the screen's `onCode`
  /// callback in [scan] so the test can pretend the camera read a code.
  Widget screen() {
    return ScanQrScreen(
      scannerBuilder: (onCode) {
        scan = onCode;
        return const SizedBox(key: fakeScanner, width: 200, height: 200);
      },
    );
  }

  /// What the shop owner's own QR code says.
  String shopCode() => encodeQr(name: 'Shop Owner', phone: '0788111222');

  /// Opens the screen one route above a base page and checks that the fake
  /// scanner is showing, so [scan] is set before a test uses it.
  Future<TestApp> openScanner(WidgetTester tester) async {
    final app = TestApp();
    await showScreenAbovePage(tester, app, screen());
    expect(find.byKey(fakeScanner), findsOneWidget);
    return app;
  }

  group('the camera view', () {
    testWidgets('shows the scanner it is given', (tester) async {
      final app = TestApp();
      await showScreen(tester, app, screen());

      expect(find.byKey(fakeScanner), findsOneWidget);
    });
  });

  group('a DailO payment code', () {
    testWidgets('chooses its contact and replaces the screen with Amount', (
      tester,
    ) async {
      final app = await openScanner(tester);

      scan(shopCode());
      await tester.pumpAndSettle();

      expectOnRoute(app, Routes.amount);
      expect(app.sendCubit.state.recipient?.name, 'Shop Owner');
      expect(app.sendCubit.state.recipient?.phone, '0788111222');
      // Replaced, not pushed: the scanner is gone from the stack.
      expect(find.byKey(fakeScanner, skipOffstage: false), findsNothing);
    });

    testWidgets('only the first valid code is acted on', (tester) async {
      final app = await openScanner(tester);

      // A camera reports the same code on several frames in a row.
      scan(shopCode());
      scan(shopCode());
      await tester.pumpAndSettle();

      final amountPages = app.pushed.where(
        (route) => route.name == Routes.amount,
      );
      expect(amountPages, hasLength(1));
    });
  });

  group('a code that is not a DailO payment code', () {
    testWidgets('shows a snack, stays on the screen and picks nobody', (
      tester,
    ) async {
      final app = await openScanner(tester);

      scan('junk');
      await tester.pumpAndSettle();

      expectSnack();
      expect(find.byKey(fakeScanner), findsOneWidget);
      expectNothingPushed(app);
      expect(app.sendCubit.state.recipient, isNull);
    });

    testWidgets('keeps scanning, so a valid code afterwards still works', (
      tester,
    ) async {
      final app = await openScanner(tester);

      scan('junk');
      await tester.pumpAndSettle();
      scan(shopCode());
      await tester.pumpAndSettle();

      expectOnRoute(app, Routes.amount);
      expect(app.sendCubit.state.recipient?.name, 'Shop Owner');
    });
  });

  group('the two ways out', () {
    testWidgets('type a number instead goes back to the previous page', (
      tester,
    ) async {
      final app = await openScanner(tester);

      await press(tester, K.scanManual);

      expect(find.byKey(fakeScanner), findsNothing);
      expect(find.byKey(basePageKey), findsOneWidget);
      // It went back; it did not open another page.
      expectNothingPushed(app);
    });

    testWidgets('my code opens the payment QR generator', (tester) async {
      final app = await openScanner(tester);

      await press(tester, K.scanMyCode);

      expectOnRoute(app, Routes.generateQr);
    });
  });
}
