import 'package:flutter/material.dart';

/// Fades [child] in while it slides up a little. It plays once, when the
/// widget is first built: the end value never changes, so later rebuilds
/// do not restart it. Larger [order] values take a little longer.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({super.key, this.order = 0, required this.child});

  final int order;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + 100 * order),
      curve: Curves.easeOut,
      builder: (context, progress, child) => Opacity(
        opacity: progress,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - progress)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
