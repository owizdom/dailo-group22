import 'package:dailo/domain/entities/app_user.dart';
import 'package:dailo/domain/entities/auth_session.dart';
import 'package:dailo/domain/entities/network.dart';
import 'package:dailo/domain/entities/recipient.dart';
import 'package:dailo/domain/entities/transaction_record.dart';

/// Fixed dates so tests never depend on the real clock.
final day1 = DateTime(2026, 11, 10, 9, 0);
final day2 = DateTime(2026, 11, 11, 9, 0);
final day3 = DateTime(2026, 11, 12, 9, 0);

const verifiedSession = AuthSession(
  uid: 'u1',
  email: 'aline@example.com',
  emailVerified: true,
);

const unverifiedSession = AuthSession(
  uid: 'u1',
  email: 'aline@example.com',
  emailVerified: false,
);

AppUser sampleUser() => AppUser(
  uid: 'u1',
  firstName: 'Aline',
  lastName: 'Mukamana',
  email: 'aline@example.com',
  phone: '0788000001',
  network: Network.mtn,
  createdAt: day1,
  updatedAt: day1,
);

/// Three saved recipients: Diane is a favourite and was paid most recently,
/// Jean was paid earlier, Eric (Airtel) was never paid.
List<Recipient> sampleRecipients() => [
  Recipient(
    id: 'r1',
    name: 'Uwase Diane',
    phone: '0788452310',
    network: Network.mtn,
    isFavorite: true,
    lastPaidAt: day3,
    createdAt: day1,
    updatedAt: day3,
  ),
  Recipient(
    id: 'r2',
    name: 'Jean Bosco',
    phone: '0791234567',
    network: Network.mtn,
    lastPaidAt: day2,
    createdAt: day1,
    updatedAt: day2,
  ),
  Recipient(
    id: 'r3',
    name: 'Eric Airtel',
    phone: '0731112223',
    network: Network.airtel,
    createdAt: day1,
    updatedAt: day1,
  ),
];

/// A recipient whose name is 30 characters, for overflow tests.
Recipient longNameRecipient() => Recipient(
  id: 'r9',
  name: 'Mukandayisenga Marie Claudine',
  phone: '0788999888',
  network: Network.mtn,
  createdAt: day1,
  updatedAt: day1,
);

/// Three records, newest first: a confirmed send, a pending airtime
/// purchase, a failed data purchase.
List<TransactionRecord> sampleTransactions() => [
  TransactionRecord(
    id: 't3',
    type: TxType.send,
    recipientId: 'r1',
    counterpartyName: 'Uwase Diane',
    counterpartyPhone: '0788452310',
    network: Network.mtn,
    amount: 10000,
    fee: 100,
    comment: 'Tomatoes, Tuesday',
    status: TxStatus.success,
    createdAt: day3,
    updatedAt: day3,
  ),
  TransactionRecord(
    id: 't2',
    type: TxType.airtime,
    counterpartyName: '',
    counterpartyPhone: '0788000001',
    network: Network.mtn,
    amount: 500,
    fee: 0,
    status: TxStatus.pending,
    createdAt: day2,
    updatedAt: day2,
  ),
  TransactionRecord(
    id: 't1',
    type: TxType.data,
    counterpartyName: '',
    counterpartyPhone: '0788000001',
    network: Network.mtn,
    amount: 1000,
    fee: 0,
    status: TxStatus.failed,
    createdAt: day1,
    updatedAt: day1,
  ),
];