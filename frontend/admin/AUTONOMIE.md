# Consignes : développement autonome du back-office (A0 → A11)

Consignes de Loick pour le back-office d'administration Next.js (`frontend/admin/`), tirées de son message
de lancement du 27/11/2026 et des règles déjà suivies pour l'application mobile
(`frontend/mobile/AUTONOMIE.md`). **Validées par Loick le 27/11/2026, avec `PLAN.md` et
`DECOUPAGES.md`.** Une nouvelle session (après une coupure ou une limite d'utilisation) relit ces
consignes, avec `CLAUDE.md` et `frontend/admin/JOURNAL.md`, avant toute action.

Réponses à Loick : toujours en français.

## 1. Les autorisations, pour travailler sans ses clics

Les autorisations déjà en place pour le mobile (git, gh, etc.) restent valables. Pour le back-office, Loick
ajoute lui-même dans `.claude/settings.local.json` (ignoré par git, interdit en écriture à Claude) la liste
de la décision **DA-G1** de `DECOUPAGES.md` : npm (`ci`, `run`, `install`, `audit`, `ls`, `view`),
`npx playwright`, `npx shadcn@…`, `node tool/…`, `tool/e2e.ps1` ; interdits : `npm publish`, installation
globale, `vercel` / `npx vercel` (la mise en ligne, c'est Loick).

Toujours interdit : suppression en masse, `git push --force`, `git reset --hard`, `git clean`, `reset_db`
lancé directement, toute action sur les bases `elecpay` et `elecpay_public`, toute commande hors du dépôt
(sauf vérifier les outils installés et **lire** les caches de paquets, sans jamais les modifier).

### Tests de bout en bout

Lancer `tool/e2e.ps1` est autorisé, **uniquement sur la base `elecpay_admin_e2e`** : le script la supprime
et la recrée en entier à chaque passage (nom écrit en dur), migrations et seed, API de test sur le port
**8010** (jetons d'accès d'une minute). Garde-fou testé : toute autre base est refusée. **Ne jamais arrêter
un passage pendant la préparation de la base.** Code de double authentification calculé depuis le secret
de démo public, sur cette base seulement.

## 2. Protection contre les coupures de courant

### a) Branche par étape, sauvegardée en continu

- Une branche par étape (`a0`, `a1`… `a11`), jamais de travail directement sur `main`.
- Toutes les 15 à 20 minutes, ou après chaque morceau cohérent : un commit de sauvegarde
  (« Sauvegarde A2.3 : … ») poussé sur GitHub, **sur la branche de l'étape seulement**.
- À la fin de chaque sous-étape, une fois **lint, types, tests et format au vert en local** (exactement
  les contrôles de la CI) : un commit propre, le push, l'intégration dans `main` (`git merge --ff-only`),
  le push de `main` et une **CI verte**. Jamais de commit « Sauvegarde … » dans `main`.
- Juste après chaque fusion dans `main` : `git switch` de retour sur la branche de l'étape.

### b) Journal de reprise : `frontend/admin/JOURNAL.md`

Mis à jour et commité avec chaque sauvegarde. Il contient : l'étape et la sous-étape en cours ; ce qui est
fait ; ce qui est en cours (fichier et idée précise) ; la prochaine action ; les choix faits en route ; les
commandes à relancer.

### c) Reprise au début de chaque session

- Lire `CLAUDE.md`, ce fichier et `JOURNAL.md`.
- Regarder `git status`, `git log -5` et `git branch`, comparer avec `origin`.
- Modifications non commitées : vérifier qu'elles passent (types, lint), puis les commiter en sauvegarde.
- Vérifier que Docker et MySQL tournent (pour les tests de bout en bout).
- Relancer les tests de la sous-étape en cours, puis reprendre à la « prochaine action ».

Un fichier abîmé se restaure depuis le dernier commit, jamais en le réécrivant de mémoire.

## 3. Méthode de A0 à A11

- **Pendant une étape : aucun arrêt.** Les sous-étapes s'enchaînent seules, chacune testée, commitée,
  intégrée dans `main` avec une CI verte.
- **À la fin de chaque étape** : tout est dans `main`, CI verte ; rapport `frontend/admin/rapports/AX.md` ;
  `JOURNAL.md`, tableaux de bord de `PLAN.md` et de `CLAUDE.md` à jour ; le rapport est montré à Loick, et
  on **attend son « Continue »** avant l'étape suivante.
- Le rapport contient : ce qui est fait ; les choix faits en route et leur raison ; les défauts trouvés et
  corrigés ; les commits ; le nombre de tests (unitaires, composants, bout en bout) ; **les captures des
  écrans à 1440 px** (et à 390 px pour les petits écrans) ; **ce que Loick doit regarder dans son
  navigateur** ; les points à surveiller ; les nouvelles dépendances et leur raison ; « Ce qui a été
  modifié ou supprimé en dehors de l'étape » et « Tests modifiés ou supprimés, et pourquoi » (même vides).
- Si Loick envoie des corrections sur un rapport, elles passent en priorité dans la sous-étape suivante.

Claude s'arrête seulement pour :
- la fin de chaque étape : rapport, puis attente du « Continue » ;
- **avant de toucher `backend/`** (DA4.1 en A4, DA11.1 en A11, ou tout autre besoin) : explication de ce qui
  change exactement, puis attente de l'accord ;
- une décision de produit que `DECOUPAGES.md` ne couvre pas et qui ne peut pas attendre ; sinon, l'option
  la plus prudente, notée dans le rapport ;
- un blocage : une CI rouge non corrigée après deux essais sérieux (noté dans `JOURNAL.md`) ;
- A11 : les actions que Loick fait lui-même (compte et projet Vercel, variables secrètes).

Pour les petits choix techniques : décider selon la charte, les maquettes (qui font foi), `openapi.json`,
`backend/docs/ADMIN.md` et `CLAUDE.md`.

## 4. Règles toujours valables

> Reprises du mobile (Loick, 19/11/2026) :
>
> - Ne jamais supprimer, désactiver ou affaiblir un test, un contrôle (contrôle du code du navigateur,
>   fraîcheur des types ou du thème, en-têtes de sécurité, lint, `npm audit`) ou une règle de sécurité pour
>   faire passer la CI. Si un test semble faux : s'arrêter et expliquer pourquoi à Loick **avant** de le
>   changer.
> - Ne jamais supprimer un fichier ou une fonction existante hors du périmètre de l'étape ; une suppression
>   qui semble nécessaire est notée dans le rapport, avec sa raison.
> - Ne jamais modifier les maquettes, la charte (`frontend/design/`) ni `DECOUPAGES.md` (une fois validé)
>   sans l'accord de Loick, sauf pour une correction qu'il a demandée.
> - Fusion dans `main` seulement à la fin d'une sous-étape, après des tests verts en local.

- **Ne jamais lire ni demander les secrets de Loick** : `backend/deploy/ngrok.env`, `.env` de production,
  `DEMO_SEED_PASSWORD`, authtoken ngrok, `android/key.properties`, jetons et variables secrètes de Vercel,
  secret du relais (DA11.1). Ils sont saisis par Loick, jamais transmis.
- Maquettes et charte font foi ; pour les factures, `backend/docs/FACTURES.md` et `FACTURE_E2C.md`.
- Argent : jamais « Marquer comme payée » (seulement « Relancer la vérification ») ; aucun montant
  modifiable à la main ; annulation d'une facture avec un motif d'au moins 10 caractères, impossible si
  elle est payée ; toute action sensible apparaît au journal (vérifié en bout en bout).
- Permissions décidées par le serveur ; l'interface masque seulement ce qui n'est pas permis.
- Badge Mode démo sur chaque page ; jamais une donnée simulée présentée comme réelle ; jamais « temps réel ».
- Un seul module des formats (mêmes résultats que l'application) ; montants en FCFA entiers.
- Le navigateur ne parle qu'au domaine du back-office (relais) ; aucun secret ni adresse d'API dans le code
  du navigateur (contrôlé en CI) ; rien de sensible dans les journaux ; en-têtes de sécurité testés.
- Accessibilité sur chaque écran : axe sans défaut, tout au clavier, focus visible, contraste de la charte.
- Les tests de bout en bout ne tournent que sur `elecpay_admin_e2e` ; aucun test sur l'API publique.
- Fichiers temporaires (captures d'essai, scripts jetables) : hors du suivi de git, jamais commités.
- Avant chaque commit : ajouter les fichiers un par un et relire `git status`.

## 5. Ce que Claude attend de Loick

- La validation de `PLAN.md`, `DECOUPAGES.md` et de ces consignes, et l'ajout des autorisations (DA-G1).
- Son « Continue » à la fin de chaque étape, après un regard sur les écrans dans son navigateur.
- Son accord avant chaque modification de `backend/` (DA4.1, DA11.1).
- En A10 : la vérification avec NVDA (DA10.1). En A11 : le compte et le projet Vercel, les variables
  secrètes, et l'API publique lancée sur le PC.

Tout le reste, Claude le fait seul.
