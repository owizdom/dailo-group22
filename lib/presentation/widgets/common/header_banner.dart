import 'package:flutter/material.dart';

import '../../../core/theme.dart';

/// The navy banner with flowing lines from the Figma design.
///
/// [HeaderBanner.card] is the rounded welcome card on Home and the sign-in
/// screens. [HeaderBanner.bar] is the full-width title band on every
/// other screen.
class HeaderBanner extends StatelessWidget {
  const HeaderBanner.card({super.key, required this.title, this.subtitle})
    : rounded = true,
      topInset = 0;

  const HeaderBanner.bar({super.key, required this.title, this.topInset = 0})
    : subtitle = null,
      rounded = false;

  final String title;
  final String? subtitle;
  final bool rounded;

  /// Extra space above the title, so the band can run under the status bar
  /// while the title stays below it.
  final double topInset;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(rounded ? AppSizes.cardRadius : 0);
    return Semantics(
      header: true,
      child: ClipRRect(
        borderRadius: radius,
        // Always as wide as the space it is given. Inside a Stack it would
        // otherwise shrink to the width of its text.
        child: SizedBox(
          width: double.infinity,
          child: CustomPaint(
            painter: const _WavePainter(),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                (rounded ? 36 : 22) + topInset,
                20,
                rounded ? 36 : 22,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: rounded ? 24 : 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle!,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the navy background and three soft ribbons with a bright edge.
/// Drawn in code so it stays sharp on every screen size.
class _WavePainter extends CustomPainter {
  const _WavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final area = Offset.zero & size;
    canvas.drawRect(area, Paint()..color = AppColors.navy);

    final ribbon = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.42
      ..color = const Color(0xFF0D0580);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = AppColors.navyBright;

    // Each ribbon is one S-curve crossing the banner at a different height.
    for (final start in const [-0.25, 0.35, 0.95]) {
      final path = Path()
        ..moveTo(-size.width * 0.1, size.height * (start + 0.55))
        ..cubicTo(
          size.width * 0.25,
          size.height * (start - 0.35),
          size.width * 0.55,
          size.height * (start + 1.05),
          size.width * 1.1,
          size.height * (start + 0.1),
        );
      canvas.drawPath(path, ribbon);
      canvas.drawPath(path.shift(Offset(0, -size.height * 0.21)), edge);
    }
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) => false;
}
