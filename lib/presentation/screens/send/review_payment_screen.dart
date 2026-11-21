import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/formatters.dart';
import '../../../core/keys.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../domain/entities/recipient.dart';
import '../../../domain/logic/phone_number.dart';
import '../../cubits/send_money_cubit.dart';
import '../../widgets/common/app_page.dart';
import '../../widgets/common/avatar.dart';
import '../../widgets/common/buttons.dart';
import '../../widgets/common/notice_box.dart';
import '../../widgets/common/result_question.dart';
import '../../widgets/common/section_card.dart';

/// Figma 15. Name, amount, fee and total before the phone dials.
class ReviewPaymentScreen extends StatelessWidget {
  const ReviewPaymentScreen({super.key});

  /// Dials, and moves on to the result when the phone could dial.
  Future<void> _confirm(BuildContext context) async {
    final cubit = context.read<SendMoneyCubit>();
    await cubit.confirm();
    if (context.mounted && cubit.state.step == SendStep.awaitingResult) {
      Navigator.pushReplacementNamed(context, Routes.paymentResult);
    }
  }

  void _cancel(BuildContext context) {
    context.read<SendMoneyCubit>().start();
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _editAmount(BuildContext context) {
    context.read<SendMoneyCubit>().backToAmount();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.s;
    return AppPage(
      title: strings.reviewPayment,
      // The Back row is replaced by "Edit amount", which also resets the step.
      showBack: false,
      children: [
        BlocBuilder<SendMoneyCubit, SendMoneyState>(
          builder: (context, state) {
            final problem = state.launchProblem;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: K.reviewEdit,
                    onPressed: () => _editAmount(context),
                    icon: const Icon(Icons.arrow_back),
                    label: Text(strings.editAmount),
                  ),
                ),
                if (state.recipient != null)
                  _RecipientCard(recipient: state.recipient!),
                const SizedBox(height: AppSizes.gap),
                _DetailsCard(state: state),
                const SizedBox(height: AppSizes.gap),
                SectionCard(
                  child: Text(
                    strings.reviewNote,
                    style: TextStyle(color: context.palette.mutedText),
                  ),
                ),
                const SizedBox(height: AppSizes.gap),
                if (problem != null) ...[
                  LaunchProblemNotice(outcome: problem),
                  const SizedBox(height: AppSizes.gap),
                ],
                PrimaryButton(
                  key: K.reviewConfirm,
                  label: strings.confirmAndPin,
                  busy: state.busy,
                  onPressed: () => _confirm(context),
                ),
                const SizedBox(height: AppSizes.gap),
                SecondaryButton(
                  key: K.reviewCancel,
                  label: strings.cancel,
                  onPressed: state.busy ? null : () => _cancel(context),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// The payee in the middle of a card, with the "check the name" notice.
class _RecipientCard extends StatelessWidget {
  const _RecipientCard({required this.recipient});

  final Recipient recipient;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        children: [
          Avatar.initials(recipient.displayName, size: 72),
          const SizedBox(height: AppSizes.gap),
          Text(
            recipient.displayName,
            key: K.reviewName,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '${recipient.network.label} · ${prettyPhone(recipient.phone)}',
            key: K.reviewPhone,
            style: TextStyle(color: context.palette.mutedText),
          ),
          const SizedBox(height: AppSizes.gap),
          NoticeBox(
            kind: NoticeKind.success,
            child: Text(context.s.checkNameNotice),
          ),
        ],
      ),
    );
  }
}

/// Amount, fee, total, the comment when there is one, and how it is sent.
class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.state});

  final SendMoneyState state;

  @override
  Widget build(BuildContext context) {
    final strings = context.s;
    return SectionCard(
      child: Column(
        children: [
          LabeledRow(
            label: strings.amount,
            value: formatFrw(state.amount),
            valueKey: K.reviewAmount,
          ),
          const Divider(),
          LabeledRow(
            label: strings.fee,
            value: state.feeKnown ? formatFrw(state.fee) : strings.feeUnknown,
            valueKey: K.reviewFee,
          ),
          const Divider(),
          LabeledRow(
            label: strings.totalDeducted,
            value: formatFrw(state.total),
            valueKey: K.reviewTotal,
          ),
          if (state.comment.isNotEmpty) ...[
            const Divider(),
            LabeledRow(label: strings.sendComment, value: state.comment),
          ],
          const Divider(),
          LabeledRow(label: strings.sendNetwork, value: strings.ussdNoData),
        ],
      ),
    );
  }
}
