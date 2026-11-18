import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.g.dart';

/// Ton d'un message de formulaire.
enum FormMessageTone { error, info }

/// Message au-dessus du bouton d'un formulaire : erreur générale (identifiants incorrects, trop de
/// tentatives, réseau…) ou information (code affiché en mode démo). Annoncé au lecteur d'écran dès
/// qu'il apparaît. Les erreurs d'UN champ, elles, s'affichent sous ce champ.
class FormMessage extends StatelessWidget {
  const FormMessage(this.text, {this.tone = FormMessageTone.error, this.reference, super.key});

  final String text;
  final FormMessageTone tone;

  /// Référence de la requête (`X-Request-ID`), en petit.
  final String? reference;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (background, iconColor, icon) = switch (tone) {
      FormMessageTone.error => (c.errorSoft, c.error, AppIcons.error),
      FormMessageTone.info => (c.currentSoft, c.currentText, AppIcons.info),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s3),
        decoration: BoxDecoration(
          color: background,
          borderRadius: const BorderRadius.all(Radius.circular(Radii.md)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcon(icon, size: 18, color: iconColor),
            const SizedBox(width: Space.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: AppText.bodySm.copyWith(
                      color: tone == FormMessageTone.error ? c.errorText : c.ink,
                    ),
                  ),
                  if (reference != null)
                    Text(
                      'Référence : $reference',
                      style: AppText.caption.copyWith(color: c.inkMuted),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
