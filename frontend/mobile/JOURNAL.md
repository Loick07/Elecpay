# Journal de reprise (développement autonome F4 → F10)

À relire au début de chaque session, avec `CLAUDE.md` et `frontend/mobile/AUTONOMIE.md`.
Mis à jour et commité avec chaque sauvegarde.

## État au 20/11/2026

- **F4, F5 et F6 terminés**, intégrés dans `main`, CI verte (rapports `rapports/F4.md`, `F5.md`,
  `F6-avant-paiement.md`, `F6.md`). **On attend le « Continue » de Loick** avant F7.
- Paiement réel branché avec l'accord de Loick (F6.3). Dates de période ajoutées au contrat du backend
  (branche `f6-dates-periode`, accord de Loick, ajout seulement).
- Jalon sur le téléphone : **groupé F4 + F5 + F6**, dès que l'itel revient (liste dans `rapports/F6.md`).
- `test/_debug` : supprimé par Loick, vérifié absent le 20/11/2026.
- Proposition en attente de Loick : cache Gradle dans la CI (touche `.github/`, hors de mes droits).

## Prochaine action

1. Après le « Continue » : branche `f7` depuis `main`, découpage de F7 dans `DECOUPAGES.md` (F7.1
   lectures de consommation…), avec D7.1 (Mois par défaut), D7.2 (Direct simulé en démo seulement),
   D7.3 (légende du calendrier + niveau lu par TalkBack).

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
