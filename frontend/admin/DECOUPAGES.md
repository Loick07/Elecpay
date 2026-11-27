# Back-office — découpages de A0 à A11 et décisions (validés)

Proposé le 27/11/2026 avec `PLAN.md` et `AUTONOMIE.md`. **Validé par Loick le 27/11/2026** : « OK » pour
**toutes les recommandations**, y compris DA4.1 et DA11.1.

## Précisions de Loick (27/11/2026)

- **DA4.1 et DA11.1** : l'**arrêt avant de toucher `backend/`** est maintenu (explication de ce qui change,
  puis attente de son accord).
- **Après le MVP** : rendre la **double authentification obligatoire aussi pour le Support** avant d'ouvrir
  le back-office à une vraie équipe (noté dans `PLAN.md`, « Après le MVP ») ; en attendant, DA1.5.
- **DA-G1** : Loick remplace lui-même tout le contenu de `.claude/settings.local.json` par le bloc complet
  que Claude lui a donné (l'existant + les ajouts ci-dessous, + l'interdiction de `DROP DATABASE` en ligne
  de commande).

**Comment répondre** : pour chaque décision (DA0.3, DA1.2…), « OK » suffit si ma recommandation te va ;
sinon indique l'option choisie. **Une décision sans réponse = ma recommandation.**

**Deux décisions touchent le backend** (marquées ⚠️) : DA4.1 (PDF d'une facture pour l'équipe) et DA11.1
(IP réelle derrière Vercel). Même validées ici, je m'arrête **avant** de modifier `backend/` et je te montre
exactement ce qui change.

Règles valables partout (rappel, non rediscutées ici, détail dans `PLAN.md`) : maquettes et charte font foi ;
jamais « Marquer comme payée » ; aucun montant modifiable ; motif d'annulation ≥ 10 caractères ; journal ;
permissions décidées par le serveur, l'interface masque ; badge Mode démo partout ; un seul module des
formats ; aucun secret dans le navigateur ; tests de bout en bout sur la base dédiée seulement.

---

## Résumé des décisions

| N° | Sujet | Recommandation |
|---|---|---|
| DA-G1 | Autorisations de Claude Code (npm, Playwright, `tool/e2e.ps1`) | liste ci-dessous, ajoutée par toi |
| DA0.3 | Thème | Jour seulement (menu Nuit) ; thème Nuit après le MVP |
| DA0.5 | Espace des milliers | U+00A0, comme l'application (mêmes chaînes) |
| DA0.8 | Déclencheurs de la CI `admin.yml` | `frontend/admin/**` + `tokens.json` + `openapi.json` |
| DA0.9 | Tests de bout en bout dans la CI | oui (Chromium), en plus du local |
| DA1.1 | Écrans sans maquette (connexion, code, sécurité, mon compte…) | charte + captures dans le rapport de A1 |
| DA1.2 | Déconnexion après inactivité | 30 min, avertissement 1 min avant |
| DA1.5 | Double authentification du support (facultative) | bandeau « recommandée », pas d'obligation |
| DA2.1 | Petits écrans | complet dès 1024 px ; en dessous, menu au-dessus et tableaux défilants |
| DA2.3 | Fraîcheur des données (quotas ngrok) | pas d'interrogation périodique, sauf transaction en attente |
| DA2.4 | Ordre des écrans | tableau de bord en dernier (A9) |
| DA4.1 ⚠️ | PDF d'une facture pour l'équipe (bouton de A6 sans route) | oui : petite route admin dans le backend |
| DA4.2 | « Renvoyer au client » (A6, sans route) | masqué ; après le MVP |
| DA4.3 | « Réémettre » une facture annulée (route sans bouton) | oui |
| DA5.1 | Clore un litige (route sans bouton) | oui |
| DA6.1 | Détacher / rattacher un compteur (routes sans bouton) | non au MVP |
| DA7.1 | Annuler une annonce programmée (route sans bouton) | oui |
| DA8.1 | « Exporter la période » du journal (A10, sans route) | masqué ; après le MVP |
| DA8.2 | Réinitialiser la double authentification d'un membre (route sans bouton) | oui (super admin, motif) |
| DA9.1 | Choix du mois du tableau de bord (A1, `/stats` sans paramètre) | mois en cours seulement |
| DA10.1 | Lecteur d'écran | NVDA à la fin (A10), avec toi |
| DA10.2 | Navigateurs | Chromium en CI ; Firefox et Edge vérifiés en A10 |
| DA11.1 ⚠️ | IP réelle derrière Vercel | relais signé (secret partagé) : petite modification du backend |
| DA11.2 | Offre gratuite de Vercel (usage non commercial) | gratuite pour la démo et la soutenance ; à revoir avant de vendre |
| DA11.3 | Région des fonctions Vercel | Paris (`cdg1`) |
| DA11.4 | Déploiements | `main` seulement, pas d'aperçus des branches |
| DA11.5 | Nom du projet Vercel (adresse) | `elecpay-admin` (→ `elecpay-admin.vercel.app` si libre) |

