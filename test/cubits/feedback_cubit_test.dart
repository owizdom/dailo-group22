import 'package:dailo/presentation/cubits/feedback_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/in_memory_repositories.dart';
import 'support.dart';

void main() {
  late FakeFeedbackRepository repo;
  late FeedbackCubit cubit;

  setUp(() {
    repo = FakeFeedbackRepository();
    cubit = FeedbackCubit(repo);
  });

  tearDown(() => cubit.close());

  Iterable<FeedbackMessage> messagesIn(List<FeedbackState> states) =>
      states.map((state) => state.message).whereType<FeedbackMessage>();

  group('send', () {
    test('stores the trimmed message and the rating, and says sent', () async {
      cubit.bind('u1');
      final states = record(cubit);

      await cubit.send(message: '  Great app, thanks  ', rating: 4);
      await settle();

      expect(repo.sent.length, 1);
      expect(repo.sent.single.message, 'Great app, thanks');
      expect(repo.sent.single.rating, 4);
      expect(messagesIn(states), [FeedbackMessage.sent]);
      expect(cubit.state.busy, isFalse);
    });

    test('a rejected write says failed and stores nothing', () async {
      cubit.bind('u1');
      final states = record(cubit);
      repo.failNext = true;

      await cubit.send(message: 'Great app, thanks', rating: 4);
      await settle();

      expect(repo.sent, isEmpty);
      expect(messagesIn(states), [FeedbackMessage.failed]);
      expect(cubit.state.busy, isFalse);
    });

    test('before bind it stores nothing and says failed', () async {
      final states = record(cubit);

      await cubit.send(message: 'Great app, thanks', rating: 4);
      await settle();

      expect(repo.sent, isEmpty);
      expect(messagesIn(states), [FeedbackMessage.failed]);
    });

    test('after bind(null) it stores nothing and says failed', () async {
      cubit.bind('u1');
      cubit.bind(null);
      final states = record(cubit);

      await cubit.send(message: 'Great app, thanks', rating: 4);
      await settle();

      expect(repo.sent, isEmpty);
      expect(messagesIn(states), [FeedbackMessage.failed]);
    });
  });
}