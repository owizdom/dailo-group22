import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../core/keys.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../domain/entities/transaction_record.dart';
import '../../../domain/logic/phone_number.dart';
import 'notice_box.dart';

/// Lists what to do inside the network's own menu, for when DailO could only
/// open the root menu and not fill in the details itself.
///
/// The steps are generic on purpose: they name no menu numbers, so they are
/// true on any network. The PIN is only ever typed in the network's dialog.
class UssdStepsNotice extends StatelessWidget {
  const UssdStepsNotice({
    super.key = K.ussdSteps,
    required this.type,
    required this.amount,
    this.phone,
  });

  /// What was attempted: a send, airtime or data.
  final TxType type;

  /// Whole francs.
  final int amount;

  /// The number to pay (send) or to buy airtime for. Null or empty means
  /// there is no number to enter.
  final String? phone;

  @override
  Widget build(BuildContext context) {
    final strings = context.s;
    final steps = _steps(strings);
    return NoticeBox(
      kind: NoticeKind.warning,
      icon: Icons.info_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.ussdStepsTitle,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < steps.length; i++) Text('${i + 1}. ${steps[i]}'),
        ],
      ),
    );
  }

  /// The step texts in order, without their numbers.
  List<String> _steps(AppStrings strings) {
    return switch (type) {
      TxType.send => [
        strings.ussdStepChooseSend,
        ..._numberStep(strings),
        strings.ussdStepEnter(formatNumber(amount)),
        strings.ussdStepCheckNameAndPin,
      ],
      TxType.airtime => [
        strings.ussdStepChooseAirtime,
        strings.ussdStepEnter(formatNumber(amount)),
        ..._numberStep(strings),
        strings.ussdStepPin,
      ],
      TxType.data => [
        strings.ussdStepChooseData,
        strings.ussdStepPickBundle(formatFrw(amount)),
        strings.ussdStepPin,
      ],
    };
  }

  /// One step for the number, or none when there is no number to enter.
  List<String> _numberStep(AppStrings strings) {
    final number = phone;
    if (number == null || number.isEmpty) return const [];
    return [strings.ussdStepEnter(prettyPhone(number))];
  }
}
