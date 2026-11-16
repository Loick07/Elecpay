# Lancer l'application sur un téléphone Android

L'application parle à l'API ElecPay qui tourne sur le PC. Deux façons de relier le téléphone :
**par USB (recommandé)** ou par Wi-Fi.

## Avant tout (les deux options)

1. Base de démo et API lancées (voir `backend/README.md`) :
   ```powershell
   docker compose up -d                      # MySQL (port 3307)
   cd backend
   .\.venv\Scripts\uvicorn.exe app.main:app --host 127.0.0.1 --port 8000
   ```
   Vérification : http://127.0.0.1:8000/api/v1/health doit répondre `"status": "ok"`.
2. Sur le téléphone : Options pour les développeurs → **Débogage USB** activé
   (et, sur certaines marques comme itel / Xiaomi, **Installer via USB** activé).

## Option 1 — USB avec `adb reverse` (recommandée)

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

Testé sur un itel A05s (Android 13, processeur 32 bits `armeabi-v7a`). En debug, la connexion USB
se coupe à chaque installation ; en profile, l'installation réussit et l'écran de démarrage s'affiche
correctement.

## Option 2 — Wi-Fi (sans câble)

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
  seule une adresse `https://` est acceptée : l'application refuse de démarrer sinon.
- Le HTTP en clair (`http://`) n'est permis qu'en debug et en profile (manifestes Android
  `src/debug` et `src/profile`) ; l'APK de production l'interdit.

## Problèmes fréquents

| Symptôme | Solution |
|---|---|
| `adb devices` est vide | Câble de données (pas seulement de charge), débogage USB activé, accepter « Autoriser le débogage USB ? » sur le téléphone |
| `unauthorized` | Débrancher, rebrancher, accepter la fenêtre sur le téléphone |
| `device not found` ou `offline` pendant l'installation | La connexion USB a lâché : débrancher et rebrancher le câble, relancer `tool\telephone.ps1`, puis passer en `flutter run --profile` (APK plus léger) |
| `failed to install` sans motif | Même cause, ou manque de place, ou « Installer via USB » désactivé : `flutter run --profile` |
| « Impossible de joindre ElecPay » | API lancée ? Tunnel ouvert (`adb reverse --list`) ? En Wi-Fi : même réseau, pare-feu, bonne IP |
