# Journal de reprise (développement autonome F4 → F10)

À relire au début de chaque session, avec `CLAUDE.md` et `frontend/mobile/AUTONOMIE.md`.
Mis à jour et commité avec chaque sauvegarde.

## État au 24/11/2026 (fin de F10)

- **F4 → F10 terminés**, intégrés dans `main`, CI verte (rapports `rapports/F4.md` à `F10.md`,
  `jalon-F4-F7.md`, `F10-avant-jalon.md`). **On attend le « Continue » de Loick** avant M1.
- **M1 — Mise en ligne** par **ngrok** (`omnivore-pardon-sixth.ngrok-free.dev`, API du PC port 8000) :
  M1.1 seed de production sûr (refuser `Demo2026!`, secrets 2FA au hasard, testé) **avec l'accord de
  Loick avant de toucher `backend/`** ; l'authtoken ngrok n'est jamais transmis ; ngrok s'installe
  seulement après M1.1.
- **Clé de l'APK livré** : `android/key.properties` chez Loick. **Ne jamais lire ce fichier ni en
  demander le contenu.** APK livrés : `flutter build apk --release --split-per-abi --obfuscate
  --split-debug-info=build/symbols --dart-define=API_BASE_URL=https://omnivore-pardon-sixth.ngrok-free.dev`.
- **Itel** : utiliser son nom mDNS (`adb-1053140373000920-CyJJM4._adb-tls-connect._tcp`), qui suit les
  changements de port ; le débogage sans fil se coupe au bout d'un moment ; **chargeur mural**
  obligatoire (il se décharge sur le port USB du PC). Ne jamais arrêter `integration.ps1` pendant la
  préparation de la base. Taille du texte de l'itel : remise à 1.0 le 24/11/2026.
- Décisions de Loick (20/11/2026) : CI sans relance automatique (`setup-gradle` si les pannes Maven
  deviennent fréquentes) ; captures avec les vraies polices ; `tool/integration.ps1` aux jalons, base
  `elecpay_e2e` seulement (supprimée et recréée à chaque passage depuis F10).
- Fichiers temporaires : dans `build/tmp/` (ignoré par git), **jamais** `test/zz_*`.
- **Avant chaque commit** : ajouter les fichiers un par un, relire `git status` ; ne jamais lancer
  `dart format` sur un dossier qui contient des `*.g.dart` (les remettre avec `git restore` sinon).

## Vidéo de démonstration : EN PAUSE, à refaire plus tard (décision de Loick, 27/11/2026)

Demande : film des 16 écrans client sur l'itel, ~3 s par écran, base `elecpay_e2e` seulement ;
titre « ElecPay — Démonstration (données simulées) », nom de chaque écran en bas, fin « ElecPay —
Loick Makosso » ; résultat dans `C:\Users\makos\ElecPay-livraisons\video\ElecPay-demo.mp4`.
**Rien n'a été filmé.** Deux essais, la nuit du 26 au 27/11 : le premier coupé par une coupure de
courant (PC et itel redémarrés), le second bloqué à l'installation de l'appli de test (15 min sur
« Performing Streamed Install », puis l'itel a disparu d'adb). Loick a remis le téléphone à la normale.

Ce qui est prêt (commité) :
- `integration_test/demo_video_test.dart` : le parcours, avec ses repères `DEMO_*` dans logcat
  (analyse et format au vert ; **jamais joué en entier**) ;
- `tool/video/tournage.py <série adb>` : lancé **avant** le parcours, il lit les repères, filme par
  segments (`screenrecord` s'arrête à 180 s : relance pendant la pause fixe d'un écran) et referme le
  lecteur PDF (Google Drive par défaut sur l'itel) ; testé seul sur l'itel (deux segments, arrêt propre) ;
- `tool/video/montage.py <sortie.mp4>` : cartons, cadre, légendes (Poppins), fondus ; images fixes
  vérifiées, **jamais essayé sur un vrai tournage** (vérifier les légendes image par image).
  Python du `backend/.venv` (Pillow) ; ffmpeg 9.1 de WinGet (hors du PATH de Bash).

Leçons (à suivre la prochaine fois) :
1. **Installer l'appli de test SANS le mode avion** : hors connexion, Play Protect bloque
   l'installation par adb (fenêtre qui attend un toucher, ou vérification qui n'aboutit pas).
   Installer en Wi-Fi, puis préparer le tournage.
2. **Filmer avec « Ne pas déranger » en silence total** (`cmd notification set_dnd none`) et la
   **barre d'état en mode démo** ; sur l'itel, renvoyer `clock -e hhmm 1000` et `battery` après
   `enter` (le premier envoi est ignoré). Les deux se perdent si le téléphone redémarre : revérifier
   par une capture juste avant de lancer.
3. **Téléphone sur le chargeur mural** (il se décharge sur le port USB du PC).
4. `flutter drive` remplace l'APK release (clé de Loick) par la version profile (clé de débogage) :
   garder une copie de l'APK installé (`adb shell pm path` puis `adb pull`) pour le réinstaller à la fin.
5. Sur l'itel, **jamais `pkill`** (`pkill -2 screenrecord` vise aussi des processus du système) :
   `kill -2 $(pidof screenrecord)`. Dans Git Bash : `MSYS_NO_PATHCONV=1` pour les chemins `/sdcard/…`.
6. Remise en état à la fin : « Ne pas déranger » en prioritaire (`set_dnd priority`), sortie du mode
   démo de la barre d'état, APK release réinstallé ; puis prévenir Loick (API publique à relancer).

## Prochaine action

1. **Back-office d'administration (Next.js, `frontend/admin/`)** : lancé officiellement par Loick le
   27/11/2026 ; attendre son message de lancement (consignes) avant toute action.
2. À rejouer au prochain jalon (port 8000 libre, API publique arrêtée) : `integration_test/account_test.dart`
   (recherche « recu » avec les mots-clés).
3. Ne jamais lire `backend/deploy/ngrok.env` ni demander l'authtoken ou `DEMO_SEED_PASSWORD`.

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
- Captures : `tester.binding.renderViews.first` (feuilles comprises), bornes en pixels physiques ;
  charger Poppins, Lucide et JetBrainsMono avec `FontLoader`.
- Fichiers écrits avec l'outil Write : vérifier qu'aucune espace insécable n'est en dur (garde
  `test/source_characters_test.dart`).

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
