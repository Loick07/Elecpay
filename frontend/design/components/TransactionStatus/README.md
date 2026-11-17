# TransactionStatus

L'écran qui suit un paiement : il montre l'état réel de la transaction et la seule action utile.

- Quatre états, une seule action chacun : **En attente** (aucune action, référence affichée), **Réussi** (Voir le reçu), **Échoué** (motif précis + Réessayer), **Vérification en cours** (statut inconnu : interdiction explicite de repayer).
- L'écran interroge l'API toutes les 3 secondes en attente, puis bascule seul. Après 2 minutes sans réponse : état Vérification en cours.
- Pastille **80px** en couleur douce du statut (comme la maquette `Attente.dc.html`, entourée en attente d'un halo de 96px qui pulse, arrêté si les animations sont réduites), titre `h1`, texte `body` `ink-muted` (300px de large au plus).
- **Vérification en cours** : toujours une sortie qui ne paie rien (« Retour à l'accueil »), et l'état se met à jour tout seul dès que l'API répond.
- Réussite : vibration légère et montée du coche en 250 ms ; pas de confettis.
