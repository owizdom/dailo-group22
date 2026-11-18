import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/keys.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../domain/entities/recipient.dart';
import '../../cubits/recipients_cubit.dart';
import '../../cubits/send_money_cubit.dart';
import '../../widgets/common/app_page.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/buttons.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/recipient_tile.dart';
import '../../widgets/common/section_card.dart';
import '../../widgets/recipients/recipient_menu.dart';
import '../../widgets/recipients/recipients_message_listener.dart';

/// Figma 9, 10, 12. Searchable list with edit, favourite and delete.
class RecipientsScreen extends StatelessWidget {
  const RecipientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final cubit = context.read<RecipientsCubit>();
    // PopScope fires for the system back button and for Navigator.pop, so
    // the search is cleared however the screen is left.
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) cubit.clearSearch();
      },
      child: RecipientsMessageListener(
        child: AppPage(
          title: s.recipientsTitle,
          children: [
            AppTextField(
              fieldKey: K.recipientsSearch,
              label: s.search,
              hint: s.recipientsSearchHint,
              suffixIcon: const Icon(Icons.search),
              onChanged: context.read<RecipientsCubit>().search,
            ),
            const SizedBox(height: AppSizes.gap),
            PrimaryButton(
              key: K.recipientsAdd,
              icon: Icons.person_add_alt_1,
              label: s.addRecipient,
              onPressed: () =>
                  Navigator.pushNamed(context, Routes.editRecipient),
            ),
            const SizedBox(height: AppSizes.gap),
            const _RecipientList(),
          ],
        ),
      ),
    );
  }
}

/// The rows, or an empty message. Rebuilds when the list or search changes.
class _RecipientList extends StatelessWidget {
  const _RecipientList();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<RecipientsCubit, RecipientsState, List<Recipient>>(
      selector: (state) => state.recents,
      builder: (context, recipients) {
        if (recipients.isEmpty) {
          return SectionCard(
            child: EmptyState(
              key: K.recipientsEmpty,
              icon: Icons.people_outline,
              message: context.s.recipientsEmpty,
            ),
          );
        }
        return SectionCard(
          child: Column(
            key: K.recipientsList,
            children: [
              for (final recipient in recipients)
                _RecipientRow(recipient: recipient),
            ],
          ),
        );
      },
    );
  }
}

/// One recipient: tap to pay, three-dot menu for the other actions.
class _RecipientRow extends StatelessWidget {
  const _RecipientRow({required this.recipient});

  final Recipient recipient;

  @override
  Widget build(BuildContext context) {
    return RecipientTile(
      key: K.recipientTile(recipient.id),
      recipient: recipient,
      onTap: () => _pay(context),
      trailing: RecipientMenu(
        key: K.recipientMenu(recipient.id),
        recipient: recipient,
        onSelected: (action) => _run(context, action),
      ),
    );
  }

  void _pay(BuildContext context) {
    context.read<SendMoneyCubit>()
      ..start()
      ..chooseRecipient(recipient);
    Navigator.pushNamed(context, Routes.amount);
  }

  Future<void> _run(BuildContext context, RecipientAction action) async {
    final cubit = context.read<RecipientsCubit>();
    switch (action) {
      case RecipientAction.edit:
        await Navigator.pushNamed(
          context,
          Routes.editRecipient,
          arguments: recipient,
        );
      case RecipientAction.favorite:
        await cubit.toggleFavorite(recipient);
      case RecipientAction.delete:
        if (await _confirmDelete(context)) await cubit.delete(recipient.id);
    }
  }

  Future<bool> _confirmDelete(BuildContext context) {
    final s = context.s;
    return showConfirmDialog(
      context,
      title: s.deleteRecipientTitle(recipient.displayName),
      message: s.deleteRecipientMessage,
      confirmLabel: s.deleteRecipientConfirm,
    );
  }
}
