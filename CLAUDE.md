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
- `backend/` — API **commune** client + admin : Python 3.14, FastAPI, Pydantic v2, SQLAlchemy 2, Alembic, PyMySQL,
  PyJWT + Argon2, Pytest + HTTPX, Ruff. Monolithe modulaire (`app/modules/<domaine>`).
- `mobile/` — application **client** Flutter : Riverpod, GoRouter, Dio, freezed/json_serializable,
  flutter_secure_storage, fl_chart, intl, flutter_animate, skeletonizer, google_fonts.
- `admin/` — **back-office web Next.js** (App Router, TypeScript, Tailwind + shadcn/ui, TanStack Query/Table,
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

## Écrans
- Client (16) : splash, connexion, inscription, mot de passe oublié, tableau de bord, liste factures, détail facture,
  paiement, état de transaction, reçu, historique transactions, analyse de consommation, compteurs & foyers,
  notifications, profil & paramètres, assistance.
- Admin (11) : tableau de bord, utilisateurs, détail utilisateur, compteurs, factures, détail facture,
  transactions, détail & rapprochement transaction, notifications, journaux d'activité, paramètres & rôles.
- Prévoir les états : chargement, vide, erreur réseau, accès refusé, session expirée, paiement en attente / échoué / inconnu.

## Design
Fond #050D1A (navy), jaune #F5A623 (actions), bleu #1E88E5, succès #22C55E, alerte #F59E0B, erreur #EF4444.
Poppins (app), Inter (back-office). Inspiration "Liquid Glass". Barre de navigation à 5 onglets avec bouton Payer central.
Les maquettes fournies servent d'inspiration couleurs/style, pas de spécification d'écrans.

## Méthode de travail
- Avancer **étape par étape** : backend solide et testé d'abord, puis Flutter, puis Next.js, puis design final.
  Une étape à la fois, jamais 5 fonctionnalités d'un coup.
- Chaque fonctionnalité livrée avec ses tests (y compris les cas d'erreur). Pas d'erreurs bêtes : lancer les tests et Ruff avant de dire que c'est fini.
- Dire clairement à chaque fin d'étape : où on en est, ce qui reste.
- Le contrat d'API (OpenAPI généré par FastAPI) fait foi pour le mobile et l'admin.

## Feuille de route
Le backend se construit en suivant **`docs/BACKEND_PLAN.md`** (étapes B0 → B11), dans l'ordre.
Ne jamais commencer une étape avant que la précédente remplisse ses critères « Terminé quand ».
À la fin de chaque étape : mettre à jour le tableau de bord en haut de ce fichier, commit et push.
Pas de Flutter ni de Next.js avant la fin de B11.

## Périmètre de travail (strict)
- Travailler **uniquement** dans ce dépôt (`C:\Users\makos\Documents\CODING\ElecPay`).
- Ne jamais lire, chercher, lister ni modifier des fichiers en dehors de ce dossier (pas de recherche dans
  `Documents`, `C:\`, ni dans les anciens projets). Si quelque chose d'extérieur semble nécessaire : demander à Loick d'abord.
- Les anciens projets (`elecpay-console`, `elecpay-api`) ne sont **pas** repris : le backend est reconstruit proprement
  selon `docs/BACKEND_PLAN.md`.
- Seules exceptions autorisées hors du dossier : vérifier les outils installés (`python --version`, `git --version`,
  `docker --version`, `mysql --version`) et installer des paquets Python dans l'environnement virtuel du projet.

## Où on en est
Étape B0 (socle) : dépôt + structure ✅. Reste : environnement Python, squelette FastAPI (`/health`), base MySQL connectée,
Alembic, Pytest, Ruff, CI GitHub Actions.
