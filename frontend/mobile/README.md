# ElecPay — application mobile (client)

Application Flutter des abonnés ElecPay (Android). Feuille de route : [`PLAN.md`](PLAN.md).
Le back-office est un site à part (`frontend/admin/`).

## Prérequis

- Flutter 3.47 (Dart 3.13), Android SDK ; un téléphone Android 7 ou plus récent (`minSdk 24`).
- L'API ElecPay lancée sur le PC (`backend/README.md`) avec la base de démo.

## Commandes (depuis `frontend/mobile/`)

| Action | Commande |
|---|---|
| Installer les dépendances | `flutter pub get` |
| Analyse du code | `flutter analyze` (doit rester sans remarque) |
| Tests | `flutter test` |
| Générer les modèles (freezed / json) | `dart run build_runner build --delete-conflicting-outputs` |
| Régénérer le thème depuis la charte | `dart run tool/generate_tokens.dart` (après tout changement de `frontend/design/tokens.json` ; un test le vérifie) |
| Préparer le téléphone (sans fil ou USB) | `.\tool\telephone.ps1` (itel : débogage sans fil recommandé, voir le guide) |
| Lancer sur le téléphone | `flutter run`, ou `flutter run --profile` si le téléphone a peu de place (guide : [`docs/TELEPHONE.md`](docs/TELEPHONE.md)) |

## Organisation du code

```
lib/
  main.dart            point d'entrée
  app/                 démarrage, routes (GoRouter), thème appliqué
  core/                commun à tout : thème de la charte, réseau (API), formats, stockage
  features/<domaine>/  un dossier par fonctionnalité (auth, factures, paiements…) :
                       écrans, widgets, état (Riverpod), accès à l'API, modèles
test/                  mêmes dossiers que lib/
```

Règles : textes en français ; montants en FCFA entiers ; une donnée simulée n'est jamais présentée
comme réelle (badge « Mode démo ») ; jamais « temps réel » hors de l'onglet Direct.

Identifiant Android : `cg.elecpay.client`. Police Poppins embarquée (pas de téléchargement).
