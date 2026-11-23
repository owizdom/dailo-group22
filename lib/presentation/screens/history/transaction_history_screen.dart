import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/keys.dart';
import '../../../core/l10n/app_strings.dart';
import '../../cubits/transactions_cubit.dart';
import '../../widgets/common/app_page.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/section_card.dart';
import '../../widgets/history/day_grouped_transactions.dart';
import '../../widgets/history/history_filters.dart';

/// Figma 13. Searchable, filterable list of every payment and purchase.
class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TransactionsCubit>();
    // PopScope fires for the system back button and for Navigator.pop, so
    // search and filter are cleared however the screen is left.
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) cubit.clearSearch();
      },
      child: AppPage(
        title: context.s.historyTitle,
        children: const [
          _SearchBox(),
          SizedBox(height: 12),
          HistoryFilters(),
          SizedBox(height: 12),
          _Results(),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(8),
      child: TextField(
        key: K.historySearch,
        onChanged: context.read<TransactionsCubit>().search,
        decoration: InputDecoration(
          hintText: context.s.historySearchHint,
          prefixIcon: const Icon(Icons.search),
        ),
      ),
    );
  }
}

/// The white card with the grouped list, or the reason it is empty.
class _Results extends StatelessWidget {
  const _Results();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionsCubit, TransactionsState>(
      builder: (context, state) {
        final records = state.visible;
        return SectionCard(
          child: records.isEmpty
              ? EmptyState(
                  key: K.historyEmpty,
                  icon: Icons.receipt_long_outlined,
                  message: context.s.historyEmpty,
                )
              : DayGroupedTransactions(records: records),
        );
      },
    );
  }
}