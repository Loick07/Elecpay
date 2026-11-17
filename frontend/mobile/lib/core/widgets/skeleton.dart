import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../theme/app_theme.dart';

/// Squelette de chargement de la charte (`frontend/design/components/Skeleton`) : posé sur le VRAI
/// widget (rempli de données d'exemple), pour que la forme corresponde toujours à ce qui va s'afficher.
///
/// Formes `surface-3`, pulsation douce de 1,4 s ; arrêtée (formes fixes) si le téléphone demande de
/// réduire les animations. Préféré au spinner pour les listes et les cartes.
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({required this.loading, required this.child, super.key});

  /// `true` : le squelette remplace le contenu ; `false` : le contenu s'affiche normalement.
  final bool loading;
  final Widget child;

  /// Durée d'une pulsation (charte).
  static const pulse = Duration(milliseconds: 1400);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final still = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: loading ? 'Chargement' : null,
      child: Skeletonizer(
        enabled: loading,
        effect: still
            ? SolidColorEffect(color: c.surface3)
            : PulseEffect(from: c.surface3, to: c.surface2, duration: pulse),
        child: child,
      ),
    );
  }
}
