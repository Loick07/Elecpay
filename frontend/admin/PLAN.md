# ElecPay — Plan de construction du back-office d'administration (Next.js)

Back-office **web** de l'équipe ElecPay (support, admin, super admin), dans `frontend/admin/`. L'application
client (Flutter) est terminée ; le backend aussi (B0 → B11) : le back-office n'invente **aucune règle
métier**, il affiche et appelle l'API d'administration (`/api/v1/admin`).
Ce document est la feuille de route. On le suit **dans l'ordre**, une étape à la fois. Une étape n'est
terminée que quand **tous** ses critères « Terminé quand » sont vrais.

**Proposé le 27/11/2026, en attente de la validation de Loick** (avec `DECOUPAGES.md`, qui liste toutes
les décisions qui lui reviennent, et `AUTONOMIE.md`, la méthode de travail).

## Tableau de bord

| Étape | Nom | Écrans | État |
|---|---|---|---|
| A0 | Socle : projet, charte, relais vers l'API, types, sécurité, CI | — | à faire |
| A1 | Connexion, double authentification et session | connexion, code, sécurité, mon compte | à faire |
| A2 | Cadre de l'application et composants communs | menu, en-tête, états | à faire |
| A3 | Utilisateurs | A2, A3 | à faire |
| A4 | Factures | A5, A6 | à faire |
| A5 | Transactions et rapprochement | A7, A8 | à faire |
| A6 | Compteurs | A4 | à faire |
| A7 | Notifications et annonces | A9 | à faire |
| A8 | Journal d'activité, paramètres et rôles | A10, A11 | à faire |
| A9 | Tableau de bord | A1 | à faire |
| A10 | Finitions : accessibilité, sécurité, parcours complet | les 11 | à faire |
| A11 | Mise en ligne sur Vercel (guide pas à pas) | — | à faire |

Ordre des écrans (décision DA2.4 de `DECOUPAGES.md`) : le tableau de bord vient **en dernier**, parce qu'il
renvoie vers tous les autres écrans (« À surveiller », activité récente) ; jusque-là, la page d'accueil
après connexion est une page provisoire « Tableau de bord : bientôt » avec les liens du menu.

## Références (elles font foi)

