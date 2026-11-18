# Lancer l'application sur un téléphone Android

L'application parle à l'API ElecPay qui tourne sur le PC. Trois façons de relier le téléphone :

| Méthode | Quand |
|---|---|
| **Débogage sans fil + `adb reverse`** | **recommandée pour l'itel A05s** (décidé au jalon F1, 16/11/2026) |
| USB + `adb reverse` | téléphone dont le câble tient (l'itel décroche pendant les installations) |
| Wi-Fi direct (sans adb) | téléphone sans débogage, ou démonstration sans PC branché |

## Avant tout (toutes les méthodes)

1. Base de démo et API lancées (voir `backend/README.md`) :
   ```powershell
   docker compose up -d                      # MySQL (port 3307)
   cd backend
   .\.venv\Scripts\uvicorn.exe app.main:app --host 127.0.0.1 --port 8000
   ```
   Vérification : http://127.0.0.1:8000/api/v1/health doit répondre `"status": "ok"`.
2. Sur le téléphone : Options pour les développeurs → **Débogage USB** activé
   (et, sur certaines marques comme itel / Xiaomi, **Installer via USB** activé).

## Méthode recommandée pour l'itel — débogage sans fil + `adb reverse`

Sur l'itel A05s, le câble USB décroche pendant les installations (« offline », `failed to install`),
même après un changement de câble. En débogage sans fil, le jalon F1 s'est joué sans une seule coupure.
`adb reverse` fonctionne aussi sans fil : l'application garde `http://127.0.0.1:8000`, **sans pare-feu
à ouvrir** et sans API exposée sur le réseau.

1. PC et téléphone sur **le même Wi-Fi**.
2. Sur le téléphone : *Options pour les développeurs* → **Débogage sans fil** → activer.
3. **Associer** (une seule fois par PC) : « Associer l'appareil avec un code d'association » affiche une
   adresse `IP:port` et un code à 6 chiffres :
   ```powershell
   adb pair 192.168.1.81:41527 783578     # adresse et code de la fenêtre d'association
   ```
4. **Se connecter** (à chaque session) avec l'adresse de l'écran principal « Débogage sans fil »
   (son port est différent, et il change quand le débogage sans fil est relancé) :
   ```powershell
   adb connect 192.168.1.81:44509
   ```
5. Puis comme en USB :
   ```powershell
   cd frontend\mobile
   .\tool\telephone.ps1                  # tunnel, place libre, API
   flutter run --profile -d 192.168.1.81:44509
   ```

`adb devices` montre souvent le téléphone plusieurs fois (adresse IP, nom annoncé
`adb-…._adb-tls-connect`, parfois deux noms annoncés) : c'est le même appareil, `tool\telephone.ps1` le
reconnaît par son numéro de série. En cas de doute, il affiche chaque entrée avec son numéro ; choisir
alors l'appareil : `.\tool\telephone.ps1 -Device 192.168.1.73:38473`.

Si la connexion se perd (Wi-Fi coupé, veille longue) : relancer l'étape 4, puis le script.
Vu au jalon F3 (18/11/2026) : la connexion a lâché deux fois en une heure, et **l'adresse IP du
téléphone a changé** (`.68` → `.73`), pas seulement le port. Relire l'écran « Débogage sans fil » à
chaque reconnexion ; si `adb connect` est refusé, refaire l'association (`adb pair`).
Pour un long essai, garder l'écran allumé : `adb shell svc power stayon true`, puis **`false` à la fin**.

### Piloter le téléphone depuis le PC (`adb shell input`)

Possible pour rejouer un parcours (toucher, saisie, captures `adb exec-out screencap -p`), avec une limite
vue sur l'itel : **`adb shell input text` perd des caractères** (« Nouveau2026 » est arrivé en
« Nveau2026 ») quand on tape d'un coup, surtout juste après l'ouverture du clavier. Taper caractère par
caractère avec une courte pause, et **afficher le mot de passe (œil) avant de valider**. Pour rejouer des
parcours de façon fiable, préférer les tests d'intégration (`integration_test`, voir `PLAN.md`).

## USB avec `adb reverse`

Le téléphone joint l'API à l'adresse `http://127.0.0.1:8000`, comme le PC : pas de Wi-Fi,
pas de pare-feu, pas d'adresse IP à connaître. C'est l'adresse par défaut de l'application.

```powershell
cd frontend\mobile
.\tool\telephone.ps1          # vérifie le téléphone, ouvre le tunnel USB, teste l'API
flutter run                   # mode debug (rechargement à chaud)
```

`tool\telephone.ps1` fait l'équivalent de :
```powershell
adb devices                   # le téléphone doit apparaître avec l'état « device »
adb reverse tcp:8000 tcp:8000 # port 8000 du téléphone → port 8000 du PC
```
Le tunnel se ferme quand le câble est débranché : relancer le script après chaque rebranchement.

### Si l'installation en mode debug échoue

