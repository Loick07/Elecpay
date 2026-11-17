import 'package:flutter/widgets.dart';

/// Mouvement de la charte : 150 ms pour une pression, 250 ms pour une apparition ou un changement
/// d'onglet, 400 ms pour le compteur du montant et la montée des barres. Courbe « ease-out », pas de
/// rebond sur les écrans d'argent.
abstract final class Motion {
  static const press = Duration(milliseconds: 150);
  static const appear = Duration(milliseconds: 250);
  static const emphasis = Duration(milliseconds: 400);
  static const curve = Curves.easeOut;

  /// Durée réelle : ZÉRO si le téléphone demande de réduire les animations (tout apparaît sans
  /// mouvement, règle de la charte).
  static Duration of(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}
