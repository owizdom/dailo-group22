import 'package:dailo/presentation/widgets/common/app_page.dart';
import 'package:dailo/presentation/widgets/common/header_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/harness.dart';

// Found on the emulator: the title band was a small centred box. In the
// Figma it spans the whole width and reaches the top edge of the screen.
void main() {
  for (final size in const [smallPhone, largePhone, landscapePhone]) {
    testWidgets('the title band spans the full width at $size', (tester) async {
      final app = TestApp();
      await app.pumpScreen(
        tester,
        const AppPage(title: 'Send Money', children: [Text('body')]),
        size: size,
      );

      final band = tester.getRect(find.byType(HeaderBanner));
      expect(band.left, 0);
      expect(band.width, size.width);
      expect(band.top, 0, reason: 'the band starts at the top edge');
    });
  }

  testWidgets('the title stays below the status bar', (tester) async {
    final app = TestApp();
    tester.view.padding = const FakeViewPadding(top: 40);
    addTearDown(tester.view.resetPadding);
    await app.pumpScreen(
      tester,
      const AppPage(title: 'Send Money', children: [Text('body')]),
    );

    final title = tester.getRect(find.text('Send Money'));
    expect(title.top, greaterThanOrEqualTo(40));
    expect(tester.getRect(find.byType(HeaderBanner)).top, 0);
  });
}
