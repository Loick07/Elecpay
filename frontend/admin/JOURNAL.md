# Journal de reprise du back-office (A0 → A11)

À relire au début de chaque session, avec `CLAUDE.md` et `frontend/admin/AUTONOMIE.md`.
Mis à jour et commité avec chaque sauvegarde.

## État au 27/11/2026 (avant A0)

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

1. **A0** sur la branche `a0` : A0.1 projet (+ CI `admin.yml` minimale dès A0.1, pour que chaque
   fusion dans `main` passe par une CI verte), A0.2 charte, A0.3 relais, A0.4 types, A0.5 sécurité.
2. Arrêt à la fin de A0 : rapport `rapports/A0.md`, attente du « Continue » de Loick.

## Choix faits en route

- **Next 16 : lire `node_modules/next/dist/docs/`** avant d'écrire du code (`AGENTS.md`, écrit par
  `next dev`, commité). Le middleware s'appelle **`proxy.ts`** depuis Next 16 (Node.js par défaut).
- **Cache Components désactivé** (A0.1) : tout est lu dans le navigateur ; la CSP à nonce exige un rendu
  dynamique, incompatible avec la coque statique de Cache Components. À revoir pour Next 17 (option
  annoncée comme obligatoire).
- **TypeScript 5.9.3** (celui du modèle `create-next-app` 16.4.6), pas la 7.0.
- **jsdom 29.0.2** : jsdom 30 et 31 exigent Node ≥ 24.15 (le PC a 24.14).
- **Vitest 5** : l'`expect` global n'est pas celui que `vitest.setup.ts` étend → chaque test importe
  `describe`, `it`, `expect` depuis `"vitest"` (types globaux retirés de `tsconfig.json`) ; un
  `afterEach` dans `vitest.setup.ts` est refusé. Le nettoyage de Testing Library passe par les globales.
- Statistiques anonymes de Next désactivées en CI (`NEXT_TELEMETRY_DISABLED=1`).
- Arrêter `next dev` : l'arrêt de la tâche ne suit pas le processus Node enfant → vérifier le port 3000
  (`netstat -ano | grep :3000`) et arrêter le processus `node` qui l'écoute.

## Commandes utiles

Depuis `frontend/admin` :
- `npm ci` · `npm run dev` (http://localhost:3000) · `npm test` · `npm run typecheck` · `npm run lint` ·
  `npm run format:check` · `npm run build`
- Avant chaque commit, les mêmes contrôles que la CI : lint, typecheck, format:check, test, build.
