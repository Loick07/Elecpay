# Journal de reprise (développement autonome F4 → F10)

À relire au début de chaque session, avec `CLAUDE.md` et `frontend/mobile/AUTONOMIE.md`.
Mis à jour et commité avec chaque sauvegarde.

## État au 19/11/2026

- **F4 terminé** (rapport `rapports/F4.md`), intégré dans `main`. **On attend le « Continue » de Loick**
  avant de commencer F5 (méthode du 19/11/2026 : arrêt en fin d'étape).
- `DECOUPAGES.md` validé (précisions de Loick en tête du fichier : elles l'emportent).
- Règles ajoutées le 19/11/2026 (`AUTONOMIE.md`, section 4) : ne jamais affaiblir un test ou un contrôle
  pour passer la CI ; pas de suppression hors périmètre ; pas de modification de `frontend/design/` ni de
  `DECOUPAGES.md` sans accord ; deux sections obligatoires dans chaque rapport.
- `.claude/settings.local.json` écrit (accord du 19/11/2026). Pas d'`Edit` dans `backend/`.
- `gh` installé mais pas connecté : CI lue par l'API publique de GitHub.

## Prochaine action

1. Après le « Continue » de Loick : branche `f5` depuis `main`, puis F5.1 (modèles et lectures des
   factures) selon `DECOUPAGES.md` (avec `share_plus` et `open_filex` en versions fixes, et le contrôle
   des autorisations de l'APK dans `apk_check` pour F5.4).
2. Jalon de mi-parcours après F5 : si l'itel est connecté, `tool/integration.ps1` avec
   `auth_flows_test.dart` puis `home_notifications_test.dart` (base `elecpay_e2e`).

## Choix faits en route

- Statuts (facture, transaction, rôle) et types de notification gardés en texte dans les modèles.
- Aucune relance automatique des lectures (`noAutomaticRetry`), sur tout conteneur Riverpod.
- Deux lectures en parallèle : `Future.wait` (garde l'`ApiFailure` d'origine), jamais `(a, b).wait`.
- Accueil : compte neuf → seulement « Ajoutez votre premier compteur » ; rien de lisible → un seul bloc.
- Liens vers les étapes suivantes : page d'attente poussée `/accueil/bientot?ecran=…&etape=…`.
- Notifications : toucher → onglet concerné ; hors ligne, lecture seule.

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
- État de la CI sans `gh` : API publique `https://api.github.com/repos/Loick07/Elecpay/actions/runs`
