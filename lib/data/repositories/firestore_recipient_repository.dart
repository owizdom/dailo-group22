import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/recipient.dart';
import '../../domain/repositories/recipient_repository.dart';
import 'write_failures.dart';

/// [RecipientRepository] backed by `users/{uid}/recipients`.
///
/// Writes are never awaited. Firestore applies them to its local cache at
/// once, so the snapshot stream updates and the app works with no connection.
/// Awaiting would block until the server answered, which may be never.
/// A later server refusal is reported through `writeFailures`.
class FirestoreRecipientRepository
    with WriteFailures
    implements RecipientRepository {
  FirestoreRecipientRepository({FirebaseFirestore? firestore})
    : _injected = firestore;

  final FirebaseFirestore? _injected;

  // Looked up on first use so the object can be built before Firebase starts.
  late final FirebaseFirestore _db = _injected ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      _db.collection('users').doc(uid).collection('recipients');

  @override
  Stream<List<Recipient>> watchAll(String uid) {
    // Needs the composite index in firestore.indexes.json: recipients,
    // isFavorite DESCENDING then name ASCENDING.
    final favouritesFirst = _collection(uid)
        .orderBy('isFavorite', descending: true)
        .orderBy('name');
    return favouritesFirst.snapshots().map((snapshot) {
      return [
        for (final doc in snapshot.docs) Recipient.fromMap(doc.id, doc.data()),
      ];
    });
  }

  @override
  Future<String> add(String uid, Recipient recipient) async {
    final ref = _collection(uid).doc();
    track(ref.set(recipient.toMap()));
    return ref.id;
  }

  @override
  Future<void> update(String uid, Recipient recipient) async {
    track(_collection(uid).doc(recipient.id).set(recipient.toMap()));
  }

  @override
  Future<void> delete(String uid, String recipientId) async {
    track(_collection(uid).doc(recipientId).delete());
  }
}
