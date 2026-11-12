# DemoBadge

Le badge Mode démo signale que les données (consommation, factures, Mobile Money) sont simulées.

- Visible en permanence dans l'en-tête de l'application et imprimé sur chaque reçu tant que `DEMO_MODE=true`.
- Pointillés `current-text` : il informe sans alarmer.
- À côté, le badge **Estimation** (`warning`) marque toute valeur de consommation estimée.
- Il disparaît uniquement quand les vraies sources (E²C, MTN MoMo, Airtel Money) sont branchées.
