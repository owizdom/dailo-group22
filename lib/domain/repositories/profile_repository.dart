import '../entities/app_user.dart';

/// Reads and updates the signed-in user's profile at `users/{uid}`.
abstract class ProfileRepository {
  Stream<AppUser?> watch(String uid);

  Future<void> update(AppUser user);

  /// Emits each time the server rejects a write that was already shown on
  /// screen from the local cache (for example a security rule refused it).
  /// Firestore then rolls the change back, so the app must tell the user.
  Stream<void> get writeFailures;
}