---

## Général

- **DA-G1 Autorisations de Claude Code** — pour travailler sans tes clics, comme pour le mobile. Le fichier
  `.claude/settings.local.json` (ignoré par git) m'est interdit en écriture : **tu l'ajoutes toi-même**.
  À ajouter dans `allow` (chacune en `Bash(…)` et en `PowerShell(…)`, même syntaxe que l'existant) :
  `npm ci*`, `npm run *`, `npm install *`, `npm audit*`, `npm ls*`, `npm view *`, `npx playwright *`,
  `npx shadcn@* *`, `node tool/*`, `.\\tool\\e2e.ps1*` et `./tool/e2e.ps1*`.
  À ajouter dans `deny` : `npm publish*`, `npm install -g*`, `npm i -g*`, `npx vercel*`, `vercel *`
  (la mise en ligne, c'est toi).
  **Recommandation : oui.** Chaque nouvelle dépendance est justifiée dans le rapport de l'étape.

## A0 — Socle

### Découpage

A0.1 projet · A0.2 charte (thème généré, formats, statuts) · A0.3 relais `/api/v1/*` · A0.4 types générés et
client · A0.5 sécurité HTTP, contrôle du code du navigateur et CI `admin.yml` (détail dans `PLAN.md`).

### Décisions

- **DA0.3 Thème** — la charte dit « thème Jour par défaut » pour le back-office.
  a) Jour seulement (menu latéral en Nuit, comme la maquette) ; b) Jour + Nuit au choix de l'utilisateur.
  **Recommandation : a)** pour le MVP (moitié moins de captures et de contrôles de contraste) ; b) après.
- **DA0.5 Espace des milliers** — Inter contient l'espace fine insécable (U+202F), Poppins non.
  a) U+00A0 comme l'application (« 12 500 FCFA » identique partout, mêmes cas de test) ; b) U+202F, plus
  fine, seulement dans le back-office. **Recommandation : a)** (la charte veut « mêmes formats »).
- **DA0.8 Déclencheurs de la CI `admin.yml`** — ta consigne : « seulement quand `frontend/admin/` change ».
  Le thème est généré depuis `frontend/design/tokens.json` et les types depuis `backend/openapi.json` :
  si l'un des deux change, le back-office peut être cassé sans que sa CI se lance.
  a) `frontend/admin/**` et `.github/workflows/admin.yml` seulement ; b) les mêmes + `tokens.json` +
  `backend/openapi.json` (comme le mobile, qui se relance pour `tokens.json`).
  **Recommandation : b).**
- **DA0.9 Tests de bout en bout dans la CI** — contrairement au mobile, ils n'ont pas besoin d'un téléphone :
  la CI peut lancer MySQL, l'API (base de test, seed) et le back-office.
  a) dans la CI (Chromium) **et** en local (`tool/e2e.ps1`) ; b) en local seulement, à la fin des étapes.
  **Recommandation : a)** (environ 5 à 8 min de plus par passage ; une régression est vue tout de suite).

## A1 — Connexion, double authentification et session

### Découpage

A1.1 connexion · A1.2 code de double authentification et configuration obligatoire (page « Sécurité ») ·
A1.3 première connexion / mot de passe oublié · A1.4 session (rafraîchissement unique, session expirée,
déconnexion, inactivité) · A1.5 Mon compte, Playwright, `tool/e2e.ps1` et premiers parcours.

### Décisions

- **DA1.1 Écrans sans maquette** — les maquettes n'ont ni connexion, ni saisie du code, ni configuration de
  la double authentification, ni Mon compte, ni pages 404 / accès refusé / API injoignable.
  a) je les construis selon la charte (carte centrée, logo, badge Mode démo, textes de la charte) et je te
  montre les captures dans le rapport de A1 ; b) tu fais d'abord des maquettes (`frontend/design/`).
  **Recommandation : a).**
