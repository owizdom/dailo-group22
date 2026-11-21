// AT16 (no overflow) and AT17 (accessibility) for every screen.
//
// One table lists every screen and what it needs to be shown. The loops at
// the bottom turn each row into six tests:
//   - no overflow on a small phone, a large phone and a phone on its side
//   - no overflow in Kinyarwanda on a small phone (its words are longer)
//   - the Android tap target and text contrast guidelines, light and dark
//
// Every test first looks for one widget that only the finished screen has
// (`mustShow`). Without that check a blank screen would pass, and a
// Placeholder is blank.
import 'package:dailo/core/keys.dart';
import 'package:dailo/domain/entities/app_settings.dart';
import 'package:dailo/domain/entities/auth_session.dart';
import 'package:dailo/domain/entities/network.dart';
import 'package:dailo/domain/entities/transaction_record.dart';
import 'package:dailo/presentation/cubits/send_money_cubit.dart';
import 'package:dailo/presentation/screens/auth/forgot_password_screen.dart';
import 'package:dailo/presentation/screens/auth/sign_in_screen.dart';
import 'package:dailo/presentation/screens/auth/sign_up_details_screen.dart';
import 'package:dailo/presentation/screens/auth/sign_up_name_screen.dart';
import 'package:dailo/presentation/screens/auth/verify_email_screen.dart';
import 'package:dailo/presentation/screens/history/buy_airtime_screen.dart';
import 'package:dailo/presentation/screens/history/buy_data_screen.dart';
import 'package:dailo/presentation/screens/history/transaction_detail_screen.dart';
import 'package:dailo/presentation/screens/history/transaction_history_screen.dart';
import 'package:dailo/presentation/screens/home/edit_profile_screen.dart';
import 'package:dailo/presentation/screens/home/feedback_screen.dart';
import 'package:dailo/presentation/screens/home/home_screen.dart';
import 'package:dailo/presentation/screens/home/settings_screen.dart';
import 'package:dailo/presentation/screens/home/splash_screen.dart';
import 'package:dailo/presentation/screens/recipients/edit_recipient_screen.dart';
import 'package:dailo/presentation/screens/recipients/generate_qr_screen.dart';
import 'package:dailo/presentation/screens/recipients/recipients_screen.dart';
import 'package:dailo/presentation/screens/send/amount_screen.dart';
import 'package:dailo/presentation/screens/send/payment_result_screen.dart';
import 'package:dailo/presentation/screens/send/review_payment_screen.dart';
import 'package:dailo/presentation/screens/send/scan_qr_screen.dart';
import 'package:dailo/presentation/screens/send/send_money_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/harness.dart';
import '../../fakes/samples.dart';

/// One screen and everything a test needs to show it.
class ScreenCase {
  ScreenCase({
    required this.name,
    required this.build,
    required this.mustShow,
    this.session = verifiedSession,
    this.prepare = doNothing,
    this.hasSpinner = false,
  });

  /// Shown in the test name.
  final String name;

  /// Creates the screen.
  final Widget Function() build;

  /// Something only the finished screen shows. A key from `keys.dart`, or
  /// the spinner for the splash screen, which has no key.
  final Finder mustShow;

  /// Who is signed in. Null is signed out, for the sign-in screens.
  final AuthSession? session;

  /// Runs after the cubits are bound and before the screen is pumped.
  /// The send-flow screens use it to move the send cubit to their step.
  final Future<void> Function(TestApp app) prepare;

  /// A spinner animates for ever, so `pumpAndSettle` would never return.
  final bool hasSpinner;
}

Future<void> doNothing(TestApp app) async {}

const longComment = 'A fairly long comment about tomatoes and Tuesday';

