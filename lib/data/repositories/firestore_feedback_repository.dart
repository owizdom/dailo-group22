import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/feedback_note.dart';
import '../../domain/repositories/feedback_repository.dart';
import 'write_failures.dart';

/// [FeedbackRepository] backed by `users/{uid}/feedback`.
class FirestoreFeedbackRepository
    with WriteFailures
    implements FeedbackRepository {
  FirestoreFeedbackRepository({FirebaseFirestore? firestore})
    : _injected = firestore;

  final FirebaseFirestore? _injected;

  // Looked up on first use so the object can be built before Firebase starts.
  late final FirebaseFirestore _db = _injected ?? FirebaseFirestore.instance;

  @override
  Future<void> send(String uid, FeedbackNote note) async {
    // Not awaited, so feedback typed offline is kept and sent later.
    // A refusal by the server is reported through writeFailures.
    track(
      _db.collection('users').doc(uid).collection('feedback').add(note.toMap()),
    );
  }
}