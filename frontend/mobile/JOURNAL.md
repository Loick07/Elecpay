# Journal de reprise (développement autonome F4 → F10)

À relire au début de chaque session, avec `CLAUDE.md` et `frontend/mobile/AUTONOMIE.md`.
Mis à jour et commité avec chaque sauvegarde.

## État au 19/11/2026

- **Étape en cours** : F4 (accueil et notifications). Sous-étapes validées : F4.0 (tests d'intégration sur
  le téléphone, base `elecpay_e2e`), F4.1 (modèles et lectures de l'accueil, commit f295202).
- **En cours** : mise en place de l'autonomie (consignes du 19/11/2026).
  - Fait : `AUTONOMIE.md` (consignes copiées), ligne ajoutée dans `CLAUDE.md` (« Méthode de travail »).
  - En attente de Loick : son accord sur `.claude/settings.local.json` (proposé, pas encore écrit).
- **CI** : F4.0 (ea3bad7) rouge à l'étape « Construire l'APK release », non reproduite en local (même
  état : APK construit). `gh` n'est pas installé sur la machine : journal de la CI illisible d'ici.
  La CI de F4.1 (f295202) rejoue la même construction : son résultat tranchera.

## Prochaine action

1. Après l'accord de Loick : écrire `.claude/settings.local.json`.
2. Créer la branche `f4` ; écrire `frontend/mobile/DECOUPAGES.md` (F5 → F10, décisions et
   recommandations), le commiter, et attendre la validation de Loick.
3. Pendant ce temps : F4.2 (écran Accueil, maquette `Main.dc.html`) sur la branche `f4`.

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
