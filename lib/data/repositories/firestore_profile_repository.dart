import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/profile_repository.dart';
import 'write_failures.dart';

/// [ProfileRepository] backed by the `users` collection.
class FirestoreProfileRepository
    with WriteFailures
    implements ProfileRepository {
  FirestoreProfileRepository({FirebaseFirestore? firestore})
    : _injected = firestore;

  final FirebaseFirestore? _injected;

  // Looked up on first use so the object can be built before Firebase starts.
  late final FirebaseFirestore _db = _injected ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('users').doc(uid);

  @override
  Stream<AppUser?> watch(String uid) {
    return _doc(uid).snapshots().map((doc) {
      final data = doc.data();
      return data == null ? null : AppUser.fromMap(doc.id, data);
    });
  }

  @override
  Future<void> update(AppUser user) async {
    // Not awaited: the local cache applies the write at once and the server
    // gets it when the phone is online again. Awaiting would hang offline.
    // A later server refusal is reported through writeFailures.
    track(_doc(user.uid).set(user.toMap()));
  }
}
