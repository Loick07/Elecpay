import 'package:flutter/material.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.g.dart';

/// Les documents acceptés à l'inscription. Textes PROVISOIRES (validé par Loick le 18/11/2026) :
/// les vrais textes juridiques arriveront plus tard, rédigés par une personne compétente.
enum LegalDocument {
  terms('/conditions', 'Conditions d’utilisation', [
    'Le service ElecPay : suivi de consommation, factures E²C, paiement Mobile Money, reçus.',
    'Votre compte : numéro de téléphone, mot de passe, sécurité de l’accès.',
    'Les paiements : rôle d’ElecPay, de MTN MoMo et d’Airtel Money, reçus et réclamations.',
    'Les foyers partagés et le paiement pour un proche.',
    'Les données simulées affichées en mode démo.',
    'Responsabilités, suspension d’un compte, modification des conditions.',
  ]),
  privacy('/confidentialite', 'Politique de confidentialité', [
    'Les données collectées : nom, téléphone, e-mail facultatif, compteurs, factures, paiements.',
    'Pourquoi elles sont utilisées, et combien de temps elles sont gardées.',
    'Qui peut les voir : vous, les membres de vos foyers, l’équipe ElecPay.',
    'Les données gardées sur votre téléphone (hors connexion) et leur effacement.',
    'Vos droits : accès, rectification, suppression de votre compte.',
    'Comment nous contacter.',
  ]);

  const LegalDocument(this.path, this.title, this.topics);

  final String path;
  final String title;

  /// Sujets que le texte définitif traitera.
  final List<String> topics;
}

/// Page d'un document juridique PROVISOIRE : bandeau « Document provisoire — en cours de
/// rédaction », puis la liste des sujets que le texte définitif traitera. Aucun engagement n'y est
/// présenté comme définitif.
class LegalScreen extends StatelessWidget {
  const LegalScreen(this.document, {super.key});

  final LegalDocument document;

  /// Bandeau affiché en tête de chaque document provisoire.
  static const provisional = 'Document provisoire — en cours de rédaction';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(title: Text(document.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Space.s4),
          children: [
            Container(
              padding: const EdgeInsets.all(Space.s4),
              decoration: BoxDecoration(
                color: c.warningSoft,
                borderRadius: const BorderRadius.all(Radius.circular(Radii.md)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppIcon(AppIcons.alert, color: c.warning),
                  const SizedBox(width: Space.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(provisional, style: AppText.bodyStrong.copyWith(color: c.warningText)),
                        const SizedBox(height: Space.s1),
                        Text(
                          'Le texte définitif sera publié avant la mise en service d’ElecPay. '
                          'Il traitera les sujets ci-dessous.',
                          style: AppText.bodySm.copyWith(color: c.ink),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.s6),
            for (final topic in document.topics)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.s3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 9, right: Space.s3),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(color: c.inkMuted, shape: BoxShape.circle),
                      ),
                    ),
                    Expanded(
                      child: Text(topic, style: AppText.body.copyWith(color: c.ink)),
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
