import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/formatters.dart';
import '../../../core/keys.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme.dart';
import '../../../domain/logic/fee_table.dart';
import '../../cubits/send_money_cubit.dart';
import '../common/notice_box.dart';
import '../common/section_card.dart';

/// The live fee and total, and the fee band hint while there is one.
/// Rebuilds on every amount change.
class FeeSummary extends StatelessWidget {
  const FeeSummary({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.s;
    return BlocBuilder<SendMoneyCubit, SendMoneyState>(
      builder: (context, state) {
        final hint = state.hint;
        // Above the largest amount there is no fee to show. A dash, not
        // "0 Frw", so the row never reads like a free transfer.
        final overLimit = state.amount > maxAmount;
        return Column(
          children: [
            LabeledRow(
              label: strings.fee,
              value: overLimit
                  ? '—'
                  : state.feeKnown
                  ? formatFrw(state.fee)
                  : strings.feeUnknown,
              valueKey: K.amountFee,
            ),
            const Divider(),
            LabeledRow(
              label: strings.total,
              value: overLimit ? '—' : formatFrw(state.total),
              valueKey: K.amountTotal,
            ),
            if (hint != null) ...[
              const SizedBox(height: AppSizes.gap),
              _BandHintNotice(
                text: strings.feeHint(
                  formatFrw(hint.cheaperAmount),
                  formatFrw(hint.saving),
                ),
                applyLabel: strings.changeTo(formatFrw(hint.cheaperAmount)),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// The warning that a slightly smaller amount costs less in fees.
class _BandHintNotice extends StatelessWidget {
  const _BandHintNotice({required this.text, required this.applyLabel});

  final String text;
  final String applyLabel;

  @override
  Widget build(BuildContext context) {
    final ink = context.palette.warningText;
    return NoticeBox(
      key: K.amountHint,
      kind: NoticeKind.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text),
          TextButton(
            key: K.amountHintApply,
            style: TextButton.styleFrom(
              foregroundColor: ink,
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
            ),
            onPressed: context.read<SendMoneyCubit>().applyHint,
            child: Text(
              applyLabel,
              style: const TextStyle(decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }
}
