import 'strings_base.dart';

/// Text for: home, settings, edit profile, feedback.
mixin HomeStrings on StringsBase {
  // Home
  String get homeWelcome => t('Welcome to DailO', 'Murakaza neza kuri DailO');
  String get homeSettingsTooltip => t('Settings', 'Igenamiterere');
  String get homeRecent => t('Recent Transactions', 'Ibyakozwe vuba');
  String get homeSeeMore => t('See More', 'Reba byinshi');
  String get homeNoRecent => t(
    'No transactions yet. Your payments will show here.',
    'Nta byakozwe. Ibyo wishyuye bizagaragara hano.',
  );
  String get homeFeedbackLink => t(
    'Have a Recommendation or Feedback?',
    'Ufite inama cyangwa igitekerezo?',
  );
  String get homeNotFound =>
      t('This page was not found.', 'Iyi paji ntabwo yabonetse.');

  // Settings
  String get settingsTitle => t('Settings', 'Igenamiterere');
  String get settingsEditProfile => t('Edit profile', 'Hindura umwirondoro');
  String get settingsDarkMode => t('Dark mode', 'Uburyo bw\'umwijima');
  String get settingsFeeWarning => t('Fee warnings', 'Kuburira ku kiguzi');
  String get settingsFeeWarningHelp => t(
    'Tell me when a slightly bigger amount costs less in fees.',
    'Mbwira iyo amafaranga arenzeho make agabanya ikiguzi.',
  );
  String get settingsNetwork => t('Default network', 'Umuyoboro usanzwe');
  String get settingsLanguage => t('Language', 'Ururimi');
  String get settingsSignOut => t('Sign out', 'Sohoka');
  String get settingsSignOutTitle => t('Sign out?', 'Urashaka gusohoka?');
  String get settingsSignOutMessage => t(
    'You will need to sign in again to use DailO.',
    'Uzasabwa kongera kwinjira kugira ngo ukoreshe DailO.',
  );

  // Edit profile
  String get profileTitle => t('Edit Profile', 'Hindura umwirondoro');
  String get profileFirstName => t('First name', 'Izina ry\'ibanze');
  String get profileLastName => t('Last name', 'Izina ry\'umuryango');
  String get profileSaved => t('Profile saved.', 'Umwirondoro wabitswe.');
  String get profileSaveFailed => t(
    'Could not save your profile. Please try again.',
    'Ntibishobotse kubika umwirondoro. Ongera ugerageze.',
  );

  // Feedback
  String get feedbackTitle => t('Feedback', 'Ibitekerezo');
  String get feedbackRatingLabel =>
      t('How do you like DailO?', 'DailO uyibonaho iki?');
  String feedbackStarTooltip(int stars) =>
      t('$stars of 5 stars', 'Inyenyeri $stars kuri 5');
  String get feedbackMessageLabel => t('Your message', 'Ubutumwa bwawe');
  String get feedbackMessageHint => t(
    'Tell us what to improve or what you like.',
    'Tubwire icyakosorwa cyangwa icyo ukunda.',
  );
  String get feedbackSend => t('Send', 'Ohereza');
  String get feedbackSent =>
      t('Thank you for your feedback.', 'Murakoze ku bitekerezo byanyu.');
  String get feedbackSendFailed => t(
    'Could not send your feedback. Please try again.',
    'Ntibishobotse kohereza ibitekerezo. Ongera ugerageze.',
  );
}
