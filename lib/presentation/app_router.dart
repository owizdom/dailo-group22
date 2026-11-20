import 'package:flutter/material.dart';

import '../core/l10n/app_strings.dart';
import '../core/routes.dart';
import '../domain/entities/recipient.dart';
import 'cubits/auth_cubit.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_up_details_screen.dart';
import 'screens/auth/sign_up_name_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'screens/history/buy_airtime_screen.dart';
import 'screens/history/buy_data_screen.dart';
import 'screens/history/transaction_detail_screen.dart';
import 'screens/history/transaction_history_screen.dart';
import 'screens/home/edit_profile_screen.dart';
import 'screens/home/feedback_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/settings_screen.dart';
import 'screens/home/splash_screen.dart';
import 'screens/recipients/edit_recipient_screen.dart';
import 'screens/recipients/generate_qr_screen.dart';
import 'screens/recipients/recipients_screen.dart';
import 'screens/send/amount_screen.dart';
import 'screens/send/payment_result_screen.dart';
import 'screens/send/review_payment_screen.dart';
import 'screens/send/scan_qr_screen.dart';
import 'screens/send/send_money_screen.dart';

/// The screen that sits at the bottom of the navigator for each sign-in state.
Widget firstScreenFor(AuthStatus status) {
  return switch (status) {
    AuthStatus.unknown => const SplashScreen(),
    AuthStatus.signedOut => const SignInScreen(),
    AuthStatus.needsVerification => const VerifyEmailScreen(),
    AuthStatus.signedIn => const HomeScreen(),
  };
}

/// Turns a route name into its screen, handing over the route arguments.
Route<void> onGenerateRoute(RouteSettings settings) {
  return MaterialPageRoute<void>(
    settings: settings,
    builder: (_) => _screenFor(settings),
  );
}

Widget _screenFor(RouteSettings settings) {
  final arguments = settings.arguments;
  return switch (settings.name) {
    Routes.signIn => const SignInScreen(),
    Routes.signUpName => const SignUpNameScreen(),
    Routes.signUpDetails => () {
      final name = arguments as ({String firstName, String lastName});
      return SignUpDetailsScreen(
        firstName: name.firstName,
        lastName: name.lastName,
      );
    }(),
    Routes.verifyEmail => const VerifyEmailScreen(),
    Routes.forgotPassword => const ForgotPasswordScreen(),
    Routes.home => const HomeScreen(),
    Routes.settings => const SettingsScreen(),
    Routes.editProfile => const EditProfileScreen(),
    Routes.feedback => const FeedbackScreen(),
    Routes.sendMoney => const SendMoneyScreen(),
    Routes.scanQr => const ScanQrScreen(),
    Routes.amount => const AmountScreen(),
    Routes.review => const ReviewPaymentScreen(),
    Routes.paymentResult => const PaymentResultScreen(),
    Routes.recipients => const RecipientsScreen(),
    Routes.editRecipient => EditRecipientScreen(
      recipient: arguments as Recipient?,
    ),
    Routes.generateQr => const GenerateQrScreen(),
    Routes.history => const TransactionHistoryScreen(),
    Routes.transactionDetail => TransactionDetailScreen(
      recordId: arguments as String,
    ),
    Routes.buyAirtime => const BuyAirtimeScreen(),
    Routes.buyData => const BuyDataScreen(),
    _ => const _NotFoundScreen(),
  };
}

/// Shown for a route name the app does not know, instead of crashing.
class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(context.s.homeNotFound)));
  }
}
