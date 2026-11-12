# Button

Le bouton déclenche une action ; son libellé dit exactement laquelle.

- **primary** (`volt` / `on-volt`) : l'action principale de l'écran, une seule par écran. Sur les écrans d'argent, le libellé contient le montant : « Payer 12 500 FCFA ».
- **secondary** (verre) : action utile mais secondaire (Télécharger le reçu, Partager).
- **ghost** (`volt-text`) : lien d'action dans une carte (Voir le détail).
- **danger** (`error-soft` / `error-text`) : action destructive, surtout dans le back-office ; elle ouvre une confirmation avec motif.
- Hauteur minimale 48px, rayon `radius-md`, police `body-strong`.
- **Chargement** : le bouton garde sa taille, un spinner remplace l'icône et le libellé décrit ce qui se passe ; il n'est plus cliquable (protection contre le double paiement).
- **Désactivé** : opacité 45 %, uniquement quand une condition visible manque (numéro incomplet).
