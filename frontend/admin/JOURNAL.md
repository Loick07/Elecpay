# Journal de reprise du back-office (A0 → A11)

À relire au début de chaque session, avec `CLAUDE.md` et `frontend/admin/AUTONOMIE.md`.
Mis à jour et commité avec chaque sauvegarde.

## État au 27/11/2026 : A0 terminée, en attente du « Continue »

- **A0 ✅** (rapport `rapports/A0.md`), tout dans `main` (`e9b6dd6` + rapport), CI `Admin` verte,
  176 tests. Branche de travail `a0` (A1 commencera sur une branche `a1` créée depuis `main`).

## Avant A0 (préparation du plan)

- Back-office **lancé par Loick le 27/11/2026**. Plan **validé le 27/11/2026** (toutes les
  recommandations ; arrêt maintenu avant `backend/` pour DA4.1 et DA11.1) : `PLAN.md` (A0 → A11),
  `DECOUPAGES.md`, `AUTONOMIE.md`. Fusionné dans `main` depuis la branche `admin-plan`.
- Autorisations DA-G1 : bloc complet de `.claude/settings.local.json` donné à Loick, qui remplace
  lui-même le fichier.
- Outils sur le PC : Node 24.14, npm 11.9 (pnpm absent). Versions publiées au 27/11/2026 : Next 16.4,
  React 19.3, Tailwind 4.3, TanStack Query 5.108, TanStack Table 9.3, React Hook Form 7.92, Zod 4.6,
  Recharts 3.11, Playwright 1.65, Vitest 5.1, openapi-typescript 7.13 ; TypeScript 7.0 (vérifier ce que
  Next 16 prend en charge).
- Points relevés en préparant le plan (détail dans `DECOUPAGES.md`) :
  - boutons des maquettes **sans route** : PDF et « Renvoyer au client » (A6), « Exporter la période »
    (A10), choix du mois (A1, `GET /admin/stats` sans paramètre) ;
  - routes **sans bouton** dans les maquettes : réémettre une facture, clore un litige, annuler une annonce
    programmée, réinitialiser la double authentification d'un membre, détacher / rattacher un compteur ;
  - derrière Vercel, l'API verrait l'**IP de Vercel** (elle ne fait confiance qu'à l'agent ngrok) ;
  - cookies : `elecpay_access` (chemin `/api/v1`), `elecpay_refresh` (`/api/v1/auth/web`),
    `elecpay_csrf` (`/`), tous `Secure` + `SameSite=Strict` : le relais doit garder le préfixe `/api/v1` ;
  - un membre invité choisit son mot de passe avec un code de réinitialisation (SMS) : la connexion du
    back-office a besoin du parcours « mot de passe oublié / première connexion ».

## Prochaine action

1. **Attendre le « Continue » de Loick** (rapport `rapports/A0.md`).
2. Puis **A1** (connexion, double authentification, session) sur la branche `a1`, en commençant par
   proposer la cible du relais en développement (jamais l'API publique par accident : point à
   surveiller du rapport A0).

## Choix faits en route

- **Next 16 : lire `node_modules/next/dist/docs/`** avant d'écrire du code (`AGENTS.md`, écrit par
  `next dev`, commité). Le middleware s'appelle **`proxy.ts`** depuis Next 16 (Node.js par défaut).
- **Cache Components désactivé** (A0.1) : tout est lu dans le navigateur ; la CSP à nonce exige un rendu
  dynamique, incompatible avec la coque statique de Cache Components. À revoir pour Next 17 (option
  annoncée comme obligatoire).
