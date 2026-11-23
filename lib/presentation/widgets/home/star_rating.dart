import 'package:flutter/material.dart';

import '../../../core/keys.dart';
import '../../../core/l10n/app_strings.dart';

/// Five star buttons. Tapping star N sets [rating] to N.
class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.rating});

  final ValueNotifier<int> rating;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return ValueListenableBuilder<int>(
      valueListenable: rating,
      builder: (context, chosen, _) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var star = 1; star <= 5; star++)
            IconButton(
              key: K.feedbackStar(star),
              tooltip: context.s.feedbackStarTooltip(star),
              color: color,
              iconSize: 32,
              icon: Icon(star <= chosen ? Icons.star : Icons.star_border),
              onPressed: () => rating.value = star,
            ),
        ],
      ),
    );
  }
}
