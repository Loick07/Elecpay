import 'dart:math' as math;
import 'dart:ui';

/// Contraste WCAG entre deux couleurs (1 à 21). Une couleur transparente est d'abord posée sur
/// `over` (le fond réel derrière elle).
double contrast(Color text, Color background, {Color? over}) {
  final bg = over == null ? background : Color.alphaBlend(background, over);
  final fg = Color.alphaBlend(text, bg);
  final la = fg.computeLuminance();
  final lb = bg.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}
