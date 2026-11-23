import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/transaction_record.dart';
import '../../domain/repositories/transaction_repository.dart';
import 'write_failures.dart';

/// [TransactionRepository] backed by `users/{uid}/transactions`.
///
/// Writes are never awaited. A payment record must save with no connection:
/// Firestore applies the write to its local cache at once and uploads it
/// later. Awaiting would block until the server answered, which may be never.
/// A later server refusal is reported through `writeFailures`.
class FirestoreTransactionRepository
    with WriteFailures
    implements TransactionRepository {
  FirestoreTransactionRepository({FirebaseFirestore? firestore})
    : _injected = firestore;

  final FirebaseFirestore? _injected;

  // Looked up on first use so the object can be built before Firebase starts.
  late final FirebaseFirestore _db = _injected ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      _db.collection('users').doc(uid).collection('transactions');

  @override
  Stream<List<TransactionRecord>> watchAll(String uid) {
    final newestFirst = _collection(uid).orderBy('createdAt', descending: true);
    return newestFirst.snapshots().map((snapshot) {
      return [
        for (final doc in snapshot.docs)
          TransactionRecord.fromMap(doc.id, doc.data()),
      ];
    });
  }

  @override
  Future<String> add(String uid, TransactionRecord record) async {
    final ref = _collection(uid).doc();
    track(ref.set(record.toMap()));
    return ref.id;
  }

  @override
  Future<void> setStatus(String uid, String recordId, TxStatus status) async {
    track(
      _collection(uid)
          .doc(recordId)
          .update({'status': status.wire, 'updatedAt': DateTime.now()}),
    );
  }

  @override
  Future<void> delete(String uid, String recordId) async {
    track(_collection(uid).doc(recordId).delete());
  }
}
