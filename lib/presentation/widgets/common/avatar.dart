import 'package:flutter/material.dart';

import '../../../core/formatters.dart';

/// A navy circle with a person's initials, or an icon.
class Avatar extends StatelessWidget {
  const Avatar.initials(this.name, {super.key, this.size = 44}) : icon = null;

  const Avatar.icon(IconData this.icon, {super.key, this.size = 44})
    : name = null;

  final String? name;
  final IconData? icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.primary,
          shape: BoxShape.circle,
        ),
        child: icon != null
            ? Icon(icon, color: scheme.onPrimary, size: size * 0.5)
            : Text(
                initialsOf(name ?? ''),
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: size * 0.36,
                ),
              ),
      ),
    );
  }
}
