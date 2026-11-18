import 'package:flutter/material.dart';

/// "Don't have an account?" with a link button next to it.
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.prompt,
    required this.linkLabel,
    required this.linkKey,
    required this.onPressed,
  });

  final String prompt;
  final String linkLabel;
  final Key linkKey;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // Wrap lets the link drop to a second line on a narrow phone.
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(prompt, style: const TextStyle(fontWeight: FontWeight.w600)),
        TextButton(key: linkKey, onPressed: onPressed, child: Text(linkLabel)),
      ],
    );
  }
}
