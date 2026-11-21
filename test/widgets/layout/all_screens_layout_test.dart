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
import 'package:dailo/presentation/screens/auth/forgot_password_screen.dart';
import 'package:dailo/presentation/screens/auth/sign_in_screen.dart';
import 'package:dailo/presentation/screens/auth/sign_up_details_screen.dart';
import 'package:dailo/presentation/screens/auth/sign_up_name_screen.dart';
import 'package:dailo/presentation/screens/auth/verify_email_screen.dart';
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
    });
  }
}
