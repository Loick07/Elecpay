# Journal de reprise (développement autonome F4 → F10)

À relire au début de chaque session, avec `CLAUDE.md` et `frontend/mobile/AUTONOMIE.md`.
Mis à jour et commité avec chaque sauvegarde.

## État au 19/11/2026

- **Étape en cours** : F4 (accueil et notifications), branche **`f4`**. Sous-étapes validées : F4.0 (tests
  d'intégration sur le téléphone, base `elecpay_e2e`), F4.1 (modèles et lectures de l'accueil, f295202).
- **Autonomie en place** :
  - `.claude/settings.local.json` écrit avec l'accord de Loick (19/11/2026), ignoré par git (ligne ajoutée
    au `.gitignore` du dépôt). Pas d'`Edit` dans `backend/` : si le backend doit changer, s'arrêter et
    demander.
  - `frontend/mobile/DECOUPAGES.md` **validé par Loick le 19/11/2026** (toutes les recommandations +
    précisions en tête du fichier : versions fixes share_plus / open_filex, contrôle des autorisations de
    l'APK, interrogation lente toutes les 15 s après 2 min, légende du calendrier, F9.5 Mise en ligne
    Oracle + Caddy + DuckDNS). Enchaîner F4 → F5 → F6 (jusqu'à l'arrêt avant `POST /payments`).
- **En cours** : F4.2 (écran Accueil, maquette `Main.dc.html`) sur `f4`.
  - Fait (sauvegarde 2122940) : `lib/features/home/home_screen.dart` + `home_cards.dart`, page d'attente
    `lib/features/pending/` (route `/accueil/bientot?ecran=…&etape=…`, protégée), formats
    `formatWeekdayDate`, `formatMonthSoFar`, `formatApproxKwh`, `formatApproxFcfa`, icônes cloche et
    chevron, `HeroBillCard(payment: HeroPayment.inProgress / none)`, 26 tests de l'écran.
  - Défauts trouvés par les tests et corrigés : ligne d'activité qui débordait à 200 % (montant sous le
    titre au-delà de 130 %) ; `(a, b).wait` enveloppait l'erreur (`ParallelWaitError`) → carte sans
    « Hors connexion » ni référence (remplacé par `Future.wait`) ; libellé de la cloche fusionné avec la
    date pour TalkBack (`Semantics(container: true)`).
  - Reste : suite complète + analyse au vert, commit propre, intégration dans `main`, CI.
- **CI** : verte sur bc09e44 (main, contient F4.1). L'échec de F4.0 (ea3bad7) était passager.
  `gh` installé (2.105.0) mais **pas encore connecté** (`gh auth login` à faire par Loick) : en attendant,
  état de la CI lu par l'API publique de GitHub.

## Prochaine action

1. F4.2 : écran Accueil (en-tête, sélecteur de foyer, HeroBillCard / AllPaidCard, carte du mois, activité
   récente, états, tirer pour actualiser, pages d'attente).
2. Intégrer la réponse de Loick sur DECOUPAGES.md dès qu'elle arrive.

## Choix faits en route

- Statuts (facture, transaction, rôle) gardés en texte dans les modèles, comme `statuses.dart` (une valeur
  nouvelle de l'API ne fait pas planter l'application).
- Aucune relance automatique des lectures (`noAutomaticRetry`), sur tout conteneur Riverpod.
- Accueil : compte neuf (aucun compteur, rien à payer) → seulement « Ajoutez votre premier compteur »
  (pas de « Tout est payé » trompeur). Ni compte, ni foyers, ni factures lisibles → un seul bloc d'état.
- Estimation de fin de mois : énergie seule (`energy_cost`, comme la maquette), arrondie (≈ kWh entier,
  ≈ centaine de FCFA). Barres : la dernière (journée pas finie) et les jours estimés en pointillé.
- Liens vers F4.3 → F8 : page d'attente poussée (sans barre du bas, bouton retour).

## Commandes utiles

- Tests et analyse : `cd frontend/mobile; flutter analyze; flutter test`
- Format (jamais les fichiers générés) :
  `find lib test tool integration_test test_driver -name '*.dart' ! -name '*.g.dart' ! -name '*.freezed.dart' | xargs dart format`
- Code généré : `dart run build_runner build -d`
- API de démo : `cd backend; .\.venv\Scripts\uvicorn.exe app.main:app --host 127.0.0.1 --port 8000`
- Tests sur le téléphone : `.\tool\integration.ps1 -Device <IP:port>` (base `elecpay_e2e`, jamais `elecpay`)
- État de la CI sans `gh` : API publique `https://api.github.com/repos/Loick07/Elecpay/actions/runs`
