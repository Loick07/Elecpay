# Journal de reprise (développement autonome F4 → F10)

À relire au début de chaque session, avec `CLAUDE.md` et `frontend/mobile/AUTONOMIE.md`.
Mis à jour et commité avec chaque sauvegarde.

## État au 19/11/2026

- **F4 terminé et validé par Loick.** **F5 (factures) en cours**, branche **`f5`** (« Continue » reçu).
- Sous-étapes de F5 faites, intégrées dans `main`, CI verte : F5.1 (a5d40ef), F5.2 (c83d7b4), F5.3 (efacfd9).
- **En cours : F5.4 (PDF)**, pas encore commité :
  - `share_plus` 13.3.1 et `open_filex` 5.0.0 (versions fixes) ; `lib/core/documents/documents.dart`
    (téléchargement dans le dossier privé, ouverture, partage ; remplaçables en test) ;
  - `ApiClient.getBytes` (+ corps d'erreur relu en JSON : sinon un 404 donnait « réponse inattendue ») ;
  - `apk_check` : liste blanche des autorisations, toujours active ; `open_filex` déclarait
    READ_EXTERNAL_STORAGE et READ_MEDIA_* : retirées dans le manifeste (`tools:node="remove"`), inutiles
    pour un fichier du dossier privé (vérifié dans son code) ; `<queries>` VIEW application/pdf ;
  - détail : « PDF » collé en bas et « Partager » en haut, désactivés hors ligne ;
  - à faire : APK release + `apk_check` (en cours de construction), suite complète, commit, fusion.
- **Fichier à supprimer par Loick** : `test/_debug/pages_debug_test.dart` (test de débogage temporaire ;
  la suppression m'a été refusée, il n'est jamais commité : `git add -A -- . ':!test/_debug'`).
- Reste ensuite : F5.5 (clôture, jalon sur l'itel : prévenir Loick un peu avant).

## Prochaine action

1. Finir F5.4 (voir ci-dessus), puis F5.5 : prévenir Loick pour le jalon (itel en débogage sans fil),
   jouer `auth_flows_test.dart`, `home_notifications_test.dart` et un test d'intégration des factures,
   captures listées dans `rapports/F4.md` + celles de F5 ; rapport `rapports/F5.md` ; arrêt.

## Choix faits en route

- Statuts (facture, transaction, rôle) et types gardés en texte dans les modèles.
- Aucune relance automatique des lectures (`noAutomaticRetry`).
- Deux lectures en parallèle : `Future.wait` (garde l'`ApiFailure` d'origine), jamais `(a, b).wait`.
- **F5 : « Mes factures » groupé par PÉRIODE** (maquette et FACTURES.md), pas par mois d'émission comme
  le disait à tort ma recommandation D5.2 : la maquette fait foi ; à signaler dans le rapport de F5.
- Bouton « Rechercher une facture » de la maquette : pas fait (aucune recherche dans l'API) ; à signaler.
- Onglets de filtre en `Wrap` (pas de défilement horizontal) : tout reste visible à 200 %.
- Police des tests = police carrée de Flutter (lettres plus larges que Poppins) : lignes plus hautes
  qu'en vrai, il faut beaucoup défiler dans les tests ; ce n'est pas un défaut de l'écran.

## Commandes utiles

- **Avant chaque commit** : `git branch --show-current` (jamais `main`) ; **juste après chaque fusion**
  dans `main` : `git switch` de retour sur la branche de l'étape.
- Tests et analyse (depuis `frontend/mobile`) : `flutter analyze`, `flutter test --reporter failures-only`
- Format exactement comme la CI, **juste avant chaque commit** :
  `git ls-files '*.dart' | grep -vE '\.(g|freezed)\.dart$' | xargs dart format --output=none --set-exit-if-changed`
- Code généré : `dart run build_runner build -d`
- APK de l'itel : `flutter build apk --release --target-platform android-arm` ; contrôles :
  `dart run tool/apk_check.dart build/app/outputs/flutter-apk/app-release.apk --cleartext=false --diagnostic=absent --demo-password=absent --lucide=reduced --launcher-icon=custom`
- API de démo : `cd backend; .\.venv\Scripts\uvicorn.exe app.main:app --host 127.0.0.1 --port 8000`
- Tests sur le téléphone : `.\tool\integration.ps1 -Device <IP:port> [-Target integration_test/…]`
  (base `elecpay_e2e`, jamais `elecpay`)
- CI : `gh run list`, `gh run view <id> --log-failed`, `gh run watch <id> --exit-status --compact`
