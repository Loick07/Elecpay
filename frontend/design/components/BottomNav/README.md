# BottomNav

La barre de navigation flottante de l'application : Accueil, Factures, Payer, Conso, Compte.

- Verre (`glass` + flou, `radius-xl`, `shadow-float`), décollée de 12px des bords et du bas de l'écran (au-dessus de la zone système). **Hauteur fixe 64px**.
- **5 entrées au même gabarit** (emplacement d'icône 24px, libellé, point) : les 5 libellés, « Payer » compris, sont **sur la même ligne**.
- Le bouton central **Payer** : disque `volt` de 56px, `shadow-volt`, **surélevé de 30px** (la moitié du disque dépasse du bord), entouré d'un **anneau de 4px couleur du fond** qui le détache de la barre ; **zone tactile 64 × 64** (le libellé « Payer » sous le disque est aussi touchable, 48px minimum). Il ouvre la feuille de paiement de la facture la plus urgente ; s'il n'y a rien à payer, l'application affiche aujourd'hui « Aucune facture à payer. » (écart avec cette fiche, signalé dans le rapport de M1).
- **Fondu** vers la couleur du fond derrière la barre (`.ep-nav-fade`) : le contenu qui défile s'efface au lieu d'apparaître sous la barre.
- Onglet actif : icône et libellé en `ink`, point `volt` dessous. Inactifs : `ink-muted`.
- Revue sur l'itel et validée par Loick pendant M1 (26/11/2026) ; implémentation : `frontend/mobile/lib/core/widgets/bottom_nav.dart`.
- Badge de notification (pastille `error`) seulement sur Factures quand une facture est en retard.
