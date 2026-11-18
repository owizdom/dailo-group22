import 'package:dailo/domain/entities/transaction_record.dart';
import 'package:dailo/presentation/cubits/feedback_cubit.dart';
import 'package:dailo/presentation/cubits/profile_cubit.dart';
import 'package:dailo/presentation/cubits/recipients_cubit.dart';
import 'package:dailo/presentation/cubits/transactions_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/in_memory_repositories.dart';
import '../fakes/samples.dart';
import 'support.dart';

void main() {
  group('defect 3: clearSearch', () {
    // clearSearch() does not exist yet, so it is reached through `dynamic`
    // to keep this file compiling. Today the call throws NoSuchMethodError.
    test('RecipientsCubit.clearSearch empties the query', () async {
      final cubit = RecipientsCubit(
        InMemoryRecipientRepository(sampleRecipients()),
      );
      addTearDown(cubit.close);
      cubit.watch('u1');
      await settle();

      cubit.search('zzz');
      expect(cubit.state.recents, isEmpty);
      (cubit as dynamic).clearSearch();
      await settle();

      expect(cubit.state.query, '');
      expect(cubit.state.recents, hasLength(3));
    });

    test('TransactionsCubit.clearSearch empties query and filter', () async {
      final cubit = TransactionsCubit(
        InMemoryTransactionRepository(sampleTransactions()),
      );
      addTearDown(cubit.close);
      cubit.watch('u1');
      await settle();

      cubit.search('zzz');
      cubit.setFilter(TxType.airtime);
      (cubit as dynamic).clearSearch();
      await settle();

      expect(cubit.state.query, '');
      expect(cubit.state.filter, isNull);
      expect(cubit.state.visible, hasLength(3));
    });
  });

  group('defect 5: a rejected write reaches the cubit', () {
    test(
      'RecipientsCubit emits failed, and nothing after watch(null)',
      () async {
        final repo = InMemoryRecipientRepository(sampleRecipients());
        final cubit = RecipientsCubit(repo);
        addTearDown(cubit.close);
        cubit.watch('u1');
        await settle();
        final states = record(cubit);

        repo.rejectLastWrite();
        await settle();

        expect(
          states.map((s) => s.message),
          contains(RecipientsMessage.failed),
        );

        cubit.watch(null);
        await settle();
        final after = record(cubit);
        repo.rejectLastWrite();
        await settle();
        expect(after, isEmpty);
      },
    );

    test(
      'TransactionsCubit emits failed, and nothing after watch(null)',
      () async {
        final repo = InMemoryTransactionRepository(sampleTransactions());
        final cubit = TransactionsCubit(repo);
        addTearDown(cubit.close);
        cubit.watch('u1');
        await settle();
        final states = record(cubit);

        repo.rejectLastWrite();
        await settle();

        expect(
          states.map((s) => s.message),
          contains(TransactionsMessage.failed),
        );

        cubit.watch(null);
        await settle();
        final after = record(cubit);
        repo.rejectLastWrite();
        await settle();
        expect(after, isEmpty);
      },
    );

    test('ProfileCubit emits failed, and nothing after watch(null)', () async {
      final repo = FakeProfileRepository(sampleUser());
      final cubit = ProfileCubit(repo);
      addTearDown(cubit.close);
      cubit.watch('u1');
      await settle();
      final states = record(cubit);

      repo.rejectLastWrite();
      await settle();

      expect(states.map((s) => s.message), contains(ProfileMessage.failed));

      cubit.watch(null);
      await settle();
      final after = record(cubit);
      repo.rejectLastWrite();
      await settle();
      expect(after, isEmpty);
    });

    test('FeedbackCubit emits failed', () async {
      final repo = FakeFeedbackRepository();
      final cubit = FeedbackCubit(repo);
      addTearDown(cubit.close);
      cubit.bind('u1');
      final states = record(cubit);

      repo.rejectLastWrite();
      await settle();

      expect(states.map((s) => s.message), contains(FeedbackMessage.failed));
    });
  });
}
