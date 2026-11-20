import 'strings_base.dart';

/// Text for: sign in, sign up, verify email, forgot password.
mixin AuthStrings on StringsBase {
  // Shared by several auth screens
  String get authWelcome => t('Welcome to DailO', 'Murakaza neza kuri DailO');
  String get authEmail => t('Email', 'Imeyili');
  String get authPassword => t('Password', 'Ijambo ry\'ibanga');
  String get authSignInTitle => t('Sign In', 'Injira');
  String get authSignUpTitle => t('Sign Up', 'Iyandikishe');
  String get authOrSocial => t(
    'or use one of your social profiles',
    'cyangwa koresha konti yawe ya Google',
  );
  String get authGoogle => t('Google', 'Google');

  // Sign in
  String get authSignInSubtitle => t(
    'Hi there! Nice to see you again',
    'Muraho! Twishimiye kongera kukubona',
  );
  String get authForgotLink =>
      t('Forgot Password?', 'Wibagiwe ijambo ry\'ibanga?');
  String get authNoAccount => t('Don\'t have an account?', 'Nta konti ufite?');

  // Sign up, step 1
  String get authSignUpSubtitle =>
      t('Welcome to the DailO app', 'Murakaza neza kuri porogaramu ya DailO');
  String get authFirstName => t('First name', 'Izina ry\'ibanze');
  String get authLastName => t('Last name', 'Izina ry\'umuryango');
  String get authHaveAccount =>
      t('Already have an account?', 'Usanzwe ufite konti?');

  // Sign up, step 2
  String get authConfirmPassword =>
      t('Confirm password', 'Emeza ijambo ry\'ibanga');
  String get authTerms => t(
    'I agree to the Terms of Service and Privacy Policy.',
    'Nemeye amabwiriza y\'imikoreshereze n\'politiki y\'ibanga.',
  );

  // Verify email
  String get authVerifyTitle => t('Verify your email', 'Emeza imeyili yawe');
  String authVerifyBody(String email) => t(
    'We sent a link to $email. Open it, then come back and tap "I have verified".',
    'Twohereje link kuri $email. Yifungure, hanyuma ugaruke ukande "Maze kwemeza".',
  );
  String get authVerified => t('I have verified', 'Maze kwemeza');
  String get authResend => t('Resend', 'Ongera wohereze');
  String get authSignOut => t('Sign out', 'Sohoka');
  String get authVerificationSent =>
      t('Verification email sent.', 'Imeyili yo kwemeza yoherejwe.');
  String get authStillUnverified => t(
    'Your email is not verified yet. Open the link we sent you first.',
    'Imeyili yawe ntiremezwa. Banza ufungure link twakohereje.',
  );

  // Forgot password
  String get authForgotTitle =>
      t('Forgot password', 'Wibagiwe ijambo ry\'ibanga');
  String get authForgotBody => t(
    'Enter your email and we will send you a link to choose a new password.',
    'Andika imeyili yawe, tukohereze link yo guhitamo ijambo ry\'ibanga rishya.',
  );
  String get authSendReset => t('Send reset link', 'Ohereza link');
  String get authResetSent => t(
    'Reset link sent. Check your email.',
    'Link yoherejwe. Reba imeyili yawe.',
  );
}
