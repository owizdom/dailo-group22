import '../entities/recipient.dart';

/// Create, read, update and delete for `users/{uid}/recipients`.
abstract class RecipientRepository {
  /// Emits the full list now and after every change, including changes
  /// made while offline.
  Stream<List<Recipient>> watchAll(String uid);

  /// Returns the new document id.
  Future<String> add(String uid, Recipient recipient);

  Future<void> update(String uid, Recipient recipient);

  Future<void> delete(String uid, String recipientId);

  /// Emits each time the server rejects a write that was already shown on
  /// screen from the local cache (for example a security rule refused it).
  /// Firestore then rolls the change back, so the app must tell the user.
  Stream<void> get writeFailures;
}
