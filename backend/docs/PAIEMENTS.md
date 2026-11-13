# Paiements Mobile Money — guide pour l'application mobile

Complète le contrat OpenAPI (`/docs`). Écrans concernés : « Paiement » (maquette client 8),
« Confirmation en attente » (9) et « Historique des paiements » (12). Le reçu (10) : `RECUS.md`.
Routes préfixées par `/api/v1`. **Mode démo : aucun débit réel** (`source: simulated`, badge « Mode démo »).

## Le parcours

1. **Écran 8** — l'abonné choisit l'opérateur (MTN MoMo / Airtel Money) et le numéro à débiter
   (modifiable : on peut payer depuis le téléphone d'un proche). Le montant affiché est celui de
   la facture ; **il n'est jamais envoyé** à l'API.
2. `POST /payments` avec un en-tête `Idempotency-Key` → `201` et la transaction `en_attente`.
3. **Écran 9** — « Confirmez sur votre téléphone » : interroger `GET /payments/{id}` toutes les
   2 à 3 secondes et afficher `step` :

   | `step`        | Afficher                                         | Fin ? |
   |---------------|--------------------------------------------------|-------|
   | `requested`   | invite envoyée, saisissez votre code PIN          | non   |
   | `pin_entered` | code saisi, en attente de l'opérateur             | non   |
   | `succeeded`   | paiement réussi → ouvrir le reçu (`receipt_id`)    | oui   |
   | `failed`      | échec + `failure_reason`, bouton « Réessayer »     | oui   |
   | `expired`     | délai dépassé (PIN non saisi), bouton « Réessayer »| oui   |

   Afficher la `reference` (`TX-00000042`) à communiquer à l'assistance. Ne **jamais** proposer de
   repayer tant que la transaction est en attente.
4. **Écran 12** — `GET /payments` : l'historique.

## Clé d'idempotence (double clic, réseau coupé)

- `Idempotency-Key` est **obligatoire** : 8 à 64 caractères `A-Z a-z 0-9 - _` (un UUID convient).
- Générer **une clé par tentative**, au moment où l'abonné appuie sur « Payer », et la garder
  tant que la réponse n'est pas arrivée : si le réseau coupe, renvoyer **la même demande avec la
  même clé** → `200` et la même transaction, **jamais un second débit**.
- Après un échec ou une expiration, « Réessayer » = **nouvelle clé**.
- Même clé pour une autre demande (autre numéro, autre facture) → `409 IDEMPOTENCY_KEY_REUSED`.

## Qui peut payer, qui voit quoi

- Payer : le **titulaire** du foyer et les **payeurs délégués** (`can_pay` de la facture, B6).
  Un lecteur reçoit `403 PAYMENT_FORBIDDEN`.
- Voir un paiement et l'historique : le payeur, et tous les membres du foyer de la facture
  (lecteurs compris). `is_mine` : c'est moi qui ai payé ; sinon le numéro est **masqué**
  (`+242 05 *** ** 02`). `payer_name` permet d'afficher « payé par Grâce Ngoma ».

## Numéros et opérateurs

MTN = numéros en `06` ; Airtel = `05` et `04` (**hypothèse à confirmer**). Un fixe (`22`) ne paie
pas en Mobile Money. Proposer par défaut le numéro du compte et l'opérateur qui lui correspond.
Le numéro est normalisé par l'API (`06 123 45 67`, `+242061234567`… sont acceptés).

## Numéros de test (mode démo)

Seuls les numéros qui finissent par `00 00 0N` déclenchent un scénario ; **tout autre numéro
réussit** (PIN saisi après ~5 s, succès après ~10 s).

| Numéro         | Scénario                                                           |
|----------------|--------------------------------------------------------------------|
| `06 000 00 02` | PIN saisi, puis échec « Solde insuffisant »                         |
| `06 000 00 03` | échec « Paiement refusé par l'abonné »                              |
| `06 000 00 04` | PIN jamais saisi : expire au bout de 10 minutes                     |
| `06 000 00 05` | PIN saisi, débit jamais confirmé : reste en attente (cas « inconnu ») |
| `06 000 00 06` | prestataire injoignable : transaction créée directement `echouee`   |

(`05 000 00 0N` fonctionne de même avec Airtel.)

## Historique (`GET /payments`)

Du plus récent au plus ancien. Filtres combinables : `status` (`en_attente`, `reussie`,
`echouee`, `expiree`), `bill_id`, `household_id`, `month` (`AAAA-MM`, heure de Brazzaville) ;
pagination commune `page` / `size`. Pour grouper « par mois », utiliser `initiated_at`.
Chaque ligne : période de la facture, foyer, compteur, montant, opérateur, statut, motif
d'échec, qui a payé.

## États particuliers

- **Prestataire injoignable** au lancement : `201` avec `status = echouee` et le motif « Service de
  paiement injoignable : aucun débit n'a été demandé. » → proposer « Réessayer » (nouvelle clé).
- **PIN saisi mais pas de confirmation** : la transaction reste `en_attente` sans limite de temps
  (seule la réponse de l'opérateur, ou une relance par l'équipe ElecPay, la termine). Afficher
  « Paiement en cours de vérification » et la référence.
- **Paiement en cours sur la facture** (lancé ailleurs, par un autre membre…) :
  `409 PAYMENT_IN_PROGRESS`, avec `details.transaction_id` → ouvrir l'écran 9 sur cette transaction.

## Codes d'erreur

| Code | Statut | Quand |
|---|---|---|
| `VALIDATION_ERROR` | 422 | champ invalide, `amount` envoyé, `Idempotency-Key` absente ou mal formée |
| `OPERATOR_MISMATCH` | 422 | le numéro n'est pas de cet opérateur (`details.expected_operator`) |
| `PHONE_NOT_MOBILE_MONEY` | 422 | numéro fixe |
| `PAYMENT_FORBIDDEN` | 403 | lecteur du foyer |
| `BILL_NOT_FOUND` | 404 | facture inexistante ou d'un autre foyer |
| `PAYMENT_NOT_FOUND` | 404 | transaction inexistante ou d'un autre foyer |
| `BILL_ALREADY_PAID` | 409 | facture déjà payée |
| `BILL_NOT_PAYABLE` | 409 | facture annulée |
| `PAYMENT_IN_PROGRESS` | 409 | un paiement de cette facture attend déjà sa confirmation |
| `IDEMPOTENCY_KEY_REUSED` | 409 | clé déjà utilisée pour une autre demande |
| `TOO_MANY_ATTEMPTS` | 429 | plus de 10 demandes de paiement en 15 minutes (`Retry-After`) |

## Côté serveur (pour mémoire)

- Seul le prestataire confirme un paiement : webhook signé `POST /webhooks/payments/{provider}`
  (HMAC, `PAYMENT_WEBHOOK_SECRET`) ou suivi d'état. Aucune route, aucun administrateur ne peut
  passer une transaction à « réussie » ; la base l'interdit aussi.
- `python -m scripts.check_pending_payments` : à planifier toutes les minutes (expirations,
  paiements que personne ne regarde plus). `python -m scripts.send_payment_webhook <id>` : envoie
  un webhook signé à l'API locale (démo).
