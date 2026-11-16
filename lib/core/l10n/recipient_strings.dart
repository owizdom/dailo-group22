import 'strings_base.dart';

/// Text for: recipients list, add and edit recipient, my QR code.
mixin RecipientStrings on StringsBase {
  // Recipients list
  String get recipientsTitle => t('Recipients', 'Abakira');
  String get recipientsSearchHint => t('Phone No. / Name', 'Nimero / Izina');
  String get addRecipient => t('Add recipient', 'Ongeramo uwakira');
  String get recipientsEmpty => t(
    'No recipients found. Add one to pay faster next time.',
    'Nta bakira babonetse. Ongeramo umwe kugira ngo wishyure vuba.',
  );
  String get menuEdit => t('Edit', 'Hindura');
  String get menuFavorite => t('Add to favorite', 'Shyira mu bo ukunda');
  String get menuUnfavorite => t('Remove favorite', 'Kura mu bo ukunda');
  String get menuDelete => t('Delete', 'Siba');
  String get recipientMenuLabel => t('More options', 'Ibindi');

  // Delete confirmation
  String deleteRecipientTitle(String name) =>
      t('Delete "$name"?', 'Siba "$name"?');
  String get deleteRecipientMessage => t('Are you sure?', 'Urabyizeye?');
  String get deleteRecipientConfirm => t('Yes, delete', 'Yego, siba');

  // Snack messages
  String get recipientAdded => t('Recipient saved.', 'Uwakira yabitswe.');
  String get recipientUpdated => t('Recipient updated.', 'Uwakira yahinduwe.');
  String get recipientDeleted => t('Recipient deleted.', 'Uwakira yasibwe.');
  String get recipientDuplicate =>
      t('This number is already saved.', 'Iyi nimero isanzwe ibitswe.');

  // Add and edit
  String get addRecipientTitle => t('Add Recipient', 'Ongeramo uwakira');
  String get editRecipientTitle => t('Edit Recipient', 'Hindura uwakira');
  String get recipientNameHint => t('Enter a name', 'Andika izina');

  // My QR code
  String get myQrTitle => t('My QR Code', 'Kode yanjye ya QR');
  String get myQrHelp => t(
    'Let someone scan this code to pay you.',
    'Reka undi muntu asikane iyi kode kugira ngo akwishyure.',
  );
  String get qrMissingPhone => t(
    'Add your phone number to your profile to get a QR code.',
    'Ongeramo nimero ya telefoni muri konti yawe kugira ngo ubone kode ya QR.',
  );
  String get addPhoneNumber =>
      t('Add phone number', 'Ongeramo nimero ya telefoni');
}
