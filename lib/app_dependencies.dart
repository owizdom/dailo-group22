import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/feedback_repository.dart';
import 'domain/repositories/profile_repository.dart';
import 'domain/repositories/recipient_repository.dart';
import 'domain/repositories/settings_repository.dart';
import 'domain/repositories/transaction_repository.dart';
import 'domain/services/ussd_launcher.dart';

/// Everything the app needs from outside: the repositories and the dialer.
///
/// `main.dart` passes the Firebase versions. Tests pass in-memory fakes,
/// so the whole app can run in a test without Firebase.
class AppDependencies {
  const AppDependencies({
    required this.auth,
    required this.profile,
    required this.recipients,
    required this.transactions,
    required this.feedback,
    required this.settings,
    required this.launcher,
  });

  final AuthRepository auth;
  final ProfileRepository profile;
  final RecipientRepository recipients;
  final TransactionRepository transactions;
  final FeedbackRepository feedback;
  final SettingsRepository settings;
  final UssdLauncher launcher;
}
