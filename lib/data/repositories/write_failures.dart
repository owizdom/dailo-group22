import 'dart:async';

/// Shared by the Firestore repositories that fire writes without awaiting.
///
/// The local cache shows a change at once and the server answers later. If the
/// server refuses it (for example a security rule), Firestore rolls the change
/// back, so the failure must still reach the user. [track] forwards a refusal
/// to [writeFailures] and never lets it become an unhandled error.
mixin WriteFailures {
  final StreamController<void> _failures = StreamController<void>.broadcast();

  Stream<void> get writeFailures => _failures.stream;

  /// Call on the future of every un-awaited write.
  void track(Future<void> write) {
    write.catchError((Object _) {
      if (!_failures.isClosed) _failures.add(null);
    });
  }
}