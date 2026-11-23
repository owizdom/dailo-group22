import 'package:dailo/core/keys.dart';
import 'package:dailo/presentation/screens/history/transaction_history_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/harness.dart';
import '../send/screen_test_helpers.dart';

void main() {
  testWidgets('defect 3: leaving History clears search and filter', (
    tester,
  ) async {
    final app = TestApp();
    await showScreenAbovePage(tester, app, const TransactionHistoryScreen());
    await enterIn(tester, K.historySearch, 'zzz');
    await press(tester, K.historyFilter('airtime'));
    expect(app.transactionsCubit.state.query, 'zzz');
    expect(app.transactionsCubit.state.filter, isNotNull);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byKey(basePageKey), findsOneWidget);
    expect(app.transactionsCubit.state.query, '');
    expect(app.transactionsCubit.state.filter, isNull);
    expect(app.transactionsCubit.state.visible, hasLength(3));
  });
}
