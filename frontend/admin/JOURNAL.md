# Journal de reprise du back-office (A0 → A11)

À relire au début de chaque session, avec `CLAUDE.md` et `frontend/admin/AUTONOMIE.md`.
Mis à jour et commité avec chaque sauvegarde.

## État au 27/11/2026 (avant A0)

- Back-office **lancé par Loick le 27/11/2026**. Plan proposé sur la branche `admin-plan` :
  `PLAN.md` (étapes A0 → A11), `DECOUPAGES.md` (découpages et décisions DA…), `AUTONOMIE.md` (méthode).
- **Aucun code** : on attend la validation de Loick (et l'ajout des autorisations DA-G1) avant A0.
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

1. Attendre la validation de Loick (`PLAN.md`, `DECOUPAGES.md`, `AUTONOMIE.md`) et ses réponses aux décisions.
2. Après validation : fusionner `admin-plan` dans `main`, ajouter dans `CLAUDE.md` (« Méthode de travail »)
   la ligne « Développement du back-office en autonomie : suivre frontend/admin/AUTONOMIE.md et reprendre
   depuis frontend/admin/JOURNAL.md », puis créer la branche `a0` et commencer A0.1.

## Choix faits en route

(aucun pour l'instant)

## Commandes utiles

(à compléter en A0 : `npm ci`, `npm run dev`, `npm run lint`, `npm test`, `npm run build`,
`.\tool\e2e.ps1`)
