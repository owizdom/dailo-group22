// SplashScreen (track D2): what the user sees while the app asks Firebase
// whether anyone is signed in.
import 'package:dailo/presentation/screens/home/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/harness.dart';

void main() {
  testWidgets('shows the app name and a progress indicator, centred', (
    tester,
  ) async {
    final app = TestApp(session: null);

    await app.pumpScreen(tester, const SplashScreen());
    // No pumpAndSettle: a progress indicator animates forever.
    await tester.pump();

    final name = find.text(app.strings().appName);
    final spinner = find.byType(CircularProgressIndicator);
    expect(name, findsOneWidget);
    expect(spinner, findsOneWidget);

    final middle = tester.view.physicalSize.width / 2;
    expect(tester.getCenter(name).dx, closeTo(middle, 1));
    expect(tester.getCenter(spinner).dx, closeTo(middle, 1));
  });
}
