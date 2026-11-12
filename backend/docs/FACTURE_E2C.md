# Structure d'une facture E²C (Basse Tension)

Référence pour le modèle de données (B1), le simulateur (B2) et le calcul des factures (B6).
Établie à partir d'une vraie facture E²C BT de la période juillet-août 2026 (centre de Pointe-Noire).
**Aucune donnée personnelle** de cette facture n'est reprise ici ni ailleurs dans le dépôt : seuls les montants.

## Identifiants

| Sur la facture | Dans ElecPay | Remarque |
|---|---|---|
| N° Branchement | `meters.reference` | identifie le point raccordé (unique) |
| N° Police | `meters.contract_number` | |
| N° Client | `meters.customer_number` | |
| Centre E²C | `meters.e2c_center` | ex. POINTE-NOIRE |
| Puissance souscrite | `meters.subscribed_power_va` | « 03 » = 3 kVA = 3000 VA |
| Numéro facture | `bills.reference` | 14 chiffres sur la facture E²C |
| Référence paiement par téléphone | *calculée* | dérivée du N° Client et du N° Branchement, non stockée |
| Période | `bills.period_start` / `period_end` / `months_count` | **bimestrielle** (« Juillet-Août », 2 mois) |
| Index ancien / nouveau | `bills.previous_index_wh` / `current_index_wh` | en kWh sur la facture, en Wh chez nous |

## Calcul (vérifié au franc près)

| Ligne | Formule | Exemple réel |
|---|---|---|
| Consommation | nouvel index − ancien index | 571 kWh |
| Montant consommation | kWh × prix unitaire, **tronqué** | 571 × 49,08 = 28 024,68 → **28 024** |
| Droit à la consommation | frais fixes × nombre de mois | **5 100** (2 mois) |
| **Total hors taxes** | consommation + droit à la consommation | **33 124** |
| T.V.A. | HT × 18 %, tronqué | 5 962,32 → **5 962** |
| C.A. (centimes additionnels) | **TVA** × 5 %, tronqué | 298,1 → **298** |
| RAV (redevance audiovisuelle, loi 16-2001) | montant fixe, **hors base TVA** | **1 000** |
| Timbre électronique | montant fixe | **0** |
| **Total à payer** | HT + RAV + TVA + C.A. + timbre | **40 384** |

Règles qui en découlent :
- **Troncature** (on coupe les décimales) à chaque ligne, jamais d'arrondi au plus proche.
- Les C.A. se calculent sur la TVA, pas sur le hors-taxes.
- La RAV et le timbre ne sont pas soumis à la TVA.
- Calcul en entiers : prix stocké en millièmes de FCFA (49,08 → 49 080), énergie en Wh, taux en points de base.
  Montant consommation = `consumption_wh × price_per_kwh_milli // 1 000 000` (division entière = troncature).

## Hypothèses à vérifier (5 à 10 vraies factures, puissances et périodes variées)

- **Droit à la consommation** : 2 550 FCFA par mois ? Ou dépendant de la puissance (850 FCFA/kVA/mois pour 3 kVA) ?
- **RAV** : 1 000 FCFA par facture, ou par période de 2 mois (500/mois) ?
- **Timbre électronique** : toujours 0 ?
- Le prix unitaire varie-t-il selon les tranches de consommation ou la puissance ?
- **Échéance** : la facture n'imprime **aucune date limite de paiement**. ElecPay suppose une émission
  3 jours après la fin de la période (observé : période close le 31/08, situation au 03/09) et une
  échéance 15 jours après l'émission (`BILL_ISSUE_DELAY_DAYS`, `BILL_DUE_DELAY_DAYS`, réglables).

Tant que ces points ne sont pas vérifiés, le tarif est stocké avec `is_assumption = true`.

## Retards de paiement (observé)

La facture de juillet-août 2026 mentionne une facture antérieure (émise début juin) toujours impayée au 03/09,
**sans pénalité ni majoration** sur la nouvelle facture. ElecPay ne calcule donc **aucun frais de retard** :
une facture dépassée passe simplement au statut `overdue`.

## Périodes de facturation

Périodes **calées sur le calendrier** (« Juillet-Août 2026 ») : janvier-février, mars-avril, mai-juin…
Durée réglable (`BILLING_PERIOD_MONTHS` : 1, 2, 3, 4, 6 ou 12 ; 2 par défaut, comme E²C).
Ancien index = relevé de minuit (heure du Congo) au début du premier jour ; nouvel index = relevé de minuit
au début du lendemain du dernier jour. Une période incomplète n'est jamais facturée.

## Impayés

La facture affiche les impayés antérieurs (« Situation du portefeuille ») : ce sont les factures précédentes
non payées. ElecPay les **calcule** (factures `unpaid` / `overdue`), sans jamais stocker de solde.

## Présentation dans l'application (phase Flutter)

Améliorations prévues par rapport au papier :
- total à payer et échéance en grand, en haut, avec le bouton Payer ;
- consommation en graphique (comparaison avec les périodes précédentes) ;
- détail du calcul dépliable, avec les termes expliqués (« Droit à la consommation », « C.A. », « RAV ») ;
- impayés antérieurs affichés à part, avec « tout payer » ;
- QR code de vérification du reçu, badge « mode démo » tant que les données sont simulées.
- Vue par période (mois, bimestre, trimestre, semestre, année) en **estimation**, en plus des factures bimestrielles.
