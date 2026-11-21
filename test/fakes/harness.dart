import 'package:dailo/app_dependencies.dart';
import 'package:dailo/core/l10n/app_strings.dart';
import 'package:dailo/core/theme.dart';
import 'package:dailo/domain/entities/app_settings.dart';
import 'package:dailo/domain/entities/auth_session.dart';
import 'package:dailo/presentation/cubits/auth_cubit.dart';
import 'package:dailo/presentation/cubits/feedback_cubit.dart';
import 'package:dailo/presentation/cubits/profile_cubit.dart';
import 'package:dailo/presentation/cubits/recipients_cubit.dart';
import 'package:dailo/presentation/cubits/send_money_cubit.dart';
import 'package:dailo/presentation/cubits/settings_cubit.dart';
import 'package:dailo/presentation/cubits/top_up_cubit.dart';
import 'package:dailo/presentation/cubits/transactions_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_auth_repository.dart';
import 'in_memory_repositories.dart';
import 'samples.dart';

/// Phone sizes in logical pixels used by the overflow tests.
const smallPhone = Size(320, 568);
const largePhone = Size(430, 932);
const landscapePhone = Size(568, 320);

/// The fakes and the real cubits built on top of them.
///
/// A widget test creates one, optionally changes the fakes, then calls
/// [pumpScreen]. The cubits are the real ones, so a tap on a screen runs
/// the same logic it runs in the app.
class TestApp {
  TestApp({
    AuthSession? session = verifiedSession,
    bool withSampleData = true,
    AppSettings settings = const AppSettings(),
  }) : auth = FakeAuthRepository(initial: session),
       profileRepo = FakeProfileRepository(
         session == null ? null : sampleUser(),
       ),
       recipientRepo = InMemoryRecipientRepository(
         withSampleData ? sampleRecipients() : const [],
       ),
       transactionRepo = InMemoryTransactionRepository(
         withSampleData ? sampleTransactions() : const [],
       ),
       feedbackRepo = FakeFeedbackRepository(),
       settingsRepo = InMemorySettingsRepository(settings),
       launcher = FakeUssdLauncher();

  final FakeAuthRepository auth;
  final FakeProfileRepository profileRepo;
  final InMemoryRecipientRepository recipientRepo;
  final InMemoryTransactionRepository transactionRepo;
  final FakeFeedbackRepository feedbackRepo;
  final InMemorySettingsRepository settingsRepo;
  final FakeUssdLauncher launcher;

  late final AuthCubit authCubit = AuthCubit(auth);
  late final ProfileCubit profileCubit = ProfileCubit(profileRepo);
  late final RecipientsCubit recipientsCubit = RecipientsCubit(recipientRepo);
  late final TransactionsCubit transactionsCubit = TransactionsCubit(
    transactionRepo,
  );
  late final SettingsCubit settingsCubit = SettingsCubit(settingsRepo);
  late final FeedbackCubit feedbackCubit = FeedbackCubit(feedbackRepo);
  late final SendMoneyCubit sendCubit = SendMoneyCubit(
    transactions: transactionRepo,
    recipients: recipientRepo,
    launcher: launcher,
  );
  late final TopUpCubit topUpCubit = TopUpCubit(
    transactions: transactionRepo,
    launcher: launcher,
  );

  /// The same seven dependencies `main.dart` builds, for whole-app tests
  /// that pump `DailoApp(dependencies: app.dependencies)`.
  AppDependencies get dependencies => AppDependencies(
    auth: auth,
    profile: profileRepo,
    recipients: recipientRepo,
    transactions: transactionRepo,
    feedback: feedbackRepo,
    settings: settingsRepo,
    launcher: launcher,
  );

  /// Does what `app.dart` does after sign-in: loads the settings and points
  /// every cubit at the signed-in user.
  Future<void> bind() async {
    await settingsCubit.load();
    final uid = auth.session?.uid;
    final settings = settingsCubit.state.settings;
    profileCubit.watch(uid);
    recipientsCubit.watch(uid);
    transactionsCubit.watch(uid);
    feedbackCubit.bind(uid);
    topUpCubit.bind(uid, network: settings.defaultNetwork);
    sendCubit.bind(
      uid,
      from: settings.defaultNetwork,
      feeWarning: settings.feeWarning,
      saved: recipientRepo.items,
    );
  }

  /// Shows [screen] inside the app's theme, strings and cubits.
  ///
  /// Any named route a screen pushes lands on a page whose only text is
  /// `route:<name>`, so a test can check navigation with
  /// `expect(find.text('route:/send/amount'), findsOneWidget)`.
  /// [pushed] records the name and arguments of every pushed route.
  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    Size size = const Size(390, 844),
    bool dark = false,
    AppLanguage language = AppLanguage.english,
    bool bindFirst = true,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    if (bindFirst) await bind();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: authCubit),
          BlocProvider.value(value: profileCubit),
          BlocProvider.value(value: recipientsCubit),
          BlocProvider.value(value: transactionsCubit),
          BlocProvider.value(value: settingsCubit),
          BlocProvider.value(value: feedbackCubit),
          BlocProvider.value(value: sendCubit),
          BlocProvider.value(value: topUpCubit),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          locale: Locale(language.code),
          supportedLocales: AppStrings.supportedLocales,
          localizationsDelegates: AppStrings.delegates,
          home: screen,
          onGenerateRoute: (settings) {
            pushed.add(settings);
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => Scaffold(body: Text('route:${settings.name}')),
            );
          },
        ),
      ),
    );
    await tester.pump();
  }

  /// Every named route pushed since [pumpScreen], oldest first.
  final List<RouteSettings> pushed = [];

  /// The strings for [language], for comparing against text on screen.
  AppStrings strings([AppLanguage language = AppLanguage.english]) {
    return AppStrings(language);
  }
}
