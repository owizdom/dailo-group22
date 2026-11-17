/// The name of every screen route. Screens navigate with
/// `Navigator.pushNamed(context, Routes.amount)` so no screen needs to
/// import another screen.
class Routes {
  static const signIn = '/sign-in';
  static const signUpName = '/sign-up';
  static const signUpDetails = '/sign-up/details';
  static const verifyEmail = '/verify-email';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';
  static const settings = '/settings';
  static const editProfile = '/settings/profile';
  static const feedback = '/feedback';
  static const sendMoney = '/send';
  static const scanQr = '/send/scan';
  static const amount = '/send/amount';
  static const review = '/send/review';
  static const paymentResult = '/send/result';
  static const recipients = '/recipients';
  static const editRecipient = '/recipients/edit';
  static const generateQr = '/qr';
  static const history = '/history';
  static const transactionDetail = '/history/detail';
  static const buyAirtime = '/airtime';
  static const buyData = '/data';
}
