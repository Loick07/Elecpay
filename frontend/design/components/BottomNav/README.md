# BottomNav

La barre de navigation flottante de l'application : Accueil, Factures, Payer, Conso, Compte.

- Verre (`glass` + flou, `radius-xl`, `shadow-float`), décollée de 12px des bords et du bas de l'écran (au-dessus de la zone système).
- Le bouton central **Payer** : disque `volt` de 56px, `shadow-volt`, surélevé de 14px. Il ouvre la feuille de paiement de la facture la plus urgente ; s'il n'y a rien à payer, il ouvre l'historique des paiements.
- Onglet actif : icône et libellé en `ink`, point `volt` dessous. Inactifs : `ink-muted`.
- Badge de notification (pastille `error`) seulement sur Factures quand une facture est en retard.
