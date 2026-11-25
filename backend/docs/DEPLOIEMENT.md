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
**Jamais** `scripts.reset_db` en production (il le refuse). `scripts.seed` ne sert qu'au serveur de
**démonstration** (section 7) : en production, il exige `DEMO_MODE=true` et un `DEMO_SEED_PASSWORD`
choisi sur le serveur (jamais `Demo2026!`), et tire au hasard le secret 2FA de chaque membre de l'équipe.

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

`daily_tick` (relevés simulés) ne sert **qu'en démonstration** : en production, il exige des sources
simulées et `DEMO_MODE=true` (refusé dès qu'E²C est branché).

## 6. Vérifier après la mise en ligne

- `GET https://<api>/api/v1/health` → `{"status": "ok", "database": "ok", ...}` ;
- `GET https://<api>/docs` → la documentation interactive s'affiche ;
- connexion au back-office avec un compte de l'équipe : la double authentification est demandée ;
- les journaux (sortie standard du conteneur) sont en JSON, sans numéro de téléphone ni jeton ;
  chaque réponse porte `X-Request-ID`, à demander à un utilisateur qui signale un problème.

## 7. Démonstration en ligne depuis le PC, avec ngrok (étape M1)

Pour Loick : l'API tourne **sur ce PC** (Windows, Docker), et **ngrok** la rend joignable en HTTPS à
l'adresse fixe **`https://omnivore-pardon-sixth.ngrok-free.dev`**. C'est l'adresse que l'APK livré
appelle (`frontend/mobile/docs/LIVRAISON.md`). Toutes les commandes se lancent dans PowerShell,
**depuis `backend/`**, avec Docker Desktop démarré.

**Sécurité, en résumé :**
- une base **dédiée**, `elecpay_public`, avec son propre utilisateur MySQL. Les bases `elecpay`,
  `elecpay_test` et `elecpay_e2e` ne sont jamais touchées. MySQL n'écoute que ce PC
  (`127.0.0.1:3307`), et ngrok n'expose **que** l'API (port 8000) ;
- les secrets sont tirés au hasard **sur ce PC** et écrits dans `deploy\ngrok.env`, qui est ignoré
  par git et n'est jamais affiché ni envoyé ;
- l'API tourne en **production** (`APP_ENV=production`), donc avec tous ses garde-fous : secrets
  forts, cookies sécurisés, CORS en https, 2FA de l'équipe obligatoire. Les données restent
  simulées : `DEMO_MODE=true`, badge « Mode démo » ;
- les comptes de démo ont un **mot de passe secret** (`DEMO_SEED_PASSWORD`), jamais `Demo2026!`.
  Les admins ont chacun un **secret 2FA tiré au hasard**.

### 7.1 Préparer (une seule fois)

1. **Base et secrets** :

   ```powershell
   .\deploy\public.ps1 -Step preparer
   ```

   Le script crée la base `elecpay_public` et son utilisateur, puis écrit `deploy\ngrok.env`. Il ne
   change rien si ce fichier existe déjà.
2. **Vérifier la configuration** (rien n'est modifié) :

   ```powershell
   .\deploy\public.ps1 -Step config
   ```

   La sortie attendue : `Configuration valide : production https://omnivore-pardon-sixth.ngrok-free.dev/api/v1/receipts/verify …`.
3. **Créer les tables** :

   ```powershell
   .\deploy\public.ps1 -Step migrer
   ```

4. **Créer les comptes de démo** :

   ```powershell
   .\deploy\public.ps1 -Step seed
   ```

   - Le **mot de passe** des comptes est la valeur `DEMO_SEED_PASSWORD` de `deploy\ngrok.env`.
     Ouvre ce fichier avec le Bloc-notes pour la lire, et ne la recopie nulle part ailleurs.
   - La **double authentification** de l'admin et du super admin est déjà active, avec un secret
     **différent pour chacun**. Les secrets sont affichés **une seule fois**, à la fin du seed :
     ajoute-les **tout de suite** dans ton application d'authentification (Google Authenticator…),
     avec le secret ou le lien en QR code.
   - Perdus ? Un super admin réinitialise la 2FA du compte depuis le back-office.

### 7.2 Installer ngrok et ajouter l'authtoken (par Loick, une seule fois)

**L'authtoken ngrok est un secret : tu l'ajoutes toi-même. Il ne va ni dans le dépôt, ni dans un
fichier du projet, ni dans une conversation.**

1. Installer ngrok, au choix :
   - **Microsoft Store** : chercher « ngrok », puis Installer ;
   - **WinGet**, dans PowerShell :

     ```powershell
     winget install ngrok -s msstore
     ```

   Vérifier dans une **nouvelle** fenêtre PowerShell : `ngrok version`.
2. Sur `https://dashboard.ngrok.com`, avec ton compte, ouvre « Your Authtoken » et copie-le.
3. Dans PowerShell :

   ```powershell
   ngrok config add-authtoken <ton authtoken>
   ```

   ngrok l'enregistre dans **son propre** fichier de configuration, dans ton profil Windows, hors du
   dépôt.

### 7.3 Mettre en ligne (à chaque fois)

Ouvre **trois fenêtres** PowerShell et laisse-les ouvertes :

1. **L'API**, depuis `backend/` :

   ```powershell
   .\deploy\public.ps1 -Step api
   ```

2. **Les tâches planifiées**, depuis `backend/` : paiements en attente, e-mails et annonces chaque
   minute ; chaque jour à partir de 6 h, relevés simulés puis alertes.

   ```powershell
   .\deploy\public.ps1 -Step taches
   ```

3. **ngrok** :

   ```powershell
   ngrok http 8000 --url=omnivore-pardon-sixth.ngrok-free.dev
   ```

   Avec une ancienne version de ngrok, l'option s'appelle `--domain=` au lieu de `--url=`. N'ajoute
   pas d'autre option : ngrok transmet lui-même l'IP réelle du visiteur, et l'API ne la croit que
   venant de ce PC (`TRUSTED_PROXIES`).

Puis **vérifier**, dans une quatrième fenêtre depuis `backend/` :

```powershell
.\deploy\public.ps1 -Step verifier
```

Le résultat attendu : deux lignes `{"status":"ok","database":"ok","demo_mode":true}`, l'une en local,
l'autre par ngrok.

Dans un navigateur, `https://omnivore-pardon-sixth.ngrok-free.dev/api/v1/health` affiche d'abord la
**page d'avertissement de ngrok** (offre gratuite) : clique sur « Visit Site ». L'application, elle,
n'est pas un navigateur et ne voit pas cette page.

**Arrêter** : `Ctrl+C` dans les trois fenêtres. **Relancer plus tard** : seulement les étapes de 7.3.
Pense à arrêter ngrok quand la démonstration ne sert pas.

### 7.4 Sauvegarder et restaurer

- **Sauvegarder** (par exemple chaque jour) :

  ```powershell
  .\deploy\public.ps1 -Step sauvegarde
  ```

  La copie va dans `deploy\sauvegardes\`, ignoré par git. Les **14 plus récentes** sont gardées.
- **Restaurer** : arrête d'abord l'API et les tâches, puis :

  ```powershell
  .\deploy\public.ps1 -Step restaurer -Fichier deploy\sauvegardes\<fichier>.sql
  ```

  Le script demande de taper `RESTAURER` pour confirmer. Seules les sauvegardes de
  `elecpay_public` sont acceptées.
- **Nouvelle version de l'API** : `git pull`, puis `.\deploy\public.ps1 -Step migrer`, puis relancer
  l'API.

### 7.5 Limites de l'offre gratuite de ngrok

- L'API n'est joignable que si **le PC est allumé**, avec l'API et ngrok lancés.
- Les navigateurs voient la page d'avertissement de ngrok une première fois. C'est le cas du lien du
  **QR code d'un reçu**, ouvert depuis un téléphone.
- ngrok fixe des quotas mensuels (requêtes, données) : largement suffisants pour une démonstration.
- Pour une API joignable jour et nuit, il faudra plus tard une machine en ligne (par exemple
  Oracle Cloud), avec la même image Docker (sections 1 à 6).