- **TypeScript 5.9.3** (celui du modèle `create-next-app` 16.4.6), pas la 7.0.
- **jsdom 29.0.2** : jsdom 30 et 31 exigent Node ≥ 24.15 (le PC a 24.14).
- **Défaut de casse du lecteur (Windows), trouvé pas à pas le 27/11/2026** : si Node démarre dans
  `c:\…` (minuscule, ce que donne parfois l'outil Bash lancé par VS Code), Vitest charge son propre
  module DEUX fois (`c:\…` et `C:\…`) → « Vitest failed to find the current suite », assertions de
  jest-dom introuvables. Reproduit à coup sûr (Vitest lancé avec `cwd` en `c:` : échec ; en `C:` :
  succès). Corrigé par **`tool/vitest.ts`** (casse officielle par `realpathSync.native`), utilisé par
  `npm test` : **toujours lancer les tests par `npm test`**, jamais `npx vitest` directement.
  Mes premières conclusions (« l'`expect` global de Vitest 5 est différent ») étaient fausses : c'était
  ce même défaut. Les tests importent quand même `describe`, `it`, `expect` (choix de clarté).
- Tests qui lisent des fichiers (`import.meta.url`) : directive `// @vitest-environment node` (sous
  jsdom, `import.meta.url` n'est pas une adresse `file:`).
- À surveiller : le même défaut de casse pourrait toucher `next dev` ou `next build` lancés depuis un
  dossier en `c:` (rien vu pour l'instant).
- **A0.5, CSP à nonce** : pages rendues à chaque requête (`await connection()` dans `layout.tsx`),
  nonce tiré par `src/proxy.ts`, en-têtes fixes dans `next.config.ts` ; contrôlé sur le vrai serveur
  par `tool/check-headers.ts` (CI) et dans un vrai navigateur par `tool/smoke-browser.ts` (local).
- **MSW 3** : l'option s'appelle `onUnhandledFrame` ; l'ancien nom `onUnhandledRequest` était ignoré
  SANS erreur (la garde « aucun réseau réel » ne marchait pas) : trouvé par le contrôle des types,
  prouvé par `tests/no-network.test.ts` (contre-épreuve faite : il échoue en mode « bypass »).
- **Navigateur local** : Playwright pilote l'Edge du PC (`channel: "msedge"`), rien à télécharger ;
  Edge lancé seul en `--headless` n'écrit ni capture ni sortie sur ce PC (abandonné).
- PC parfois très lent (un fichier de tests : 1 min) : le test de fraîcheur des types a un délai de
  60 s (génération mesurée à 12 s) ; la comparaison reste exacte.
- Statistiques anonymes de Next désactivées en CI (`NEXT_TELEMETRY_DISABLED=1`).
- Arrêter `next dev` : l'arrêt de la tâche ne suit pas le processus Node enfant → vérifier le port 3000
  (`netstat -ano | grep :3000`) et arrêter le processus `node` qui l'écoute.

## Cible du relais en développement et en test (décision de Loick du 27/11/2026, A1.0)

- **Jamais l'API publique** (port 8000, base `elecpay_public`). Aucune valeur par défaut :
  `ELECPAY_API_URL` manquante ou vers le port 8000 → `next dev` / `next start` **refusent de
  démarrer** (`next.config.ts`, prouvé par `tests/startup-guard.test.ts`), le relais répond 500.
- **API de développement** : `.\tool\dev-api.ps1` (port **8001**, base **`elecpay_admin_dev`**,
  écrits en dur ; créée et remplie la première fois, puis gardée ; `-Reset` pour la recréer).
- `frontend/admin/.env.local` (créé par Loick depuis `env.local.example` : je n'ai pas le droit
  d'écrire les fichiers `.env*`) ; pour mes propres essais, `ELECPAY_API_URL` passée dans
  l'environnement de la commande.
- Ports : 8000 = API publique (jamais) · 8001 = API de développement · 8010 = API des tests de bout
  en bout (A1.5) · 8011 = essais ponctuels sur `elecpay_e2e` · 3000 = `npm run dev` de Loick ·
  3001 / 3010 = mes serveurs d'essai. `next dev` et `next start` n'écoutent que `127.0.0.1`.
- `suppressHydrationWarning` sur `<html>` et `<body>` : une extension du navigateur de Loick ajoute
  `__processed_…__` à `<body>` (« 1 Issue » de Next) ; reproduit puis corrigé.

## Commandes utiles

Depuis `frontend/admin` :
- `npm ci` · `npm run dev` (http://localhost:3000) · `npm test` · `npm run typecheck` · `npm run lint` ·
  `npm run format:check` · `npm run build`
- Avant chaque commit, les mêmes contrôles que la CI : lint, typecheck, format:check, test, build.
- Fichiers générés (tests de fraîcheur) : `npm run generate:tokens` après un changement de
  `frontend/design/tokens.json` ; `npm run generate:api` après un changement de `backend/openapi.json`.
- Appels à l'API : `unwrap(api.GET("/api/v1/…"))` (`src/lib/api/client.ts`) → données ou `ApiError`
  (message + `requestId` à afficher en « Référence : … »).
- **Essai réel du relais** (A0.3, sans toucher l'API publique ni la base de démo) : API de test sur le
  port 8011 et la base jetable `elecpay_e2e` (lecture seulement)
  `cd backend; DATABASE_URL=mysql+pymysql://elecpay:elecpay@127.0.0.1:3307/elecpay_e2e?charset=utf8mb4
  .venv/Scripts/uvicorn.exe app.main:app --host 127.0.0.1 --port 8011`, puis le back-office avec
  `ELECPAY_API_URL=http://127.0.0.1:8011 npx next dev` (depuis PowerShell). À la fin : vérifier que
  les ports 3000 et 8011 sont libres (l'arrêt de la tâche ne suit pas toujours le processus enfant).
