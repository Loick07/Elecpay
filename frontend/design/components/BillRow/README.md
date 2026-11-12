# BillRow

Une ligne de la liste des factures : période, compteur, montant et statut.

- Ligne de 64px minimum sur `surface-1`, séparateur `line` entre lignes, toute la ligne est cliquable (ouvre le détail).
- Gauche : icône facture dans un carré `surface-2`. Centre : période (`body-strong`), puis foyer + échéance ou date de paiement (`body-sm`, `ink-muted`). Droite : montant (`amount`) au-dessus du badge.
- Tri par défaut : en retard, puis à payer, puis le reste par date décroissante.
