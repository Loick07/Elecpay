# Journal de reprise (développement autonome F4 → F10)

À relire au début de chaque session, avec `CLAUDE.md` et `frontend/mobile/AUTONOMIE.md`.
Mis à jour et commité avec chaque sauvegarde.

## État au 20/11/2026 (fin de F7, jalon F4 + F5 + F6 + F7)

- **F4, F5, F6 et F7 terminés**, intégrés dans `main`, CI verte (rapports `rapports/F4.md` à `F7.md`).
  Rapport F7 validé par Loick le 20/11/2026.
- **Jalon groupé F4 + F5 + F6 + F7** sur l'itel (de retour, débogage sans fil `192.168.1.68:42519`) :
  branche `jalon-f4-f7`, rapport `rapports/jalon-F4-F7.md`. Ensuite : **F8, « Continue » donné**.
- Décisions de Loick (20/11/2026) :
  - CI : rien ne change, pas de relance automatique ; lire le journal avant de relancer ;
    `gradle/actions/setup-gradle` seulement si les pannes Maven deviennent fréquentes ;
  - captures avec les vraies polices : méthode à garder ;
  - `tool/integration.ps1` autorisé aux jalons, base `elecpay_e2e` seulement (noté dans `AUTONOMIE.md`).
- Rappel : ajouter les fichiers un par un et relire `git status` avant chaque commit.

## Prochaine action

1. Finir le jalon F4 → F7 (rapport, fusion), puis branche `f8` depuis `main`, découpage de F8 dans
   `DECOUPAGES.md`.

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
- **F7 : la police carrée des tests cache les problèmes de largeur** (onglets empilés, « → » absent de
  Poppins) : une capture avec les vraies polices (test temporaire, `FontLoader` sur `assets/fonts/`)
  les a montrés. À refaire pour tout écran dense, tant que l'itel est en panne.
- F7 : en test, `dragUntilVisible(finder.hitTestable(), …)` (un élément construit hors écran n'est pas
  « visible » pour un toucher).

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
