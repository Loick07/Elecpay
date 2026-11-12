# ElecPay

Plateforme de gestion de la vie électrique des abonnés E²C (Congo-Brazzaville) :
suivi de consommation, factures détaillées, paiement Mobile Money, reçus numériques,
historique financier, multi-compteurs / foyers, paiement pour un proche, et back-office d'administration.

> Phase actuelle : **données simulées** (consommation, factures, Mobile Money). Seules les
> intégrations réelles E²C et MTN MoMo / Airtel Money restent à brancher, via des interfaces prévues pour ça.

## Structure du dépôt

| Dossier    | Contenu                                   | Technologie                         |
|------------|-------------------------------------------|-------------------------------------|
| `backend/` | API commune (client + admin), règles métier, simulateurs — plan : `backend/PLAN.md` | Python 3.14 · FastAPI · SQLAlchemy 2 · Alembic · MySQL 8 |
| `frontend/design/` | Charte UI/UX validée et maquettes | tokens, composants de référence |
| `frontend/mobile/` | Application client (16 écrans) | Flutter · Riverpod · GoRouter · Dio |
| `frontend/admin/` | Back-office web (11 écrans) | Next.js · TypeScript · Tailwind · shadcn/ui |

## Ordre de construction

1. **Backend** solide et testé (modèle de données → auth → compteurs/relevés → factures → paiements simulés → reçus → notifications → admin)
2. **Mobile** Flutter branché sur l'API
3. **Back-office** Next.js
4. Raffinement du design, puis intégrations réelles

Vue d'ensemble : [`PLAN.md`](PLAN.md) · Backend : [`backend/PLAN.md`](backend/PLAN.md) · Frontend : [`frontend/README.md`](frontend/README.md).
