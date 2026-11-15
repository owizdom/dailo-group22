import 'strings_base.dart';

/// Text for: send money, scan QR, amount, review, result.
mixin SendStrings on StringsBase {
  // Send money
  String get sendEnterNumber =>
      t('Enter phone number', 'Andika nimero ya telefoni');
  String get sendScanTooltip => t('Scan QR code', 'Sikana kode ya QR');
  String get sendViewAll => t('View All', 'Reba byose');
  String get noRecents =>
      t('No recent recipients yet.', 'Nta bakiriye baheruka kuboneka.');
  String get noFavorites => t(
    'No favourites yet. Star a recipient to see them here.',
    'Nta bakunzwe ruhari. Shyira inyenyeri ku wakira kugira ngo agaragare hano.',
  );

  // Scan QR
  String get scanTitle => t('Scan QR Code', 'Sikana kode ya QR');
  String get scanHelp => t(
    'Point the camera at the QR code of the person you are paying.',
    'Garagaza kamera kuri kode ya QR y\'uwo ushaka kwishyura.',
  );
  String get scanManual =>
      t('Type a number instead', 'Andika nimero aho kuyisikana');
  String get scanMyCode =>
      t('Generate a payment QR code', 'Kora kode ya QR yo kwishyuriraho');
  String get scanInvalid => t(
    'This is not a DailO payment code.',
    'Iyi si kode yo kwishyura ya DailO.',
  );

  // Amount
  String get amountPlaceholder => t('Enter amount', 'Andika umubare');
  String get sendComment => t('Comment', 'Igitekerezo');
  String get sendOptional => t('(optional)', '(si ngombwa)');
  String get commentHint =>
      t('e.g. Tomatoes, Tuesday', 'urugero: Inyanya, ku wa kabiri');
  String get reviewPayment => t('Review payment', 'Reba ubwishyu');
  String get feeUnknown =>
      t('Your network shows the fee', 'Umuyoboro wawe ugaragaza ikiguzi');
  String feeHint(String cheaperAmount, String saving) => t(
    'Sending $cheaperAmount or less saves you $saving in fees.',
    'Kohereza $cheaperAmount cyangwa munsi bigabanya ikiguzi kuri $saving.',
  );
  String changeTo(String amount) =>
      t('Change to $amount', 'Hindura ube $amount');

  // Review
  String get editAmount => t('Edit amount', 'Hindura umubare');
  String get checkNameNotice => t(
    'Check the name your network shows before you enter your PIN.',
    'Reba izina umuyoboro wawe ugaragaza mbere yo kwandika PIN yawe.',
  );
  String get totalDeducted => t('Total deducted', 'Igiteranyo cyakuweho');
  String get sendNetwork => t('Network', 'Umuyoboro');
  String get ussdNoData =>
      t('USSD · no data needed', 'USSD · nta interineti ikenewe');
  String get reviewNote => t(
    'Nothing is sent until you confirm. DailO then dials *182# for you, '
        'and your phone asks for your MoMo PIN.',
    'Nta kintu cyoherezwa utaremeza. DailO ikanda *182# ubwayo, '
        'hanyuma telefoni yawe ikagusaba PIN ya MoMo.',
  );
  String get confirmAndPin =>
      t('Confirm and enter PIN', 'Emeza hanyuma wandike PIN');

  // Result
  String get paymentSent => t('Payment Sent', 'Amafaranga yoherejwe');
  String get paymentResult => t('Payment Result', 'Ibyavuye mu kwishyura');
  String sentTo(String name) => t('sent to $name', 'yoherejwe kuri $name');
  String paymentTo(String name) => t('payment to $name', 'kwishyura $name');
  String get sendStatus => t('Status', 'Uko bihagaze');
  String get sendDate => t('Date', 'Itariki');
  String get savedToHistory => t(
    'Saved to Transaction History. No mobile data was used.',
    'Byabitswe mu mateka y\'ibyakozwe. Nta interineti yakoreshejwe.',
  );
  String get sendPayAgain => t('Pay again', 'Ongera wishyure');
}
