# Consignes : développement autonome de F4 à F10

Consignes de Loick, données le 19/11/2026 (copiées en intégralité, sans modification). Une nouvelle
session (après une coupure ou une limite d'utilisation) doit les relire, avec `CLAUDE.md` et
`frontend/mobile/JOURNAL.md`, avant toute action.

---

Réponds-moi toujours en français.

## 0. Enregistre d'abord ces consignes dans le dépôt

Une nouvelle session (après une coupure ou une limite d'utilisation) ne se souviendra pas de ce message. Avant toute chose :

- copie l'intégralité de ces consignes dans frontend/mobile/AUTONOMIE.md ;
- ajoute dans CLAUDE.md, section « Méthode de travail », une ligne qui dit : « Développement Flutter en autonomie : suivre frontend/mobile/AUTONOMIE.md et reprendre depuis frontend/mobile/JOURNAL.md » ;
- commite et pousse.

## 1. Les autorisations, pour travailler sans mes clics

Propose-moi le contenu de .claude/settings.local.json (vérifie qu'il est ignoré par git). Il doit autoriser à l'avance seulement, dans ce dépôt :

- flutter test, flutter analyze, flutter build apk, flutter pub get, flutter drive ;
- dart format, dart run build_runner, dart run tool/... ;
- git status, git diff, git log, git branch, git add, git commit, git push (sans --force), git switch, git merge --ff-only, git fetch, git pull --ff-only ;
- gh run list, gh run view, gh run watch ;
- adb devices, adb reverse, adb shell screencap ;
- les scripts du dépôt tool/telephone.ps1 et tool/integration.ps1.

Interdit : suppression en masse, git push --force, git reset --hard, git clean, reset_db sur la base de démo elecpay, et toute commande hors du dépôt. Utilise la syntaxe exacte de ta version de Claude Code. Montre-moi le fichier et attends mon accord : c'est le seul accord à attendre avant de démarrer.

## 2. Protection contre les coupures de courant

### a) Branche par étape, sauvegardée en continu

- Une branche par étape (f4, f5… f10), jamais de travail directement sur main.
- Toutes les 15 à 20 minutes, ou après chaque morceau cohérent : un commit de sauvegarde (sauvegarde F5.2 : …) poussé sur GitHub.
- À la fin de chaque sous-étape, une fois les tests, l'analyse et le format au vert : un commit propre, le push, l'intégration dans main (git merge --ff-only), le push de main et une CI verte.

### b) Journal de reprise : frontend/mobile/JOURNAL.md, mis à jour et commité avec chaque sauvegarde. Il contient :

- l'étape et la sous-étape en cours ;
- ce qui est fait ;
- ce qui est en cours (fichier et idée précise) ;
- la prochaine action ;
- les choix faits en route ;
- les commandes à relancer si besoin.

### c) Reprise au début de chaque session

- Lis CLAUDE.md, AUTONOMIE.md et JOURNAL.md.
- Regarde git status, git log -5 et git branch, et compare avec origin.
- S'il y a des modifications non commitées, vérifie qu'elles compilent, puis commite-les en sauvegarde.
- Vérifie que Docker et MySQL tournent.
- Relance les tests de la sous-étape en cours.
- Reprends à la « prochaine action », sans refaire ce qui est déjà fait.

Un fichier abîmé se restaure depuis le dernier commit, jamais en le réécrivant de mémoire.

## 3. Méthode de travail de F4 à F10

> **Changement de méthode demandé par Loick le 19/11/2026 (il remplace « enchaîne F4 → F5 → F6 » et
> « passe directement à l'étape suivante » ci-dessous) :**
>
> - **Arrêt à la fin de chaque étape** (F4, F5, F6, F7, F8, F9, F10), au lieu d'enchaîner.
> - **Pendant une étape : aucun arrêt.** Toutes les sous-étapes s'enchaînent seules, avec tests,
>   commits, intégration dans `main` et CI verte à chaque sous-étape.
> - **À la fin d'une étape** : tout est intégré dans `main` et la CI est verte ; rapport
>   `frontend/mobile/rapports/FX.md` (ce qui est fait, les choix faits en route, les défauts trouvés et
>   corrigés, les commits, le nombre de tests, la taille de l'APK release, **ce qu'il faut regarder sur
>   le téléphone**, les points à surveiller) ; `JOURNAL.md` et tableaux de bord à jour ; le rapport est
>   montré à Loick, et on **attend son « Continue »** avant de commencer l'étape suivante.
> - Les autres arrêts restent : en F6 avant de brancher le paiement réel, avant de toucher `backend/`
>   (mise en ligne), et en cas de CI rouge impossible à corriger.

Avant de coder la suite, termine ce qui reste de F4.0 (section 5), puis propose-moi en un seul document (frontend/mobile/DECOUPAGES.md, commité) le découpage de F5, F6, F7, F8, F9 et F10, avec toutes les décisions qui me reviennent et ta recommandation pour chacune. Attends ma validation de ce document. C'est le deuxième et dernier accord à attendre avant F6.

Pendant ce temps, avance sur F4 (son découpage est déjà validé, voir section 6).

Une fois DECOUPAGES.md validé, enchaîne F4 → F5 → F6 (première partie) sans t'arrêter.

À la fin de chaque étape, écris un rapport dans frontend/mobile/rapports/FX.md, commite-le, mets à jour les tableaux de bord de PLAN.md et CLAUDE.md, et passe directement à l'étape suivante. Le rapport contient :

- ce qui est fait ;
- les choix faits en route et leur raison ;
- les défauts trouvés et corrigés ;
- les commits ;
- le nombre de tests, et la taille de l'APK release ;
- les points à surveiller.

Si je t'envoie des corrections sur un rapport, intègre-les en priorité dans la sous-étape suivante.

Tu t'arrêtes seulement pour :

- F6, avant de brancher l'envoi réel du paiement (POST /payments) : rapport, puis attente de ma validation ;
- une décision de produit que DECOUPAGES.md ne couvre pas et qui ne peut pas attendre. Sinon, prends l'option la plus prudente, note-la dans le rapport et continue ;
- un blocage : une CI rouge que tu ne sais pas corriger après deux essais sérieux. Écris-le dans JOURNAL.md et arrête-toi ;
- la fin de F10 : rapport final, et vérification sur mon itel avec moi.

Pour les petits choix techniques, décide toi-même selon la charte, les maquettes (qui font foi), openapi.json et CLAUDE.md.

Jalon de mi-parcours (après F5) : si mon itel est connecté (adb devices), joue les tests d'intégration avec tool/integration.ps1, sur la base elecpay_e2e, et range les captures. Avant toute action sur le téléphone, vérifie qu'ElecPay est au premier plan. Si le téléphone n'est pas là, note-le dans le rapport et reporte le jalon à la fin de F10, sans t'arrêter.

## 4. Règles toujours valables

> **Règles ajoutées par Loick le 19/11/2026 :**
>
> - Ne jamais supprimer, désactiver ou affaiblir un test, un contrôle (`apk_check`, contrat, analyse) ou
>   une règle de sécurité pour faire passer la CI. Si un test semble faux : s'arrêter et expliquer
>   pourquoi à Loick **avant** de le changer.
> - Ne jamais supprimer un fichier ou une fonction existante hors du périmètre de l'étape. Une suppression
>   qui semble nécessaire est notée dans le rapport, avec sa raison.
> - Ne jamais modifier les maquettes, la charte (`frontend/design/`) ni `DECOUPAGES.md` sans l'accord de
>   Loick, sauf pour une correction qu'il a demandée.
> - Chaque rapport de fin d'étape contient une section « Ce qui a été modifié ou supprimé en dehors de
>   l'étape » et une section « Tests modifiés ou supprimés, et pourquoi », même vides.

- Maquettes et charte font foi ; pour les factures, backend/docs/FACTURES.md et FACTURE_E2C.md.
- formats.dart est le seul endroit des formats ; montants entiers en FCFA.
- Badge Mode démo, et jamais une donnée simulée présentée comme réelle. Jamais le mot « temps réel ».
- Aucune écriture hors ligne. Toute route GET rangée dans cache_policy.dart, dont GET /payments/{id} jamais en cache.
- Tout modèle ajouté au test de contrat. Aucun test sur le réseau réel.
- Règle 2 sur chaque écran : 360 × 800, texte à 100, 130 et 200 %, clavier ouvert pour les formulaires.
- Verre opaque par défaut ; AppConfig jamais affaibli ; rien de sensible dans l'APK release (apk_check en CI).
- Paiement (F6) : clé d'idempotence ; double toucher = une seule demande ; après Échoué ou Expiré, nouvelle demande avec une nouvelle clé ; après une réponse inconnue, jamais de nouvelle demande, on consulte GET /payments/{id} et un renvoi garde la même clé ; jamais « Échoué » sur un délai dépassé ; Payer désactivé hors ligne ; « Vérification en cours » avec une sortie qui ne paie rien et une mise à jour automatique ; remesurer la fluidité de la vraie feuille de paiement.

## 5. Ce qui reste de F4.0

- Tests d'intégration sur une base dédiée (elecpay_e2e) : integration.ps1 ne doit plus jamais remettre à zéro la base de démo elecpay.
- Les captures de build/integration/ ne sont jamais commitées.
- Commit, push, CI verte.

## 6. F4, découpage et choix déjà validés

### F4.1 : modèles et lectures de l'accueil

- Modèles freezed (factures, résumé de consommation, série de jours, foyers, paiements, notifications), ajoutés au test de contrat.
- Routes rangées dans cache_policy.dart : tout l'accueil est en cache.
- Un homeProvider assemble l'accueil.
- Chaque carte se charge et échoue séparément, prouvé par un test.
- La facture la plus urgente :
  - d'abord une facture en retard (la plus ancienne), sinon l'échéance la plus proche, dans le foyer choisi ;
  - si elle a un paiement en cours, la carte affiche « Paiement en cours » au lieu de Payer ;
  - si un autre foyer a une facture en retard, un rappel « 1 facture en retard dans … » ;
  - le foyer par défaut est celui de la facture la plus urgente, et le choix de l'utilisateur est gardé ;
  - tout est testé.

### F4.2 : Accueil (maquette Main.dc.html)

- En-tête : date, « Bonjour + prénom », badge Mode démo, cloche avec un point rouge.
- Sélecteur de foyer.
- HeroBillCard (opaque) avec Détail et Payer, ou AllPaidCard.
- Carte du mois : kWh depuis le 1er, « Estimation fin de mois : ≈ … », barres des 12 derniers jours, la dernière en pointillé.
- Activité récente : paiements réussis et factures émises fusionnés, avec « Tout voir ».
- Plusieurs compteurs : celui de la facture urgente, avec son nom.
- États : chargement, hors ligne, erreur avec référence, « Ajoutez votre premier compteur ».
- Tirer vers le bas pour actualiser.
- Les liens vers les écrans des étapes suivantes mènent à une page d'attente.

### F4.3 : Notifications (écran 13)

- Groupes Aujourd'hui / Cette semaine / Plus tôt, non-lues mises en avant, « Tout marquer comme lu », défilement par pages.
- Un toucher marque la notification lue et ouvre l'onglet concerné.
- Badge de la cloche mis à jour au retour sur l'app et sur l'accueil, jamais par interrogation périodique.

### F4.4 : clôture

- Un parcours d'intégration de l'accueil et des notifications.
- Rapport rapports/F4.md, tableaux de bord, CI verte.

## 7. Résumé de ce que tu attends de moi

- Mon accord sur settings.local.json, au début.
- Ma validation de DECOUPAGES.md (F5 à F10).
- Ma validation en F6, avant l'envoi réel du paiement.
- Ma présence pour la vérification finale sur l'itel, à la fin de F10.

Tout le reste, tu le fais seul.
