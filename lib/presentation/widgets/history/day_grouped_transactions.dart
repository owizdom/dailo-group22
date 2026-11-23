import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../core/keys.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../domain/entities/transaction_record.dart';
import '../common/transaction_tile.dart';

/// Transactions under Today, Yesterday and Earlier headings. A heading with
/// no records is left out. Tapping a tile opens that record's detail.
class DayGroupedTransactions extends StatelessWidget {
  const DayGroupedTransactions({super.key, required this.records});

  /// Newest first, as the cubit keeps them.
  final List<TransactionRecord> records;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Column(
      key: K.historyList,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final bucket in DayBucket.values) ..._group(context, bucket, now),
      ],
    );
  }

  List<Widget> _group(BuildContext context, DayBucket bucket, DateTime now) {
    final inBucket = records
        .where((record) => dayBucket(record.createdAt, now: now) == bucket)
        .toList();
    if (inBucket.isEmpty) return const [];
    return [
      _Heading(bucket),
      for (final record in inBucket)
        TransactionTile(
          key: K.transactionTile(record.id),
          record: record,
          onTap: () => Navigator.pushNamed(
            context,
            Routes.transactionDetail,
            arguments: record.id,
          ),
        ),
    ];
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.bucket);

  final DayBucket bucket;

  @override
  Widget build(BuildContext context) {
    final strings = context.s;
    final text = switch (bucket) {
      DayBucket.today => strings.today,
      DayBucket.yesterday => strings.yesterday,
      DayBucket.earlier => strings.earlier,
    };
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(text, style: TextStyle(color: context.palette.mutedText)),
    );
  }
}