| Quoi | Où |
|---|---|
| Les 11 écrans (contenu, textes, états, interactions) et la **matrice des permissions** | `frontend/design/maquettes/admin/README.md` et `sources/*.dc.html` (+ `Menu.dc.html`) |
| Charte : couleurs, Inter, densité, tableaux, statuts, formats, voix, états, accessibilité | `frontend/design/CHARTE.md`, `frontend/design/tokens.json` |
| Composants de référence du back-office | `frontend/design/components/AdminTable`, `AdminKpi`, `StatusBadge`, `DemoBadge`, `StateBlock`… |
| Contrat d'API | `backend/openapi.json` (niveau de chaque route dans `x-permission` : `staff`, `admin`, `super_admin`) |
| Guide de l'API d'administration | `backend/docs/ADMIN.md` |
| Connexion par cookies, CSRF, double authentification, codes d'erreur | `backend/docs/AUTHENTIFICATION.md` |
| Factures (en cas d'écart avec une maquette) | `backend/docs/FACTURES.md`, `FACTURE_E2C.md` |
| API publique par ngrok (PC de Loick) | `backend/docs/DEPLOIEMENT.md`, section 7 |

## Déjà décidé (CLAUDE.md et message de lancement de Loick, 27/11/2026)

- **Next.js (App Router), TypeScript, Tailwind + shadcn/ui, TanStack Query et TanStack Table, React Hook
  Form + Zod, Recharts.** Icônes `lucide-react` (charte). Versions publiées au 27/11/2026 : Next 16.4,
  React 19.3, Tailwind 4.3, TanStack Query 5 et Table 9, React Hook Form 7, Zod 4, Recharts 3 ; Node 24
  (installé sur le PC). Versions **fixées** dans `package-lock.json`.
- **Inter** (back-office) et **JetBrains Mono** (références), servies par `next/font` (fichiers copiés au
  moment de la construction : aucune requête vers Google depuis le navigateur). **Thème Jour** par défaut,
  **menu latéral bleu nuit** (thème Nuit), **largeur de référence 1440 px**.
- Les **11 écrans** des maquettes, qui font foi ; **Support en lecture seule**, Admin, Super admin.
- **L'API d'administration existe** (`/api/v1/admin`, 40 routes) ; le contrat `backend/openapi.json` fait foi.
- **Hébergement sur Vercel** (offre gratuite), relié à l'API du PC par ngrok
  (`https://omnivore-pardon-sixth.ngrok-free.dev`). Loick crée lui-même le compte Vercel (avec GitHub).

## Architecture : un seul domaine pour le navigateur

```
Navigateur ──► back-office (Vercel, ou localhost:3000)
                 │  pages : /connexion, /utilisateurs, /factures/…   (aucune donnée rendue côté serveur)
                 │  relais : /api/v1/*  (route serveur Next, même domaine que les pages)
                 ▼
               API ElecPay  (https://omnivore-pardon-sixth.ngrok-free.dev/api/v1/*, ou http://127.0.0.1:8000)
```

- Le navigateur ne parle **qu'au domaine du back-office** : les pages appellent `/api/v1/…` sur le même
  domaine, et le **relais** (route serveur Next, `src/app/api/v1/[...chemin]/route.ts`) transmet à l'API.
  Les cookies `elecpay_access` (chemin `/api/v1`), `elecpay_refresh` (`/api/v1/auth/web`) et
  `elecpay_csrf` (`/`) que dépose l'API sont donc posés **sur le domaine du back-office** : `SameSite=Strict`
  et `Secure` fonctionnent, aucun cookie tiers, **aucun CORS** à ouvrir dans le backend.
- Le relais : liste blanche des en-têtes transmis (cookies, `X-CSRF-Token`, `Content-Type`, `Accept`,
  `User-Agent` du navigateur pour le journal, `X-Request-ID`) ; ajoute **`ngrok-skip-browser-warning`**
  (sinon ngrok renvoie sa page d'avertissement au lieu du JSON) ; recopie les `Set-Cookie` et
  `Content-Disposition` (exports CSV) ; refuse une requête qui modifie quelque chose si son `Origin`
  n'est pas le back-office ; délai de 25 s ; API injoignable → `502` au format commun avec un message
  clair (« L'API ElecPay ne répond pas. Le PC qui l'héberge est peut-être éteint. ») ; **ne journalise
  jamais** cookies, jetons, CSRF, corps des requêtes ni numéros (méthode, chemin sans paramètres, statut,
  durée, `X-Request-ID` seulement).
- **IP réelle** : derrière Vercel, l'API verrait l'adresse de Vercel (elle ne fait confiance qu'à l'agent
  ngrok du PC). Conséquences : journal faussé et limites partagées par toute l'équipe (20 tentatives de
  connexion / 15 min / IP). Solution proposée : décision **DA11.1** (⚠️ modification du backend, avec arrêt).
- L'adresse de l'API est une variable **serveur** (`ELECPAY_API_URL`), jamais `NEXT_PUBLIC_…` : le code du
  navigateur ne contient **aucun secret** et ne connaît même pas l'adresse de l'API (`connect-src 'self'`).
- Données lues **dans le navigateur** par TanStack Query à travers le relais ; aucune donnée rendue côté
  serveur (le cookie d'accès n'est envoyé qu'à `/api/v1`, pas aux pages). Les pages sont gardées côté
  navigateur (`GET /me` au chargement) ; **la vraie protection reste le serveur**, qui refuse tout.

## Règles valables partout

- **Argent** : jamais de bouton ni de route « Marquer comme payée » (elle n'existe pas : seule « Relancer la
  vérification auprès de l'opérateur ») ; **aucun montant modifiable à la main** (aucun champ de montant
  hors du formulaire de tarif, super admin) ; annulation d'une facture avec un **motif d'au moins
  10 caractères**, impossible si elle est payée, déjà annulée ou en cours de paiement (`can_cancel`, le
  bouton n'apparaît pas) ; toute action sensible apparaît au **journal** (vérifié par les tests de bout en bout).
- **Permissions** contrôlées par le serveur (`x-permission`) ; l'interface **masque** seulement ce qui n'est
  pas permis (lu dans `GET /admin/permissions`) ; un `403` affiche « Accès refusé », jamais une page cassée.
- **Mode démo visible partout** (badge dans l'en-tête de chaque page et sur la connexion, lu dans
  `GET /health`) ; jamais une donnée simulée présentée comme réelle ; jamais « temps réel ».
- **Formats** : un seul module (`src/lib/format/`) pour montants (FCFA entiers), kWh, dates et heures de
  Brazzaville, périodes bimestrielles, téléphones ; **mêmes résultats que l'application** (mêmes cas de
  test que `frontend/mobile/test/core/format/`). **Statuts** : couleur + icône + mot, testés contre
  `openapi.json`. Références en JetBrains Mono, chiffres tabulaires.
- **Textes** : français, vouvoiement, voix de la charte ; les messages d'erreur de l'API (déjà en français)
  sont affichés avec « Référence : … » (`X-Request-ID`).
- **États** de la charte sur chaque écran : chargement (squelettes), vide, erreur + Réessayer, accès
  refusé, session expirée, API injoignable.
- **Sécurité** : aucun secret dans le code du navigateur (contrôlé en CI), en-têtes de sécurité (CSP avec
  nonce…), rien de sensible dans les journaux, aucun `dangerouslySetInnerHTML`, pages non indexées
  (`noindex`), retour après connexion vers un chemin **interne** seulement.
- **Accessibilité** : contraste ≥ 4,5:1 (tokens de la charte), tout au clavier avec un focus visible,
  libellés pour les lecteurs d'écran, graphiques doublés d'une valeur en texte.

## Méthode (la même que pour le mobile, voir `AUTONOMIE.md`)

- Une branche par étape (`a0`, `a1`…), sauvegardes poussées ; sous-étapes enchaînées sans arrêt, chacune
  testée, commitée, intégrée dans `main` (`git merge --ff-only`) avec une CI verte.
- **Arrêt à la fin de chaque étape** : rapport `rapports/AX.md` (avec captures des écrans à 1440 px), tableaux
  de bord à jour, attente du « Continue » de Loick. Arrêts aussi **avant de toucher `backend/`** (DA4.1,
  DA11.1) et pour une CI rouge impossible à corriger.
- Le regard de Loick : chaque fin d'étape, il ouvre les écrans dans son navigateur (`npm run dev` sur l'API
  locale de démo) ; les tests complètent ce regard, ils ne le remplacent pas.

## Tests

| Sorte | Outil | Où | Quand |
|---|---|---|---|
| Unitaires (formats, statuts, permissions, relais, session) | Vitest | `src/**/*.test.ts` | CI, à chaque commit |
| Composants (rendu, états, formulaires, accessibilité axe) | Vitest + Testing Library + MSW | `src/**/*.test.tsx` | CI |
| Fraîcheur : types générés depuis `openapi.json`, thème depuis `tokens.json` | Vitest | `tests/fraicheur/` | CI |
| Bout en bout sur l'**API de test** (base dédiée, recréée à chaque passage) | Playwright (Chromium) + `@axe-core/playwright` | `e2e/` | CI (DA0.9) et en local (`tool/e2e.ps1`) |
| Contrôle du code envoyé au navigateur (aucun secret, aucune adresse d'API) | script `tool/bundle-check` | `.next/static` | CI |
| Lecteur d'écran (NVDA), Firefox | à la main | — | A10 (DA10.1, DA10.2) |

Base des tests de bout en bout : **`elecpay_admin_e2e`**, supprimée et recréée par `tool/e2e.ps1` (nom écrit
en dur, garde-fou testé comme `frontend/mobile/tool/integration.ps1`), API de test sur un **port dédié
(8010)**, jetons d'accès d'une minute (session expirée) : jamais `elecpay`, `elecpay_public` ni `elecpay_e2e`.
Comptes de démo du seed (`backend/docs/ADMIN.md`) ; code de double authentification calculé par le test
depuis le secret de démo public, **seulement** sur cette base. Une connexion par rôle, réutilisée
(`storageState`), pour ne pas toucher aux limites de tentatives.

## Les étapes

### A0 — Socle : projet, charte, relais vers l'API, types, sécurité, CI

- **A0.1 Projet** : Next.js dans `frontend/admin/` (App Router, TypeScript strict, ESLint avec les règles
  d'accessibilité `jsx-a11y`, Prettier), npm et Node 24 (`engines`, `.nvmrc`), organisation par domaine
  (`src/features/<domaine>`, `src/lib`, `src/components/ui` pour shadcn/ui), Inter et JetBrains Mono par
  `next/font`, `lucide-react`.
- **A0.2 Charte** : variables CSS et thème Tailwind **générés depuis `frontend/design/tokens.json`**
  (`tool/generate-tokens`, test de fraîcheur ; DA0.4), thème Jour + menu Nuit ; échelle typographique
  `admin-*` ; module des formats et des statuts (mêmes cas de test que le mobile ; DA0.5).
- **A0.3 Relais** `/api/v1/*` (voir « Architecture ») avec ses tests unitaires (API simulée : en-têtes
  transmis ou retirés, cookies, CSRF, `Origin`, délai, `502`, flux d'un CSV, rien de sensible dans les
  journaux) ; variable serveur `ELECPAY_API_URL` (défaut en développement : `http://127.0.0.1:8000`).
- **A0.4 Types et client** : types générés depuis `backend/openapi.json` (`openapi-typescript`, fichier commité,
  **test de fraîcheur**), client typé (`openapi-fetch`) ; erreurs au format commun → message + référence ;
  TanStack Query (réglages communs : DA2.3).
- **A0.5 Sécurité et CI** : en-têtes (CSP avec nonce, `frame-ancestors 'none'`, `connect-src 'self'`, HSTS,
  `Referrer-Policy`, `Permissions-Policy`, `X-Content-Type-Options`, `X-Robots-Tag: noindex`) testés ;
  `tool/bundle-check` (aucun `NEXT_PUBLIC_` hors liste blanche, ni secret, ni mot de passe de démo, ni
  adresse de l'API dans `.next/static`) ; **`.github/workflows/admin.yml`** (DA0.8) : installation `npm ci`,
  lint, types, tests, fraîcheur, construction, contrôle du code du navigateur, `npm audit` (dépendances de
  production, failles graves). Page provisoire avec le badge « Mode démo » lu par le relais.

Terminé quand : `npm run dev` affiche une page au thème de la charte, avec le badge « Mode démo » lu dans
`GET /health` **à travers le relais** sur l'API locale ; les en-têtes de sécurité sont présents ; la CI
`admin.yml` est verte et ne se lance que pour les chemins prévus.

### A1 — Connexion, double authentification et session

Écrans sans maquette, construits selon la charte et montrés en captures (DA1.1).
- **A1.1 Connexion** (`POST /auth/web/login`) : téléphone (saisie libre, normalisée par l'API) + mot de
  passe ; client refusé (`403 FORBIDDEN` : « Ce site est réservé à l'équipe ElecPay. ») ; `429` → compte à
  rebours ; erreurs avec référence.
- **A1.2 Double authentification** : saisie du code (6 chiffres ou code de secours `ABCD-EFGH`,
  `POST /auth/web/login/2fa`, défi de 5 min) ; **configuration obligatoire** pour admin et super admin
  (`403 TWO_FACTOR_SETUP_REQUIRED` → page « Sécurité » : QR code affiché comme image, premier code, **10
  codes de secours montrés une seule fois**).
- **A1.3 Première connexion ou mot de passe oublié** (un membre invité choisit son mot de passe avec le
  code reçu par SMS) : téléphone → code → nouveau mot de passe ; en mode démo, le code renvoyé par l'API
  est affiché comme sur le mobile.
- **A1.4 Session** : un seul rafraîchissement à la fois, **aussi entre onglets** (DA1.3) ; `401
  TOKEN_EXPIRED` ou `NOT_AUTHENTICATED` → une tentative `POST /auth/web/refresh` puis rejeu ; échec →
  « Votre session a expiré. Reconnectez-vous pour continuer. » et retour à la page demandée (DA1.4) ;
  déconnexion (`POST /auth/web/logout`, tous les onglets) ; déconnexion après inactivité (DA1.2) ;
  `X-CSRF-Token` relu dans le cookie à chaque requête qui modifie.
- **A1.5 Mon compte** : profil, changement de mot de passe, état de la double authentification, nouveaux
  codes de secours ; mise en place de **Playwright** et de `tool/e2e.ps1` (base `elecpay_admin_e2e`) ;
  premiers parcours : connexion avec et sans double authentification, client refusé, session expirée
  (jetons d'une minute), déconnexion.

Terminé quand : les trois comptes de démo (support, admin, super admin) se connectent, la double
authentification est exigée là où il faut, la session expirée et la déconnexion marchent, et ces
parcours passent en bout en bout sur l'API de test.

### A2 — Cadre de l'application et composants communs

- **A2.1 Cadre** : menu latéral bleu nuit (`Menu.dc.html` : entrées masquées selon les permissions, ex.
  Journal invisible pour le support), en-tête (badge Mode démo, nom et rôle, Mon compte, déconnexion),
  largeur de référence 1440 px ; petits écrans (DA2.1) ; pages d'erreur (404, accès refusé, API injoignable).
- **A2.2 Permissions** : `GET /admin/permissions` → `peut(…)` dans les composants ; tests par rôle.
- **A2.3 Composants** : `AdminTable` (TanStack Table, pagination serveur de 20 lignes, tri et filtres dans
  l'adresse : DA2.2), `AdminKpi`, `StatusBadge`, panneau latéral de détail, blocs d'état, confirmation avec
  motif (React Hook Form + Zod, mêmes limites que le backend), avis de réussite, export CSV, « Actualiser » +
  « Mis à jour à … » (DA2.3) ; chacun testé (rendu, clavier, axe).

Terminé quand : le cadre s'affiche pour les trois rôles avec le bon menu, les composants passent leurs
tests d'accessibilité et un écran d'essai utilise tableau, panneau et confirmation.

### A3 — Utilisateurs (écrans A2 et A3)

- Liste : recherche nom / téléphone (au moins 3 chiffres), filtres par rôle et statut, colonnes de la
  maquette (foyers, impayés, dernière connexion, statut), pagination, **export CSV** (admin).
- Détail : identité, foyers et compteurs, transactions récentes, résumé financier, sessions ouvertes,
  journal du compte ; **désactiver** (motif obligatoire, ferme les sessions ; jamais soi-même ; un compte
  de l'équipe seulement par un super admin), **réactiver**, **envoyer un code de réinitialisation**.
- Numéros masqués pour le support (fait par le serveur, affiché tel quel).

Terminé quand : les parcours (recherche, détail, désactivation avec motif puis réactivation) passent en
bout en bout pour chaque rôle, le support ne voit aucune action, et chaque action est au journal.

### A4 — Factures (écrans A5 et A6)

- Liste : totaux du mois (émis, facturé, encaissé, reste), filtres par statut et par mois, recherche,
  export CSV (admin).
- Détail : les 6 lignes E²C, période bimestrielle, index, tarif appliqué, source des relevés (simulée en
  démo), payeurs autorisés, historique, transactions liées ; **« Annuler la facture »** (motif ≥ 10
  caractères, absent si `can_cancel` est faux) ; **« Réémettre »** pour une facture annulée (DA4.3) ;
  PDF (DA4.1, ⚠️ backend) ; « Renvoyer au client » (DA4.2).
- Aucun montant modifiable : un test vérifie qu'aucun champ de saisie n'existe sur ces écrans.

Terminé quand : annulation avec motif (refusée sous 10 caractères, impossible sur une facture payée) et
réémission passent en bout en bout, et apparaissent au journal.

### A5 — Transactions et rapprochement (écrans A7 et A8)

- Liste : indicateurs du jour (encaissé, réussies, échouées, en attente, délai moyen), filtres (statut,
  opérateur, jour), numéro **toujours masqué**, motif d'échec.
- Détail : comparaison ElecPay ↔ opérateur (dernière vérification ; « jamais vérifiée » si vide),
  chronologie, clé d'idempotence, verrou de facture ; **seule action : « Relancer la vérification auprès de
  l'opérateur »** (affiche le `message` ; `503` → « réessayez plus tard ») ; **« Ouvrir un litige »** et
  sa clôture (DA5.1) ; mise à jour pendant qu'une transaction est en attente (DA2.3).
- **Aucun bouton « Marquer comme payée »** : test de composant + test de bout en bout + recherche dans le
  code source (aucun texte ni route de ce genre).

Terminé quand : relance (avec le prestataire simulé : réussite, échec, opérateur injoignable) et litige
(ouverture, clôture) passent en bout en bout, au journal, et la transaction ne passe « réussie » que par
l'opérateur.

### A6 — Compteurs (écran A4)

- Relevés reçus du jour, anomalies (index en baisse, relevé manquant ; compteur du haut sur 30 jours),
  compteurs inactifs ; panneau de détail : index d'hier et d'aujourd'hui, explication,
  **« Demander un relevé de contrôle »** (note facultative, une seule fois) / **« Classer sans suite »**
  (note obligatoire) ; le relevé n'est jamais modifié. Détacher / rattacher : DA6.1.

Terminé quand : traitement d'une anomalie (les deux issues) en bout en bout, au journal.

### A7 — Notifications et annonces (écran A9)

- Rédaction d'une annonce : destinataires (tous, factures en retard, un quartier, un client), **nombre de
  destinataires affiché avant l'envoi** (`/announcements/audience`), aperçu sur un téléphone, envoi ou
  programmation (5 min à 90 jours), annulation d'une annonce programmée ; annonces envoyées avec taux de
  lecture ; alertes automatiques activables (avertissement : couper une alerte l'arrête pour toute la
  plateforme). Push : phase 2 (affiché comme tel).

Terminé quand : envoi immédiat, programmation puis annulation passent en bout en bout, au journal.

### A8 — Journal d'activité, paramètres et rôles (écrans A10 et A11)

- Journal (admin) : filtres (domaine, action, auteur, dates), détail avant / après dépliable, IP et
  navigateur ; **ni modifiable ni supprimable** (aucune action) ; export : DA8.1.
- Paramètres : **Équipe** (membres, rôle, état de la double authentification ; inviter, changer un rôle,
  réinitialiser la double authentification d'un membre : super admin, motif ; DA8.2), **Permissions**
  (matrice lue dans l'API), **Tarifs datés** (nouvelle version au plus tôt demain ; les factures émises ne
  changent jamais), **Intégrations** (simulateurs en démo, push en phase 2, mode démo ; aucun secret).
- Test transversal : chaque action sensible des étapes A3 → A8 apparaît au journal avec son auteur.

Terminé quand : invitation d'un membre (jusqu'à sa première connexion), changement de rôle et nouveau tarif
passent en bout en bout (super admin seulement), et le journal les montre.

### A9 — Tableau de bord (écran A1)

- 4 indicateurs (encaissé du mois, factures impayées, taux de paiements non aboutis sur 7 jours,
  transactions en attente), encaissements des 30 derniers jours et factures du mois par statut (Recharts,
  avec la valeur en texte), « À surveiller » (paiement bloqué, échecs répétés, relevés anormaux, retards
  de plus de 30 jours, factures non émises, e-mails abandonnés) qui ouvre l'écran concerné, activité
  récente de l'équipe ; mois en cours seulement (DA9.1). Devient la page d'accueil après connexion.

Terminé quand : chaque point « À surveiller » mène au bon écran, les graphiques ont leur équivalent en
texte, et la page provisoire a disparu.

### A10 — Finitions : accessibilité, sécurité, parcours complet

- Revue des états sur les 11 écrans ; accessibilité : axe sur chaque écran (bout en bout), parcours au
  clavier, contraste, **NVDA** (DA10.1) ; Firefox (DA10.2) ; petits écrans.
- Sécurité : revue des en-têtes, du relais, des journaux, du code du navigateur ; `npm audit`.
- Parcours complet en bout en bout (support, admin, super admin) ; guide d'utilisation court
  (`docs/UTILISATION.md`) ; mesure du poids des pages.

Terminé quand : aucun défaut d'accessibilité relevé par axe, tous les parcours verts, rapport final avec
captures, vérification par Loick dans son navigateur.

### A11 — Mise en ligne sur Vercel (guide pas à pas)

- Guide `docs/VERCEL.md` : Loick crée le compte Vercel (avec GitHub) et importe le dépôt (dossier racine
  `frontend/admin`), variables serveur (`ELECPAY_API_URL=https://omnivore-pardon-sixth.ngrok-free.dev`, et le
  secret du relais de DA11.1, **saisis par Loick**, jamais transmis), région (DA11.3), déploiement de
  `main` seulement (DA11.4), nom du projet (DA11.5) ; conditions de l'offre gratuite (DA11.2).
- ⚠️ **Arrêt avant de toucher `backend/`** pour l'IP réelle (DA11.1).
- Vérifications en ligne : connexion + double authentification, cookies `Secure` / `SameSite=Strict` sur le
  domaine du back-office, aucune page d'avertissement de ngrok, export CSV, en-têtes de sécurité, pages non
  indexées, « API injoignable » propre quand le PC est éteint.

Terminé quand : le back-office en ligne fonctionne de bout en bout contre l'API publique (PC + ngrok), avec
la vraie IP au journal (si DA11.1 b), et le guide permet à Loick de redéployer seul.
