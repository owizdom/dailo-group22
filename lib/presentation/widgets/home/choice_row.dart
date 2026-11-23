import 'package:flutter/material.dart';

/// A label with one `ChoiceChip` per option. [keys] gives each chip the key
/// a test taps.
class ChoiceRow<T> extends StatelessWidget {
  const ChoiceRow({
    super.key,
    required this.label,
    required this.options,
    required this.labels,
    required this.keys,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final List<T> options;
  final List<String> labels;
  final List<Key> keys;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (var i = 0; i < options.length; i++)
              ChoiceChip(
                key: keys[i],
                label: Text(labels[i]),
                selected: options[i] == selected,
                selectedColor: scheme.primary,
                labelStyle: TextStyle(
                  color: options[i] == selected
                      ? scheme.onPrimary
                      : scheme.onSurface,
                ),
                checkmarkColor: scheme.onPrimary,
                onSelected: (_) => onSelected(options[i]),
              ),
          ],
        ),
      ],
    );
  }
}
