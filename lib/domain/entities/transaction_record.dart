import 'package:equatable/equatable.dart';

import 'dates.dart';
import 'network.dart';

/// What kind of USSD action a record describes.
enum TxType {
  send('send'),
  airtime('airtime'),
  data('data');

  const TxType(this.wire);
  final String wire;

  static TxType fromWire(Object? value) {
    return TxType.values.firstWhere(
      (type) => type.wire == value,
      orElse: () => TxType.send,
    );
  }
}

/// What the user told DailO happened. DailO cannot read the operator's
/// answer, so a record stays [pending] until the user confirms it.
enum TxStatus {
  pending('pending'),
  success('success'),
  failed('failed');

  const TxStatus(this.wire);
  final String wire;

  static TxStatus fromWire(Object? value) {
    return TxStatus.values.firstWhere(
      (status) => status.wire == value,
      orElse: () => TxStatus.pending,
    );
  }
}

/// One payment or purchase. Stored at `users/{uid}/transactions/{id}`.
///
/// Named TransactionRecord because Firestore already has a class called
/// Transaction.
class TransactionRecord extends Equatable {
  const TransactionRecord({
    required this.id,
    required this.type,
    this.recipientId,
    required this.counterpartyName,
    required this.counterpartyPhone,
    required this.network,
    required this.amount,
    required this.fee,
    this.comment = '',
    this.status = TxStatus.pending,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Empty until Firestore assigns one.
  final String id;
  final TxType type;

  /// The saved recipient this was sent to, when there is one.
  final String? recipientId;

  /// Name and number as they were at payment time. A receipt must not change
  /// when the recipient is renamed or deleted later.
  final String counterpartyName;
  final String counterpartyPhone;
  final Network network;

  /// Whole Rwandan francs.
  final int amount;
  final int fee;
  final String comment;
  final TxStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// The exact field names stored in Firestore, in ERD order.
  /// The total is not stored: it is always amount plus fee.
  static const fields = [
    'type',
    'recipientId',
    'counterpartyName',
    'counterpartyPhone',
    'network',
    'amount',
    'fee',
    'comment',
    'status',
    'createdAt',
    'updatedAt',
  ];

  int get total => amount + fee;

  Map<String, Object?> toMap() {
    return {
      'type': type.wire,
      'recipientId': recipientId,
      'counterpartyName': counterpartyName,
      'counterpartyPhone': counterpartyPhone,
      'network': network.wire,
      'amount': amount,
      'fee': fee,
      'comment': comment,
      'status': status.wire,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory TransactionRecord.fromMap(String id, Map<String, Object?> map) {
    // A document with no date yet is read as created now.
    final now = DateTime.now();
    return TransactionRecord(
      id: id,
      type: TxType.fromWire(map['type']),
      recipientId: map['recipientId'] as String?,
      counterpartyName: map['counterpartyName'] as String? ?? '',
      counterpartyPhone: map['counterpartyPhone'] as String? ?? '',
      network: Network.fromWire(map['network']),
      amount: map['amount'] as int? ?? 0,
      fee: map['fee'] as int? ?? 0,
      comment: map['comment'] as String? ?? '',
      status: TxStatus.fromWire(map['status']),
      createdAt: readDate(map['createdAt'], fallback: now),
      updatedAt: readDate(map['updatedAt'], fallback: now),
    );
  }

  TransactionRecord copyWith({
    String? id,
    TxStatus? status,
    DateTime? updatedAt,
  }) {
    return TransactionRecord(
      id: id ?? this.id,
      type: type,
      recipientId: recipientId,
      counterpartyName: counterpartyName,
      counterpartyPhone: counterpartyPhone,
      network: network,
      amount: amount,
      fee: fee,
      comment: comment,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    recipientId,
    counterpartyName,
    counterpartyPhone,
    network,
    amount,
    fee,
    comment,
    status,
    createdAt,
    updatedAt,
  ];
}