/// Puts a 30-character name (29 in fact, see `samples.dart`) everywhere
/// the app shows a name, and a long comment on the first transaction.
void addLongNames(TestApp app) {
  app.recipientRepo.items.add(longNameRecipient());

  final user = app.profileRepo.user;
  if (user != null) {
    app.profileRepo.user = user.copyWith(
      firstName: 'Mukandayisenga',
      lastName: 'Marie Claudine',
    );
  }

  // Replaces t3 (a confirmed send, the newest record) with the same
  // payment to the long-named recipient. The id stays t3.
  app.transactionRepo.items[0] = TransactionRecord(
    id: 't3',
    type: TxType.send,
    recipientId: 'r9',
    counterpartyName: longNameRecipient().name,
    counterpartyPhone: '0788999888',
    network: Network.mtn,
    amount: 10500,
    fee: 250,
    comment: longComment,
    status: TxStatus.success,
    createdAt: day3,
    updatedAt: day3,
  );
}

/// Moves the send cubit through the steps up to [step], with the worst-case
/// inputs: the long-named recipient, an amount 500 above a fee band (so the
/// hint shows) and a long comment.
Future<void> sendUpTo(TestApp app, SendStep step) async {
  final send = app.sendCubit;
  send.start();
  send.chooseRecipient(longNameRecipient());
  send.setAmount(10500);
  send.setComment(longComment);
  if (step != SendStep.amount) send.toReview();
  if (step == SendStep.awaitingResult || step == SendStep.done) {
    await send.confirm();
  }
  if (step == SendStep.done) await send.report(TxStatus.success);

  // If the cubit did not get there, say so here instead of failing later
  // with a puzzling "widget not found".
  expect(send.state.step, step, reason: 'the send cubit did not reach $step');
}

/// Every screen, in the order of `contracts/screens.md`.
final screenCases = <ScreenCase>[
  ScreenCase(
    name: 'SignInScreen',
    build: () => const SignInScreen(),
    mustShow: find.byKey(K.signInSubmit),
    session: null,
  ),
  ScreenCase(
    name: 'SignUpNameScreen',
    build: () => const SignUpNameScreen(),
    mustShow: find.byKey(K.signUpContinue),
    session: null,
  ),
  ScreenCase(
    name: 'SignUpDetailsScreen',
    build: () => const SignUpDetailsScreen(
      firstName: 'Mukandayisenga',
      lastName: 'Marie Claudine',
    ),
    mustShow: find.byKey(K.signUpSubmit),
    session: null,
  ),
  ScreenCase(
    name: 'VerifyEmailScreen',
    build: () => const VerifyEmailScreen(),
    mustShow: find.byKey(K.verifyCheck),
    session: unverifiedSession,
  ),
  ScreenCase(
    name: 'ForgotPasswordScreen',
    build: () => const ForgotPasswordScreen(),
    mustShow: find.byKey(K.forgotSubmit),
    session: null,
  ),
  ScreenCase(
    name: 'SplashScreen',
    build: () => const SplashScreen(),
    mustShow: find.byType(CircularProgressIndicator),
    session: null,
    hasSpinner: true,
  ),
  ScreenCase(
    name: 'HomeScreen',
    build: () => const HomeScreen(),
    mustShow: find.byKey(K.homeSend),
  ),
  ScreenCase(
    name: 'SettingsScreen',
    build: () => const SettingsScreen(),
    mustShow: find.byKey(K.settingsSignOut),
  ),
  ScreenCase(
    name: 'EditProfileScreen',
    build: () => const EditProfileScreen(),
    mustShow: find.byKey(K.profileSave),
  ),
  ScreenCase(
    name: 'FeedbackScreen',
    build: () => const FeedbackScreen(),
    mustShow: find.byKey(K.feedbackSubmit),
  ),
  ScreenCase(
    name: 'SendMoneyScreen',
    build: () => const SendMoneyScreen(),
    mustShow: find.byKey(K.sendContinue),
  ),
  ScreenCase(
    name: 'ScanQrScreen',
    build: () => ScanQrScreen(scannerBuilder: (_) => const SizedBox()),
    mustShow: find.byKey(K.scanManual),
  ),
  ScreenCase(
    name: 'AmountScreen',
    build: () => const AmountScreen(),
    mustShow: find.byKey(K.amountReview),
    prepare: (app) => sendUpTo(app, SendStep.amount),
  ),
  ScreenCase(
    name: 'ReviewPaymentScreen',
    build: () => const ReviewPaymentScreen(),
    mustShow: find.byKey(K.reviewConfirm),
    prepare: (app) => sendUpTo(app, SendStep.review),
  ),
  ScreenCase(
    name: 'PaymentResultScreen (asking what the network said)',
    build: () => const PaymentResultScreen(),
    mustShow: find.byKey(K.resultYes),
    prepare: (app) => sendUpTo(app, SendStep.awaitingResult),
  ),
  ScreenCase(
    name: 'PaymentResultScreen (receipt)',
    build: () => const PaymentResultScreen(),
    mustShow: find.byKey(K.resultDone),
    prepare: (app) => sendUpTo(app, SendStep.done),
  ),
  ScreenCase(
    name: 'RecipientsScreen',
    build: () => const RecipientsScreen(),
    mustShow: find.byKey(K.recipientsAdd),
  ),
  ScreenCase(
    name: 'EditRecipientScreen',
    build: () => EditRecipientScreen(recipient: longNameRecipient()),
    mustShow: find.byKey(K.editSave),
  ),
  ScreenCase(
    name: 'GenerateQrScreen',
    build: () => const GenerateQrScreen(),
    mustShow: find.byKey(K.qrImage),
  ),
  ScreenCase(
    name: 'TransactionHistoryScreen',
    build: () => const TransactionHistoryScreen(),
    mustShow: find.byKey(K.historySearch),
  ),
  ScreenCase(
    name: 'TransactionDetailScreen',
    build: () => const TransactionDetailScreen(recordId: 't3'),
    mustShow: find.byKey(K.detailStatus),
  ),
  ScreenCase(
    name: 'BuyAirtimeScreen',
    build: () => const BuyAirtimeScreen(),
    mustShow: find.byKey(K.airtimeBuy),
  ),
  ScreenCase(
    name: 'BuyDataScreen',
    build: () => const BuyDataScreen(),
    mustShow: find.byKey(K.dataBuy),
  ),
];

