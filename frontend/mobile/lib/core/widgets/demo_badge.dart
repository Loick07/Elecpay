import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.g.dart';

/// Badge « Mode démo » (composant `DemoBadge` de la charte) : les données sont simulées.
/// Pointillés `current-text` sur fond `current-soft` : il informe sans alarmer.
class DemoBadge extends StatelessWidget {
  const DemoBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: 'Mode démo : les données affichées sont simulées',
      child: CustomPaint(
        painter: _DashedBorderPainter(color: c.currentText),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: Space.s3, vertical: Space.s1),
          decoration: BoxDecoration(
            color: c.currentSoft,
            borderRadius: const BorderRadius.all(Radius.circular(Radii.full)),
          ),
          child: Text('MODE DÉMO', style: AppText.overline.copyWith(color: c.currentText)),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.height / 2));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()..addRRect(rect);
    for (final metric in path.computeMetrics()) {
      for (var distance = 0.0; distance < metric.length; distance += 6) {
        canvas.drawPath(metric.extractPath(distance, distance + 3), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => oldDelegate.color != color;
}
