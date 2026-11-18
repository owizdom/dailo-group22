import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme.dart';
import '../../../domain/entities/transaction_record.dart';
import '../../../domain/logic/phone_number.dart';
import 'avatar.dart';

/// The icon the design uses for each kind of transaction.
IconData iconForTxType(TxType type) {
  return switch (type) {
    TxType.send => Icons.send_outlined,
    TxType.airtime => Icons.phone_android,
    TxType.data => Icons.cell_tower,
  };
}

/// One payment or purchase in a list: icon, what it was, who it went to,
/// the amount and its result.
class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.record, this.onTap});

  final TransactionRecord record;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final strings = context.s;
    final palette = context.palette;
    final who = record.counterpartyName.isEmpty
        ? prettyPhone(record.counterpartyPhone)
        : record.counterpartyName;
    final statusColor = switch (record.status) {
      TxStatus.success => palette.successText,
      TxStatus.failed => Theme.of(context).colorScheme.error,
      TxStatus.pending => palette.mutedText,
    };
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      minVerticalPadding: 10,
      leading: Avatar.icon(iconForTxType(record.type)),
      title: Text(
        strings.txType(record.type),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        who,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: palette.mutedText),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatFrw(record.amount),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            strings.txStatus(record.status),
            style: TextStyle(color: statusColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
