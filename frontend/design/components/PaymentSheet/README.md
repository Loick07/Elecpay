# PaymentSheet

La feuille du bas où l'on choisit le moyen de paiement et le numéro, puis où l'on lance le paiement.

- Feuille en verre (`radius-xl` en haut, `shadow-float`), poignée en haut. S'ouvre depuis le bouton Payer central ou le détail d'une facture.
- Rappel du montant en `amount-hero` : le montant vient de la facture et n'est jamais saisi.
- Moyens de paiement en choix exclusifs ; le choix actif prend le contour `volt` et le fond `volt-soft`. Opérateurs écrits en toutes lettres.
- Numéro prérempli avec celui du compte, modifiable (paiement pour un proche ou depuis le numéro d'un proche).
- Au clic : bouton en chargement, puis écran TransactionStatus. Une seule demande part, même si l'utilisateur tape deux fois.
