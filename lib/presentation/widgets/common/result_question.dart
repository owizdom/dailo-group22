import 'package:flutter/material.dart';

import '../../../core/keys.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme.dart';
import '../../../domain/entities/transaction_record.dart';
import '../../../domain/services/ussd_launcher.dart';
import 'buttons.dart';
import 'notice_box.dart';

/// Asked after the phone's USSD dialog closes. DailO cannot read the
/// operator's answer, so the user tells it what happened.
class ResultQuestion extends StatelessWidget {
  const ResultQuestion({
    super.key,
    required this.onAnswer,
    this.busy = false,
    this.steps,
  });

  /// Called with success, failed, or pending for "Not sure".
  final ValueChanged<TxStatus> onAnswer;
  final bool busy;

  /// Shown above the question, for example a `UssdStepsNotice` when only the
  /// root menu was dialled.
  final Widget? steps;

  @override
  Widget build(BuildContext context) {
    final strings = context.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (steps != null) ...[steps!, const SizedBox(height: 16)],
        Text(
          strings.resultQuestion,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          strings.resultQuestionHelp,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.palette.mutedText),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          key: K.resultYes,
          label: strings.resultYes,
          icon: Icons.check,
          busy: busy,
          onPressed: () => onAnswer(TxStatus.success),
        ),
        const SizedBox(height: AppSizes.gap),
        SecondaryButton(
          key: K.resultNo,
          label: strings.resultNo,
          icon: Icons.close,
          onPressed: busy ? null : () => onAnswer(TxStatus.failed),
        ),
        const SizedBox(height: AppSizes.gap),
        OutlinedButton(
          key: K.resultNotSure,
          onPressed: busy ? null : () => onAnswer(TxStatus.pending),
          child: Text(strings.resultNotSure),
        ),
      ],
    );
  }
}

/// Explains why the phone could not dial, and what to do about it.
class LaunchProblemNotice extends StatelessWidget {
  const LaunchProblemNotice({super.key, required this.outcome});

  final UssdOutcome outcome;

  @override
  Widget build(BuildContext context) {
    return NoticeBox(
      key: K.reviewProblem,
      kind: NoticeKind.warning,
      child: Text(context.s.launchProblem(outcome)),
    );
  }
}
