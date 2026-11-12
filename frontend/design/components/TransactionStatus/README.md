# TransactionStatus

L'écran qui suit un paiement : il montre l'état réel de la transaction et la seule action utile.

- Quatre états, une seule action chacun : **En attente** (aucune action, référence affichée), **Réussi** (Voir le reçu), **Échoué** (motif précis + Réessayer), **Vérification en cours** (statut inconnu : interdiction explicite de repayer).
- L'écran interroge l'API toutes les 3 secondes en attente, puis bascule seul. Après 2 minutes sans réponse : état Vérification en cours.
- Pastille 64px en couleur douce du statut, titre `h2`, texte `body` `ink-muted` (32 caractères de large au plus).
- Réussite : vibration légère et montée du coche en 250 ms ; pas de confettis.
