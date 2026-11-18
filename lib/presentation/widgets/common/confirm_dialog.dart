import 'package:flutter/material.dart';

import '../../../core/keys.dart';
import '../../../core/l10n/app_strings.dart';

/// Asks the user to confirm before something that cannot be undone.
/// Returns true only when they tap the confirm button.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final answer = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final scheme = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        icon: Icon(Icons.delete_outline, color: scheme.error),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            key: K.confirmNo,
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.s.cancel),
          ),
          FilledButton(
            key: K.confirmYes,
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
              minimumSize: const Size(96, 48),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return answer ?? false;
}
