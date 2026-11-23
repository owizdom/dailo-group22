import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/keys.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme.dart';
import '../../cubits/auth_cubit.dart';
import '../../widgets/auth/auth_message_listener.dart';
import '../../widgets/auth/auth_submit_button.dart';
import '../../widgets/common/app_page.dart';
import '../../widgets/common/buttons.dart';
import '../../widgets/common/section_card.dart';

/// Replaces Figma 4. Tells the user to open the emailed link, with Resend and "I have verified".
class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final cubit = context.read<AuthCubit>();
    final email = context.select<AuthCubit, String>(
      (cubit) => cubit.state.session?.email ?? '',
    );
    return AuthMessageListener(
      child: AppPage(
        title: s.authVerifyTitle,
        // Nothing to go back to: the app shell decides this screen is shown.
        showBack: false,
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(s.authVerifyBody(email), textAlign: TextAlign.center),
                const SizedBox(height: AppSizes.gap),
                AuthSubmitButton(
                  key: K.verifyCheck,
                  label: s.authVerified,
                  onPressed: cubit.checkVerified,
                ),
                const SizedBox(height: AppSizes.gap),
                SecondaryButton(
                  key: K.verifyResend,
                  label: s.authResend,
                  onPressed: cubit.resendVerification,
                ),
                const SizedBox(height: 4),
                TextButton(
                  key: K.verifySignOut,
                  onPressed: cubit.signOut,
                  child: Text(s.authSignOut),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
