import 'package:flutter/material.dart';

import '../../../core/keys.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme.dart';
import '../../../domain/entities/recipient.dart';

/// What the three-dot menu can do to a recipient.
enum RecipientAction { edit, favorite, delete }

/// The three-dot menu at the end of a recipient row (Figma 10).
class RecipientMenu extends StatelessWidget {
  const RecipientMenu({
    super.key,
    required this.recipient,
    required this.onSelected,
  });

  final Recipient recipient;
  final ValueChanged<RecipientAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return PopupMenuButton<RecipientAction>(
      tooltip: s.recipientMenuLabel,
      onSelected: onSelected,
      itemBuilder: (context) => [
        _item(
          RecipientAction.edit,
          K.recipientEdit,
          Icons.edit_outlined,
          s.menuEdit,
        ),
        _item(
          RecipientAction.favorite,
          K.recipientFavorite,
          recipient.isFavorite ? Icons.star : Icons.star_border,
          recipient.isFavorite ? s.menuUnfavorite : s.menuFavorite,
        ),
        _item(
          RecipientAction.delete,
          K.recipientDelete,
          Icons.delete_outline,
          s.menuDelete,
          danger: true,
        ),
      ],
    );
  }

  PopupMenuItem<RecipientAction> _item(
    RecipientAction action,
    Key key,
    IconData icon,
    String label, {
    bool danger = false,
  }) {
    return PopupMenuItem(
      key: key,
      value: action,
      child: _MenuRow(icon: icon, label: label, danger: danger),
    );
  }
}

/// An icon and a label. Delete is drawn in the error colour, as in Figma 10.
class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.danger,
  });

  final IconData icon;
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? Theme.of(context).colorScheme.error
        : context.palette.onSecondaryButton;
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color),
          ),
        ),
      ],
    );
  }
}