- **DA1.2 Déconnexion après inactivité** — le jeton de rafraîchissement vaut 30 jours : sur un poste partagé,
  une session de l'équipe resterait ouverte un mois.
  a) déconnexion après **30 min** sans activité, avec un avertissement 1 min avant (« Rester connecté ») ;
  b) aucune (seule la déconnexion manuelle). **Recommandation : a)** (comptes qui touchent à l'argent).
- **DA1.5 Double authentification du support** — obligatoire pour admin et super admin (backend),
  facultative pour le support. a) bandeau « Double authentification recommandée » dans Mon compte tant
  qu'elle est inactive ; b) rien. **Recommandation : a)** (aucune obligation ajoutée : le serveur décide).

## A2 — Cadre de l'application et composants communs

### Découpage

A2.1 menu latéral, en-tête, pages d'erreur · A2.2 permissions (`GET /admin/permissions`) · A2.3 tableau,
indicateurs, statuts, panneau latéral, confirmation avec motif, avis, export CSV, « Actualiser ».

### Décisions

- **DA2.1 Petits écrans** — maquette : « sur petit écran, le menu passe au-dessus, les tableaux défilent
  horizontalement ». a) tout complet dès 1024 px de large, en dessous la règle de la maquette (vérifiée à
  390 px pour ne rien casser) ; b) une vraie version téléphone. **Recommandation : a).**
- **DA2.3 Fraîcheur des données** — l'offre gratuite de ngrok a des quotas mensuels, et chaque appel
  traverse ngrok jusqu'au PC. a) aucune interrogation périodique : données gardées 30 s, relues au retour
  sur l'onglet, bouton « Actualiser » + « Mis à jour à 10:42 » ; **seule exception** : le détail d'une
  transaction **en attente**, relu toutes les 10 s tant qu'il est ouvert ; b) relecture automatique de
  toutes les listes (toutes les 30 s). **Recommandation : a).**
- **DA2.4 Ordre des écrans** — a) tableau de bord en dernier (A9) : il renvoie vers tous les autres écrans,
  ses liens marchent dès sa construction ; d'ici là, une page provisoire après connexion ; b) tableau de
  bord juste après le cadre, avec des pages d'attente (comme l'accueil du mobile en F4).
  **Recommandation : a).**

## A3 — Utilisateurs (A2, A3)

A3.1 liste (recherche, filtres, pagination, export CSV) · A3.2 détail (identité, foyers et compteurs,
transactions, résumé financier, sessions, journal du compte) · A3.3 actions (désactiver avec motif,
réactiver, code de réinitialisation) et parcours de bout en bout par rôle. Aucune décision.

## A4 — Factures (A5, A6)

### Découpage

A4.1 liste et totaux du mois, export · A4.2 détail (6 lignes E²C, index, tarif, source, payeurs, historique,
transactions liées) · A4.3 annuler (motif ≥ 10 caractères) et réémettre · A4.4 PDF (si DA4.1) et parcours
de bout en bout.

### Décisions

- **DA4.1 ⚠️ PDF d'une facture pour l'équipe** — la maquette A6 a « Télécharger le PDF », mais la seule
  route PDF (`GET /bills/{id}/pdf`) est réservée au foyer de la facture : l'équipe reçoit un refus.
  a) ajouter `GET /admin/bills/{id}/pdf` (niveau `staff`), qui réutilise le générateur existant
  (même PDF que le client, « Mode démo »), avec ses tests et le contrat régénéré : **modification du
  backend, arrêt avant** ; b) bouton masqué. **Recommandation : a)** (le support doit voir le même
  document que le client qui appelle).
- **DA4.2 « Renvoyer au client »** (maquette A6) — aucune route. a) masqué, noté « après le MVP » ;
  b) nouvelle route (renvoyer la notification de la facture). **Recommandation : a).**
- **DA4.3 « Réémettre »** — la route existe (`POST /admin/bills/{id}/reissue`, `can_reissue`) mais la
  maquette ne montre pas le bouton. C'est la suite d'une annulation (facture recalculée, numérotée et
  datée du jour, « Facture corrigée » au client). a) bouton sur une facture annulée, avec confirmation ;
  b) pas au MVP. **Recommandation : a).**

## A5 — Transactions et rapprochement (A7, A8)

### Découpage

