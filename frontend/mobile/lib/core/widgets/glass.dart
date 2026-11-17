import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.g.dart';

/// Rendu des surfaces « verre » : flou d'arrière-plan, ou fond OPAQUE sans flou.
///
/// Le flou coûte cher sur un petit téléphone (l'itel A05s) : le réglage « sans flou » sera comparé
/// au jalon de F3 (bouton sur la page Diagnostic, debug et profile).
enum GlassMode { blur, opaque }

class GlassModeNotifier extends Notifier<GlassMode> {
  @override
  GlassMode build() => GlassMode.blur;

  void set(GlassMode mode) => state = mode;
}

final glassModeProvider = NotifierProvider<GlassModeNotifier, GlassMode>(GlassModeNotifier.new);

/// Surface en verre de la charte. RÉSERVÉE à la barre du bas et aux feuilles du bas (un test
/// l'impose) : ailleurs, une surface opaque (`surface-1`, `surface-2`).
///
/// - flou : `BackdropFilter` (sigma 12) + couleur `glass` + bordure `glass-border` ;
/// - sans flou (réglage, ou contraste élevé demandé par le téléphone) : fond opaque `surface-2`,
///   même bordure, même forme.
class GlassSurface extends ConsumerWidget {
  const GlassSurface({
    required this.child,
    required this.borderRadius,
    this.shadows = const [],
    super.key,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final List<BoxShadow> shadows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final opaque =
        ref.watch(glassModeProvider) == GlassMode.opaque || MediaQuery.highContrastOf(context);
    final decorated = DecoratedBox(
      decoration: BoxDecoration(
        color: opaque ? c.surface2 : c.glass,
        borderRadius: borderRadius,
        border: Border.all(color: c.glassBorder),
      ),
      child: child,
    );
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: borderRadius, boxShadow: shadows),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: opaque
            ? decorated
            : BackdropFilter(
                filter: ImageFilter.blur(sigmaX: Blur.glassSigma, sigmaY: Blur.glassSigma),
                child: decorated,
              ),
      ),
    );
  }
}
