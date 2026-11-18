import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/formatters.dart';
import '../../../core/keys.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../domain/entities/transaction_record.dart';
import '../../cubits/transactions_cubit.dart';
import '../common/empty_state.dart';
import '../common/section_card.dart';
import '../common/transaction_tile.dart';

/// The white "Recent Transactions" card on Home: the five newest records
/// under Today, Yesterday and Earlier headings, and a See More link.
class RecentTransactionsCard extends StatelessWidget {
  const RecentTransactionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.s;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.homeRecent,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                key: K.homeSeeMore,
                onPressed: () => Navigator.pushNamed(context, Routes.history),
                child: Text(strings.homeSeeMore),
              ),
            ],
          ),
          BlocBuilder<TransactionsCubit, TransactionsState>(
            builder: (context, state) => state.recent.isEmpty
                ? EmptyState(
                    key: K.homeRecentEmpty,
                    icon: Icons.receipt_long_outlined,
                    message: strings.homeNoRecent,
                  )
                : _RecentList(records: state.recent),
          ),
        ],
      ),
    );
  }
}

class _RecentList extends StatelessWidget {
  const _RecentList({required this.records});

  /// Newest first, as the cubit keeps them.
  final List<TransactionRecord> records;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Column(
      key: K.homeRecentList,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final bucket in DayBucket.values) ...[
          if (_inBucket(bucket, now).isNotEmpty) _DayHeading(bucket),
          for (final record in _inBucket(bucket, now))
            TransactionTile(
              key: K.transactionTile(record.id),
              record: record,
              onTap: () => Navigator.pushNamed(
                context,
                Routes.transactionDetail,
                arguments: record.id,
              ),
            ),
        ],
      ],
    );
  }

  List<TransactionRecord> _inBucket(DayBucket bucket, DateTime now) {
    return records
        .where((record) => dayBucket(record.createdAt, now: now) == bucket)
        .toList();
  }
}

/// "Today ———" with a thin line running to the edge of the card.
class _DayHeading extends StatelessWidget {
  const _DayHeading(this.bucket);

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
      child: Row(
        children: [
          Text(text, style: TextStyle(color: context.palette.mutedText)),
          const SizedBox(width: 12),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}
