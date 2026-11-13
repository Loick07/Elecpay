# Reçus — guide pour l'application mobile

Complète le contrat OpenAPI (`/docs`). Écran concerné : « Reçu » (maquette client 10), atteint
depuis l'écran 9 quand le paiement réussit, depuis l'historique (12) ou depuis la notification.
Routes préfixées par `/api/v1`. **Mode démo : aucun débit réel** (`source: simulated`).

## Le reçu naît avec le succès

- Un reçu est créé **automatiquement**, au moment exact où le paiement est confirmé (même
  opération en base) : un paiement réussi a toujours son reçu ; un échec n'en a jamais.
- Sur l'écran 9, quand `step` passe à `succeeded`, la réponse de `GET /payments/{id}` contient
  `receipt_id` et `receipt_number` → ouvrir `GET /receipts/{receipt_id}`.
- La notification « Paiement réussi » dit « Reçu EP-2026-000124 disponible » et porte
  `data_json.receipt_id`.

## Routes

| Usage | Route | Connexion |
|---|---|---|
| Mes reçus (du plus récent au plus ancien) | `GET /receipts?household_id=&year=&page=1&size=20` | oui |
| Écran 10 | `GET /receipts/{id}` | oui |
| « Télécharger » / « Partager » | `GET /receipts/{id}/pdf` | oui |
| Vérification publique | `GET /receipts/verify/{code}` | **non** |

Qui voit un reçu : le payeur (même s'il a quitté le foyer depuis) et tous les membres du foyer de
la facture (lecteurs compris). Un reçu d'un autre foyer répond `404 RECEIPT_NOT_FOUND`.

## Écran 10

| Champ | Afficher |
|---|---|
| `number` | « Reçu EP-2026-000123 » |
| `amount` | montant payé (FCFA entiers, séparateur de milliers) |
| `bill_period_label`, `bill_reference` | « Facture Sept.-Oct. 2026 · N° … » |
| `household_name`, `meter_reference` | « Maison Mpita · 0412-8833 » |
| `payer_name` | « Payé par Grâce Ngoma » |
| `operator_label`, `phone_number` | « MTN MoMo · +242 06 *** ** 67 » — **toujours masqué**, même pour le payeur : un reçu est fait pour être partagé |
| `issued_at` | date et heure (afficher en heure de Brazzaville) |
| `transaction_reference` | « TX-00000042 » |
| `verification_code` | « 8F3K-2Q9M-7XHT » (déjà en groupes de 4) |
| `source` | `simulated` → badge « Mode démo » |

## Numéro et code de vérification

- Numéro `EP-AAAA-NNNNNN` : une suite par année d'émission (heure de Brazzaville).
- Code de vérification : 12 caractères, **sans caractères qu'on confond** (ni 0/O, ni 1/I/L),
  renvoyé déjà découpé (`8F3K-2Q9M-7XHT`). Il est imprévisible : c'est lui qui prouve le reçu.

## PDF

`application/pdf`, `Content-Disposition: attachment; filename="recu-EP-2026-000123.pdf"`, jamais mis
en cache. Contient : montant, détail, bandeau « Mode démo » si simulé, **QR code** et code de
vérification. Le QR code mène à `RECEIPT_VERIFY_URL/<code>` (réglage serveur ; aujourd'hui la route
de vérification de l'API, demain une page web publique). Pour « Partager » : télécharger le fichier
avec le jeton, puis l'ouvrir avec la feuille de partage du téléphone.

## Vérification publique (`GET /receipts/verify/{code}`)

- **Sans connexion.** Code accepté avec ou sans tirets, en majuscules ou minuscules, avec espaces.
- Réponse : `valid`, `number`, `issued_at`, `amount`, `bill_period_label`, `meter_reference`
  **partiellement masqué** (`0412-••33`), `demo`, `message`. **Ni nom, ni téléphone, ni foyer.**
- Code inconnu ou mal formé : `404 RECEIPT_CODE_UNKNOWN` (toujours la même réponse).
- 30 vérifications par adresse IP toutes les 15 minutes, puis `429` (`Retry-After`).

## Codes d'erreur

| Code | Statut | Quand |
|---|---|---|
| `RECEIPT_NOT_FOUND` | 404 | reçu inexistant ou d'un autre foyer |
| `HOUSEHOLD_NOT_FOUND` | 404 | filtre `household_id` sur un foyer d'un autre |
| `RECEIPT_CODE_UNKNOWN` | 404 | vérification publique : aucun reçu ne porte ce code |
| `TOO_MANY_ATTEMPTS` | 429 | trop de vérifications publiques depuis cette adresse |
| `VALIDATION_ERROR` | 422 | `year` hors 2000–2100, pagination invalide |
| `UNAUTHORIZED` | 401 | routes connectées : pas connecté ou jeton expiré |

## Côté serveur (pour mémoire)

Un reçu n'est **jamais modifié ni supprimé** (la base l'interdit) ; il n'existe que pour un
paiement réussi. Le PDF est généré à chaque demande, jamais stocké.
