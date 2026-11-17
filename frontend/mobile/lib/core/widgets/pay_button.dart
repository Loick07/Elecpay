import 'dart:async';

import 'package:flutter/material.dart';

import '../format/numbers.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.g.dart';
import 'app_button.dart';

/// Bouton « Payer 31 420 FCFA » (montant dans le libellé, charte). Partout où l'on paie : carte de
/// la facture urgente, détail d'une facture, feuille de paiement.
///
/// HORS LIGNE (règle validée le 16/11/2026) : désactivé, avec « Connexion nécessaire pour payer »
/// en dessous. Aucun paiement ne part sans réseau, aucun n'est mis en file d'attente.
class PayButton extends StatelessWidget {
  const PayButton({
    required this.amount,
    required this.online,
    required this.onPay,
    this.loadingLabel = 'Envoi de la demande…',
    super.key,
  });

  final int amount;

  /// `false` : la donnée affichée vient du cache (pas de réseau) → bouton désactivé.
  final bool online;
  final FutureOr<void> Function() onPay;
  final String loadingLabel;

  /// Texte affiché sous le bouton quand il n'y a pas de réseau.
  static const offlineHint = 'Connexion nécessaire pour payer';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final button = AppButton(
      label: 'Payer ${formatFcfa(amount)}',
      icon: AppIcons.securePay,
      loadingLabel: loadingLabel,
      onPressed: online ? onPay : null,
    );
    if (online) return button;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        button,
        const SizedBox(height: Space.s2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(AppIcons.offline, size: 16, color: c.inkMuted),
            const SizedBox(width: Space.s2),
            Flexible(
              child: Text(
                offlineHint,
                textAlign: TextAlign.center,
                style: AppText.bodySm.copyWith(color: c.inkMuted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
