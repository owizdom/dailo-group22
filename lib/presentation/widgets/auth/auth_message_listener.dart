import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n/app_strings.dart';
import '../../cubits/auth_cubit.dart';
import '../common/snack.dart';

/// Shows a snack for each one-off [AuthState.error] and [AuthState.notice].
///
/// Only the screen on top reacts, so two open screens never both show it.
class AuthMessageListener extends StatelessWidget {
  const AuthMessageListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (before, after) =>
          after.error != null || after.notice != null,
      listener: (context, state) {
        if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
        final error = state.error;
        if (error != null) {
          showSnack(context, context.s.authError(error), error: true);
        } else {
          showSnack(context, _noticeText(context, state.notice!));
        }
      },
      child: child,
    );
  }

  String _noticeText(BuildContext context, AuthNotice notice) {
    final s = context.s;
    return switch (notice) {
      AuthNotice.verificationSent => s.authVerificationSent,
      AuthNotice.resetSent => s.authResetSent,
      AuthNotice.stillUnverified => s.authStillUnverified,
    };
  }
}
