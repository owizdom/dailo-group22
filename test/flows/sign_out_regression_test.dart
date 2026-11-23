import 'package:dailo/app.dart';
import 'package:dailo/core/keys.dart';
import 'package:dailo/domain/entities/auth_session.dart';
import 'package:dailo/presentation/cubits/profile_cubit.dart';
import 'package:dailo/presentation/cubits/recipients_cubit.dart';
import 'package:dailo/presentation/cubits/transactions_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/harness.dart';

void main() {
  testWidgets('defect 7: signing out empties the data cubits', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final app = TestApp();
    await tester.pumpWidget(DailoApp(dependencies: app.dependencies));
    await tester.pumpAndSettle();
    expect(find.byKey(K.homeSend), findsOneWidget);
    expect(find.byKey(K.transactionTile('t3')), findsOneWidget);

    app.auth.emit(null);
    await tester.pumpAndSettle();

    final context = tester.element(find.byKey(K.signInSubmit));
    expect(context.read<RecipientsCubit>().state.all, isEmpty);
    expect(context.read<TransactionsCubit>().state.all, isEmpty);
    expect(context.read<ProfileCubit>().state.user, isNull);

    app.auth.emit(
      const AuthSession(uid: 'u2', email: 'b@example.com', emailVerified: true),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(K.homeSend), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
