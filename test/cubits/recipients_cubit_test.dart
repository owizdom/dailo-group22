import 'package:dailo/domain/entities/network.dart';
import 'package:dailo/domain/entities/recipient.dart';
import 'package:dailo/presentation/cubits/recipients_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/in_memory_repositories.dart';
import '../fakes/samples.dart';
import 'support.dart';

void main() {
  late InMemoryRecipientRepository repo;
  late RecipientsCubit cubit;

  setUp(() {
    repo = InMemoryRecipientRepository(sampleRecipients());
    cubit = RecipientsCubit(repo);
  });

  tearDown(() => cubit.close());

  /// Starts following u1's recipients and waits for the first list.
  Future<void> load() async {
    cubit.watch('u1');
    await settle();
  }

  Recipient stored(String id) => repo.items.firstWhere((r) => r.id == id);

  Iterable<RecipientsMessage> messagesIn(List<RecipientsState> states) =>
      states.map((state) => state.message).whereType<RecipientsMessage>();

  group('watch', () {
    test('loads the three saved recipients', () async {
      await load();

      expect(cubit.state.all.map((r) => r.id), ['r1', 'r2', 'r3']);
      expect(cubit.state.loading, isFalse);
    });

    test('watch(null) clears the list', () async {
      await load();

      cubit.watch(null);
      await settle();

      expect(cubit.state.all, isEmpty);
    });

    test(
      'after watch(null) repository changes no longer reach the state',
      () async {
        await load();
        cubit.watch(null);
        await settle();

        await repo.add('u1', sampleRecipients().first);
        await settle();

        expect(repo.items.length, 4);
        expect(cubit.state.all, isEmpty);
      },
    );

    test('a change in the repository shows without asking again', () async {
      await load();

      await repo.delete('u1', 'r3');
      await settle();

      expect(cubit.state.all.map((r) => r.id), ['r1', 'r2']);
    });
  });

  group('search, recents and favourites', () {
    test('a name search keeps the matching recipient', () async {
      await load();

      cubit.search('diane');
      await settle();

      expect(cubit.state.query, 'diane');
      expect(cubit.state.matching.map((r) => r.name), ['Uwase Diane']);
    });

    test('digits match the phone number', () async {
      await load();

      cubit.search('0791');
      await settle();

      expect(cubit.state.matching.map((r) => r.name), ['Jean Bosco']);
    });

    test('an empty search restores everyone', () async {
      await load();
      cubit.search('diane');
      await settle();

      cubit.search('');
      await settle();

      expect(cubit.state.matching.length, 3);
    });

    test('recents run from the latest payment to the oldest', () async {
      await load();

      expect(cubit.state.recents.map((r) => r.name), [
        'Uwase Diane',
        'Jean Bosco',
        'Eric Airtel',
      ]);
    });

    test('favourites are only the starred recipients', () async {
      await load();

      expect(cubit.state.favorites.map((r) => r.name), ['Uwase Diane']);
    });
  });

  group('add', () {
    test('saves a valid number in the 07 form and says it was added', () async {
      await load();
      final states = record(cubit);

      final id = await cubit.add(name: 'New Person', phone: '+250788111222');
      await settle();

      expect(id, isNotNull);
      expect(repo.items.length, 4);
      final added = repo.items.singleWhere((r) => r.phone == '0788111222');
      expect(added.id, id);
      expect(added.name, 'New Person');
      expect(added.network, Network.mtn);
      expect(messagesIn(states), contains(RecipientsMessage.added));
      expect(cubit.state.all.length, 4);
    });

    test('an Airtel number is saved with the Airtel network', () async {
      await load();

      await cubit.add(name: 'Airtel Person', phone: '0731234567');
      await settle();

      final added = repo.items.singleWhere((r) => r.phone == '0731234567');
      expect(added.network, Network.airtel);
    });

    test('an invalid number saves nothing and says it failed', () async {
      await load();
      final states = record(cubit);

      final id = await cubit.add(name: 'X', phone: '123');
      await settle();

      expect(id, isNull);
      expect(repo.items.length, 3);
      expect(messagesIn(states), contains(RecipientsMessage.failed));
    });

    test('a number that is already saved returns the existing id', () async {
      await load();
      final states = record(cubit);

      final id = await cubit.add(name: 'Dup', phone: '0788452310');
      await settle();

      expect(id, 'r1');
      expect(repo.items.length, 3);
      expect(messagesIn(states), contains(RecipientsMessage.duplicate));
    });

    test(
      'the same number with a country prefix is still a duplicate',
      () async {
        await load();

        final id = await cubit.add(name: 'Dup', phone: '+250 788 452 310');
        await settle();

        expect(id, 'r1');
        expect(repo.items.length, 3);
      },
    );
  });

  group('edit, delete and favourite', () {
    test('edit changes the stored recipient and says updated', () async {
      await load();
      final states = record(cubit);

      await cubit.edit(stored('r2').copyWith(name: 'Renamed'));
      await settle();

      expect(stored('r2').name, 'Renamed');
      expect(cubit.state.all.firstWhere((r) => r.id == 'r2').name, 'Renamed');
      expect(messagesIn(states), contains(RecipientsMessage.updated));
    });

    test('delete removes the recipient and says deleted', () async {
      await load();
      final states = record(cubit);

      await cubit.delete('r2');
      await settle();

      expect(repo.items.map((r) => r.id), ['r1', 'r3']);
      expect(cubit.state.all.map((r) => r.id), ['r1', 'r3']);
      expect(messagesIn(states), contains(RecipientsMessage.deleted));
    });

    test(
      'toggleFavorite stars a recipient, and again removes the star',
      () async {
        await load();

        await cubit.toggleFavorite(stored('r2'));
        await settle();

        expect(stored('r2').isFavorite, isTrue);
        expect(
          cubit.state.favorites.map((r) => r.name),
          contains('Jean Bosco'),
        );

        final starred = cubit.state.all.firstWhere((r) => r.id == 'r2');
        await cubit.toggleFavorite(starred);
        await settle();

        expect(stored('r2').isFavorite, isFalse);
        expect(
          cubit.state.favorites.map((r) => r.name),
          isNot(contains('Jean Bosco')),
        );
      },
    );
  });

  group('when the repository rejects a write', () {
    /// Runs [action] with the next write failing, then checks that a failed
    /// message was emitted and the list is exactly as it was.
    Future<void> expectFailureKeepsList(Future<void> Function() action) async {
      await load();
      final before = cubit.state.all;
      final states = record(cubit);
      repo.failNext = true;

      await action();
      await settle();

      expect(messagesIn(states), contains(RecipientsMessage.failed));
      expect(cubit.state.all.length, 3);
      expect(cubit.state.all, before);
    }

    test('add says failed and keeps the list', () async {
      await expectFailureKeepsList(() async {
        final id = await cubit.add(name: 'New Person', phone: '0788111222');
        expect(id, isNull);
      });
    });

    test('edit says failed and keeps the list', () {
      return expectFailureKeepsList(
        () => cubit.edit(stored('r2').copyWith(name: 'Renamed')),
      );
    });

    test('delete says failed and keeps the list', () {
      return expectFailureKeepsList(() => cubit.delete('r2'));
    });

    test('toggleFavorite says failed and keeps the list', () {
      return expectFailureKeepsList(() => cubit.toggleFavorite(stored('r2')));
    });
  });

  group('messages are one-off', () {
    test('the state after a message has no message', () async {
      await load();
      final states = record(cubit);
      await cubit.delete('r2');
      await settle();

      cubit.search('a');
      await settle();

      final last = states.lastIndexWhere((state) => state.message != null);
      expect(states[last].message, RecipientsMessage.deleted);
      expect(last, lessThan(states.length - 1));
      expect(states[last + 1].message, isNull);
      expect(cubit.state.message, isNull);
    });
  });
}
