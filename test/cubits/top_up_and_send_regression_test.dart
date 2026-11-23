import 'package:dailo/domain/entities/network.dart';
import 'package:dailo/domain/entities/transaction_record.dart';
import 'package:dailo/domain/services/ussd_launcher.dart';
import 'package:dailo/presentation/cubits/send_money_cubit.dart';
import 'package:dailo/presentation/cubits/top_up_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/in_memory_repositories.dart';
import '../fakes/samples.dart';

/// A dialer that throws, as a broken platform channel would.
class _ThrowingLauncher implements UssdLauncher {
  @override
  Future<UssdOutcome> run(String code) async => throw Exception('boom');
}

void main() {
  group('defect 1: airtime for another number is normalised', () {
    for (final typed in ['+250788123456', '0788 123 456']) {
      test('"$typed" is stored as 0788123456', () async {
        final transactions = InMemoryTransactionRepository();
        final cubit = TopUpCubit(
          transactions: transactions,
          launcher: FakeUssdLauncher(),
        )..bind('u1', network: Network.mtn);
        addTearDown(cubit.close);

        await cubit.buy(type: TxType.airtime, amount: 500, forPhone: typed);

        expect(transactions.items.single.counterpartyPhone, '0788123456');
      });
    }
  });

  group('defect 2: a typed number is saved with a name', () {
    test('the saved recipient is named by its phone number', () async {
      final transactions = InMemoryTransactionRepository();
      final recipients = InMemoryRecipientRepository();
      final cubit = SendMoneyCubit(
        transactions: transactions,
        recipients: recipients,
        launcher: FakeUssdLauncher(),
      );
      addTearDown(cubit.close);
      cubit.bind('u1', from: Network.mtn, feeWarning: true);
      cubit.start();

      expect(cubit.chooseTyped('0788111222'), isTrue);
      cubit.setAmount(1000);
      cubit.toReview();
      await cubit.confirm();
      await cubit.report(TxStatus.success);

      expect(recipients.items, hasLength(1));
      expect(recipients.items.single.name, '0788111222');
      expect(recipients.items.single.phone, '0788111222');
      expect(transactions.items.single.counterpartyName, '');
    });
  });

  group(
    'defect 6: a throwing repository or dialer does not strand the cubit',
    () {
      late InMemoryTransactionRepository transactions;
      late InMemoryRecipientRepository recipients;
      late FakeUssdLauncher launcher;
      late SendMoneyCubit send;

      final diane = sampleRecipients().firstWhere((r) => r.id == 'r1');

      SendMoneyCubit build(UssdLauncher dialer) {
        final cubit = SendMoneyCubit(
          transactions: transactions,
          recipients: recipients,
          launcher: dialer,
        );
        addTearDown(cubit.close);
        cubit.bind('u1', from: Network.mtn, feeWarning: true);
        cubit.start();
        cubit.chooseRecipient(diane);
        cubit.setAmount(10000);
        cubit.toReview();
        return cubit;
      }

      setUp(() {
        transactions = InMemoryTransactionRepository();
        recipients = InMemoryRecipientRepository(sampleRecipients());
        launcher = FakeUssdLauncher();
        send = build(launcher);
      });

      test('confirm with a failing repository stays on review', () async {
        transactions.failNext = true;

        await send.confirm();

        expect(send.state.busy, isFalse);
        expect(send.state.step, SendStep.review);
        expect(send.state.launchProblem, UssdOutcome.unsupported);
      });

      test('confirm with a throwing dialer fails the record', () async {
        final thrower = build(_ThrowingLauncher());

        await thrower.confirm();

        expect(thrower.state.busy, isFalse);
        expect(thrower.state.step, SendStep.review);
        expect(thrower.state.launchProblem, UssdOutcome.unsupported);
        expect(transactions.items.single.status, TxStatus.failed);
      });

      test(
        'report with a failing repository completes and is not busy',
        () async {
          await send.confirm();
          expect(send.state.step, SendStep.awaitingResult);
          transactions.failNext = true;

          await send.report(TxStatus.success);

          expect(send.state.busy, isFalse);
        },
      );

      test(
        'top-up buy with a failing repository reports a launch problem',
        () async {
          final topUp = TopUpCubit(
            transactions: transactions,
            launcher: launcher,
          )..bind('u1', network: Network.mtn);
          addTearDown(topUp.close);
          transactions.failNext = true;

          await topUp.buy(type: TxType.airtime, amount: 500);

          expect(topUp.state.busy, isFalse);
          expect(topUp.state.awaitingResult, isFalse);
          expect(topUp.state.launchProblem, UssdOutcome.unsupported);
        },
      );
    },
  );
}
