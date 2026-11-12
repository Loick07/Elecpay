# Consommation — guide pour l'application mobile

Complète le contrat OpenAPI (`/docs`). Écran concerné : « Consommation » (maquette client 11).
Routes préfixées par `/api/v1`, ouvertes à tous les membres du foyer (lecteurs compris).
Un compteur d'un autre foyer répond `404 METER_NOT_FOUND`.

## Règle d'or : jamais « temps réel »

Les valeurs viennent de **relevés journaliers** (un index à minuit, heure de Brazzaville).
- `measured_until` : dernière journée relevée (en général hier). L'afficher : « Relevé jusqu'au 11/11 ».
- `source` : `simulated` en mode démo → afficher le badge « Mode démo ».
- `tariff_is_assumption` : le tarif n'est pas encore vérifié → les coûts sont indicatifs.
- Chaque période porte `is_estimated` (valeur estimée ou anomalie), `has_anomaly`, `is_partial`
  (journées manquantes) et `is_current` (période en cours). L'onglet « Direct » est prévu en phase 2.

## Routes

| Onglet / usage | Route |
|---|---|
| Année : 12 barres mensuelles + comparaison an dernier | `GET /meters/{id}/consumption` (défaut : `granularity=month`, année en cours) |
| Mois : une barre par jour | `GET /meters/{id}/consumption?granularity=day` (défaut : mois en cours) |
| Semaine : 7 barres + comparaison semaine précédente | `…?granularity=day&from=<lundi>&to=<dimanche>` |
| Semaine par semaine | `…?granularity=week&from=…&to=…` |
| Vue par période (bimestre, trimestre, semestre, année) | `…?granularity=bimester\|quarter\|semester\|year` |
| Accueil / onglet Mois : ce mois, mois dernier, estimation | `GET /meters/{id}/consumption/summary` |
| Jour : index, moyenne du même jour, classement | `GET /meters/{id}/consumption/days/{AAAA-MM-JJ}` |
| Relevés bruts (paginés) | `GET /meters/{id}/readings?page=1&size=20&from=…&to=…` |

Paramètres de la série : `granularity` (`day`, `week`, `month`, `bimester`, `quarter`, `semester`, `year`),
`from` / `to` (dates incluses, alignées sur les périodes), `compare` (`last_year` ou `previous`).
Plages maximales : 400 jours en vue jour, ~3 ans en semaines, ~10 ans au-delà (`400 INVALID_RANGE`).

## Énergie et coûts

- Énergie : `consumption_wh` (entier, exact) et `consumption_kwh` (3 décimales, pour l'affichage).
- `energy_cost` : **énergie seule** (kWh × tarif en vigueur chaque jour) — c'est le coût affiché par la maquette.
- `estimated_total` : **facture estimée complète** (droit à la consommation, TVA, C.A., RAV et timbre au
  prorata), à partir du mois et jusqu'à 12 mois. Toujours afficher « estimation » : la facture officielle
  est celle d'E²C (bimestrielle). Deux mois estimés séparément peuvent différer de 1 à quelques FCFA de la
  facture bimestrielle (troncature ligne par ligne).
- Montants en FCFA entiers ; `null` si aucun tarif n'est connu pour la période.

## Résumé (`/summary`)

- `this_month` : du 1er à la dernière journée relevée ; moyenne par jour ; `highest_day`.
- `month_end_estimate` : consommation relevée + moyenne journalière × `remaining_days`, en kWh, énergie et
  facture estimée. `basis` = `current_month`, ou `last_7_days` le 1er du mois (rien encore relevé).
- `last_month` : le mois précédent complet.
- `variation_percent` : ce mois comparé au mois dernier **sur les mêmes jours** (du 1er au N).

## Comparaisons

Toujours sur les **mêmes journées relevées** : un mois en cours n'est jamais comparé à un mois complet.
- `last_year` (défaut pour mois et au-delà) : mêmes dates un an plus tôt.
- `previous` (défaut pour jour et semaine) : la plage précédente de même durée.
`variation_percent` vaut `null` si la référence est vide.

## Pagination commune

`?page=1&size=20` (taille ≤ 100) → `{"items": [...], "total": 132, "page": 1, "size": 20}`.
Une page au-delà de la fin renvoie `items: []` (pas d'erreur). Même format pour les factures et paiements.

## Codes d'erreur

| Code | Statut | Quand |
|---|---|---|
| `METER_NOT_FOUND` | 404 | compteur inexistant ou d'un autre foyer |
| `INVALID_RANGE` | 400 | `to` avant `from`, ou plage trop longue (`details.max_days`) |
| `CONSUMPTION_DAY_NOT_FOUND` | 404 | journée non relevée (aujourd'hui, avant installation, futur) |
| `VALIDATION_ERROR` | 422 | paramètre invalide (granularité, date, page…) |