A5.1 liste et indicateurs du jour · A5.2 détail et comparaison avec l'opérateur, chronologie, clé
d'idempotence, verrou · A5.3 relancer la vérification, litiges, relecture pendant l'attente, preuves
qu'aucun « Marquer comme payée » n'existe.

### Décisions

- **DA5.1 Clore un litige** — `POST /admin/transactions/{id}/disputes/{d}/close` existe (issue : pas de
  débit, remboursé, débit confirmé + note) ; la maquette ne montre que « Ouvrir un litige ».
  a) bouton « Clore le litige » (admin) sur un litige ouvert ; b) pas au MVP (litiges jamais clos).
  **Recommandation : a)** (la clôture ne change ni la transaction ni la facture).

## A6 — Compteurs (A4)

A6.1 relevés du jour, anomalies, compteurs inactifs · A6.2 panneau de détail, relevé de contrôle, classer
sans suite, parcours de bout en bout.

- **DA6.1 Détacher / rattacher un compteur** — routes existantes, absentes de la maquette. Action lourde
  (les factures suivent le compteur). a) pas au MVP ; b) dans le panneau de détail (admin), avec
  confirmation et l'avertissement des factures à payer. **Recommandation : a)** (la maquette fait foi).

## A7 — Notifications et annonces (A9)

A7.1 rédaction, destinataires et aperçu · A7.2 envoi, programmation, annulation, annonces envoyées et taux
de lecture · A7.3 alertes automatiques.

- **DA7.1 Annuler une annonce programmée** — route existante (`/announcements/{id}/cancel`), pas de bouton
  dans la maquette. a) bouton « Annuler l'envoi » sur une annonce programmée ; b) non.
  **Recommandation : a)** (sinon une erreur de programmation ne se rattrape pas).

## A8 — Journal, paramètres et rôles (A10, A11)

A8.1 journal (filtres, avant / après, IP et navigateur) · A8.2 équipe (inviter, rôle, double
authentification) et permissions · A8.3 tarifs datés et intégrations · A8.4 test transversal du journal.

- **DA8.1 « Exporter la période »** (maquette A10) — aucune route d'export du journal. a) masqué, noté
  « après le MVP » ; b) nouvelle route CSV dans le backend. **Recommandation : a).**
- **DA8.2 Réinitialiser la double authentification d'un membre** — route existante
  (`/admin/team/{id}/2fa/reset`, super admin, motif, ferme ses sessions), pas de bouton dans la maquette.
  a) bouton dans l'onglet Équipe ; b) non. **Recommandation : a)** (un admin qui perd son téléphone ne peut
  plus se connecter sinon).

## A9 — Tableau de bord (A1)

A9.1 indicateurs et graphiques (avec leur valeur en texte) · A9.2 « À surveiller » et activité récente,
page d'accueil.

- **DA9.1 Choix du mois** — la maquette montre « Novembre 2026 » comme un sélecteur, mais `GET /admin/stats`
  ne prend aucun paramètre (mois en cours). a) libellé fixe du mois en cours ; b) paramètre `month` à ajouter
  au backend. **Recommandation : a)** pour le MVP.

## A10 — Finitions

A10.1 revue des états et de l'accessibilité (axe sur chaque écran, clavier, NVDA) · A10.2 revue de sécurité ·
A10.3 parcours complet par rôle, Firefox, guide d'utilisation, rapport final.

- **DA10.1 Lecteur d'écran** — a) NVDA (gratuit, Windows) sur les parcours principaux, avec toi, en A10, en
  plus d'axe automatique sur chaque écran ; b) axe seulement. **Recommandation : a).**
- **DA10.2 Navigateurs** — a) Chromium dans la CI ; Firefox et Edge vérifiés en A10 (Playwright en local) ;
  b) les trois dans la CI (plus lent). **Recommandation : a).**

## A11 — Mise en ligne sur Vercel

A11.1 guide `docs/VERCEL.md` (compte et projet créés par toi, variables serveur saisies par toi) · A11.2 ⚠️
IP réelle (backend, après accord) · A11.3 vérifications en ligne et rapport.

