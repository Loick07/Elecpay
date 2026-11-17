# ElecPay — instructions pour Claude

## Le projet
ElecPay est un vrai produit (MVP à déployer et vendre), pas seulement un projet de soutenance.
Plateforme de gestion de la vie électrique des abonnés E²C (Congo-Brazzaville) :
suivi de consommation (jour / semaine / mois / année — périodique ou estimé, **jamais "temps réel"**),
factures détaillées, paiement Mobile Money, reçu numérique, historique financier,
multi-compteurs / foyers, paiement pour un proche à distance, back-office d'administration.

Auteur : Loick Makosso (Pointe-Noire). Directeur de mémoire : Ir Mbemba Donald.
Langue de travail : **français**.

## Architecture (décidée, ne pas remettre en cause)
Deux grands dossiers, à ne jamais mélanger : **`backend/`** (API, base, simulateurs, `backend/PLAN.md`) et **`frontend/`** (`design/`, `mobile/`, `admin/`).
- `backend/` — API **commune** client + admin : Python 3.14, FastAPI, Pydantic v2, SQLAlchemy 2, Alembic, PyMySQL,
  PyJWT + Argon2, Pytest + HTTPX, Ruff. Monolithe modulaire (`app/modules/<domaine>`).
- `frontend/mobile/` — application **client** Flutter : Riverpod, GoRouter, Dio, freezed/json_serializable,
  flutter_secure_storage, fl_chart, intl, flutter_animate, skeletonizer ; polices embarquées
  (Poppins + JetBrains Mono, pas de google_fonts).
- `frontend/admin/` — **back-office web Next.js** (App Router, TypeScript, Tailwind + shadcn/ui, TanStack Query/Table,
  React Hook Form + Zod, Recharts). L'admin n'est PAS dans l'app Flutter.
- Base : MySQL 8 dans Docker (`docker-compose.yml`, port 3307 pour éviter XAMPP).
- Pas maintenant : Kubernetes, microservices, Redis, Kafka, WebSockets, ML.

## Données simulées
Tout est simulé pour l'instant (relevés de consommation avec motifs réalistes + 12–24 mois d'historique,
factures calculées depuis les relevés et un tarif daté, Mobile Money avec `en_attente` → webhook de confirmation,
y compris des échecs). Seules les API E²C et MTN/Airtel restent à brancher, derrière des interfaces :
`PaymentProvider` (simulated → mtn / airtel), `BillingSource` et `ConsumptionSource` (simulated → e2c),
choisies par configuration (`PAYMENT_PROVIDER=simulated`). Afficher un badge "mode démo".
Ne jamais présenter une donnée simulée comme réelle.

## Règles métier non négociables
- Montants en FCFA entiers (BIGINT / int), jamais de float.
- Facture jamais supprimée (annulation avec motif + audit) ; facture payée immuable.
- Transaction : `en_attente` → `reussie` | `echouee` | `expiree`. Seul le prestataire (webhook) passe à `reussie`.
  Un admin ne peut pas forcer un paiement confirmé.
- Clé d'idempotence sur chaque paiement ; verrou de la facture pendant un paiement.
- Index de compteur jamais décroissant, sinon relevé marqué en anomalie.
- Tarifs datés. Pas de solde de portefeuille stocké.
- Rôles : Client, Payeur délégué, Support (lecture seule), Admin, Super admin — contrôlés côté serveur, actions sensibles dans `audit_logs`.
- Sécurité : Argon2, access token 15 min + refresh 30 j rotatif et révocable, cookies httpOnly pour le back-office,
  rate limiting, signature des webhooks, CORS strict. `.env` jamais commité.

## Tables prévues
users, refresh_tokens, households, household_members, meters, meter_readings, tariffs, bills, bill_lines,
payment_transactions, receipts, notifications, audit_logs.
Ajoutées en cours de route (22 au total, voir `backend/docs/SCHEMA.md`) : password_reset_codes,
notification_preferences, payment_disputes, announcements, alert_settings, two_factor_secrets,
two_factor_backup_codes, email_verification_codes, email_outbox.

