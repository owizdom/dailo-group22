import 'package:dailo/domain/entities/network.dart';
import 'package:dailo/domain/entities/transaction_record.dart';
import 'package:dailo/domain/logic/ussd_codes.dart';
import 'package:dailo/domain/services/ussd_launcher.dart';
import 'package:dailo/presentation/cubits/top_up_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/in_memory_repositories.dart';

void main() {
  late InMemoryTransactionRepository transactions;
  late FakeUssdLauncher launcher;
  late TopUpCubit cubit;

  setUp(() {
    transactions = InMemoryTransactionRepository();
    launcher = FakeUssdLauncher();
    cubit = TopUpCubit(transactions: transactions, launcher: launcher);
    cubit.bind('u1', network: Network.mtn);
  });

  tearDown(() => cubit.close());

  /// The one record the purchase saved.
  TransactionRecord savedRecord() => transactions.items.single;

  group('airtime', () {
    test('saves one pending record for the user\'s own line', () async {
      await cubit.buy(type: TxType.airtime, amount: 500);

      final saved = savedRecord();
      expect(saved.type, TxType.airtime);
      expect(saved.status, TxStatus.pending);
      expect(saved.amount, 500);
      expect(saved.fee, 0);
      expect(saved.counterpartyPhone, '');
      expect(saved.network, Network.mtn);
    });

    test('dials the airtime code once and waits for the result', () async {
      await cubit.buy(type: TxType.airtime, amount: 500);

      expect(launcher.codes.length, 1);
      expect(launcher.codes.single, airtimeCode(500, network: Network.mtn));
      expect(cubit.state.awaitingResult, isTrue);
      expect(cubit.state.busy, isFalse);
      expect(cubit.state.recordId, savedRecord().id);
    });

    test('airtime for someone else keeps their number', () async {
      await cubit.buy(
        type: TxType.airtime,
        amount: 500,
        forPhone: '0788452310',
      );

      expect(savedRecord().counterpartyPhone, '0788452310');
      expect(
        launcher.codes.single,
        airtimeCode(500, forPhone: '0788452310', network: Network.mtn),
      );
    });
  });

  group('data', () {
    test('saves a data record and opens the data menu', () async {
      await cubit.buy(type: TxType.data, amount: 1000);

      expect(savedRecord().type, TxType.data);
      expect(savedRecord().amount, 1000);
      expect(launcher.codes.single, dataMenuCode(Network.mtn));
      expect(cubit.state.awaitingResult, isTrue);
    });
  });

  group('buy', () {
    test('refuses a send, which has its own flow', () async {
      await expectLater(
        () => cubit.buy(type: TxType.send, amount: 500),
        throwsArgumentError,
      );

      expect(transactions.items, isEmpty);
      expect(launcher.codes, isEmpty);
    });
  });

  group('when the phone cannot dial', () {
    test('no SIM marks the record failed and stops waiting', () async {
      launcher.outcome = UssdOutcome.noSim;

      await cubit.buy(type: TxType.airtime, amount: 500);

      expect(cubit.state.launchProblem, UssdOutcome.noSim);
      expect(cubit.state.awaitingResult, isFalse);
      expect(savedRecord().status, TxStatus.failed);
    });
  });

  group('report and reset', () {
    test('report(success) updates the record and ends the wait', () async {
      await cubit.buy(type: TxType.airtime, amount: 500);

      await cubit.report(TxStatus.success);

      expect(savedRecord().status, TxStatus.success);
      expect(cubit.state.result, TxStatus.success);
      expect(cubit.state.awaitingResult, isFalse);
    });

    test('reset returns to the initial state', () async {
      await cubit.buy(type: TxType.airtime, amount: 500);
      await cubit.report(TxStatus.success);

      cubit.reset();

      expect(cubit.state, const TopUpState());
    });
  });
}
