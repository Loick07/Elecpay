# Déploiement de l'API ElecPay

Pour la personne qui met l'API en ligne. L'API est une image Docker (`backend/Dockerfile`)
reliée à une base MySQL 8, derrière un proxy HTTPS (répartiteur de l'hébergeur, Nginx, Caddy…).
Le contrat d'API à jour est `backend/openapi.json`.

## 1. Construire l'image

```bash
cd backend
docker build -t elecpay-api:<version> .
```

L'image ne contient **aucun secret** (`.env` exclu par `.dockerignore`), ni les tests. Elle tourne
sous l'utilisateur `elecpay` (jamais root), sans l'en-tête `server`, avec un contrôle de santé
sur `GET /api/v1/health` (200 si l'API et la base répondent, 503 sinon).

## 2. Configuration (variables d'environnement)

En production, l'API **refuse de démarrer** si un réglage de sécurité manque ou est faible.

| Variable | Production | Rôle |
|---|---|---|
| `APP_ENV` | `production` | active les contrôles de sécurité ci-dessous |
| `DATABASE_URL` | obligatoire | `mysql+pymysql://utilisateur:motdepasse@hote:3306/elecpay` |
| `JWT_SECRET` | ≥ 32 caractères aléatoires | signe les jetons de connexion |
| `TWO_FACTOR_KEY` | ≥ 32 caractères, ≠ `JWT_SECRET` | chiffre les secrets de double authentification |
| `PAYMENT_WEBHOOK_SECRET` | ≥ 32 caractères | vérifie la signature des webhooks des opérateurs |
| `RECEIPT_VERIFY_URL` | en `https://` | adresse imprimée dans le QR code des reçus |
| `CORS_ORIGINS` | origines en `https://` | site du back-office, ex. `https://admin.elecpay.cg` |
| `AUTH_COOKIE_SECURE` | `true` (imposé) | cookies du back-office seulement en HTTPS |
| `TEAM_2FA_REQUIRED` | `true` (imposé) | double authentification obligatoire pour admin et super admin |
| `TRUSTED_PROXIES` | IP / réseau du proxy | seulement derrière eux, l'IP réelle est lue dans `X-Forwarded-For` |
| `RATE_LIMIT_PER_MINUTE` | `300` | requêtes par IP et par minute (0 = aucune limite) |
| `LOG_FORMAT` | `json` (par défaut en production) | journaux sur la sortie standard, une ligne JSON par événement |
| `LOG_LEVEL` | `INFO` | `DEBUG`, `INFO`, `WARNING`, `ERROR` |
| `PAYMENT_PROVIDER`, `BILLING_SOURCE` | `simulated` aujourd'hui | MTN, Airtel et E²C se brancheront ici |
| `DEMO_MODE` | `true` tant qu'un simulateur est actif (imposé) | badge « mode démo », mention sur les reçus |

Autres réglages (valeurs par défaut correctes) : `ACCESS_TOKEN_MINUTES` (15),
`REFRESH_TOKEN_DAYS` (30), `PAYMENT_TIMEOUT_MINUTES` (10), `BILLING_PERIOD_MONTHS` (2),
`BILL_ISSUE_DELAY_DAYS` (3), `BILL_DUE_DELAY_DAYS` (15). Modèle complet : `backend/.env.example`.

Générer un secret :

```bash
python -c "import secrets; print(secrets.token_urlsafe(48))"
```

Chaque secret est **différent** et conservé dans le coffre de l'hébergeur, jamais dans le dépôt.
Changer `TWO_FACTOR_KEY` rend les secrets de 2FA illisibles : chaque membre devra la réactiver
(réinitialisation par un super admin).

## 3. Base de données et migrations

Avant **chaque** mise en service d'une nouvelle version (même image) :

```bash
docker run --rm --env-file .env.production elecpay-api:<version> alembic upgrade head
```

La base doit autoriser les triggers (`log_bin_trust_function_creators=1`) : les garde-fous métier
(facture jamais supprimée, paiement terminé figé, journal intouchable…) en dépendent.
**Jamais** `scripts.seed` ni `scripts.reset_db` en production (le seed le refuse de toute façon).

## 4. Lancer l'API

```bash
docker run -d --name elecpay-api --env-file .env.production -p 8000:8000 elecpay-api:<version>
```

Derrière le proxy HTTPS, renseigner `TRUSTED_PROXIES` avec l'adresse du proxy. Sans cela, l'API
voit l'IP du proxy pour tout le monde (limites et journal faussés) ; avec une valeur trop large,
un client pourrait choisir son IP. Une seule instance pour l'instant : les compteurs de limites
sont en mémoire du processus (plusieurs instances : prévoir une mémoire partagée).

## 5. Tâches planifiées

Chaque tâche se lance avec la même image et la même configuration
(`docker run --rm --env-file .env.production elecpay-api:<version> python -m scripts.<tâche>`).
Toutes sont **idempotentes** : relancées ou superposées, elles ne font jamais deux fois la même chose.

| Tâche | Fréquence | Rôle |
|---|---|---|
| `check_pending_payments` | toutes les minutes | fait le point sur les paiements en attente (état chez l'opérateur, expiration après 10 min sans code PIN) |
| `send_emails` | toutes les minutes | envoie les récapitulatifs de paiement (reçu PDF joint), retente en cas de panne |
| `send_announcements` | toutes les minutes | envoie les annonces programmées par l'équipe |
| `daily_alerts` | chaque matin (ex. 6 h, heure de Brazzaville) | passage en retard, rappels d'échéance et de retard, consommation inhabituelle |

`daily_tick` (relevés simulés) ne sert **qu'en démonstration** : il est refusé en production.

## 6. Vérifier après la mise en ligne

- `GET https://<api>/api/v1/health` → `{"status": "ok", "database": "ok", ...}` ;
- `GET https://<api>/docs` → la documentation interactive s'affiche ;
- connexion au back-office avec un compte de l'équipe : la double authentification est demandée ;
- les journaux (sortie standard du conteneur) sont en JSON, sans numéro de téléphone ni jeton ;
  chaque réponse porte `X-Request-ID`, à demander à un utilisateur qui signale un problème.
