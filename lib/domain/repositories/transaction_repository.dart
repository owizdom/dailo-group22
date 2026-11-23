import '../entities/transaction_record.dart';

/// Create, read, update and delete for `users/{uid}/transactions`.
abstract class TransactionRepository {
  /// Emits the list newest first, now and after every change.
  Stream<List<TransactionRecord>> watchAll(String uid);

  /// Returns the new document id straight away. The write is accepted by
  /// the local cache first, so this works with no connection.
  Future<String> add(String uid, TransactionRecord record);

  Future<void> setStatus(String uid, String recordId, TxStatus status);

  Future<void> delete(String uid, String recordId);

  /// Emits each time the server rejects a write that was already shown on
  /// screen from the local cache (for example a security rule refused it).
  /// Firestore then rolls the change back, so the app must tell the user.
  Stream<void> get writeFailures;
}
