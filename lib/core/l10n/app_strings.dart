import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/entities/transaction_record.dart';
import '../../domain/repositories/auth_failure.dart';
import '../../domain/services/ussd_launcher.dart';
import '../validators.dart';
import 'auth_strings.dart';
import 'history_strings.dart';
import 'home_strings.dart';
import 'recipient_strings.dart';
import 'send_strings.dart';
import 'strings_base.dart';

/// Every piece of text the app shows, in English and Kinyarwanda.
///
/// Screens read it with `context.s`, for example `context.s.save`.
/// Strings used by more than one screen live here; each area of the app
/// adds its own in a mixin file next to this one.
class AppStrings extends StringsBase
    with
        AuthStrings,
        HomeStrings,
        SendStrings,
        RecipientStrings,
        HistoryStrings {
  const AppStrings(super.language);

  static AppStrings of(BuildContext context) {
    return Localizations.of<AppStrings>(context, AppStrings) ??
        const AppStrings(AppLanguage.english);
  }

  /// Put this list in `MaterialApp.localizationsDelegates`.
  static const delegates = <LocalizationsDelegate<Object>>[
    _AppStringsDelegate(),
    _MaterialFallbackDelegate(),
    _CupertinoFallbackDelegate(),
    DefaultWidgetsLocalizations.delegate,
  ];

  /// Put this list in `MaterialApp.supportedLocales`.
  static const supportedLocales = [Locale('en'), Locale('rw')];

  // Shared words
  String get appName => 'DailO';
  String get tagline => t(
    'A simple interface to navigate through MOMO',
    'Uburyo bworoshye bwo gukoresha MOMO',
  );
  String get back => t('Back', 'Subira inyuma');
  String get save => t('Save', 'Bika');
  String get cancel => t('Cancel', 'Hagarika');
  String get continueLabel => t('Continue', 'Komeza');
  String get confirm => t('Confirm', 'Emeza');
  String get delete => t('Delete', 'Siba');
  String get edit => t('Edit', 'Hindura');
  String get done => t('Done', 'Birangiye');
  String get retry => t('Try again', 'Ongera ugerageze');
  String get yes => t('Yes', 'Yego');
  String get no => t('No', 'Oya');
  String get search => t('Search', 'Shakisha');
  String get name => t('Name', 'Izina');
  String get phoneNumber => t('Phone number', 'Nimero ya telefoni');
  String get amount => t('Amount', 'Umubare w\'amafaranga');
  String get fee => t('Transaction fee', 'Ikiguzi cyo kohereza');
  String get total => t('Total', 'Igiteranyo');
  String get today => t('Today', 'Uyu munsi');
  String get yesterday => t('Yesterday', 'Ejo hashize');
  String get earlier => t('Earlier', 'Mbere');
  String get sendMoney => t('Send Money', 'Kohereza amafaranga');
  String get generateQr => t('Generate QR Code', 'Kora kode ya QR');
  String get buyAirtime => t('Buy Airtime', 'Kugura ama inite');
  String get buyData => t('Buy Data', 'Kugura interineti');
  String get recents => t('Recents', 'Ibiheruka');
  String get favorites => t('Favorite', 'Abo ukunda');
  String get somethingWrong => t(
    'Something went wrong. Please try again.',
    'Habaye ikibazo. Ongera ugerageze.',
  );
  String get savedOffline => t(
    'Saved on this phone. It will sync when you are back online.',
    'Byabitswe kuri telefoni. Bizoherezwa nubona interineti.',
  );

  // After the USSD dialog closes
  String get resultQuestion =>
      t('Did the payment go through?', 'Ese kwishyura byagenze neza?');
  String get resultQuestionHelp => t(
    'Check the message from your network, then choose one.',
    'Reba ubutumwa bw\'umuyoboro wawe, hanyuma uhitemo.',
  );

  // Steps shown when only the network's root menu could be dialled
  String get ussdStepsTitle => t(
    'Follow these steps in your network\'s own menu',
    'Kurikiza izi ntambwe muri menu y\'umuyoboro wawe',
  );
  String get ussdStepChooseSend =>
      t('Choose Send Money', 'Hitamo Kohereza amafaranga');
  String get ussdStepChooseAirtime =>
      t('Choose Buy Airtime', 'Hitamo Kugura ama inite');
  String get ussdStepChooseData =>
      t('Choose Buy Data', 'Hitamo Kugura interineti');
  String ussdStepEnter(String value) => t('Enter $value', 'Andika $value');
  String ussdStepPickBundle(String price) => t(
    'Choose the bundle that costs $price',
    'Hitamo interineti igura $price',
  );
  String get ussdStepCheckNameAndPin => t(
    'Check the name, then enter your PIN in the network\'s own dialog',
    'Genzura izina, hanyuma wandike PIN yawe mu idirishya ry\'umuyoboro',
  );
  String get ussdStepPin => t(
    'Enter your PIN in the network\'s own dialog',
    'Andika PIN yawe mu idirishya ry\'umuyoboro',
  );
  String get resultYes => t('Yes, it was confirmed', 'Yego, byemejwe');
  String get resultNo => t('No, it failed', 'Oya, byanze');
  String get resultNotSure => t('I am not sure', 'Simbizi neza');

  /// Why the phone could not dial, and what to do next.
  String launchProblem(UssdOutcome outcome) {
    return switch (outcome) {
      UssdOutcome.permissionDenied => t(
        'DailO needs permission to make phone calls so it can dial *182# '
            'for you. Allow it, then try again.',
        'DailO ikeneye uruhushya rwo guhamagara kugira ngo ikande *182#. '
            'Rwemere, hanyuma wongere ugerageze.',
      ),
      UssdOutcome.noSim => t(
        'No SIM card was found. Insert your MTN or Airtel SIM and try again.',
        'Nta SIM karita yabonetse. Shyiramo SIM ya MTN cyangwa Airtel '
            'wongere ugerageze.',
      ),
      UssdOutcome.unsupported => t(
        'This device cannot dial USSD codes.',
        'Iki gikoresho ntigishobora gukanda kode za USSD.',
      ),
      UssdOutcome.launched => '',
    };
  }

  /// The label for each transaction type.
  String txType(TxType type) {
    return switch (type) {
      TxType.send => sendMoney,
      TxType.airtime => buyAirtime,
      TxType.data => buyData,
    };
  }

  /// The label for each transaction result.
  String txStatus(TxStatus status) {
    return switch (status) {
      TxStatus.success => t('Confirmed by you', 'Wabyemeje'),
      TxStatus.failed => t('Failed', 'Byanze'),
      TxStatus.pending => t('Not confirmed', 'Ntibiremezwa'),
    };
  }

  /// A polite message for each form problem.
  String fieldError(FieldError error) {
    return switch (error) {
      FieldError.required => t(
        'Please fill in this field.',
        'Uzuza aha hantu.',
      ),
      FieldError.invalidEmail => t(
        'Please enter a valid email, like name@example.com.',
        'Andika imeyili nyayo, nka name@example.com.',
      ),
      FieldError.weakPassword => t(
        'Use at least 8 characters with a letter and a number.',
        'Koresha inyuguti 8 nibura, harimo inyuguti n\'umubare.',
      ),
      FieldError.passwordMismatch => t(
        'The two passwords do not match.',
        'Amagambo y\'ibanga yombi ntahura.',
      ),
      FieldError.nameTooShort => t(
        'Please enter at least 2 letters.',
        'Andika inyuguti 2 nibura.',
      ),
      FieldError.nameTooLong => t(
        'Please keep it under 30 letters.',
        'Ntirenze inyuguti 30.',
      ),
      FieldError.invalidPhone => t(
        'Please enter a Rwandan number, like 078 123 4567.',
        'Andika nimero yo mu Rwanda, nka 078 123 4567.',
      ),
      FieldError.invalidAmount => t(
        'Please enter an amount of at least 1 Frw.',
        'Andika amafaranga guhera kuri 1 Frw.',
      ),
      FieldError.amountTooLarge => t(
        'The most you can send at once is 10,000,000 Frw.',
        'Ntushobora kohereza arenze 10,000,000 Frw icyarimwe.',
      ),
      FieldError.messageTooShort => t(
        'Please tell us a little more (10 letters or more).',
        'Tubwire birambuye (inyuguti 10 nibura).',
      ),
      FieldError.messageTooLong => t(
        'Please keep it under 2,000 letters.',
        'Ntirenze inyuguti 2,000.',
      ),
      FieldError.termsNotAccepted => t(
        'Please accept the terms to continue.',
        'Emera amabwiriza kugira ngo ukomeze.',
      ),
    };
  }

  /// A clear message for each sign-in problem.
  String authError(AuthFailureCode code) {
    return switch (code) {
      AuthFailureCode.invalidEmail => t(
        'That email address does not look right.',
        'Iyo imeyili ntabwo yanditse neza.',
      ),
      AuthFailureCode.wrongCredentials => t(
        'The email or password is not correct.',
        'Imeyili cyangwa ijambo ry\'ibanga si byo.',
      ),
      AuthFailureCode.emailInUse => t(
        'An account already uses this email. Try signing in.',
        'Iyi imeyili isanzwe ifite konti. Gerageza kwinjira.',
      ),
      AuthFailureCode.weakPassword => t(
        'Please choose a stronger password.',
        'Hitamo ijambo ry\'ibanga rikomeye.',
      ),
      AuthFailureCode.userDisabled => t(
        'This account has been turned off.',
        'Iyi konti yarahagaritswe.',
      ),
      AuthFailureCode.tooManyRequests => t(
        'Too many tries. Please wait a minute and try again.',
        'Wagerageje kenshi. Tegereza umunota wongere ugerageze.',
      ),
      AuthFailureCode.network => t(
        'No connection. Signing in needs the internet once.',
        'Nta interineti. Kwinjira bisaba interineti rimwe.',
      ),
      AuthFailureCode.googleCancelled => t(
        'Google sign-in was cancelled.',
        'Kwinjira na Google byahagaritswe.',
      ),
      AuthFailureCode.unknown => somethingWrong,
    };
  }
}

/// Shorter access from a widget: `context.s.save`.
extension StringsContext on BuildContext {
  AppStrings get s => AppStrings.of(this);
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppStrings> load(Locale locale) async {
    return AppStrings(AppLanguage.fromCode(locale.languageCode));
  }

  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}

/// Flutter ships no Kinyarwanda text for its own widgets (tooltips, dialogs,
/// text selection). Without these two delegates a `rw` locale throws
/// "No MaterialLocalizations found". They hand Flutter its English text, and
/// the app's own strings above cover everything the user reads.
class _MaterialFallbackDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _MaterialFallbackDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    return DefaultMaterialLocalizations.load(const Locale('en'));
  }

  @override
  bool shouldReload(_MaterialFallbackDelegate old) => false;
}

class _CupertinoFallbackDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _CupertinoFallbackDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    return DefaultCupertinoLocalizations.load(const Locale('en'));
  }

  @override
  bool shouldReload(_CupertinoFallbackDelegate old) => false;
}