/// The three phone shapes from the spec: small, large and landscape.
const phoneSizes = {
  'small phone (320x568)': smallPhone,
  'large phone (430x932)': largePhone,
  'phone on its side (568x320)': landscapePhone,
};

/// Builds the app for [screen], prepares it and shows its screen.
Future<void> showScreen(
  WidgetTester tester,
  ScreenCase screen, {
  Size size = const Size(390, 844),
  bool dark = false,
  AppLanguage language = AppLanguage.english,
}) async {
  final app = TestApp(session: screen.session);
  addLongNames(app);
  await app.bind();
  await screen.prepare(app);
  await app.pumpScreen(
    tester,
    screen.build(),
    size: size,
    dark: dark,
    language: language,
    bindFirst: false, // bound above, before prepare
  );
  if (screen.hasSpinner) {
    await tester.pump(const Duration(seconds: 1));
  } else {
    await tester.pumpAndSettle();
  }
}

void main() {
  for (final screen in screenCases) {
    group(screen.name, () {
      for (final MapEntry(key: label, value: size) in phoneSizes.entries) {
        testWidgets('has no overflow on a $label', (tester) async {
          await showScreen(tester, screen, size: size);

          expect(screen.mustShow, findsOneWidget);
          // Flutter reports an overflow as an exception during layout.
          expect(tester.takeException(), isNull);
        });
      }

      testWidgets('has no overflow in Kinyarwanda on a small phone', (
        tester,
      ) async {
        await showScreen(
          tester,
          screen,
          size: smallPhone,
          language: AppLanguage.kinyarwanda,
        );

        expect(screen.mustShow, findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      for (final dark in [false, true]) {
        final theme = dark ? 'dark' : 'light';
        testWidgets('meets the accessibility guidelines in the $theme theme', (
          tester,
        ) async {
          final handle = tester.ensureSemantics();
          try {
            await showScreen(tester, screen, dark: dark);

            expect(screen.mustShow, findsOneWidget);
            await expectLater(
              tester,
              meetsGuideline(androidTapTargetGuideline),
            );
            await expectLater(tester, meetsGuideline(textContrastGuideline));
          } finally {
            // Released even when a check above fails, so the real failure
            // is reported instead of a "semantics handle still open" error.
            handle.dispose();
          }
        });
      }
    });
  }
}
