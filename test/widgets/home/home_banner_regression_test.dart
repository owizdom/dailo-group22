import 'package:dailo/presentation/widgets/common/header_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Found by hand on the emulator: on Home the welcome banner sits in a Stack
// under the settings icon, and it shrank to the width of its text. The white
// icon then ended up beside the banner on the pale page, where nobody could
// see it. A short title is used here on purpose: the test font is wide, so a
// long title fills the width by accident and hides the bug.
void main() {
  testWidgets('a banner inside a Stack still fills the width', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: Stack(children: [HeaderBanner.card(title: 'Hi')]),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(HeaderBanner)).width, 300);
  });
}
