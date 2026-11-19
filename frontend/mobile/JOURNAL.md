# Journal de reprise (développement autonome F4 → F10)

À relire au début de chaque session, avec `CLAUDE.md` et `frontend/mobile/AUTONOMIE.md`.
Mis à jour et commité avec chaque sauvegarde.

## État au 19/11/2026

- **F4 et F5 terminés** (rapports `rapports/F4.md`, `rapports/F5.md`), intégrés dans `main`, CI verte.
  **On attend le « Continue » de Loick** avant F6.
- **Jalon sur le téléphone REPORTÉ** : l'itel de Loick ne démarre plus. Il devient un **jalon groupé
  F4 + F5 + F6**, à jouer dès que l'itel revient (liste complète en fin de `rapports/F5.md`) : tests
  d'intégration `auth_flows_test.dart`, `home_notifications_test.dart`, `bills_test.dart` (+ ceux de F6),
  captures, PDF ouvert et partagé, texte à 130 / 200 %, TalkBack, fluidité, vraie feuille de paiement.
- `test/_debug/pages_debug_test.dart` : Loick dit l'avoir supprimé, mais il était encore présent le
  19/11/2026 au soir ; jamais commité (`git add -A -- . ':!test/_debug'` tant qu'il existe).

## Prochaine action

1. Après le « Continue » : branche `f6` depuis `main`, F6.1 (modèles et règles du paiement, sans envoi
   réel) selon `DECOUPAGES.md` (avec la précision : après 2 min, interroger environ toutes les 15 s).
2. Arrêt obligatoire avant F6.3 (branchement de `POST /payments`) : rapport et accord de Loick.

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
