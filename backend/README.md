# ElecPay — backend

API commune (application client + back-office) : Python 3.14, FastAPI, SQLAlchemy 2, Alembic, MySQL 8.4.
Feuille de route : [`PLAN.md`](PLAN.md) (étapes B0 → B11). Le backend se termine (B11) avant de commencer l'application Flutter.

## Première installation (Windows)

Prérequis : Python 3.14, Docker Desktop (ouvert).

```powershell
# depuis la racine du dépôt : démarrer MySQL (port 3307)
docker compose up -d

# depuis backend/
cd backend
python -m venv .venv
.venv\Scripts\python -m pip install -r requirements-dev.txt
copy .env.example .env          # puis adapter si besoin (jamais commité)
.venv\Scripts\alembic upgrade head
```

## Au quotidien (depuis `backend/`)

| Action | Commande |
|---|---|
| Lancer l'API | `.venv\Scripts\python -m uvicorn app.main:app --reload` → http://127.0.0.1:8000/docs |
| Tests | `.venv\Scripts\python -m pytest` |
| Qualité | `.venv\Scripts\ruff check .` et `.venv\Scripts\ruff format .` |
| Nouvelle migration | `.venv\Scripts\alembic revision --autogenerate -m "description"` |
| Appliquer les migrations | `.venv\Scripts\alembic upgrade head` |
| **Recréer la base de démo** | `.venv\Scripts\python -m scripts.reset_db` puis `.venv\Scripts\python -m scripts.seed` |
| Relevé quotidien (faire « vivre » la démo) | `.venv\Scripts\python -m scripts.daily_tick` (une fois par jour ; `--today AAAA-MM-JJ` pour simuler une date) |

Données de démo : 18 mois de relevés, factures, paiements et reçus **simulés**, personnes fictives.
Tous les comptes de démo ont le mot de passe `Demo2026!` (liste affichée par `scripts.seed`).
`reset_db` et `seed` refusent de tourner avec `APP_ENV=production`.

Les tests utilisent la base `elecpay_test` (créée par `docker/mysql/init/`), jamais la base de développement.
La CI GitHub Actions (`.github/workflows/backend.yml`) lance Ruff, les migrations et les tests à chaque push.

## Base de données

- Authentification (mobile et back-office) : [`docs/AUTHENTIFICATION.md`](docs/AUTHENTIFICATION.md).
- Foyers, membres et compteurs : [`docs/FOYERS_COMPTEURS.md`](docs/FOYERS_COMPTEURS.md).
- Consommation (séries, résumé, relevés, pagination) : [`docs/CONSOMMATION.md`](docs/CONSOMMATION.md).
- Schéma, relations et garde-fous : [`docs/SCHEMA.md`](docs/SCHEMA.md). Calcul des factures E²C : [`docs/FACTURE_E2C.md`](docs/FACTURE_E2C.md).
- Plusieurs règles métier sont des **triggers MySQL** (facture jamais supprimée, paiement terminé figé, audit intouchable…).
  Ils exigent l'option `log_bin_trust_function_creators=1`, déjà réglée dans `docker-compose.yml`.
  Si le conteneur MySQL existait avant cette option : `docker compose up -d` le recrée (les données sont conservées).
- Écrire une migration :
  1. modifier les modèles (`app/modules/<domaine>/models.py`) et les importer dans `app/db/models.py` ;
  2. `alembic revision --autogenerate -m "..."`, puis **relire** le fichier généré ;
  3. ajouter à la main ce qu'Alembic ne génère pas (triggers) ;
  4. vérifier `alembic upgrade head`, `alembic downgrade -1`, `alembic upgrade head`, puis `pytest`.
- Les migrations sont autonomes : elles n'importent jamais le code de l'application (`app.*`).
