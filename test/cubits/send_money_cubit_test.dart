import 'package:dailo/domain/entities/network.dart';
import 'package:dailo/domain/entities/recipient.dart';
import 'package:dailo/domain/entities/transaction_record.dart';
import 'package:dailo/domain/logic/fee_table.dart';
import 'package:dailo/domain/logic/qr_payload.dart';
import 'package:dailo/domain/logic/ussd_codes.dart';
import 'package:dailo/domain/services/ussd_launcher.dart';
import 'package:dailo/presentation/cubits/send_money_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/in_memory_repositories.dart';
import '../fakes/samples.dart';
import 'support.dart';

/// A dialer that notes how many transaction records existed at the moment
/// it was asked to dial, and what the newest record's status was.
class _SpyLauncher implements UssdLauncher {
  _SpyLauncher(this.transactions);

  final InMemoryTransactionRepository transactions;
  final List<int> recordsWhenDialled = [];
  final List<TxStatus> statusWhenDialled = [];

  @override
  Future<UssdOutcome> run(String code) async {
    recordsWhenDialled.add(transactions.items.length);
    if (transactions.items.isNotEmpty) {
      statusWhenDialled.add(transactions.items.first.status);
    }
    return UssdOutcome.launched;
  }
}

void main() {
  late InMemoryTransactionRepository transactions;
  late InMemoryRecipientRepository recipients;
  late FakeUssdLauncher launcher;
  late SendMoneyCubit cubit;

  // Diane is saved, on MTN. Eric is saved, on Airtel.
  final diane = sampleRecipients().firstWhere((r) => r.id == 'r1');
  final eric = sampleRecipients().firstWhere((r) => r.id == 'r3');

  setUp(() {
    transactions = InMemoryTransactionRepository();
    recipients = InMemoryRecipientRepository(sampleRecipients());
    launcher = FakeUssdLauncher();
    cubit = SendMoneyCubit(
      transactions: transactions,
      recipients: recipients,
      launcher: launcher,
    );
    cubit.bind(
      'u1',
      from: Network.mtn,
      feeWarning: true,
      saved: sampleRecipients(),
    );
    cubit.start();
  });

  tearDown(() => cubit.close());

  /// Picks [to], enters [amount] and [comment], and opens the review step.
  void goToReview({Recipient? to, int amount = 10000, String comment = ''}) {
    cubit.chooseRecipient(to ?? diane);
    cubit.setAmount(amount);
    if (comment.isNotEmpty) cubit.setComment(comment);
    cubit.toReview();
  }

  /// The one record the payment saved.
  TransactionRecord savedRecord() => transactions.items.single;

  group('start and choosing a recipient', () {
    test('start begins at the recipient step with nothing chosen', () {
      expect(cubit.state.step, SendStep.recipient);
      expect(cubit.state.recipient, isNull);
      expect(cubit.state.amount, 0);
    });

    test('chooseRecipient moves to the amount step', () {
      cubit.chooseRecipient(diane);

      expect(cubit.state.step, SendStep.amount);
      expect(cubit.state.recipient, diane);
    });

    test('a typed number that is saved picks the saved recipient', () {
      final accepted = cubit.chooseTyped('0788452310');

      expect(accepted, isTrue);
      expect(cubit.state.recipient?.id, 'r1');
      expect(cubit.state.recipient?.name, 'Uwase Diane');
    });

    test('a typed number is cleaned before it is matched', () {
      final accepted = cubit.chooseTyped('250 788 452 310');

      expect(accepted, isTrue);
      expect(cubit.state.recipient?.id, 'r1');
    });

    test('a typed number that is not saved picks an unsaved recipient', () {
      final accepted = cubit.chooseTyped('0788111222');

      expect(accepted, isTrue);
      final picked = cubit.state.recipient!;
      expect(picked.id, '');
      expect(picked.name, '');
      expect(picked.phone, '0788111222');
      expect(picked.network, Network.mtn);
    });

    test('an invalid typed number is refused and changes nothing', () async {
      final before = cubit.state;
      final states = record(cubit);

      final accepted = cubit.chooseTyped('123');
      await settle();

      expect(accepted, isFalse);
      expect(cubit.state, before);
      expect(states, isEmpty);
    });

    test('a scanned DailO code picks the contact in it', () {
      final accepted = cubit.chooseScanned(
        encodeQr(name: 'Shop Owner', phone: '0788111222'),
      );

      expect(accepted, isTrue);
      final picked = cubit.state.recipient!;
      expect(picked.id, '');
      expect(picked.name, 'Shop Owner');
      expect(picked.phone, '0788111222');
      expect(picked.network, Network.mtn);
    });

    test('a scanned code that is not DailO is refused', () async {
      final before = cubit.state;

      final accepted = cubit.chooseScanned('junk');
      await settle();

      expect(accepted, isFalse);
      expect(cubit.state, before);
    });
  });

  group('amount, fee and hint', () {
    test('10,500 to an MTN recipient costs 250 and hints at 10,000', () {
      cubit.chooseRecipient(diane);

      cubit.setAmount(10500);

      expect(cubit.state.amount, 10500);
      expect(cubit.state.fee, 250);
      expect(
        cubit.state.fee,
        feeFor(10500, from: Network.mtn, to: Network.mtn),
      );
      expect(cubit.state.total, 10750);
      expect(cubit.state.feeKnown, isTrue);
      expect(cubit.state.hint?.cheaperAmount, 10000);
      expect(cubit.state.hint?.saving, 150);
    });

    test('10,000 costs 100 and has no hint', () {
      cubit.chooseRecipient(diane);

      cubit.setAmount(10000);

      expect(cubit.state.fee, 100);
      expect(cubit.state.total, 10100);
      expect(cubit.state.hint, isNull);
    });

    test('an Airtel recipient is off-net, so 1,000 costs 100', () {
      cubit.chooseRecipient(eric);

      cubit.setAmount(1000);

      expect(cubit.state.fee, 100);
      expect(
        cubit.state.fee,
        feeFor(1000, from: Network.mtn, to: Network.airtel),
      );
    });

    test('with the fee warning off there is no hint', () {
      cubit.bind(
        'u1',
        from: Network.mtn,
        feeWarning: false,
        saved: sampleRecipients(),
      );
      cubit.start();
      cubit.chooseRecipient(diane);

      cubit.setAmount(10500);

      expect(cubit.state.hint, isNull);
      expect(cubit.state.fee, 250);
    });

    test('paying from Airtel leaves the fee unknown and zero', () {
      cubit.bind(
        'u1',
        from: Network.airtel,
        feeWarning: true,
        saved: sampleRecipients(),
      );
      cubit.start();
      cubit.chooseRecipient(diane);

      for (final amount in [1000, 10500, 200000]) {
        cubit.setAmount(amount);

        expect(cubit.state.feeKnown, isFalse, reason: 'amount $amount');
        expect(cubit.state.fee, 0, reason: 'amount $amount');
        expect(cubit.state.hint, isNull, reason: 'amount $amount');
      }
    });

    test('applyHint takes the cheaper amount and its lower fee', () {
      cubit.chooseRecipient(diane);
      cubit.setAmount(10500);

      cubit.applyHint();

      expect(cubit.state.amount, 10000);
      expect(cubit.state.fee, 100);
      expect(cubit.state.hint, isNull);
    });

    test('setComment keeps the comment', () {
      cubit.chooseRecipient(diane);

      cubit.setComment('Tomatoes, Tuesday');

      expect(cubit.state.comment, 'Tomatoes, Tuesday');
    });
  });

  group('review', () {
    test('toReview moves to review when a recipient and amount are set', () {
      cubit.chooseRecipient(diane);
      cubit.setAmount(10000);

      cubit.toReview();

      expect(cubit.state.canReview, isTrue);
      expect(cubit.state.step, SendStep.review);
    });

    test('toReview does not move with an amount of zero', () {
      cubit.chooseRecipient(diane);

      cubit.toReview();

      expect(cubit.state.step, SendStep.amount);
    });

    test('toReview does not move with no recipient', () {
      cubit.setAmount(5000);

      cubit.toReview();

      expect(cubit.state.step, SendStep.recipient);
    });

    test('backToAmount keeps the recipient, amount and comment', () {
      goToReview(amount: 10500, comment: 'Tomatoes, Tuesday');

      cubit.backToAmount();

      expect(cubit.state.step, SendStep.amount);
      expect(cubit.state.recipient, diane);
      expect(cubit.state.amount, 10500);
      expect(cubit.state.comment, 'Tomatoes, Tuesday');
    });
  });

  group('confirm', () {
    test('saves one pending record with the payment details', () async {
      goToReview(amount: 10000, comment: 'Tomatoes, Tuesday');

      await cubit.confirm();

      final saved = savedRecord();
      expect(saved.type, TxType.send);
      expect(saved.status, TxStatus.pending);
      expect(saved.amount, 10000);
      expect(saved.fee, 100);
      expect(saved.comment, 'Tomatoes, Tuesday');
      expect(saved.counterpartyName, 'Uwase Diane');
      expect(saved.counterpartyPhone, '0788452310');
      expect(saved.recipientId, 'r1');
      expect(saved.network, Network.mtn);
    });

    test('dials the MTN to MTN code and waits for the result', () async {
      goToReview(amount: 10000);

      await cubit.confirm();

      expect(launcher.codes.single, '*182*1*1*0788452310*10000#');
      expect(
        launcher.codes.single,
        sendMoneyCode('0788452310', 10000, from: Network.mtn, to: Network.mtn),
      );
      expect(cubit.state.step, SendStep.awaitingResult);
      expect(cubit.state.recordId, savedRecord().id);
      expect(cubit.state.busy, isFalse);
    });

    test('dials the off-net code for an Airtel recipient', () async {
      goToReview(to: eric, amount: 1000);

      await cubit.confirm();

      expect(launcher.codes.single, '*182*1*2*0731112223*1000#');
      expect(
        launcher.codes.single,
        sendMoneyCode(
          '0731112223',
          1000,
          from: Network.mtn,
          to: Network.airtel,
        ),
      );
    });

    test('the code holds digits, stars and a hash, never letters', () async {
      goToReview(amount: 10000);

      await cubit.confirm();

      expect(launcher.codes.single, isNot(contains(RegExp(r'[A-Za-z]'))));
    });

    test('an unsaved recipient is recorded by number only', () async {
      cubit.chooseTyped('0788111222');
      cubit.setAmount(1000);
      cubit.toReview();

      await cubit.confirm();

      expect(savedRecord().recipientId, isNull);
      expect(savedRecord().counterpartyPhone, '0788111222');
    });

    test('the record is written before the phone is asked to dial', () async {
      final spy = _SpyLauncher(transactions);
      final spied = SendMoneyCubit(
        transactions: transactions,
        recipients: recipients,
        launcher: spy,
      );
      addTearDown(spied.close);
      spied.bind(
        'u1',
        from: Network.mtn,
        feeWarning: true,
        saved: sampleRecipients(),
      );
      spied.start();
      spied.chooseRecipient(diane);
      spied.setAmount(10000);
      spied.toReview();

      await spied.confirm();

      expect(spy.recordsWhenDialled, [1]);
      expect(spy.statusWhenDialled, [TxStatus.pending]);
    });

    test('with no signed-in user nothing is written', () async {
      cubit.bind(null, from: Network.mtn, feeWarning: true);
      cubit.start();
      goToReview();

      await cubit.confirm();

      expect(transactions.items, isEmpty);
    });
  });

  group('when the phone cannot dial', () {
    const problems = [
      UssdOutcome.permissionDenied,
      UssdOutcome.noSim,
      UssdOutcome.unsupported,
    ];

    for (final problem in problems) {
      test(
        '$problem keeps the review step and marks the record failed',
        () async {
          launcher.outcome = problem;
          goToReview(amount: 10000, comment: 'Tomatoes, Tuesday');

          await cubit.confirm();

          expect(cubit.state.step, SendStep.review);
          expect(cubit.state.launchProblem, problem);
          expect(savedRecord().status, TxStatus.failed);
          expect(cubit.state.recipient, diane);
          expect(cubit.state.amount, 10000);
          expect(cubit.state.comment, 'Tomatoes, Tuesday');
          expect(cubit.state.busy, isFalse);
        },
      );
    }

    test('a second confirm that dials clears the problem', () async {
      launcher.outcome = UssdOutcome.permissionDenied;
      goToReview();
      await cubit.confirm();

      launcher.outcome = UssdOutcome.launched;
      await cubit.confirm();

      expect(cubit.state.launchProblem, isNull);
      expect(cubit.state.step, SendStep.awaitingResult);
      final id = cubit.state.recordId;
      expect(id, isNotNull);
      expect(transactions.items.map((r) => r.id), contains(id));
    });
  });

  group('report', () {
    /// Takes a payment to Diane all the way to the awaiting-result step.
    Future<void> payDiane() async {
      goToReview(amount: 10000);
      await cubit.confirm();
    }

    test(
      'success records it, finishes, and updates when Diane was paid',
      () async {
        await payDiane();

        await cubit.report(TxStatus.success);
        await settle();

        expect(savedRecord().status, TxStatus.success);
        expect(cubit.state.step, SendStep.done);
        expect(cubit.state.result, TxStatus.success);
        final paid = recipients.items.firstWhere((r) => r.id == 'r1');
        expect(paid.lastPaidAt!.isAfter(day3), isTrue);
      },
    );

    test('success saves an unsaved recipient', () async {
      cubit.chooseTyped('0788111222');
      cubit.setAmount(1000);
      cubit.toReview();
      await cubit.confirm();

      await cubit.report(TxStatus.success);
      await settle();

      expect(recipients.items.length, 4);
      final added = recipients.items.singleWhere(
        (r) => r.phone == '0788111222',
      );
      expect(added.network, Network.mtn);
    });

    test('failed records it and saves no recipient', () async {
      cubit.chooseTyped('0788111222');
      cubit.setAmount(1000);
      cubit.toReview();
      await cubit.confirm();

      await cubit.report(TxStatus.failed);
      await settle();

      expect(savedRecord().status, TxStatus.failed);
      expect(cubit.state.step, SendStep.done);
      expect(cubit.state.result, TxStatus.failed);
      expect(recipients.items.length, 3);
    });

    test('failed leaves the date Diane was last paid alone', () async {
      await payDiane();

      await cubit.report(TxStatus.failed);
      await settle();

      final unchanged = recipients.items.firstWhere((r) => r.id == 'r1');
      expect(unchanged.lastPaidAt, day3);
    });

    test('pending leaves the record pending and finishes', () async {
      await payDiane();

      await cubit.report(TxStatus.pending);
      await settle();

      expect(savedRecord().status, TxStatus.pending);
      expect(cubit.state.step, SendStep.done);
      expect(cubit.state.result, TxStatus.pending);
    });
  });

  group('payAgain', () {
    test('starts a new payment to the same recipient', () async {
      goToReview(amount: 10000, comment: 'Tomatoes, Tuesday');
      await cubit.confirm();
      await cubit.report(TxStatus.success);

      cubit.payAgain();

      expect(cubit.state.step, SendStep.amount);
      expect(cubit.state.recipient?.id, 'r1');
      expect(cubit.state.amount, 0);
      expect(cubit.state.recordId, isNull);
      expect(cubit.state.result, isNull);
    });
  });

  group('the whole flow', () {
    test('moves through the steps in order', () async {
      final states = record(cubit);

      cubit.chooseRecipient(diane);
      cubit.setAmount(10000);
      cubit.toReview();
      await cubit.confirm();
      await cubit.report(TxStatus.success);
      await settle();

      // Collapse repeats, so only the order of the steps is compared.
      final steps = <SendStep>[];
      for (final state in states) {
        if (steps.isEmpty || steps.last != state.step) steps.add(state.step);
      }
      expect(steps, [
        SendStep.amount,
        SendStep.review,
        SendStep.awaitingResult,
        SendStep.done,
      ]);
    });
  });
}
