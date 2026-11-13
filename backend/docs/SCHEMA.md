# Schéma de la base ElecPay (B1)

13 tables, MySQL 8.4, créées par 6 migrations Alembic (`backend/alembic/versions/`).
Conventions : `id` BIGINT auto-incrémenté ; `created_at` / `updated_at` en UTC (microsecondes) ;
montants en FCFA entiers ; énergie en Wh entiers ; prix en millièmes de FCFA ; taux en points de base.
Calculs de facture : voir [`FACTURE_E2C.md`](FACTURE_E2C.md).

## Relations

```mermaid
erDiagram
    users ||--o{ refresh_tokens : "sessions"
    users ||--o{ households : "possède (owner_id)"
    users ||--o{ household_members : "est membre"
    users ||--o{ household_members : "a invité (invited_by)"
    households ||--o{ household_members : "membres"
    households |o--o{ meters : "compteurs (null = détaché)"
    meters ||--o{ meter_readings : "relevés"
    meters ||--o{ bills : "factures"
    tariffs ||--o{ bills : "tarif appliqué"
    bills ||--|{ bill_lines : "lignes"
    bills ||--o{ payment_transactions : "tentatives de paiement"
    users ||--o{ payment_transactions : "payeur"
    payment_transactions ||--o| receipts : "reçu si réussie"
    users ||--o{ notifications : "destinataire"
    users |o--o{ audit_logs : "auteur (null = système)"
    refresh_tokens |o--o| refresh_tokens : "remplacé par"

    users {
        string phone UK "+242 + 9 chiffres"
        string email UK "facultatif"
        string role "client support admin super_admin"
        bool is_active
    }
    households {
        string name
        string city
        bigint owner_id FK "seule source du propriétaire"
    }
    household_members {
        string role "payer viewer"
        string status "invited active revoked"
    }
    meters {
        string reference UK "N° Branchement E2C"
        string customer_number "N° Client"
        int subscribed_power_va "3 kVA = 3000"
        string status "active suspended terminated"
    }
    meter_readings {
        datetime read_at
        bigint index_wh
        bigint consumption_wh
        bool is_anomaly "avec motif obligatoire"
    }
    tariffs {
        string code
        bigint price_per_kwh_milli "49,08 = 49080"
        int vat_rate_bp "18 % = 1800"
        date valid_from "périodes sans chevauchement"
    }
    bills {
        string reference UK
        date period_start
        int months_count "2 = bimestrielle"
        bigint amount_total "= HT + taxes + redevances"
        string status "unpaid pending_payment paid overdue cancelled"
    }
    bill_lines {
        string kind "energy fixed_fee audiovisual_fee vat additional_tax stamp"
        bigint amount
    }
    payment_transactions {
        string status "en_attente reussie echouee expiree"
        string idempotency_key UK
        bigint amount "= total de la facture"
        string provider "simulated mtn airtel (qui traite)"
        string operator "mtn airtel (choisi par l'abonné, B7)"
        datetime pin_entered_at "PIN saisi : n'expire plus (B7)"
    }
    receipts {
        string number UK "EP-2026-000123"
        string verification_code UK
    }
    notifications {
        string type
        json data_json
        datetime read_at "null = non lue"
    }
    audit_logs {
        string action "domaine.verbe"
        json before_json
        json after_json
    }
```

## Garde-fous assurés par la base

Ces règles tiennent même si un futur code est bogué ou si quelqu'un écrit du SQL à la main.

| Règle métier | Mécanisme |
|---|---|
| Rien n'est jamais supprimé en cascade | toutes les clés étrangères en `RESTRICT` |
| Montants et énergie entiers, jamais négatifs | type `StrictBigInteger` (refuse les float) + `CHECK >= 0` |
| Valeurs fixes (rôles, statuts, types) | `VARCHAR` + `CHECK ... IN (...)` |
| Un tarif : périodes sans chevauchement | triggers `trg_tariffs_no_overlap_*` |
| Facture jamais supprimée, contenu jamais modifié, figée une fois payée ou annulée | triggers `trg_bills_*`, `trg_bill_lines_*` |
| Une seule facture active par compteur et par période | colonne calculée `active_period_start` + unicité |
| Une seule transaction en attente, une seule réussie par facture | colonnes calculées `pending_bill_id` / `succeeded_bill_id` + unicité |
| Montant payé = total de la facture ; facture payée ou annulée non payable | trigger `trg_payment_transactions_insert` |
| Transaction terminée figée (aucun admin ne peut forcer un succès) ; opérateur, numéro, montant fixés à la création ; « PIN saisi » jamais effacé (B7) | trigger `trg_payment_transactions_update` |
| Reçu seulement pour un paiement réussi, jamais modifié (sauf ajout du PDF) | triggers `trg_receipts_*` |
| Journal d'audit jamais modifié ni supprimé | triggers `trg_audit_logs_*` |

Les triggers exigent l'option MySQL `log_bin_trust_function_creators=1`
(activée dans `docker-compose.yml` et dans la CI).

## Règles vérifiées par les services (pas exprimables en contraintes simples)

- le propriétaire d'un foyer n'est pas aussi membre de son propre foyer (B4) ;
- seul un payeur délégué actif ou le propriétaire peut payer les factures d'un foyer (B7) ;
- l'index d'un nouveau relevé ne descend pas sous le précédent, sinon relevé marqué en anomalie (B2 / B5) ;
- total d'une facture = somme de ses lignes (B2 / B6, testé) ;
- aucun mot de passe, jeton ou hash dans les journaux d'audit (B10 / B11).
