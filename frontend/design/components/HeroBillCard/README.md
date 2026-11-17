# HeroBillCard

La carte héros du tableau de bord montre la facture la plus urgente et permet de la payer.

- Carte **opaque** (`surface-1`, `radius-xl`, `shadow-card`) : depuis le 17/11/2026, le verre est réservé à la barre du bas et aux feuilles (voir CHARTE.md). Elle reste posée sur un fond `bg` éclairé de deux halos doux (bleu en haut à droite, jaune en bas à gauche), dessinés par l'écran d'accueil.
- Ordre de lecture : période → **montant** (`amount-hero`) → échéance → compteur et consommation → bouton.
- Le compte à rebours (« dans 13 jours ») passe en `warning` à 5 jours, en `error` après l'échéance (badge En retard).
- Plusieurs foyers : la carte montre la facture la plus urgente, tous foyers confondus, avec le nom du foyer.
- Aucune facture à payer : la carte affiche « Tout est payé » en `success` et la date de la prochaine facture prévue.
