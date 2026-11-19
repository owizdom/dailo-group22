import 'package:dailo/core/keys.dart';
import 'package:dailo/core/routes.dart';
import 'package:dailo/presentation/screens/recipients/generate_qr_screen.dart';
import 'package:dailo/presentation/widgets/common/buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../fakes/harness.dart';
import '../../fakes/samples.dart';
import '../send/screen_test_helpers.dart';

/// Shows the user's own payment QR code, so someone else can scan it to pay
/// them.
void main() {
  /// True when the QR code sits on a white background, either its own or a
  /// white box around it. A dark QR on a dark page cannot be scanned.
  bool sitsOnWhite(WidgetTester tester) {
    final element = tester.element(find.byKey(K.qrImage));
    var white = (element.widget as QrImageView).backgroundColor == Colors.white;
    element.visitAncestorElements((ancestor) {
      final widget = ancestor.widget;
      final color = switch (widget) {
        ColoredBox() => widget.color,
        DecoratedBox(:final decoration) =>
          decoration is BoxDecoration ? decoration.color : null,
        Material() => widget.color,
        PhysicalModel() => widget.color,
        _ => null,
      };
      if (color == Colors.white) white = true;
      return !white;
    });
    return white;
  }

  group('a profile with a phone number', () {
    testWidgets('shows the QR code, the name and the number', (tester) async {
      final app = TestApp();
      await showScreen(tester, app, const GenerateQrScreen());

      expect(find.byKey(K.qrImage), findsOneWidget);
      expect(find.byKey(K.qrMissingPhone), findsNothing);
      expect(find.textContaining('Aline Mukamana'), findsWidgets);
      expect(find.textContaining('078 800 0001'), findsWidgets);
    });

    for (final dark in [false, true]) {
      testWidgets('the QR code sits on white in the ${dark ? 'dark' : 'light'} '
          'theme', (tester) async {
        final app = TestApp();
        await showScreen(tester, app, const GenerateQrScreen(), dark: dark);

        expect(find.byKey(K.qrImage), findsOneWidget);
        expect(sitsOnWhite(tester), isTrue);
      });
    }
  });

  group('a profile without a usable phone number', () {
    for (final phone in ['', '12345']) {
      testWidgets('"$phone" shows the missing-phone message and no QR code', (
        tester,
      ) async {
        final app = TestApp();
        app.profileRepo.user = sampleUser().copyWith(phone: phone);
        await showScreen(tester, app, const GenerateQrScreen());

        expect(find.byKey(K.qrMissingPhone), findsOneWidget);
        expect(find.byKey(K.qrImage), findsNothing);
      });
    }

    testWidgets('the button opens Edit profile so the number can be added', (
      tester,
    ) async {
      final app = TestApp();
      app.profileRepo.user = sampleUser().copyWith(phone: '');
      await showScreen(tester, app, const GenerateQrScreen());

      // The contract names no key for this button, so find the one shared
      // primary or secondary button on the screen.
      final button = find.byWidgetPredicate(
        (widget) => widget is PrimaryButton || widget is SecondaryButton,
      );
      expect(button, findsOneWidget);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expectOnRoute(app, Routes.editProfile);
    });
  });
}
