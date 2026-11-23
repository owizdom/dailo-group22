import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/keys.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../domain/entities/transaction_record.dart';
import '../../cubits/transactions_cubit.dart';

/// The All / Send / Airtime / Data chips above the history list.
class HistoryFilters extends StatelessWidget {
  const HistoryFilters({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.s;
    // A null type means "show every type".
    final choices = <(String, String, TxType?)>[
      ('all', strings.filterAll, null),
      ('send', strings.filterSend, TxType.send),
      ('airtime', strings.filterAirtime, TxType.airtime),
      ('data', strings.filterData, TxType.data),
    ];
    return BlocBuilder<TransactionsCubit, TransactionsState>(
      buildWhen: (before, after) => before.filter != after.filter,
      builder: (context, state) {
        return Wrap(
          spacing: 8,
          children: [
            for (final (id, label, type) in choices)
              ChoiceChip(
                key: K.historyFilter(id),
                label: Text(label),
                selected: state.filter == type,
                onSelected: (_) =>
                    context.read<TransactionsCubit>().setFilter(type),
              ),
          ],
        );
      },
    );
  }
}
