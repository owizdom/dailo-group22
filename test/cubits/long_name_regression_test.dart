import 'package:dailo/domain/entities/network.dart';
import 'package:dailo/domain/entities/transaction_record.dart';
import 'package:dailo/domain/logic/qr_payload.dart';
import 'package:dailo/presentation/cubits/send_money_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/in_memory_repositories.dart';

// Found by the verifier: a scanned QR code carries a full name, and two
// 30-character names joined by a space make 61 characters. The server
// refuses a recipient name over 60, so the saved name is cut to fit.
void main() {
  test('a scanned 61-character name is saved within the limit', () async {
    final recipients = InMemoryRecipientRepository();
    final cubit = SendMoneyCubit(
      transactions: InMemoryTransactionRepository(),
      recipients: recipients,
      launcher: FakeUssdLauncher(),
    );
    addTearDown(cubit.close);
    final longName = '${'A' * 30} ${'B' * 30}';
    expect(longName.length, 61);

    cubit.bind('u1', from: Network.mtn, feeWarning: true);
    cubit.start();
    cubit.chooseScanned(encodeQr(name: longName, phone: '0788111222'));
    cubit.setAmount(1000);
    cubit.toReview();
    await cubit.confirm();
    await cubit.report(TxStatus.success);

    final saved = recipients.items.single;
    expect(saved.name.length, 60);
    expect(saved.name, longName.substring(0, 60));
  });
}
