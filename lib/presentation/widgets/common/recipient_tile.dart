import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../domain/entities/recipient.dart';
import '../../../domain/logic/phone_number.dart';
import 'avatar.dart';

/// One saved recipient in a list: avatar, name, network and number.
class RecipientTile extends StatelessWidget {
  const RecipientTile({
    super.key,
    required this.recipient,
    this.onTap,
    this.trailing,
  });

  final Recipient recipient;
  final VoidCallback? onTap;

  /// Usually the three-dot menu.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      minVerticalPadding: 10,
      leading: Avatar.initials(recipient.displayName),
      title: Row(
        children: [
          Flexible(
            child: Text(
              recipient.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (recipient.isFavorite) ...[
            const SizedBox(width: 6),
            Icon(Icons.star, size: 16, color: context.palette.mutedText),
          ],
        ],
      ),
      subtitle: Text(
        '${recipient.network.label} · ${prettyPhone(recipient.phone)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: context.palette.mutedText),
      ),
      trailing: trailing,
    );
  }
}
