import 'package:flutter/material.dart';

import '../../../core/theme.dart';

enum NoticeKind { warning, success }

/// A tinted box for something the user should read before going on,
/// such as the fee band warning.
class NoticeBox extends StatelessWidget {
  const NoticeBox({
    super.key,
    required this.kind,
    required this.child,
    this.icon,
  });

  final NoticeKind kind;
  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final warning = kind == NoticeKind.warning;
    final fill = warning ? palette.warningFill : palette.successFill;
    final ink = warning ? palette.warningText : palette.successText;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppSizes.fieldRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon ?? (warning ? Icons.warning_amber : Icons.check_circle),
            color: ink,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DefaultTextStyle.merge(
              style: TextStyle(color: ink, height: 1.35),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
