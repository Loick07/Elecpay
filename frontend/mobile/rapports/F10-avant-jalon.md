# F10 — arrêt avant la CI de l'APK livré et le jalon final

État au 21/11/2026, branche `f10`. **F10.0 → F10.4 (partie `frontend/`) sont faits**, intégrés dans
`main`, CI verte. Il reste deux choses qui demandent Loick : la **CI de l'APK livré** (fichier hors de
mon périmètre) et le **jalon final sur l'itel** (F10.5). Le rapport complet `rapports/F10.md` suivra.

## Fait

- **F10.0 — Un seul « charger la suite »** (ajout de Loick, rapport de F5) : Notifications utilise
  maintenant `LoadMoreFooter`, comme Factures et Historique. Un test interdit toute copie dans les écrans.
- **F10.1 — Revue des états, écran par écran** :
  - Compte : si le profil ne se lit pas (hors connexion sans cache, ou erreur du serveur), l'écran le dit
    (« Hors connexion : profil non chargé. Réessayer » / « Profil illisible : réessayer ») au lieu d'un
    en-tête vide ;
  - tests ajoutés : chargement (détail de facture, reçu, historique, foyers, notifications, profil),
    Compte hors ligne avec et sans cache, profil hors connexion, « Mot de passe et sécurité » hors
    connexion (message clair, rien de changé, aucune relance) ;
  - les autres états (vide, erreur, accès refusé, session expirée, paiement en attente / échoué /
    inconnu) avaient déjà leurs tests, écran par écran ;
  - la page d'attente « … : bientôt » est retirée : plus aucun lien n'y menait.
- **F10.2 — Accessibilité** (`test/app/accessibility_test.dart`), sur les 17 écrans et feuilles client, à
  l'écran de l'itel :
  - zones tactiles d'au moins 48 points, toutes avec un libellé lu par TalkBack ;
  - contraste du texte (thème Nuit partout, et thème Jour sur 5 écrans) ;
  - texte à 200 % : rien ne déborde, du haut au bas de chaque écran.

  Tout passe. J'ai vérifié que ces règles échouent bien sur un mauvais écran (petite cible, texte gris
  sur gris) : elles ne passent pas « à vide ».
- **F10.3 — Parcours complet** (`integration_test/full_journey_test.dart`) : inscription → compteur
  (nouveau foyer) → consommation → facture à payer → paiement simulé → reçu → historique. **Pas encore
  joué** : il se joue sur l'itel, au jalon (base `elecpay_e2e`).
- **F10.4 — APK livré, partie `frontend/`** :
  - construction : `--split-per-abi --obfuscate --split-debug-info`, avec
    `API_BASE_URL=https://omnivore-pardon-sixth.ngrok-free.dev` (sans chemin : l'application ajoute
    `/api/v1` ; j'avais écrit `…/api/v1` dans M1, c'est corrigé) ;
  - tailles : **itel (armeabi-v7a) 15,9 Mo**, arm64 18,5 Mo, x86_64 19,9 Mo (objectif < 25 Mo ; 17,6 Mo
    avant, toutes architectures dans un seul APK). Obscurcissement vérifié : aucun nom de classe dans le
    code compilé ; symboles rangés dans `build/symbols/` ;
  - `apk_check` : deux contrôles en plus, `--api-url` (l'adresse https est bien compilée dans l'APK) et
    `--signature=release` (refuse la clé de débogage d'Android, via `apksigner`), avec leurs tests ;
  - signature : `android/app/build.gradle.kts` lit ta clé dans `android/key.properties` (ignoré par git)
    ou dans les variables `ELECPAY_KEYSTORE_*` (CI). Sans clé, Gradle signe en débogage, le dit, et
    `apk_check --signature=release` refuse l'APK (vérifié). **Testé avec une clé jetable** créée dans
    `build/tmp/jetable.jks` : APK signé, tous les contrôles OK ;
  - guide `docs/LIVRAISON.md` : créer la clé, construire, contrôler, installer.

## ⚠️ Rappel pour le rapport de F10

**L'APK release est construit, signé et contrôlé, mais il ne sera utilisable qu'après M1** : il exige
le HTTPS, donc l'API exposée par ngrok. La vérification finale de F10 se fait avec un **APK profile**
branché sur l'API du PC, comme aux jalons.

## Ce que j'attends de toi

1. **La CI de l'APK livré** : c'est `.github/workflows/mobile.yml`, hors de `frontend/`, et tu m'as dit
   de ne rien changer à la CI. Je propose de modifier seulement l'étape « Construire l'APK release » :
   - construire avec `--split-per-abi --obfuscate --split-debug-info=build/symbols` et
     `--dart-define=API_BASE_URL=https://omnivore-pardon-sixth.ngrok-free.dev` ;
   - contrôler **chaque** APK avec `apk_check`, en ajoutant `--api-url=…`, et écrire la taille de chacun
     dans le résumé ;
   - signature :
     - **a)** sans secrets GitHub : la CI garde la clé de débogage et vérifie
       `--signature=debug`. L'APK livré est alors signé chez toi, avec ta clé ;
     - **b)** avec tes 4 secrets (`ELECPAY_KEYSTORE_FILE` en base64, mots de passe, alias) : la CI signe
       avec ta clé et vérifie `--signature=release`.
   - **Ma recommandation : a)**. Ta clé ne sort jamais de ton PC ; la CI contrôle tout le reste.
   - **Ta réponse** : oui / non pour la modification de `mobile.yml`, et a) ou b).
2. **Ta clé de l'APK livré** (D10.1) : la créer avec `docs/LIVRAISON.md` (section 1) et la sauvegarder
   hors du PC. **Ne me l'envoie jamais**, ni ses mots de passe.
3. **Le jalon final (F10.5)**, quand tu es prêt avec l'itel en débogage sans fil :
   - donne-moi l'adresse `IP:port` ;
   - je joue les 17 tests d'intégration (les 16 du jalon F4–F7 et le parcours complet), sur
     `elecpay_e2e` seulement ;
   - ensuite, avec toi : Compteurs et foyers (F8), Compte et assistance (F9), texte agrandi, TalkBack,
     sur un APK profile branché sur l'API du PC.
4. **Fichier à supprimer de ton côté** (je ne supprime rien) : `frontend/mobile/build/tmp/jetable.jks`,
   la clé jetable du test (dans `build/`, ignoré par git, jamais livrée). L'APK
   `app-armeabi-v7a-release.apk` du dossier de construction est signé avec cette clé : **ne pas
   l'installer**, il sera reconstruit.

## Points à surveiller

- Un test (`add_meter_sheet_test` : clavier ouvert et texte à 200 %) a échoué **une fois** pendant une
  suite complète, puis a passé seul et dans trois suites complètes. Je n'ai rien changé : je le surveille.
- Avertissement de Flutter au build : « unobfuscated DWARF debugging information ». L'option `--strip`
  qu'il propose n'existe pas dans `flutter build apk` (Flutter 3.47), et le code est bien obscurci
  (vérifié). À revoir si Flutter ajoute l'option.

## Tests

1781 tests au vert (1706 à la fin de F9), analyse et format comme en CI.
