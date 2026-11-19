# Journal de reprise (développement autonome F4 → F10)

À relire au début de chaque session, avec `CLAUDE.md` et `frontend/mobile/AUTONOMIE.md`.
Mis à jour et commité avec chaque sauvegarde.

## État au 19/11/2026 (soir)

- **F4 et F5 terminés et validés.** **F6 en cours**, branche **`f6`**.
- Sous-étapes de F6 faites, intégrées dans `main` : F6.0 (4631475, libellés de période à partir des
  dates), F6.1 (57f27f7, règles du paiement), F6.2 (2c214b9, feuille + écran d'attente + points
  d'entrée). CI verte sur F6.0, F6.1 et F6.2.
- **ARRÊT OBLIGATOIRE** : rapport `rapports/F6-avant-paiement.md` remis à Loick ; **on attend son accord
  avant F6.3** (branchement réel de `POST /payments`). La passerelle de l'application est
  `NotYetConnectedPaymentGateway` : aucune requête de paiement ne part.
- Question posée dans le rapport : ajouter les dates de période aux paiements, reçus et « facture
  précédente » côté **backend** (accord de Loick nécessaire avant de toucher `backend/`).
- Jalon sur le téléphone : **groupé F4 + F5 + F6**, dès que l'itel revient.
- `test/_debug/pages_debug_test.dart` : toujours présent sur le disque ; jamais commité
  (`git add -A -- . ':!test/_debug'`).

## Prochaine action

1. Après l'accord de Loick : F6.3, `ApiPaymentGateway` (`POST /payments` + `Idempotency-Key` par le client
   authentifié, `GET /payments/{id}` en direct), tests sur faux serveur, test d'intégration avec les
   numéros de test du simulateur.
2. Puis F6.4 (reçu), F6.5 (historique), rapport `rapports/F6.md`, arrêt de fin d'étape.

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