En mode debug, l'APK pèse environ 200 Mo, car le code Dart n'y est pas compilé. Sur certains téléphones
ou câbles, la connexion USB lâche pendant un envoi aussi gros : le téléphone passe « offline »,
ou l'installation échoue avec `failed to install` sans motif. Il faut aussi assez de place libre
(au moins 600 Mo).

Dans ce cas, utiliser le **mode profile** : le code est compilé comme en production (environ 23 Mo),
sans rechargement à chaud.

```powershell
flutter run --profile
```

Testé sur un itel A05s (Android 13, processeur 32 bits `armeabi-v7a`) : en debug, la connexion USB
se coupe à chaque installation ; en profile, l'installation passe parfois, mais le câble a encore
décroché au jalon F1. D'où le débogage sans fil, recommandé pour ce téléphone.

## Wi-Fi direct (sans adb)

Le PC et le téléphone doivent être sur **le même réseau Wi-Fi**, et ce réseau doit être déclaré
**privé** dans Windows.

1. Lancer l'API en écoute sur le réseau local (et pas seulement sur le PC) :
   ```powershell
   .\.venv\Scripts\uvicorn.exe app.main:app --host 0.0.0.0 --port 8000
   ```
2. Trouver l'adresse IP du PC : `ipconfig` → « Adresse IPv4 » de la carte Wi-Fi (ex. `192.168.1.20`).
3. Ouvrir le port 8000 **uniquement sur les réseaux privés**. Cette commande est à lancer une seule fois
   par Loick, dans un PowerShell **administrateur** :
   ```powershell
   New-NetFirewallRule -DisplayName "ElecPay API (développement)" -Direction Inbound `
     -Protocol TCP -LocalPort 8000 -Profile Private -Action Allow
   ```
   Pour la retirer : `Remove-NetFirewallRule -DisplayName "ElecPay API (développement)"`.
4. Lancer l'application avec l'adresse du PC :
   ```powershell
   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000
   ```
   Test préalable depuis le navigateur du téléphone : `http://192.168.1.20:8000/api/v1/health`.

Ne jamais lancer l'API en `--host 0.0.0.0` sur un Wi-Fi public.

## Ce que l'écran de démarrage doit afficher

| Situation | Écran |
|---|---|
| API joignable, mode démo | « API joignable » + badge **MODE DÉMO** |
| API joignable, base injoignable | « ElecPay est momentanément indisponible » |
| API injoignable | « Impossible de joindre ElecPay… » + **Réessayer** (en debug : rappel de la commande `adb reverse`) |

## Sécurité

- L'adresse de l'API se choisit à la compilation (`--dart-define=API_BASE_URL=…`). En **release**,
  seule une adresse `https://` est acceptée (`AppConfig`) : sinon l'application affiche
  « Configuration invalide : La version livrée exige une API en https:// » et ne fait aucun appel.
  **C'est ce contrôle qui protège les appels de l'application.**
- Le manifeste Android n'autorise le HTTP en clair qu'en debug et en profile (`src/debug`, `src/profile`) ;
  l'APK release l'interdit (vérifié en CI par `tool/apk_check.dart`). Ce réglage ne protège que le code
  natif Android : **le client HTTP de Dart (Dio) ne le respecte pas.**

Vérifié sur l'itel A05s le 16/11/2026 :
- avec un APK profile dont le manifeste interdit le HTTP en clair (Android l'a bien enregistré : pas de
  drapeau `USES_CLEARTEXT_TRAFFIC`), l'application a quand même joint `http://127.0.0.1:8000`. Le manifeste
  ne suffit donc pas ;
- l'APK release compilé avec `http://127.0.0.1:8000` affiche « Configuration invalide » au démarrage.

## Problèmes fréquents

| Symptôme | Solution |
|---|---|
| `adb devices` est vide | Câble de données (pas seulement de charge), débogage USB activé, accepter « Autoriser le débogage USB ? » sur le téléphone |
| `unauthorized` | Débrancher, rebrancher, accepter la fenêtre sur le téléphone |
| `device not found` ou `offline` pendant l'installation | La connexion USB a lâché : passer au **débogage sans fil** (méthode recommandée pour l'itel) ; à défaut, rebrancher, relancer `tool\telephone.ps1` et utiliser `flutter run --profile` (APK plus léger) |
| Sans fil : `failed to connect` | Même Wi-Fi ? Débogage sans fil toujours actif ? Le port a pu changer : relire l'écran « Débogage sans fil » et refaire `adb connect` |
| Sans fil : `adb pair` refusé | Le code d'association expire vite : rouvrir la fenêtre d'association et utiliser le nouveau code |
| L'écran s'éteint pendant un essai | Normal ; pour un long essai : `adb shell svc power stayon true`, puis `false` à la fin |
| `failed to install` sans motif | Même cause, ou manque de place, ou « Installer via USB » désactivé : `flutter run --profile` |
| « Impossible de joindre ElecPay » | API lancée ? Tunnel ouvert (`adb reverse --list`) ? En Wi-Fi : même réseau, pare-feu, bonne IP |
