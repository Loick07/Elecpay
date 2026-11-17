import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.g.dart';
import 'statuses.dart';

/// Badge de statut de la charte (`frontend/design/components/StatusBadge`) : TOUJOURS une couleur,
/// une icône et un mot. Hauteur 26, rayon `radius-sm`, fond doux, texte `*-text`, icône de la
/// couleur de base. Le libellé vient de la table des statuts (jamais inventé).
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final StatusStyle status;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: 'Statut : ${status.label}',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 26),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: Space.s1),
        decoration: BoxDecoration(
          color: status.background(c),
          borderRadius: const BorderRadius.all(Radius.circular(Radii.sm)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(status.icon, size: 14, color: status.iconColor(c)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                status.label,
                style: AppText.caption.copyWith(
                  color: status.foreground(c),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
