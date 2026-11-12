# StatusBadge

Le badge affiche le statut d'une facture ou d'une transaction avec une couleur, une icône et un mot.

- Correspondance statut → libellé → couleur : voir la table « Statuts » de la charte. Ne jamais inventer un libellé.
- Hauteur 26px, rayon `radius-sm`, fond `*-soft`, texte de la couleur du statut.
- Le jaune `volt` n'est jamais utilisé pour un statut ; « Paiement en cours » utilise `warning` avec son icône.
- Statut `inconnu` (le prestataire n'a pas répondu) : « Vérification en cours », jamais « Échouée ».