## Écrans
- Client (16) : splash, connexion, inscription, mot de passe oublié, tableau de bord, liste factures, détail facture,
  paiement, état de transaction, reçu, historique transactions, analyse de consommation, compteurs & foyers,
  notifications, profil & paramètres, assistance.
- Admin (11) : tableau de bord, utilisateurs, détail utilisateur, compteurs, factures, détail facture,
  transactions, détail & rapprochement transaction, notifications, journaux d'activité, paramètres & rôles.
- Prévoir les états : chargement, vide, erreur réseau, accès refusé, session expirée, paiement en attente / échoué / inconnu.

## Design
Charte UI/UX **validée** dans `frontend/design/` (`CHARTE.md`, `tokens.json`, composants de référence). Elle fait foi pour Flutter et Next.js.
Maquettes **validées** (12/11/2026) : 16 écrans client (`frontend/design/maquettes/client/README.md`) et 11 écrans du back-office (`frontend/design/maquettes/admin/README.md`, avec la matrice des permissions). Elles décrivent aussi ce que chaque étape du backend doit fournir.
Consommation « en direct » (onglet Direct) : uniquement avec compteur communicant ou capteur, simulée en démo, prévue en phase 2 ; ailleurs on n'écrit jamais « temps réel ».
Fond #050D1A (navy), jaune #F5A623 (actions), bleu #1E88E5, succès #22C55E, alerte #F59E0B, erreur #EF4444.
Poppins (app), Inter (back-office). Inspiration "Liquid Glass". Barre de navigation à 5 onglets avec bouton Payer central.
Les **maquettes validées** (`frontend/design/maquettes/`) sont la **spécification des écrans** : contenu, ordre, textes, états et interactions. Les fichiers `sources/*.dc.html` se lisent comme du HTML (styles en ligne = valeurs exactes, script `data-dc-script` = données et comportements). Les images envoyées au tout début du projet n'étaient qu'une inspiration de couleurs.
Pour les factures, en cas d'écart, `backend/docs/FACTURES.md` et `FACTURE_E2C.md` font foi (facture bimestrielle, 6 lignes E²C).

## Méthode de travail
- Avancer **étape par étape** : backend solide et testé d'abord, puis Flutter, puis Next.js, puis design final.
  Une étape à la fois, jamais 5 fonctionnalités d'un coup.
