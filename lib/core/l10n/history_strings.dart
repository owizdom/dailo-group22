import 'strings_base.dart';

/// Text for: transaction history, transaction detail, buy airtime, buy data.
mixin HistoryStrings on StringsBase {
  // History list
  String get historyTitle => t('Transaction History', 'Amateka y\'ibyakozwe');
  String get historySearchHint => t('Phone No. / Name', 'Nimero / Izina');
  String get filterAll => t('All', 'Byose');
  String get filterSend => t('Send', 'Kohereza');
  String get filterAirtime => t('Airtime', 'Ama inite');
  String get filterData => t('Data', 'Interineti');
  String get historyEmpty =>
      t('No transactions to show.', 'Nta byakozwe byo kwerekana.');

  // Transaction detail
  String get detailTitle => t('Transaction', 'Igikorwa');
  String get detailNotFound =>
      t('This record was not found.', 'Iki gikorwa nticyabonetse.');
  String get detailType => t('Type', 'Ubwoko');
  String get detailStatus => t('Status', 'Imimerere');
  String get detailComment => t('Comment', 'Igitekerezo');
  String get detailDate => t('Date', 'Itariki');
  String get detailNetwork => t('Network', 'Umuyoboro');
  String get markConfirmed => t('Mark as confirmed', 'Emeza ko byagenze neza');
  String get markFailed => t('Mark as failed', 'Emeza ko byanze');
  String get deleteRecordTitle =>
      t('Delete this record?', 'Usibe iki gikorwa?');
  String get deleteRecordMessage => t(
    'It will be removed from your history. This cannot be undone.',
    'Kizavanwa mu mateka yawe. Ntibishobora gusubizwa.',
  );
  String get recordUpdated => t('Record updated.', 'Byahinduwe.');
  String get recordDeleted => t('Record deleted.', 'Byasibwe.');

  // Buy airtime and buy data
  String get topUpAmountHint => t('Enter Amount', 'Andika umubare');
  String get airtimePhoneLabel =>
      t('For another number (optional)', 'Nimero y\'undi (si ngombwa)');
  String get airtimePhoneHint => t(
    'Leave empty to buy for this line',
    'Reka ubusa kugura kuri iyi nimero',
  );
  String get dataIntro => t(
    'The network\'s bundle menu will open. Pick a bundle there, then '
        'enter its price here so DailO can keep a record.',
    'Menu y\'amapaki y\'umuyoboro irafunguka. Hitamo ipaki, hanyuma '
        'wandike igiciro cyayo hano kugira ngo DailO ibike inyandiko.',
  );
  String get dataAmountLabel => t('Price of the bundle', 'Igiciro cy\'ipaki');
  String get dataBuyButton => t('Open bundle menu', 'Fungura menu y\'amapaki');
  String get purchaseSaved => t(
    'Purchase saved to Transaction History.',
    'Byabitswe mu mateka y\'ibyakozwe.',
  );
}