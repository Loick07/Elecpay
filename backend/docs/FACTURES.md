# Factures — guide pour l'application mobile

Complète le contrat OpenAPI (`/docs`). Écrans concernés : « Mes factures » (maquette client 6),
« Détail de la facture » (7) et la carte « facture la plus urgente » de l'Accueil (5).
Routes préfixées par `/api/v1`, ouvertes à tous les membres du foyer (lecteurs compris).
Structure et calcul d'une facture E²C : `FACTURE_E2C.md`.

## Routes

| Usage | Route |
|---|---|
| Liste « Mes factures » + reste à payer | `GET /bills?status=&household_id=&meter_id=&year=&page=1&size=20` |
| Carte de l'Accueil (facture la plus urgente) | `GET /bills?status=to_pay&size=…` puis choisir la plus ancienne échéance |
| Détail : lignes, index, comparaison | `GET /bills/{id}` |
| Bouton « PDF » | `GET /bills/{id}/pdf` |

## Filtres de l'écran 6

| Onglet | Paramètre | Contenu |
|---|---|---|
| Toutes | *(aucun)* | toutes les factures **sauf les annulées** |
| À payer | `status=to_pay` | impayées, en retard **et** paiement en cours |
| En retard | `status=overdue` | en retard (y compris une impayée dont l'échéance vient de passer) |
| Payées | `status=paid` | payées |
| — | `status=pending_payment` | paiement Mobile Money en cours |
| — | `status=cancelled` | annulées (seulement si on les demande) |

Autres filtres, combinables : `household_id`, `meter_id` (un foyer ou compteur d'un autre → `404`),
`year` (année du **début** de la période : « Nov.-Déc. 2026 » est en 2026).
Tri : la période la plus récente d'abord. Pour grouper par mois, utiliser `period_start`.

## Reste à payer (`outstanding`)

Renvoyé avec chaque page de la liste : `amount` et `count` (impayées, en retard, en cours de paiement),
dont `overdue_amount` / `overdue_count`. Il suit `household_id` et `meter_id` mais **ignore `status`,
`year` et la pagination** : sans filtre, c'est le « Reste à payer tous foyers » de la maquette.

## Statut affiché

`status` est le statut **à afficher** : une facture impayée dont l'échéance est dépassée arrive en
`overdue` dès le lendemain de l'échéance, avec `days_overdue`, même si le relevé quotidien n'est pas
encore passé.

| `status` | Libellé | `can_pay` possible |
|---|---|---|
| `unpaid` | À payer | oui |
| `overdue` | En retard (+ `days_overdue` jours) | oui |
| `pending_payment` | Paiement en cours | **non** (jamais deux paiements à la fois) |
| `paid` | Payée (`paid_at`) | non |
| `cancelled` | Annulée (`cancelled_reason` dans le détail) | non |

**Bouton « Payer »** : l'afficher seulement si `can_pay` est vrai. Il faut être propriétaire ou
payeur délégué (`my_role` = `owner` ou `payer`) **et** que la facture soit à payer. Un lecteur
(`viewer`) voit la facture sans pouvoir la payer.

## Détail (`GET /bills/{id}`)

En plus des champs de la liste :
- index : `previous_index_wh` / `current_index_wh` (exacts) et `*_kwh` (affichage) ; `billed_power_va` ;
- compteur : `meter_contract_number` (N° Police), `meter_customer_number` (N° Client), `e2c_center` ;
- sous-totaux : `amount_ht`, `amount_tax` (TVA + C.A.), `amount_fees` (RAV + timbre) ;
- `lines` : les 6 lignes E²C dans l'ordre (`position`). Chaque ligne donne la valeur exacte en entiers
  (`quantity_milli`, `unit_price_milli`, `rate_bp`, `base_amount`) et la même valeur prête à afficher
  (`quantity`, `unit_price`, `rate_percent`). `amount` est le montant de la ligne (FCFA, tronqué) ;
  la somme des `amount` vaut toujours `amount_total` ;
- `tariff` : `is_assumption = true` → afficher que le tarif reste à confirmer ;
- `previous_bill` : la facture précédente **du même compteur** (non annulée) et les écarts en kWh, FCFA
  et % (`null` en % si la précédente vaut 0). `previous_bill` vaut `null` pour la première facture.
- une facture annulée reste consultable : `cancelled_at`, `cancelled_reason`.

## PDF (`GET /bills/{id}/pdf`)

`application/pdf`, `Content-Disposition: attachment; filename="facture-<numéro>.pdf"`, jamais mis en cache.
Même accès que le détail. Le PDF porte un bandeau **« Mode démo »** tant que les données sont simulées
et rappelle que **seule la facture E²C fait foi**. Pour l'ouvrir, envoyer le jeton comme pour les autres
routes, enregistrer le fichier, puis l'ouvrir ou le partager.

## Montants et énergie

- Montants en **FCFA entiers** (`amount_*`). Afficher avec un séparateur de milliers : « 40 384 FCFA ».
- Énergie : `consumption_wh` (exact) et `consumption_kwh` (3 décimales, affichage seulement).
- Les nombres décimaux (`*_kwh`, `quantity`, `unit_price`, `rate_percent`) servent **uniquement à
  l'affichage**. Les montants ne sont jamais des nombres décimaux.
- `source` : `simulated` en mode démo → badge « Mode démo ».

## D'où viennent les factures

Une facture est émise **le 3e jour après la fin de sa période** (8 h, heure de Brazzaville) par le relevé
quotidien, avec une échéance à 15 jours (hypothèses, voir `FACTURE_E2C.md`). Elle est bimestrielle comme
chez E²C. Son contenu ne change jamais ; seul son statut évolue (paiement en B7, annulation par
l'administration en B10). Une facture payée est entièrement figée.

## Codes d'erreur

| Code | Statut | Quand |
|---|---|---|
| `BILL_NOT_FOUND` | 404 | facture inexistante, d'un autre foyer, ou d'un compteur détaché |
| `METER_NOT_FOUND` | 404 | filtre `meter_id` sur un compteur inexistant ou d'un autre foyer |
| `HOUSEHOLD_NOT_FOUND` | 404 | filtre `household_id` sur un foyer inexistant ou d'un autre |
| `VALIDATION_ERROR` | 422 | `status` inconnu, `year` hors 2000–2100, pagination invalide |
| `UNAUTHORIZED` | 401 | pas connecté ou jeton expiré |
