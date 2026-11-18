import 'package:flutter/widgets.dart';

/// Widget keys for everything a test taps, types into or reads.
///
/// Tests find widgets by these keys instead of by text, so they keep
/// passing when the wording or the language changes. A screen must put
/// each key on the widget described next to it.
class K {
  // Sign in
  static const signInEmail = Key('signIn.email'); // TextFormField
  static const signInPassword = Key('signIn.password'); // TextFormField
  static const signInSubmit = Key('signIn.submit'); // button
  static const signInGoogle = Key('signIn.google'); // button
  static const signInForgot = Key('signIn.forgot'); // text button
  static const signInToSignUp = Key('signIn.toSignUp'); // text button

  // Sign up, step 1 (name) and step 2 (details)
  static const signUpFirstName = Key('signUp.firstName');
  static const signUpLastName = Key('signUp.lastName');
  static const signUpContinue = Key('signUp.continue');
  static const signUpGoogle = Key('signUp.google');
  static const signUpToSignIn = Key('signUp.toSignIn');
  static const signUpEmail = Key('signUp.email');
  static const signUpPhone = Key('signUp.phone');
  static const signUpPassword = Key('signUp.password');
  static const signUpConfirm = Key('signUp.confirm');
  static const signUpTerms = Key('signUp.terms'); // Checkbox
  static const signUpSubmit = Key('signUp.submit');

  // Verify email
  static const verifyResend = Key('verify.resend');
  static const verifyCheck = Key('verify.check'); // "I have verified"
  static const verifySignOut = Key('verify.signOut');

  // Forgot password
  static const forgotEmail = Key('forgot.email');
  static const forgotSubmit = Key('forgot.submit');

  // Home
  static const homeSend = Key('home.send');
  static const homeQr = Key('home.qr');
  static const homeAirtime = Key('home.airtime');
  static const homeData = Key('home.data');
  static const homeSeeMore = Key('home.seeMore');
  static const homeSettings = Key('home.settings');
  static const homeFeedback = Key('home.feedback');
  static const homeRecentList = Key('home.recentList'); // list of tiles
  static const homeRecentEmpty = Key('home.recentEmpty');

  // Settings and profile
  static const settingsDark = Key('settings.dark'); // Switch
  static const settingsFeeWarning = Key('settings.feeWarning'); // Switch
  static const settingsNetworkMtn = Key('settings.network.mtn');
  static const settingsNetworkAirtel = Key('settings.network.airtel');
  static const settingsLanguageEnglish = Key('settings.language.en');
  static const settingsLanguageKinyarwanda = Key('settings.language.rw');
  static const settingsEditProfile = Key('settings.editProfile');
  static const settingsSignOut = Key('settings.signOut');
  static const profileFirstName = Key('profile.firstName');
  static const profileLastName = Key('profile.lastName');
  static const profilePhone = Key('profile.phone');
  static const profileSave = Key('profile.save');

  // Feedback
  static const feedbackMessage = Key('feedback.message');
  static const feedbackSubmit = Key('feedback.submit');
  static Key feedbackStar(int rating) => Key('feedback.star.$rating');

  // Send money: choose a recipient
  static const sendPhone = Key('send.phone'); // TextFormField
  static const sendScan = Key('send.scan'); // icon button
  static const sendContinue = Key('send.continue');
  static const sendTabRecents = Key('send.tab.recents');
  static const sendTabFavorites = Key('send.tab.favorites');
  static const sendList = Key('send.list'); // list of recipient tiles
  static const sendListEmpty = Key('send.listEmpty');
  static const sendViewAll = Key('send.viewAll');

  // Scan QR
  static const scanManual = Key('scan.manual'); // "type number instead"
  static const scanMyCode = Key('scan.myCode'); // "generate a payment QR"

  // Amount
  static const amountRecipient = Key('amount.recipient'); // header card
  static const amountField = Key('amount.field'); // TextFormField
  static const amountFee = Key('amount.fee'); // Text
  static const amountTotal = Key('amount.total'); // Text
  static const amountHint = Key('amount.hint'); // fee band notice
  static const amountHintApply = Key('amount.hintApply'); // "Change to ..."
  static const amountComment = Key('amount.comment');
  static const amountReview = Key('amount.review'); // button
  static Key amountChip(int value) => Key('amount.chip.$value');

  // Review
  static const reviewName = Key('review.name'); // Text
  static const reviewPhone = Key('review.phone'); // Text
  static const reviewAmount = Key('review.amount'); // Text
  static const reviewFee = Key('review.fee'); // Text
  static const reviewTotal = Key('review.total'); // Text
  static const reviewConfirm = Key('review.confirm'); // button
  static const reviewCancel = Key('review.cancel'); // button
  static const reviewEdit = Key('review.edit'); // "Edit amount"
  static const reviewProblem = Key('review.problem'); // launch problem notice

  // Shown whenever only the root menu *182# could be dialled: the steps to
  // follow inside the network's own menu.
  static const ussdSteps = Key('ussd.steps');

  // Result: the "Did MTN confirm it?" question, then the receipt
  static const resultYes = Key('result.yes');
  static const resultNo = Key('result.no');
  static const resultNotSure = Key('result.notSure');
  static const resultStatus = Key('result.status'); // Text
  static const resultDone = Key('result.done');
  static const resultPayAgain = Key('result.payAgain');

  // Recipients
  static const recipientsSearch = Key('recipients.search');
  static const recipientsList = Key('recipients.list');
  static const recipientsEmpty = Key('recipients.empty');
  static const recipientsAdd = Key('recipients.add');
  static const recipientEdit = Key('recipient.edit'); // menu item
  static const recipientFavorite = Key('recipient.favorite'); // menu item
  static const recipientDelete = Key('recipient.delete'); // menu item
  static const confirmYes = Key('confirm.yes'); // dialog
  static const confirmNo = Key('confirm.no'); // dialog
  static Key recipientTile(String id) => Key('recipient.tile.$id');
  static Key recipientMenu(String id) => Key('recipient.menu.$id');

  // Add or edit a recipient
  static const editName = Key('edit.name');
  static const editPhone = Key('edit.phone');
  static const editSave = Key('edit.save');

  // My payment QR code
  static const qrImage = Key('qr.image');
  static const qrMissingPhone = Key('qr.missingPhone');

  // Transaction history and detail
  static const historySearch = Key('history.search');
  static const historyList = Key('history.list');
  static const historyEmpty = Key('history.empty');
  static const detailStatus = Key('detail.status'); // Text
  static const detailMarkSuccess = Key('detail.markSuccess');
  static const detailMarkFailed = Key('detail.markFailed');
  static const detailDelete = Key('detail.delete');
  static Key historyFilter(String type) => Key('history.filter.$type');
  static Key transactionTile(String id) => Key('tx.tile.$id');

  // Airtime and data
  static const airtimeAmount = Key('airtime.amount');
  static const airtimePhone = Key('airtime.phone'); // optional, other number
  static const airtimeBuy = Key('airtime.buy');
  static const dataAmount = Key('data.amount');
  static const dataBuy = Key('data.buy');
}
