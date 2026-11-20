import 'package:dailo/domain/entities/network.dart';
import 'package:dailo/presentation/cubits/profile_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/in_memory_repositories.dart';
import '../fakes/samples.dart';
import 'support.dart';

void main() {
  late FakeProfileRepository repo;
  late ProfileCubit cubit;

  setUp(() {
    repo = FakeProfileRepository(sampleUser());
    cubit = ProfileCubit(repo);
  });

  tearDown(() => cubit.close());

  /// Starts following u1's profile and waits for it to load.
  Future<void> load() async {
    cubit.watch('u1');
    await settle();
  }

  group('watch', () {
    test('loads the signed-in user', () async {
      await load();

      expect(cubit.state.user, sampleUser());
    });

    test('watch(null) clears the user', () async {
      await load();

      cubit.watch(null);
      await settle();

      expect(cubit.state.user, isNull);
    });
  });

  group('save', () {
    test('updates the stored profile and says saved', () async {
      await load();
      final states = record(cubit);

      await cubit.save(
        firstName: 'New',
        lastName: 'Name',
        phone: '0791234567',
        network: Network.mtn,
      );
      await settle();

      final stored = repo.user!;
      expect(stored.firstName, 'New');
      expect(stored.lastName, 'Name');
      expect(stored.phone, '0791234567');
      expect(stored.uid, 'u1');
      expect(stored.email, 'aline@example.com');
      expect(stored.updatedAt.isBefore(day1), isFalse);
      expect(
        states.map((state) => state.message),
        contains(ProfileMessage.saved),
      );
      expect(cubit.state.user?.firstName, 'New');
      expect(cubit.state.saving, isFalse);
    });

    test('keeps a changed network', () async {
      await load();

      await cubit.save(
        firstName: 'Aline',
        lastName: 'Mukamana',
        phone: '0731234567',
        network: Network.airtel,
      );
      await settle();

      expect(repo.user!.network, Network.airtel);
      expect(repo.user!.phone, '0731234567');
    });

    test('a rejected write says failed and keeps the old profile', () async {
      await load();
      final states = record(cubit);
      repo.failNext = true;

      await cubit.save(
        firstName: 'New',
        lastName: 'Name',
        phone: '0791234567',
        network: Network.mtn,
      );
      await settle();

      expect(
        states.map((state) => state.message),
        contains(ProfileMessage.failed),
      );
      expect(repo.user, sampleUser());
      expect(cubit.state.user, sampleUser());
      expect(cubit.state.saving, isFalse);
    });

    test('does nothing when no profile is loaded', () async {
      final states = record(cubit);

      await cubit.save(
        firstName: 'New',
        lastName: 'Name',
        phone: '0791234567',
        network: Network.mtn,
      );
      await settle();

      expect(repo.user, sampleUser());
      expect(states, isEmpty);
    });
  });
}
