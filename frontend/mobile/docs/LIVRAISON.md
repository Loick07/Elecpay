# Livrer l'APK d'ElecPay (F10.4)

Ce guide sert à **construire, signer, contrôler et installer** l'APK livré de l'application client.
Toutes les commandes se lancent dans PowerShell, **depuis `frontend/mobile`**.

> **À savoir avant tout** : l'APK livré exige une API en **https** (`AppConfig` refuse le HTTP en
> clair). Il ne fonctionne donc qu'**après l'étape M1** (API du PC exposée par ngrok sur
> `https://omnivore-pardon-sixth.ngrok-free.dev`). Jusque-là, on vérifie l'application sur l'itel avec
> un **APK profile** branché sur l'API du PC (`docs/TELEPHONE.md`).

## 1. Créer la clé de l'APK livré (une seule fois, par Loick)

La clé prouve que chaque mise à jour vient bien d'ElecPay. **Si elle est perdue, plus aucune mise à
jour n'est possible** pour les téléphones qui ont déjà l'application. Elle reste chez toi : **jamais
dans le dépôt** (`*.jks` et `key.properties` sont ignorés par git), **jamais envoyée à Claude**.

1. Créer la clé, en dehors du dépôt (exemple : `C:\Users\<toi>\cles\elecpay-release.jks`) :

   ```powershell
   keytool -genkeypair -v -keystore "$env:USERPROFILE\cles\elecpay-release.jks" `
     -storetype JKS -keyalg RSA -keysize 4096 -validity 10000 -alias elecpay
   ```

   `keytool` est fourni avec Android Studio (`C:\Program Files\Android\Android Studio\jbr\bin`).
   Choisis un mot de passe solide et note-le dans ton gestionnaire de mots de passe.
2. **Sauvegarder** le fichier `.jks` et son mot de passe **hors du PC** (clé USB rangée, coffre).
3. Créer `frontend/mobile/android/key.properties` (ignoré par git) :

   ```properties
   storeFile=C:\\Users\\<toi>\\cles\\elecpay-release.jks
   storePassword=<mot de passe>
   keyAlias=elecpay
   keyPassword=<mot de passe>
   ```

Sans ce fichier, Gradle signe l'APK avec la **clé de débogage** et le dit dans le journal
(« aucune clé de l'APK livré ») ; `apk_check --signature=release` le refuse.

**En CI** (seulement si Loick le décide) : les mêmes valeurs deviennent des secrets GitHub
`ELECPAY_KEYSTORE_FILE` (fichier recréé depuis un secret en base64), `ELECPAY_KEYSTORE_PASSWORD`,
`ELECPAY_KEY_ALIAS`, `ELECPAY_KEY_PASSWORD`, lus par `android/app/build.gradle.kts`.

## 2. Construire l'APK livré

```powershell
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/symbols `
  --dart-define=API_BASE_URL=https://omnivore-pardon-sixth.ngrok-free.dev
```

- `--split-per-abi` : un APK par type de processeur, dans `build/app/outputs/flutter-apk/` :
  - `app-armeabi-v7a-release.apk` : **celui de l'itel A05s** (processeur 32 bits) ;
  - `app-arm64-v8a-release.apk` : la plupart des téléphones récents ;
  - `app-x86_64-release.apk` : émulateurs.
- `--obfuscate --split-debug-info` : noms du code effacés dans l'APK. Les symboles restent dans
  `build/symbols/` : **les garder avec chaque version livrée**, ils servent à relire un plantage.
- `API_BASE_URL` : **sans chemin** (l'application ajoute `/api/v1`), **en https**.

## 3. Contrôler l'APK livré

```powershell
dart run tool/apk_check.dart build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk `
  --cleartext=false --diagnostic=absent --demo-password=absent --lucide=reduced `
  --launcher-icon=custom --api-url=https://omnivore-pardon-sixth.ngrok-free.dev --signature=release
```

Le contrôle affiche la taille (objectif : **moins de 25 Mo**) et refuse l'APK si :
- le HTTP en clair est permis, ou les sauvegardes Android sont actives ;
- une autorisation hors liste blanche est demandée (l'APK n'a qu'`INTERNET`) ;
- la page Diagnostic ou le mot de passe de démo est dedans ;
- l'icône Flutter par défaut est restée, ou le nom affiché n'est pas « ElecPay » ;
- l'adresse https de l'API n'est pas celle donnée au build ;
- l'APK est signé avec la clé de débogage.

## 4. Installer sur un téléphone

- **Par câble ou débogage sans fil** (téléphone en mode développeur, `docs/TELEPHONE.md`) :

  ```powershell
  adb install -r build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
  ```

- **Sans PC** : envoyer l'APK sur le téléphone (câble, WhatsApp, Drive), l'ouvrir, puis autoriser
  « Installer des applications inconnues » **pour l'application qui ouvre le fichier** (Fichiers,
  WhatsApp…), le temps de l'installation seulement.
- Un APK signé avec la clé de débogage ne peut pas remplacer un APK signé avec la clé livrée (et
  inversement) : désinstaller d'abord l'ancienne version (les données de l'application sont perdues,
  il faut se reconnecter).

## 5. Ce qui reste à faire pour une publication (après le MVP)

- **Play Store** : un fichier `.aab` (`flutter build appbundle`), un compte développeur, la
  suppression du compte depuis l'application (D9.5), les vrais textes des conditions et de la
  confidentialité.
