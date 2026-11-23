import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/formatters.dart';
import '../../../core/keys.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../domain/entities/transaction_record.dart';
import '../../cubits/send_money_cubit.dart';
import '../../cubits/transactions_cubit.dart';
import '../../widgets/common/app_page.dart';
import '../../widgets/common/buttons.dart';
import '../../widgets/common/notice_box.dart';
import '../../widgets/common/result_question.dart';
import '../../widgets/common/section_card.dart';
import '../../widgets/common/ussd_steps_notice.dart';
import '../../widgets/send/result_icon.dart';

/// Figma 16. Asks what the operator said, then shows the receipt.
class PaymentResultScreen extends StatelessWidget {
  const PaymentResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SendMoneyCubit>();
    return BlocBuilder<SendMoneyCubit, SendMoneyState>(
      // Done and Pay again reset the cubit just before they leave. Keeping
      // the last receipt on screen stops one frame of the wrong step.
      buildWhen: (before, after) =>
          after.step == SendStep.awaitingResult || after.step == SendStep.done,
      builder: (context, state) {
        final asking = state.step == SendStep.awaitingResult;
        return PopScope(
          // While the question is open, the system back button answers
          // "Not sure" instead of leaving.
          canPop: !asking,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) cubit.report(TxStatus.pending);
          },
          child: AppPage(
            title: _title(context, state),
            showBack: false,
            children: [
              if (asking)
                ResultQuestion(
                  onAnswer: cubit.report,
                  steps: state.usedRootMenu ? _stepsFor(state) : null,
                )
              else
                _Receipt(state: state),
            ],
          ),
        );
      },
    );
  }

  /// What to do in the network's menu, repeating the payment's details.
  Widget _stepsFor(SendMoneyState state) {
    return UssdStepsNotice(
      type: TxType.send,
      amount: state.amount,
      phone: state.recipient?.phone,
    );
  }

  String _title(BuildContext context, SendMoneyState state) {
    final strings = context.s;
    return switch (state.step) {
      SendStep.awaitingResult => strings.sendMoney,
      _ when state.result == TxStatus.success => strings.paymentSent,
      _ => strings.paymentResult,
    };
  }
}

/// The receipt: icon, amount, who was paid, the details and the two buttons.
class _Receipt extends StatelessWidget {
  const _Receipt({required this.state});

  final SendMoneyState state;

  void _done(BuildContext context) {
    context.read<SendMoneyCubit>().start();
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  /// Goes back to the Amount screen this payment came from, so Back from
  /// there still reaches Send Money. Opens a new Amount screen only when
  /// there is none underneath.
  void _payAgain(BuildContext context) {
    context.read<SendMoneyCubit>().payAgain();
    final navigator = Navigator.of(context);
    var amountBelow = false;
    navigator.popUntil((route) {
      amountBelow = route.settings.name == Routes.amount;
      return amountBelow || route.isFirst;
    });
    if (!amountBelow) navigator.pushNamed(Routes.amount);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.s;
    final status = state.result ?? TxStatus.pending;
    final name = state.recipient?.displayName ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: ResultIcon(status: status)),
        const SizedBox(height: 20),
        Text(
          formatFrw(state.amount),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          status == TxStatus.success
              ? strings.sentTo(name)
              : strings.paymentTo(name),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: context.palette.mutedText),
        ),
        const SizedBox(height: 20),
        _DetailsCard(state: state, status: status),
        const SizedBox(height: AppSizes.gap),
        NoticeBox(
          kind: NoticeKind.success,
          child: Text(strings.savedToHistory),
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          key: K.resultDone,
          label: strings.done,
          onPressed: () => _done(context),
        ),
        const SizedBox(height: AppSizes.gap),
        SecondaryButton(
          key: K.resultPayAgain,
          label: strings.sendPayAgain,
          onPressed: () => _payAgain(context),
        ),
      ],
    );
  }
}

/// Status, fee and the date the payment was saved.
class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.state, required this.status});

  final SendMoneyState state;
  final TxStatus status;

  @override
  Widget build(BuildContext context) {
    final strings = context.s;
    return SectionCard(
      child: Column(
        children: [
          LabeledRow(
            label: strings.sendStatus,
            value: strings.txStatus(status),
            valueKey: K.resultStatus,
          ),
          const Divider(),
          LabeledRow(
            label: strings.fee,
            value: state.feeKnown ? formatFrw(state.fee) : strings.feeUnknown,
          ),
          _SavedDateRow(recordId: state.recordId),
        ],
      ),
    );
  }
}

/// The date row, read from the saved transaction. It is left out until the
/// record shows up in the list.
class _SavedDateRow extends StatelessWidget {
  const _SavedDateRow({required this.recordId});

  final String? recordId;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<TransactionsCubit, TransactionsState, DateTime?>(
      selector: (state) {
        for (final record in state.all) {
          if (record.id == recordId) return record.createdAt;
        }
        return null;
      },
      builder: (context, savedAt) {
        if (savedAt == null) return const SizedBox.shrink();
        return Column(
          children: [
            const Divider(),
            LabeledRow(
              label: context.s.sendDate,
              value: formatDateTime(savedAt),
            ),
          ],
        );
      },
    );
  }
}
