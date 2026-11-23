import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../domain/entities/transaction_record.dart';

/// The round icon on the receipt. It scales in once when the receipt opens.
class ResultIcon extends StatelessWidget {
  const ResultIcon({super.key, required this.status});

  final TxStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = context.palette;
    final (icon, background, foreground) = switch (status) {
      TxStatus.success => (
        Icons.check,
        palette.successText,
        palette.successFill,
      ),
      TxStatus.failed => (Icons.close, scheme.error, scheme.onError),
      TxStatus.pending => (
        Icons.help_outline,
        palette.mutedText,
        scheme.surface,
      ),
    };
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Icon(icon, color: foreground, size: 48),
      ),
    );
  }
}
