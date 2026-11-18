import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.g.dart';

/// Rendu des surfaces « verre » : fond OPAQUE sans flou (par défaut), ou flou d'arrière-plan.
///
/// SANS FLOU PAR DÉFAUT (décision de Loick au jalon F3, 18/11/2026) : mesuré sur l'itel A05s en
/// profile, l'ouverture de la feuille de paiement passe de 17 ms (sans flou) à 62 ms (flou) par image
/// au 90e centile (integration_test/glass_perf_test.dart). Le flou devient une option « Effet verre »
/// de l'écran Compte (F9) ; en attendant, interrupteur sur les pages Diagnostic et Catalogue.
enum GlassMode { blur, opaque }

class GlassModeNotifier extends Notifier<GlassMode> {
  @override
  GlassMode build() => GlassMode.opaque;

  void set(GlassMode mode) => state = mode;
}

final glassModeProvider = NotifierProvider<GlassModeNotifier, GlassMode>(GlassModeNotifier.new);

/// Surface en verre de la charte. RÉSERVÉE à la barre du bas et aux feuilles du bas (un test
/// l'impose) : ailleurs, une surface opaque (`surface-1`, `surface-2`).
///
/// - sans flou (par défaut, et toujours si le téléphone demande un contraste élevé) : fond opaque
///   `surface-2`, bordure `glass-border` ;
/// - flou (option « Effet verre ») : `BackdropFilter` (sigma 12) + couleur `glass`, même bordure,
///   même forme.
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
