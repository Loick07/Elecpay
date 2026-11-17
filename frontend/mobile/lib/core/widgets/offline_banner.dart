import 'package:flutter/material.dart';

import '../cache/cached_api.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.g.dart';

/// Bannière « hors connexion » de la charte : `warning-soft` EN HAUT de l'écran ; le contenu en
/// cache reste affiché dessous, avec sa date (texte de `CachedData.label`).
class OfflineBanner extends StatelessWidget {
  const OfflineBanner(this.label, {super.key});

  /// La bannière d'une donnée lue dans le cache, ou rien du tout si la donnée est fraîche.
  static Widget forData(Fetched<Object?> fetched) =>
      fetched is CachedData<Object?> ? OfflineBanner(fetched.label) : const SizedBox.shrink();

  /// « Hors connexion. Les données affichées datent du 12 nov. à 08:15. »
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s3),
        decoration: BoxDecoration(
          color: c.warningSoft,
          borderRadius: const BorderRadius.all(Radius.circular(Radii.md)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcon(AppIcons.offline, color: c.warning),
            const SizedBox(width: Space.s3),
            Expanded(
              child: Text(label, style: AppText.bodySm.copyWith(color: c.warningText)),
            ),
          ],
        ),
      ),
    );
  }
}
