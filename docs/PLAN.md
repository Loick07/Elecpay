# ElecPay — Plan de construction

Document complet : « ElecPay — Plan directeur de construction » (Claude Docs).

## Architecture
- Backend commun FastAPI + MySQL 8 (Docker), monolithe modulaire
- Client : Flutter (Android / iOS)
- Admin : Next.js (navigateur)
- Intégrations derrière des interfaces : `PaymentProvider` (simulé → MTN / Airtel), `BillingSource` (simulé → E²C)
  sélectionnées par configuration (`PAYMENT_PROVIDER=simulated`)

## Règles métier non négociables
- Montants en FCFA entiers (BIGINT), jamais de float
- Une facture n'est jamais supprimée (annulation tracée) ; une facture payée est immuable
- Transaction : `en_attente` → `reussie` | `echouee` | `expiree` ; seul le prestataire confirme
- Clé d'idempotence sur chaque paiement ; verrou de la facture pendant le paiement
- Index de compteur jamais décroissant (sinon anomalie signalée)
- Tarifs datés ; pas de solde de portefeuille stocké
- Contrôles de rôle (Client, Payeur délégué, Support, Admin, Super admin) côté serveur + journal d'audit

## Phases
0. Socle : dépôt, Docker MySQL, CI, squelette FastAPI
1. Modèle de données + migrations + jeu de données simulé
2. API client (auth, compteurs, consommation, factures, paiements, reçus, notifications)
3. Application Flutter
4. Back-office Next.js
5. Design final, durcissement sécurité, déploiement VPS
