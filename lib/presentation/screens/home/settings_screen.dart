import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/keys.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme.dart';
import '../../../domain/entities/app_settings.dart';
import '../../../domain/entities/network.dart';
import '../../cubits/auth_cubit.dart';
import '../../cubits/settings_cubit.dart';
import '../../widgets/common/app_page.dart';
import '../../widgets/common/buttons.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../widgets/common/section_card.dart';
import '../../widgets/home/choice_row.dart';
import '../../widgets/home/profile_card.dart';

/// Profile, appearance, language, default network and sign out.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    final strings = context.s;
    final confirmed = await showConfirmDialog(
      context,
      title: strings.settingsSignOutTitle,
      message: strings.settingsSignOutMessage,
      confirmLabel: strings.settingsSignOut,
    );
    if (confirmed && context.mounted) context.read<AuthCubit>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.s;
    return AppPage(
      title: strings.settingsTitle,
      children: [
        // One list item, so every control is built even in landscape.
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ProfileCard(),
            const SizedBox(height: AppSizes.gap),
            const SectionCard(child: _Preferences()),
            const SizedBox(height: AppSizes.gap),
            SecondaryButton(
              key: K.settingsSignOut,
              icon: Icons.logout,
              label: strings.settingsSignOut,
              onPressed: () => _signOut(context),
            ),
          ],
        ),
      ],
    );
  }
}

/// The four saved preferences. Each control calls one cubit setter.
class _Preferences extends StatelessWidget {
  const _Preferences();

  @override
  Widget build(BuildContext context) {
    final strings = context.s;
    final cubit = context.read<SettingsCubit>();
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final settings = state.settings;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              key: K.settingsDark,
              contentPadding: EdgeInsets.zero,
              title: Text(strings.settingsDarkMode),
              value: settings.darkMode,
              onChanged: cubit.setDarkMode,
            ),
            SwitchListTile(
              key: K.settingsFeeWarning,
              contentPadding: EdgeInsets.zero,
              title: Text(strings.settingsFeeWarning),
              subtitle: Text(strings.settingsFeeWarningHelp),
              value: settings.feeWarning,
              onChanged: cubit.setFeeWarning,
            ),
            const SizedBox(height: AppSizes.gap),
            ChoiceRow<Network>(
              label: strings.settingsNetwork,
              options: Network.values,
              labels: [for (final network in Network.values) network.label],
              keys: const [K.settingsNetworkMtn, K.settingsNetworkAirtel],
              selected: settings.defaultNetwork,
              onSelected: cubit.setDefaultNetwork,
            ),
            const SizedBox(height: AppSizes.gap),
            ChoiceRow<AppLanguage>(
              label: strings.settingsLanguage,
              options: AppLanguage.values,
              labels: [
                for (final language in AppLanguage.values) language.label,
              ],
              keys: const [
                K.settingsLanguageEnglish,
                K.settingsLanguageKinyarwanda,
              ],
              selected: settings.language,
              onSelected: cubit.setLanguage,
            ),
          ],
        );
      },
    );
  }
}