- Chaque fonctionnalité livrée avec ses tests (y compris les cas d'erreur). Pas d'erreurs bêtes : lancer les tests et Ruff avant de dire que c'est fini.
- Dire clairement à chaque fin d'étape : où on en est, ce qui reste.
- Le contrat d'API (OpenAPI généré par FastAPI) fait foi pour le mobile et l'admin.

## Feuille de route
Le backend se construit en suivant **`backend/PLAN.md`** (étapes B0 → B11), dans l'ordre.
Ne jamais commencer une étape avant que la précédente remplisse ses critères « Terminé quand ».
À la fin de chaque étape : mettre à jour le tableau de bord en haut de ce fichier, commit et push.
Pas de Flutter ni de Next.js avant la fin de B11.

## Périmètre de travail (strict)
- Travailler **uniquement** dans ce dépôt (`C:\Users\makos\Documents\CODING\ElecPay`).
- Ne jamais lire, chercher, lister ni modifier des fichiers en dehors de ce dossier (pas de recherche dans
  `Documents`, `C:\`, ni dans les anciens projets). Si quelque chose d'extérieur semble nécessaire : demander à Loick d'abord.
- Les anciens projets (`elecpay-console`, `elecpay-api`) ne sont **pas** repris : le backend est reconstruit proprement
  selon `backend/PLAN.md`.
- Seules exceptions autorisées hors du dossier : vérifier les outils installés (`python --version`, `git --version`,
  `docker --version`, `mysql --version`), installer des paquets Python dans l'environnement virtuel du projet, et
  **lire** les caches de paquets (pub, pip) pour examiner une dépendance du projet — **jamais les modifier**
  (exception ajoutée par Loick le 17/11/2026).

## Où on en est
**B0 (socle technique) ✅ terminé le 12/11/2026** — CI verte sur GitHub.
Python 3.14 + `.venv`, MySQL 8.4 Docker (port 3307, bases `elecpay` et `elecpay_test`), config Pydantic Settings,
SQLAlchemy 2 (`get_db`, `Base`, `UTCDateTime`, mixins), FastAPI (erreurs au format commun, CORS, `/api/v1/health`),
Alembic, Ruff, CI GitHub Actions. Mode d'emploi : `backend/README.md`.

**B1 (modèle de données) ✅ terminé le 12/11/2026** — CI verte. 13 tables, 6 migrations autonomes, 15 triggers MySQL
(facture jamais supprimée et figée, paiement terminé figé, une seule transaction en attente / réussie par facture,
tarifs sans chevauchement, audit intouchable), 300 tests. Schéma : `backend/docs/SCHEMA.md`.
Facture E²C analysée (bimestrielle, troncature, TVA 18 %, C.A. 5 % de la TVA, RAV, timbre) : `backend/docs/FACTURE_E2C.md`.
Décisions : prix en millièmes de FCFA, puissance en VA, propriétaire = `households.owner_id` uniquement,
vues mensuelle / trimestrielle… en **estimation** (B5), facture officielle bimestrielle.
Besoins des maquettes reportés aux étapes B3–B11 : tableau dans `backend/PLAN.md` (fin de B1).

**B2 (simulateurs et données de démo) ✅ terminé le 12/11/2026** — CI verte. Moteur de calcul unique
`app/modules/bills/calculator.py` (reproduit la vraie facture : 571 kWh → 40 384 FCFA) ; simulateurs dans `app/simulators/` ;
`python -m scripts.reset_db && python -m scripts.seed` (~19 s, 13 comptes fictifs, mot de passe `Demo2026!`) ;
`python -m scripts.daily_tick` (relevé quotidien idempotent). Argon2id dans `app/core/security.py`, UTC+1 dans
`app/core/timezone.py`. Hypothèses : échéance = émission + 15 j, émission = fin de période + 3 j, pas de frais de retard.
509 tests (~1 min).

**B3 (comptes et authentification) ✅ terminé le 12/11/2026** — CI verte. Routes `/auth/*`, `/auth/web/*` (back-office :
cookies httpOnly + CSRF, réservé à l'équipe), `/me`, `/me/password`. Gardiens `current_user` / `require_role` dans
`app/modules/auth/dependencies.py` (à utiliser pour toutes les routes suivantes). Limites de tentatives, audit,
SMS simulé (`app/integrations/sms/`). Guide pour Flutter / Next.js : `backend/docs/AUTHENTIFICATION.md`. 736 tests.

**B4 (foyers, compteurs et délégation) ✅ terminé le 12/11/2026** — CI verte. Accès centralisés dans
`app/modules/households/access.py` (`household_access`, `meter_access` : à utiliser pour toute route qui touche
un foyer, un compteur ou ses factures ; pas d'accès → 404). Invitations (compte existant requis), compteurs ajoutés
avec N° branchement + N° client via `BillingSource`, historique de démo via `ConsumptionSource`
(`app/integrations/`). Guide Flutter : `backend/docs/FOYERS_COMPTEURS.md`. 868 tests.

**B5 (consommation) ✅ terminé le 12/11/2026** — CI verte. Agrégation pure (`app/modules/consumption/aggregation.py`,
7 granularités), deux coûts `energy_cost` / `estimated_total` (`costs.py`, moteur unique), routes `/meters/{id}/consumption`
(+ `/summary`, `/days/{date}`) et `/meters/{id}/readings`. Pagination commune `app/core/pagination.py` (à réutiliser),
calendrier `app/core/calendar.py`. Guide Flutter : `backend/docs/CONSOMMATION.md`. 992 tests.

**B6 (factures) ✅ terminé le 12/11/2026** — CI verte. `generate_bill` (`app/modules/bills/service.py`) est
l'unique endroit qui crée une facture (relevé quotidien, seed, import d'historique) ; `mark_overdue_bills`
pour les retards. Routes `/bills` (filtres, reste à payer, retard affiché à la lecture), `/bills/{id}` (lignes,
comparaison), `/bills/{id}/pdf` (fpdf2, « Mode démo »). Numéro de facture = AAAAMMJJ + séquence du jour.
Guide Flutter : `backend/docs/FACTURES.md`. 1122 tests.

**B7 (paiements) ✅ terminé le 13/11/2026** — CI verte. Interface `PaymentProvider` + prestataire simulé
(`app/integrations/payment_providers/`, numéros de test « … 00 00 0N », webhooks HMAC). Routes `POST /payments`
(`Idempotency-Key` obligatoire, verrou de facture), `GET /payments/{id}` (suivi : état chez le prestataire puis
expiration à 10 min sans PIN), `GET /payments` (historique), `POST /webhooks/payments/{provider}` (signé).
`apply_provider_update` (`app/modules/payments/confirmation.py`) est la seule voie vers « réussie ».
Commandes `scripts.check_pending_payments` et `scripts.send_payment_webhook`. Guide Flutter :
`backend/docs/PAIEMENTS.md`. 1276 tests.

**B8 (reçus) ✅ terminé le 13/11/2026** — CI verte. `issue_receipt` (`app/modules/receipts/service.py`),
seul créateur de reçu, appelé au succès d'un paiement (même transaction SQL) ; numéro `EP-AAAA-NNNNNN` par année,
code de vérification de 12 caractères (`secrets`, sans 0/O/1/I/L). Routes `/receipts`, `/receipts/{id}` (numéro de
téléphone toujours masqué), `/receipts/{id}/pdf` (QR code `segno` vers `RECEIPT_VERIFY_URL`), `/receipts/verify/{code}`
(publique, sans nom ni téléphone, limitée par IP). Guide Flutter : `backend/docs/RECUS.md`. 1336 tests.

**B9 (notifications) ✅ terminé le 13/11/2026** — CI verte. Routes `/notifications` (groupes aujourd'hui /
cette semaine / plus tôt, lu, tout lu, `unread-count`) et `/me/notification-preferences` (interrupteurs de l'écran 14,
appliqués dans `insert_notifications`, passage obligé de toute notification). Alertes quotidiennes `run_daily_alerts`
(retard + rappel tous les 7 jours, échéance J-5 et jour J, consommation inhabituelle) ; commande de production
`scripts.daily_alerts`. Toutes les commandes importent `app.db.models` (testé processus par processus).
Guide Flutter : `backend/docs/NOTIFICATIONS.md`. 1414 tests.

**B10 (API d'administration) ✅ terminé le 14/11/2026** — CI verte. 11 écrans du back-office sous
`/api/v1/admin` (`app/modules/admin/`). Chaque route se déclare avec `admin_route(…, Permission.X)` (niveaux
staff / admin / super_admin, mention `x-permission` du contrat) ; chaque écriture passe par
`record_admin_action` (journal avec IP et navigateur, testé route par route contre le contrat OpenAPI).
Nouveautés : traitement des anomalies de relevé, litiges (`payment_disputes`), annonces (`announcements`,
commande `scripts.send_announcements`), alertes automatiques activables (`alert_settings`), réémission d'une
facture annulée par `generate_bill(..., reissue_at=…)`, « Relancer la vérification » par
`apply_provider_update` (jamais de « marquer comme payée »). 2FA de l'équipe : reportée en B11.
Guide Next.js : `backend/docs/ADMIN.md`. 1823 tests.

**B11 (durcissement et contrat d'API) ✅ terminé le 15/11/2026** — CI verte. **Le backend est terminé.**
Sécurité HTTP (`app/core/http_security.py` : en-têtes, limite 300 requêtes / min / IP, IP réelle seulement via
`TRUSTED_PROXIES`) ; journaux JSON masqués avec `X-Request-ID` (`app/core/logs.py`) ; double authentification
TOTP de l'équipe (obligatoire pour admin et super admin, secret chiffré, `TWO_FACTOR_KEY` ; démo : secret public
imprimé par le seed) ; « Paiement reçu » par e-mail avec le reçu PDF (adresse vérifiée, file `email_outbox`,
`scripts.send_emails`) ; contrat `backend/openapi.json` (`scripts.export_openapi`, testé à jour) ; `Dockerfile` ;
guide `backend/docs/DEPLOIEMENT.md`. Parcours client et admin complets testés et joués sur l'API réelle.
1945 tests, couverture 99 %.

**Application Flutter** (`frontend/mobile/`) : feuille de route **`frontend/mobile/PLAN.md`** (F0 → F10, validée
le 15/11/2026), même méthode que le backend (sous-étapes expliquées en français et validées une à une).
Références : maquettes client, charte, `backend/openapi.json`, guides `backend/docs/*.md`.

**F0 (socle et accès à l'API depuis le téléphone) ✅ terminé le 16/11/2026** — CI `Mobile` verte.
Flutter 3.47 (Android, `cg.elecpay.client`, `minSdk 24`), polices embarquées, thème généré depuis `tokens.json`
(`tool/generate_tokens.dart`, testé à jour), `API_BASE_URL` au lancement (https exigé en release par `AppConfig`,
HTTP en clair seulement en debug / profile, contrôlé dans l'APK par `tool/apk_check.dart`), écran de démarrage
avec badge « Mode démo ». Téléphone : guide `frontend/mobile/docs/TELEPHONE.md`, script `tool/telephone.ps1`
(USB `adb reverse` ; sur l'itel A05s de Loick : `flutter run --profile`). Vérifié sur le téléphone : Dio ignore
`usesCleartextTraffic`, donc **`AppConfig` est le seul vrai verrou contre le HTTP en clair** (l'APK release avec
`http://` affiche « Configuration invalide ») ; ne jamais l'affaiblir.

**F1 (accès à l'API et cache hors ligne) ✅ terminé le 17/11/2026** — CI `Mobile` verte, sous-étapes commitées
une à une. Tout est dans `frontend/mobile/lib/core/` ; guide des écrans : **`frontend/mobile/docs/API.md`**.
Écrans : lectures par `cachedApiProvider` (cache par utilisateur, « Hors ligne · données du … »), actions par
`authenticatedApiProvider` (aucune relance automatique), session par `sessionManagerProvider` /
`sessionStateProvider`. Toute route GET se range dans `lib/core/cache/cache_policy.dart` (en cache ou jamais,
dont `GET /payments/{id}`) ; tout modèle s'ajoute au test de contrat (`test/contract/`). Jetons : un seul
rafraîchissement, enregistrés avant le rejeu. `allowBackup="false"` + `dataExtractionRules`. Page Diagnostic en
debug / profile, absente de l'APK release avec le mot de passe de démo (`tool/apk_check.dart` en CI).
Aucun test ne touche le réseau réel (`test/flutter_test_config.dart`). Jalon F1 joué sur l'itel en **débogage sans
fil** (méthode recommandée pour ce téléphone, `frontend/mobile/docs/TELEPHONE.md`). 216 tests.
Méthode Flutter : **commit + push à chaque sous-étape validée** ; tableaux de bord en fin d'étape ; vérification
sur le téléphone seulement aux jalons (fin F1, fin F3, F4–F5, fin F10 : voir `frontend/mobile/PLAN.md`).

**F2 (composants de la charte et formats) ✅ terminé le 18/11/2026** — CI `Mobile` verte, sous-étapes commitées
une à une. Formats : **`lib/core/format/formats.dart`** (seul endroit qui formate montants, kWh, dates, périodes,
téléphones ; aucun caractère invisible en dur, codes `\u…` obligatoires). Composants dans `lib/core/widgets/` :
bouton, champ, téléphone, statuts (`statuses.dart`, testés contre `openapi.json`), squelette, blocs d'état
(`stateForFailure`), bannière hors connexion, feuilles du bas, feuille « session expirée », badge, ligne et
carte de facture, bouton Payer (désactivé hors ligne), feuille de paiement, état d'un paiement, barre du bas.
Verre **réservé à la barre du bas et aux feuilles** (réglage « sans flou »). Icônes : police Lucide embarquée,
codes générés (`tool/generate_icons.dart`), réduite dans l'APK release (contrôlé en CI). Charte : `success-text`
/ `warning-text` ajoutés. Page Catalogue (debug / profile). Tests sur l'écran de l'itel (360 × 800, texte 200 %).
454 tests, APK release 14,6 Mo.

**Prochaine étape : F3** (connexion) : proposer d'abord son découpage. Jalon sur l'itel à la fin de F3.
