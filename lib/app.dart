import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/l10n/app_strings.dart';
import 'core/theme.dart';
import 'presentation/app_router.dart';
import 'presentation/cubits/auth_cubit.dart';
import 'presentation/cubits/feedback_cubit.dart';
import 'presentation/cubits/profile_cubit.dart';
import 'presentation/cubits/recipients_cubit.dart';
import 'presentation/cubits/send_money_cubit.dart';
import 'presentation/cubits/settings_cubit.dart';
import 'presentation/cubits/top_up_cubit.dart';
import 'presentation/cubits/transactions_cubit.dart';

import 'app_dependencies.dart';

export 'app_dependencies.dart';

/// The root widget: creates the cubits, applies the saved theme and
/// language, and shows the right first screen for the sign-in state.
class DailoApp extends StatelessWidget {
  const DailoApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // lazy: false so every cubit exists before the first auth event.
        BlocProvider(lazy: false, create: (_) => AuthCubit(dependencies.auth)),
        BlocProvider(
          lazy: false,
          create: (_) => SettingsCubit(dependencies.settings)..load(),
        ),
        BlocProvider(
          lazy: false,
          create: (_) => ProfileCubit(dependencies.profile),
        ),
        BlocProvider(
          lazy: false,
          create: (_) => RecipientsCubit(dependencies.recipients),
        ),
        BlocProvider(
          lazy: false,
          create: (_) => TransactionsCubit(dependencies.transactions),
        ),
        BlocProvider(
          lazy: false,
          create: (_) => FeedbackCubit(dependencies.feedback),
        ),
        BlocProvider(
          lazy: false,
          create: (_) => SendMoneyCubit(
            transactions: dependencies.transactions,
            recipients: dependencies.recipients,
            launcher: dependencies.launcher,
          ),
        ),
        BlocProvider(
          lazy: false,
          create: (_) => TopUpCubit(
            transactions: dependencies.transactions,
            launcher: dependencies.launcher,
          ),
        ),
      ],
      child: const _CubitBinder(child: _DailoMaterialApp()),
    );
  }
}

/// Points the cubits at the signed-in user and at the saved settings.
///
/// The data cubits are re-pointed only when the user changes, so flipping a
/// switch in Settings does not restart their Firestore listeners. The send
/// and top-up cubits also follow the settings they depend on.
class _CubitBinder extends StatelessWidget {
  const _CubitBinder({required this.child});

  final Widget child;

  /// The user id the data belongs to: null unless fully signed in.
  static String? _uidOf(AuthState state) {
    return state.status == AuthStatus.signedIn ? state.uid : null;
  }

  void _bindData(BuildContext context) {
    final uid = _uidOf(context.read<AuthCubit>().state);
    context.read<ProfileCubit>().watch(uid);
    context.read<RecipientsCubit>().watch(uid);
    context.read<TransactionsCubit>().watch(uid);
    context.read<FeedbackCubit>().bind(uid);
    _bindPayments(context);
  }

  void _bindPayments(BuildContext context) {
    final uid = _uidOf(context.read<AuthCubit>().state);
    final settings = context.read<SettingsCubit>().state.settings;
    context.read<TopUpCubit>().bind(uid, network: settings.defaultNetwork);
    context.read<SendMoneyCubit>().bind(
      uid,
      from: settings.defaultNetwork,
      feeWarning: settings.feeWarning,
      saved: context.read<RecipientsCubit>().state.all,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthCubit, AuthState>(
          listenWhen: (before, after) => _uidOf(before) != _uidOf(after),
          listener: (context, _) => _bindData(context),
        ),
        BlocListener<SettingsCubit, SettingsState>(
          listenWhen: (before, after) => before.settings != after.settings,
          listener: (context, _) => _bindPayments(context),
        ),
        BlocListener<RecipientsCubit, RecipientsState>(
          // Compare contents: the cubit emits a new list on every snapshot,
          // and comparing identity would re-bind forever.
          listenWhen: (before, after) => !listEquals(before.all, after.all),
          listener: (context, _) => _bindPayments(context),
        ),
      ],
      child: child,
    );
  }
}

/// The MaterialApp with the saved theme and language.
class _DailoMaterialApp extends StatelessWidget {
  const _DailoMaterialApp();

  @override
  Widget build(BuildContext context) {
    final status = context.select((AuthCubit cubit) => cubit.state.status);
    final settings = context.select(
      (SettingsCubit cubit) => cubit.state.settings,
    );
    return MaterialApp(
      // A new key for each sign-in state throws the whole navigator away and
      // builds a fresh one, so no earlier screen (Home, Settings...) can stay
      // underneath, not even offstage, after signing in or out.
      key: ValueKey(status),
      debugShowCheckedModeBanner: false,
      title: 'DailO',
      // Screens without the navy title band sit on the page colour, so the
      // clock and battery icons must contrast with it: dark icons on the
      // light theme, light icons on the dark theme. AppPage overrides this
      // with light icons over its navy band.
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: Theme.of(context).brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: child ?? const SizedBox.shrink(),
      ),
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
      locale: Locale(settings.language.code),
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: AppStrings.delegates,
      home: firstScreenFor(status),
      onGenerateRoute: onGenerateRoute,
    );
  }
}
