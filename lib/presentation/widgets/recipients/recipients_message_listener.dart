import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n/app_strings.dart';
import '../../cubits/recipients_cubit.dart';
import '../common/snack.dart';

/// Shows a snack for each one-off [RecipientsMessage].
///
/// Only the screen on top reacts, so two open screens never both show it.
class RecipientsMessageListener extends StatelessWidget {
  const RecipientsMessageListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<RecipientsCubit, RecipientsState>(
      listenWhen: (before, after) => after.message != null,
      listener: (context, state) {
        if (ModalRoute.of(context)?.isCurrent ?? true) {
          showSnack(
            context,
            _textFor(context, state.message!),
            error: state.message == RecipientsMessage.failed,
          );
        }
      },
      child: child,
    );
  }

  String _textFor(BuildContext context, RecipientsMessage message) {
    final s = context.s;
    return switch (message) {
      RecipientsMessage.added => s.recipientAdded,
      RecipientsMessage.updated => s.recipientUpdated,
      RecipientsMessage.deleted => s.recipientDeleted,
      RecipientsMessage.duplicate => s.recipientDuplicate,
      RecipientsMessage.failed => s.somethingWrong,
    };
  }
}
