import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import 'app.dart';
import 'data/repositories/firebase_auth_repository.dart';
import 'data/repositories/firestore_feedback_repository.dart';
import 'data/repositories/firestore_profile_repository.dart';
import 'data/repositories/firestore_recipient_repository.dart';
import 'data/repositories/firestore_transaction_repository.dart';
import 'data/repositories/prefs_settings_repository.dart';
import 'data/services/android_ussd_launcher.dart';
import 'data/services/simulated_ussd_launcher.dart';
import 'domain/services/ussd_launcher.dart';
import 'firebase_options.dart';

/// Run with `--dart-define=SIMULATE_USSD=true` on an emulator without a SIM.
const _simulateUssd = bool.fromEnvironment('SIMULATE_USSD');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Saved records stay readable and writable without a connection.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  final UssdLauncher launcher = _simulateUssd
      ? SimulatedUssdLauncher()
      : AndroidUssdLauncher();
  runApp(
    DailoApp(
      dependencies: AppDependencies(
        auth: FirebaseAuthRepository(),
        profile: FirestoreProfileRepository(),
        recipients: FirestoreRecipientRepository(),
        transactions: FirestoreTransactionRepository(),
        feedback: FirestoreFeedbackRepository(),
        settings: PrefsSettingsRepository(),
        launcher: launcher,
      ),
    ),
  );
}
