import '../entities/feedback_note.dart';

/// Saves feedback to `users/{uid}/feedback`.
abstract class FeedbackRepository {
  Future<void> send(String uid, FeedbackNote note);

  /// Emits each time the server rejects a write that was already shown on
  /// screen from the local cache (for example a security rule refused it).
  /// Firestore then rolls the change back, so the app must tell the user.
  Stream<void> get writeFailures;
}