- **DA11.1 ⚠️ IP réelle derrière Vercel** — chemin : navigateur → Vercel → ngrok → PC. L'API ne fait
  confiance qu'à l'agent ngrok du PC (`TRUSTED_PROXIES`) : elle prendrait l'adresse de **Vercel** pour celle
  du navigateur. Journal faussé (IP de Vercel) et limites partagées par toute l'équipe (20 tentatives de
  connexion / 15 min / IP, 300 requêtes / min). Vercel n'a pas d'adresses fixes à déclarer comme proxy.
  a) accepter l'IP de Vercel ; b) **relais signé** : le relais envoie l'IP du navigateur dans un en-tête
  dédié avec un secret partagé (`ELECPAY_PROXY_SECRET`, variable serveur de Vercel et du `.env` de
  production, saisi par toi, jamais transmis) ; l'API ne lit cet en-tête que si le secret est bon (petite
  modification de `app/core/request_context.py` + tests) : **modification du backend, arrêt avant**.
  **Recommandation : b).**
- **DA11.2 Offre gratuite de Vercel** — ses conditions réservent l'offre gratuite (« Hobby ») à un usage
  personnel et **non commercial**. a) gratuite pour la démonstration et la soutenance, puis offre payante
  (Pro) ou autre hébergeur avant de vendre ; b) payante dès le départ. **Recommandation : a)** (noté dans le
  guide, à décider avant le premier client).
- **DA11.3 Région des fonctions** — par défaut, Vercel exécute le relais aux États-Unis : chaque appel
  traverserait deux fois l'Atlantique. a) Paris (`cdg1`), au plus près de ngrok et du PC ; b) Cape Town
  (`cpt1`). **Recommandation : a)** (à mesurer en A11 ; b) si c'est plus rapide).
- **DA11.4 Déploiements** — Vercel déploie par défaut chaque branche (« aperçus »), qui seraient branchés
  sur la vraie API. a) `main` seulement ; b) aperçus protégés par mot de passe. **Recommandation : a).**
- **DA11.5 Nom du projet** — il donne l'adresse `<nom>.vercel.app`. a) `elecpay-admin` ; b) un autre nom
  (jamais un nom qui imite E²C). **Recommandation : a)** (domaine personnalisé plus tard).

---

## Choix techniques (je les fais, sauf objection de ta part)

- **npm** (déjà installé avec Node 24.14) plutôt que pnpm ; `package-lock.json` commité, `npm ci` en CI,
  versions exactes. TypeScript : la version la plus récente **prise en charge par Next 16** (TypeScript 7.0
  vient de sortir : seulement si Next le prend en charge).
- **Relais par une route serveur** Next (`/api/v1/[...chemin]`) plutôt que des « rewrites » : les rewrites
  ne permettent ni d'ajouter proprement `ngrok-skip-browser-warning`, ni de filtrer les en-têtes, ni de
  donner un message clair quand l'API ne répond pas.
- **Thème généré depuis `tokens.json`** (script + test de fraîcheur), sans toucher `frontend/design/` ;
  `tokens.css` reste la référence d'aperçu de la charte.
- **Types générés** par `openapi-typescript` (fichier commité, test de fraîcheur) et client `openapi-fetch` ;
  schémas Zod **écrits à la main seulement pour les formulaires**, avec les mêmes limites que le backend
  (motif ≥ 10 caractères, etc.).
- **Aucune donnée rendue côté serveur** : TanStack Query dans le navigateur, à travers le relais ; pages
  gardées côté navigateur, le serveur refuse de toute façon.
- **Session** : `401 TOKEN_EXPIRED` **ou** `NOT_AUTHENTICATED` (le cookie d'accès disparaît du navigateur au
  bout de 15 min) → une seule tentative de rafraîchissement ; un seul rafraîchissement **entre onglets**
  (verrou du navigateur, Web Locks) pour ne jamais rejouer un jeton déjà utilisé (`REFRESH_TOKEN_REUSED`
  fermerait la session) ; déconnexion propagée aux autres onglets ; retour à la page demandée après
  reconnexion (chemin interne seulement, testé).
- **Filtres, tri et page dans l'adresse** (liens partageables, bouton « retour » du navigateur).
- **Tests** : Vitest + Testing Library + MSW (API simulée) ; Playwright + `@axe-core/playwright` ; une
  connexion par rôle réutilisée (`storageState`) ; code de double authentification calculé par `otpauth`
  depuis le secret de démo, **seulement** sur `elecpay_admin_e2e`.
- **QR code** de la double authentification affiché comme image (`data:image/svg+xml`), jamais injecté dans
  la page ; aucun `dangerouslySetInnerHTML` (règle de lint).
- **Aucun identifiant de démo prérempli**, jamais (contrôlé dans le code du navigateur).
