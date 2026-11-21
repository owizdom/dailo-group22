import 'package:dailo/core/keys.dart';
import 'package:dailo/presentation/screens/recipients/recipients_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/harness.dart';
import '../send/screen_test_helpers.dart';

void main() {
  testWidgets('defect 3: leaving the screen clears the search', (tester) async {
    final app = TestApp();
    await showScreenAbovePage(tester, app, const RecipientsScreen());
    await enterIn(tester, K.recipientsSearch, 'zzz');
    await tester.pumpAndSettle();
    expect(app.recipientsCubit.state.query, 'zzz');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byKey(basePageKey), findsOneWidget);
    expect(app.recipientsCubit.state.query, '');
    expect(app.recipientsCubit.state.recents, hasLength(3));
  });

  testWidgets('defect 5: a rejected write shows a snack bar', (tester) async {
    final app = TestApp();
    await showScreen(tester, app, const RecipientsScreen());

    app.recipientRepo.rejectLastWrite();
    await tester.pump();
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
  });
}
