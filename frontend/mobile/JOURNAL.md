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
  - `frontend/mobile/DECOUPAGES.md` (F5 → F10, décisions D5.1 … D10.4) commité : **en attente de la
    validation de Loick** (deuxième accord, obligatoire avant F6).
- **En cours** : F4.2 (écran Accueil, maquette `Main.dc.html`) sur `f4`.
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

## Commandes utiles

- Tests et analyse : `cd frontend/mobile; flutter analyze; flutter test`
- Format (jamais les fichiers générés) :
  `find lib test tool integration_test test_driver -name '*.dart' ! -name '*.g.dart' ! -name '*.freezed.dart' | xargs dart format`
- Code généré : `dart run build_runner build -d`
- API de démo : `cd backend; .\.venv\Scripts\uvicorn.exe app.main:app --host 127.0.0.1 --port 8000`
- Tests sur le téléphone : `.\tool\integration.ps1 -Device <IP:port>` (base `elecpay_e2e`, jamais `elecpay`)
- État de la CI sans `gh` : API publique `https://api.github.com/repos/Loick07/Elecpay/actions/runs`
