# Image de l'API ElecPay (B11.6). Construire depuis backend/ :
#     docker build -t elecpay-api .
# Lancer (les réglages viennent de l'environnement, JAMAIS d'un .env copié dans l'image) :
#     docker run --env-file .env.production -p 8000:8000 elecpay-api
# Migrations avant chaque mise en service (même image) :
#     docker run --env-file .env.production elecpay-api alembic upgrade head
# Guide complet : docs/DEPLOIEMENT.md

FROM python:3.14-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# Dépendances d'exécution seulement (pas les outils de test), installées avant le code :
# l'étape est réutilisée tant que requirements.txt ne change pas.
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY alembic.ini .
COPY alembic ./alembic
COPY app ./app
COPY scripts ./scripts

# Jamais en root dans le conteneur.
RUN useradd --create-home --uid 10001 elecpay
USER elecpay

EXPOSE 8000

# Supervision : /api/v1/health répond 200 (API + base) ou 503 (base injoignable).
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8000/api/v1/health', timeout=4).status == 200 else 1)"

# --no-server-header : ne révèle pas « uvicorn » (B11.1).
# --no-proxy-headers : l'IP réelle derrière un proxy est lue par l'API elle-même, seulement
#   depuis TRUSTED_PROXIES (app/core/request_context.py) ; une seule règle, pas deux.
# Pas de --access-log : le journal d'accès est celui de l'API (sans paramètres, B11.2).
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", \
     "--no-server-header", "--no-proxy-headers", "--no-access-log"]
