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

Les tests utilisent la base `elecpay_test` (créée par `docker/mysql/init/`), jamais la base de développement.
La CI GitHub Actions (`.github/workflows/backend.yml`) lance Ruff, les migrations et les tests à chaque push.
