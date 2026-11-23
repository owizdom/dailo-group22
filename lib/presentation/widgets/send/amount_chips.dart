import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../core/keys.dart';
import '../../../core/theme.dart';

/// The quick amounts under the amount field: 500, 1,000, 5,000 and 10,000.
class AmountChips extends StatelessWidget {
  const AmountChips({super.key, required this.onPick});

  static const amounts = [500, 1000, 5000, 10000];

  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final amount in amounts) ...[
          if (amount != amounts.first) const SizedBox(width: 8),
          Expanded(
            child: TextButton(
              key: K.amountChip(amount),
              style: TextButton.styleFrom(
                backgroundColor: context.palette.field,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.fieldRadius),
                ),
              ),
              onPressed: () => onPick(amount),
              child: FittedBox(child: Text(formatNumber(amount))),
            ),
          ),
        ],
      ],
    );
  }
}
