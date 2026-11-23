import 'package:dailo/domain/entities/network.dart';
import 'package:dailo/domain/entities/transaction_record.dart';
import 'package:dailo/presentation/cubits/transactions_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/in_memory_repositories.dart';
import '../fakes/samples.dart';
import 'support.dart';

void main() {
  late InMemoryTransactionRepository repo;
  late TransactionsCubit cubit;

  setUp(() {
    repo = InMemoryTransactionRepository(sampleTransactions());
    cubit = TransactionsCubit(repo);
  });

  tearDown(() => cubit.close());

  /// Starts following u1's records and waits for the first list.
  Future<void> load() async {
    cubit.watch('u1');
    await settle();
  }

  List<String> visibleIds() => cubit.state.visible.map((r) => r.id).toList();

  Iterable<TransactionsMessage> messagesIn(List<TransactionsState> states) =>
      states.map((state) => state.message).whereType<TransactionsMessage>();

  group('watch', () {
    test('loads the three records, newest first', () async {
      await load();

      expect(cubit.state.all.map((r) => r.id), ['t3', 't2', 't1']);
      expect(cubit.state.loading, isFalse);
    });

    test('watch(null) clears the list', () async {
      await load();

      cubit.watch(null);
      await settle();

      expect(cubit.state.all, isEmpty);
    });

    test('a change in the repository shows without asking again', () async {
      await load();

      await repo.delete('u1', 't2');
      await settle();

      expect(cubit.state.all.map((r) => r.id), ['t3', 't1']);
    });
  });

  group('search and filter', () {
    test('a name search leaves the matching record', () async {
      await load();

      cubit.search('diane');
      await settle();

      expect(cubit.state.query, 'diane');
      expect(visibleIds(), ['t3']);
    });

    test('the search also reads the comment', () async {
      await load();

      cubit.search('tomatoes');
      await settle();

      expect(visibleIds(), ['t3']);
    });

    test('the search also reads the phone number', () async {
      await load();

      cubit.search('0788452310');
      await settle();

      expect(visibleIds(), ['t3']);
    });

    test('a filter by type leaves that type only', () async {
      await load();

      cubit.setFilter(TxType.airtime);
      await settle();

      expect(cubit.state.filter, TxType.airtime);
      expect(visibleIds(), ['t2']);
    });

    test('setFilter(null) shows every type again', () async {
      await load();
      cubit.setFilter(TxType.airtime);
      await settle();

      cubit.setFilter(null);
      await settle();

      expect(cubit.state.filter, isNull);
      expect(cubit.state.visible.length, 3);
    });

    test('a filter and a search work together', () async {
      await load();

      // This number is on the airtime record and the data record.
      cubit.search('0788000001');
      await settle();
      expect(visibleIds(), ['t2', 't1']);

      cubit.setFilter(TxType.airtime);
      await settle();
      expect(visibleIds(), ['t2']);

      cubit.setFilter(TxType.send);
      await settle();
      expect(visibleIds(), isEmpty);
    });
  });

  group('recent', () {
    test('holds at most the five newest records', () async {
      // Seven records, newest first.
      final seven = List.generate(
        7,
        (i) => TransactionRecord(
          id: 'x$i',
          type: TxType.send,
          counterpartyName: 'Person $i',
          counterpartyPhone: '0788000001',
          network: Network.mtn,
          amount: 1000,
          fee: 20,
          createdAt: day1.add(Duration(days: 7 - i)),
          updatedAt: day1.add(Duration(days: 7 - i)),
        ),
      );
      await cubit.close();
      cubit = TransactionsCubit(InMemoryTransactionRepository(seven));
      await load();

      expect(cubit.state.all.length, 7);
      expect(cubit.state.recent.map((r) => r.id), [
        'x0',
        'x1',
        'x2',
        'x3',
        'x4',
      ]);
    });
  });

  group('setStatus and delete', () {
    test('setStatus changes the record and says updated', () async {
      await load();
      final states = record(cubit);

      await cubit.setStatus('t2', TxStatus.success);
      await settle();

      final changed = repo.items.firstWhere((r) => r.id == 't2');
      expect(changed.status, TxStatus.success);
      expect(
        cubit.state.all.firstWhere((r) => r.id == 't2').status,
        TxStatus.success,
      );
      expect(messagesIn(states), contains(TransactionsMessage.updated));
    });

    test('delete removes the record and says deleted', () async {
      await load();
      final states = record(cubit);

      await cubit.delete('t1');
      await settle();

      expect(repo.items.map((r) => r.id), ['t3', 't2']);
      expect(cubit.state.all.map((r) => r.id), ['t3', 't2']);
      expect(messagesIn(states), contains(TransactionsMessage.deleted));
    });

    test('a rejected setStatus says failed and keeps the list', () async {
      await load();
      final before = cubit.state.all;
      final states = record(cubit);
      repo.failNext = true;

      await cubit.setStatus('t2', TxStatus.success);
      await settle();

      expect(messagesIn(states), contains(TransactionsMessage.failed));
      expect(cubit.state.all.length, 3);
      expect(cubit.state.all, before);
    });

    test('a rejected delete says failed and keeps the list', () async {
      await load();
      final before = cubit.state.all;
      final states = record(cubit);
      repo.failNext = true;

      await cubit.delete('t1');
      await settle();

      expect(messagesIn(states), contains(TransactionsMessage.failed));
      expect(cubit.state.all.length, 3);
      expect(cubit.state.all, before);
    });
  });
}
