import 'package:dailo/core/keys.dart';
import 'package:dailo/core/theme.dart';
import 'package:dailo/presentation/screens/auth/sign_in_screen.dart';
import 'package:dailo/presentation/screens/auth/sign_up_name_screen.dart';
import 'package:dailo/presentation/widgets/common/app_page.dart';
import 'package:dailo/presentation/widgets/common/header_banner.dart';
import 'package:dailo/presentation/widgets/send/amount_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/harness.dart';

// Details taken from the Figma frames, so the build keeps matching them.
void main() {
  InputDecoration decorationOf(WidgetTester tester, Key key) {
    final field = find.descendant(
      of: find.byKey(key),
      matching: find.byType(TextField),
    );
    return tester.widget<TextField>(field).decoration!;
  }

  testWidgets('sign-in fields are underlined, as in the Figma frame', (
    tester,
  ) async {
    await TestApp(session: null).pumpScreen(tester, const SignInScreen());

    for (final key in [K.signInEmail, K.signInPassword]) {
      final decoration = decorationOf(tester, key);
      expect(decoration.filled, isFalse);
      expect(decoration.enabledBorder, isA<UnderlineInputBorder>());
    }
  });

  testWidgets('sign-up name fields are underlined, as in the Figma frame', (
    tester,
  ) async {
    await TestApp(session: null).pumpScreen(tester, const SignUpNameScreen());

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(2));
    for (final field in tester.widgetList<TextField>(fields)) {
      expect(field.decoration!.enabledBorder, isA<UnderlineInputBorder>());
    }
  });

  test('button labels use Inter, the typeface of the Figma design', () {
    for (final theme in [buildLightTheme(), buildDarkTheme()]) {
      final filled = theme.filledButtonTheme.style!.textStyle!.resolve({})!;
      final outlined = theme.outlinedButtonTheme.style!.textStyle!.resolve({})!;
      expect(filled.fontFamily, 'Inter');
      expect(outlined.fontFamily, 'Inter');
    }
  });

  test('three quick amounts, as in the Figma Amount frame', () {
    expect(AmountChips.amounts, [500, 1000, 5000]);
  });

  testWidgets('the title band is at least 80 pixels tall', (tester) async {
    await TestApp().pumpScreen(
      tester,
      const AppPage(title: 'Send Money', children: [Text('body')]),
    );

    expect(
      tester.getSize(find.byType(HeaderBanner)).height,
      greaterThanOrEqualTo(80),
    );
  });
}
