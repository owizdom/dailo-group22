import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/formatters.dart';
import '../../../core/keys.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme.dart';
import '../../../domain/entities/transaction_record.dart';
import '../../../domain/logic/phone_number.dart';
import '../../cubits/transactions_cubit.dart';
import '../../widgets/common/app_page.dart';
import '../../widgets/common/avatar.dart';
import '../../widgets/common/buttons.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/section_card.dart';
import '../../widgets/common/snack.dart';
import '../../widgets/common/transaction_tile.dart';

/// One record in full, with actions to correct its result or delete it.
class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key, required this.recordId});

  final String recordId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TransactionsCubit, TransactionsState>(
      listenWhen: (before, after) => after.message != null,
      listener: (context, state) => _showMessage(context, state.message!),
      builder: (context, state) {
        final record = state.all.where((r) => r.id == recordId).firstOrNull;
        return AppPage(
          title: context.s.detailTitle,
          children: record == null
              ? [_NotFound()]
              : [
                  _Header(record),
                  const SizedBox(height: AppSizes.gap),
                  _Details(record),
                  const SizedBox(height: AppSizes.gap),
                  _Actions(record),
                ],
        );
      },
    );
  }

  void _showMessage(BuildContext context, TransactionsMessage message) {
    final strings = context.s;
    switch (message) {
      case TransactionsMessage.updated:
        showSnack(context, strings.recordUpdated);
      case TransactionsMessage.deleted:
        showSnack(context, strings.recordDeleted);
      case TransactionsMessage.failed:
        showSnack(context, strings.somethingWrong, error: true);
    }
  }
}

class _NotFound extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: EmptyState(
        icon: Icons.search_off,
        message: context.s.detailNotFound,
      ),
    );
  }
}

/// The icon, the kind of transaction and who it was for.
class _Header extends StatelessWidget {
  const _Header(this.record);

  final TransactionRecord record;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        children: [
          Avatar.icon(iconForTxType(record.type)),
          const SizedBox(width: AppSizes.gap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.s.txType(record.type),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (record.counterpartyName.isNotEmpty)
                  Text(
                    record.counterpartyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.palette.mutedText),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Label and value rows. Empty parts (no phone, no comment) are left out.
class _Details extends StatelessWidget {
  const _Details(this.record);

  final TransactionRecord record;

  @override
  Widget build(BuildContext context) {
    final strings = context.s;
    return SectionCard(
      child: Column(
        children: [
          LabeledRow(
            label: strings.detailStatus,
            value: strings.txStatus(record.status),
            valueKey: K.detailStatus,
          ),
          if (record.counterpartyPhone.isNotEmpty)
            LabeledRow(
              label: strings.phoneNumber,
              value: prettyPhone(record.counterpartyPhone),
            ),
          LabeledRow(label: strings.amount, value: formatFrw(record.amount)),
          LabeledRow(label: strings.fee, value: formatFrw(record.fee)),
          LabeledRow(label: strings.total, value: formatFrw(record.total)),
          if (record.comment.isNotEmpty)
            LabeledRow(
              label: strings.detailComment,
              value: record.comment,
              strong: false,
            ),
          LabeledRow(
            label: strings.detailDate,
            value: formatDateTime(record.createdAt),
          ),
          LabeledRow(label: strings.detailNetwork, value: record.network.label),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions(this.record);

  final TransactionRecord record;

  @override
  Widget build(BuildContext context) {
    final strings = context.s;
    final cubit = context.read<TransactionsCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (record.status != TxStatus.success) ...[
          PrimaryButton(
            key: K.detailMarkSuccess,
            label: strings.markConfirmed,
            icon: Icons.check,
            onPressed: () => cubit.setStatus(record.id, TxStatus.success),
          ),
          const SizedBox(height: AppSizes.gap),
        ],
        if (record.status != TxStatus.failed) ...[
          SecondaryButton(
            key: K.detailMarkFailed,
            label: strings.markFailed,
            icon: Icons.close,
            onPressed: () => cubit.setStatus(record.id, TxStatus.failed),
          ),
          const SizedBox(height: AppSizes.gap),
        ],
        OutlinedButton.icon(
          key: K.detailDelete,
          icon: const Icon(Icons.delete_outline),
          label: Text(strings.delete),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => _delete(context),
        ),
      ],
    );
  }

  /// Asks first. Only a Yes deletes the record and goes back to the list.
  Future<void> _delete(BuildContext context) async {
    final strings = context.s;
    final cubit = context.read<TransactionsCubit>();
    final navigator = Navigator.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: strings.deleteRecordTitle,
      message: strings.deleteRecordMessage,
      confirmLabel: strings.delete,
    );
    if (!confirmed) return;
    await cubit.delete(record.id);
    navigator.pop();
  }
}