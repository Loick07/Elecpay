# Notifications — guide pour l'application mobile

Complète le contrat OpenAPI (`/docs`). Écrans concernés : « Notifications » (maquette client 13),
la cloche de l'Accueil (5) et les interrupteurs « Me prévenir » de « Compte » (14).
Routes préfixées par `/api/v1`, toutes connectées. Push (FCM) : phase 2 ; aujourd'hui l'application
lit ses notifications.

## Routes

| Usage | Route |
|---|---|
| Écran 13 (liste) | `GET /notifications?unread_only=false&page=1&size=20` |
| Badge de la cloche | `GET /notifications/unread-count` → `{"unread_count": 3}` |
| Toucher une notification | `POST /notifications/{id}/read` |
| « Tout marquer comme lu » | `POST /notifications/read-all` → `{"marked": 3, "unread_count": 0}` |
| Lire les interrupteurs (écran 14) | `GET /me/notification-preferences` |
| Changer un interrupteur | `PATCH /me/notification-preferences` (seuls les champs envoyés changent) |

## Écran 13

- Ordre : de la plus récente à la plus ancienne (date de l'événement).
- `group` : `today` (« Aujourd'hui », depuis minuit), `this_week` (« Cette semaine », depuis lundi),
  `earlier` (« Plus tôt ») — heure de Brazzaville. Afficher un titre à chaque changement de groupe.
- `is_read` faux → mettre en avant. `unread_count` (dans la liste et sur la route du badge) :
  « 3 non lues » / « Tout est lu ».
- Une notification n'apparaît qu'à partir de son heure (ex. un rappel prévu à 8 h).
- Marquer comme lu est sans effet si c'est déjà fait. La notification de quelqu'un d'autre :
  `404 NOTIFICATION_NOT_FOUND`.

## Ouvrir le bon écran (`data`)

| `type` | Titre type | Écran à ouvrir avec `data` |
|---|---|---|
| `bill_issued` | Nouvelle facture | 7 (`bill_id`) |
| `bill_due_soon` | Échéance dans 5 jours / aujourd'hui | 7 (`bill_id`) |
| `bill_overdue` | Facture en retard / Rappel | 7 (`bill_id`) |
| `payment_succeeded` | Paiement réussi / Facture payée | 10 (`receipt_id`), sinon 7 (`bill_id`) |
| `payment_failed` | Paiement non abouti | 12 ou 9 (`transaction_id`) |
| `invitation_received` | Invitation | 15 (`household_id`) |
| `consumption_anomaly` | Relevé inhabituel | 11 (`meter_id`) |
| `high_consumption` | Consommation inhabituelle | 11 (`meter_id`, `day`) |
| `announcement` | Annonce de l'équipe (B10) | aucun écran particulier |

Prévoir qu'un champ de `data` puisse manquer (ou `data` vide) : ouvrir alors la liste concernée.

## Quand partent les alertes automatiques

| Alerte | Quand | Qui |
|---|---|---|
| Nouvelle facture | à l'émission | titulaire |
| Échéance proche | 5 jours avant (« dans N jours »), puis le jour même | titulaire + payeurs délégués |
| Facture en retard | le lendemain de l'échéance, puis tous les 7 jours | titulaire + payeurs délégués |
| Paiement réussi / échoué | à la réponse de l'opérateur | payeur ; le titulaire si un délégué a payé |
| Consommation inhabituelle | journée d'hier > moyenne des 30 jours précédents + 30 % | membres du foyer |
| Relevé inhabituel | relevé erroné (index en baisse…) | titulaire |

## Interrupteurs « Me prévenir » (écran 14)

| Champ | Libellé | Par défaut |
|---|---|---|
| `due_soon` | Échéances — 5 jours avant, puis le jour même | activé |
| `payments` | Paiements — réussis, échoués, reçus disponibles | activé |
| `high_consumption` | Consommation inhabituelle — un jour au-dessus de la moyenne de 30 % | **désactivé** |

- `PATCH` avec un seul champ, ex. `{"payments": false}` ; la réponse renvoie les trois valeurs.
- Une alerte coupée **n'est pas créée** (elle ne réapparaît pas si on la réactive plus tard).
- Couper « Paiements » ne change rien au paiement lui-même : le reçu est créé, et le titulaire est
  quand même prévenu si c'est un délégué qui a payé.
- Toujours envoyés (pas d'interrupteur) : nouvelle facture, retard, invitation, relevé inhabituel,
  annonces de l'équipe.

## Codes d'erreur

| Code | Statut | Quand |
|---|---|---|
| `NOTIFICATION_NOT_FOUND` | 404 | notification inexistante, pas encore visible, ou à quelqu'un d'autre |
| `VALIDATION_ERROR` | 422 | `PATCH` vide, valeur non booléenne, interrupteur inconnu ; pagination invalide |
| `UNAUTHORIZED` | 401 | pas connecté ou jeton expiré |

## Côté serveur (pour mémoire)

`python -m scripts.daily_alerts` (chaque matin en production) : passage en retard, rappels de retard
et d'échéance, consommation inhabituelle. En démo, `scripts.daily_tick` le fait déjà.
