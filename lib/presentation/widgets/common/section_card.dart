import 'package:flutter/material.dart';

import '../../../core/theme.dart';

/// A white rounded card that groups related content, as in the Figma.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: padding, child: child),
    );
  }
}

/// One line of a summary: a label on the left and a value on the right.
/// Used for Amount, Transaction fee and Total.
class LabeledRow extends StatelessWidget {
  const LabeledRow({
    super.key,
    required this.label,
    required this.value,
    this.valueKey,
    this.strong = true,
  });

  final String label;
  final String value;

  /// Goes on the value Text so tests can read it.
  final Key? valueKey;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: AppSizes.gap),
          Flexible(
            child: Text(
              value,
              key: valueKey,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: strong ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
