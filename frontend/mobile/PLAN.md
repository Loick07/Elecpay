# ElecPay — Plan de construction de l'application mobile (Flutter)

Application **client** ElecPay (le back-office est un site Next.js à part, `frontend/admin/`).
Ce document est la feuille de route de l'application. On le suit **dans l'ordre**, une étape à la fois.
Une étape n'est terminée que quand **tous** ses critères « Terminé quand » sont vrais.

## Tableau de bord

| Étape | Nom | État |
|---|---|---|
| F0 | Socle et accès à l'API depuis le téléphone | ✅ terminé le 16/11/2026 |
| F1 | Accès à l'API et cache hors ligne | ✅ terminé le 17/11/2026 |
| F2 | Composants de la charte et formats | ✅ terminé le 18/11/2026 |
| F3 | Connexion | ✅ terminé le 18/11/2026 |
| F4 | Accueil et notifications | ✅ terminé le 19/11/2026 |
| F5 | Factures | ✅ terminé le 19/11/2026 (sans le jalon sur le téléphone) |
| F6 | Paiement, reçus et historique | prochaine étape |
| F7 | Consommation | à faire |
| F8 | Compteurs et foyers | à faire |
| F9 | Compte et assistance | à faire |
| F10 | Finitions et livraison (APK) | à faire |

Après F10 : le back-office Next.js (`frontend/admin/`).

## Point de reprise (mis à jour le 19/11/2026)

- **Terminé** : le backend (B0 → B11, `backend/PLAN.md`), commité, poussé, CI verte.
- **Plan validé par Loick le 15/11/2026** (avec ses réponses et ajouts ci-dessous).
- **F0 ✅ terminé le 16/11/2026** :
  - projet Flutter `cg.elecpay.client` (`minSdk 24`), polices embarquées Poppins + JetBrains Mono ;
  - thème Nuit / Jour généré depuis `tokens.json` (`dart run tool/generate_tokens.dart`, testé à jour) ;
  - adresse de l'API au lancement (`API_BASE_URL`, https exigé en release par `AppConfig`) ;
  - écran de démarrage avec la santé de l'API et le badge « Mode démo » ;
  - guide `docs/TELEPHONE.md` (USB `adb reverse` d'abord, Wi-Fi ensuite) et script `tool/telephone.ps1` ;
  - CI `.github/workflows/mobile.yml` : format, analyse, fraîcheur des tokens, tests, APK release
    (taille dans les journaux, HTTP en clair interdit vérifié par `tool/apk_check.dart`).
  - Vérifié sur l'itel A05s de Loick (Android 13, 32 bits) : « API joignable » + « MODE DÉMO », et l'écran
    d'erreur avec « Réessayer ». Sur ce téléphone, `flutter run --profile` (l'APK debug de 200 Mo fait
    décrocher l'USB).
  - Vérifié sur le téléphone (nouveau câble USB, 16/11/2026) : Dio **ignore** `usesCleartextTraffic` (un APK
    au manifeste interdisant le HTTP en clair a joint l'API en `http://`) ; le vrai verrou est `AppConfig`, et
    l'APK release compilé avec `http://` affiche bien « Configuration invalide ». Détails : `docs/TELEPHONE.md`.
- **F1 ✅ terminé le 17/11/2026** (sous-étapes commitées une à une, CI verte à chaque fois) :
  - F1.1 modèles freezed écrits à la main + test de contrat générique contre `backend/openapi.json` ;
    `UserRole.unknown` sans aucun droit ;
  - F1.2 client Dio unique (`ApiSettings` : 15 s / 30 s), `X-Request-ID`, `ApiFailure` (messages en
    français, référence), aucune relance automatique ;
  - F1.3 jetons dans `flutter_secure_storage`, un seul rafraîchissement à la fois, nouveaux jetons enregistrés
    avant le rejeu, `allowBackup="false"` + `dataExtractionRules` (tout exclu), vérifiés dans l'APK ;
  - F1.4 cache hors ligne par utilisateur (JSON, 30 jours), liste de ce qui n'est jamais en cache (dont
    `GET /payments/{id}`), session expirée : rien d'affiché avant la reconnexion du même compte ; aucun test
    ne peut toucher le réseau réel ;
  - F1.5 page Diagnostic (debug / profile), absente de l'APK release avec le mot de passe de démo (vérifié en
    CI) ; guide `docs/API.md` pour les écrans suivants.
  - **Jalon F1 joué sur l'itel** (débogage sans fil, jetons d'une minute) : connexion de démo, 5 refus `401` →
    un seul rafraîchissement → 5 lectures rejouées, hors ligne avec la date, déconnexion hors ligne qui efface
    cache et jetons. Trois défauts d'affichage vus au jalon, corrigés et testés.
  - **Débogage sans fil recommandé pour l'itel** (le câble USB décroche) : `docs/TELEPHONE.md`.
- **F2 ✅ terminé le 18/11/2026** (sous-étapes commitées une à une, CI verte à chaque fois) :
  - F2.1 module unique de formats `lib/core/format/` (Poppins sans U+202F → U+00A0, période bimestrielle de
    la maquette, téléphone aux règles du backend) ; aucun caractère invisible écrit en dur (test) ;
  - F2.2 mouvement, verre réservé à la barre du bas et aux feuilles (réglage « sans flou »), statuts testés
    contre `openapi.json`, `success-text` / `warning-text`, police Lucide embarquée (`lucide-static` 1.73.0,
    codes générés par `tool/generate_icons.dart`), bouton (une seule action même en double toucher),
    champ de saisie et champ téléphone ;
  - F2.3 squelettes, blocs d'état (`stateForFailure`), bannière hors connexion, feuille « session
    expirée » qui masque tout l'écran du dessous ;
  - F2.4 badge, ligne et carte de facture, bouton Payer (désactivé hors ligne), feuille de paiement
    (apparence), état d'un paiement (« Vérification en cours » : jamais « échoué », sortie obligatoire) ;
  - F2.5 barre du bas, coquille `/accueil` `/factures` `/conso` `/compte` (pages d'attente), page
    Catalogue (debug / profile), `apk_check --lucide=reduced` en CI (police 2 172 octets, APK 14,6 Mo).
  - Tous les composants testés sur l'écran de l'itel (360 × 800) avec texte à 130 % et 200 %. 454 tests.
- **F3 ✅ terminé le 18/11/2026** (sous-étapes commitées une à une, CI verte à chaque fois) :
  - F3.1 splash (2 s au plus ; avec une session et l'API injoignable → l'accueil ; « Hors connexion »
    seulement sans session), garde de navigation, feuille « session expirée », badge Mode démo (dernière
    valeur connue gardée, affiché tant qu'on ne sait pas) ;
  - F3.2 connexion (numéro gardé et mot de passe vidé après « incorrect » ; 429 → « Trop de tentatives. »
    et bouton à compte à rebours) ;
  - F3.3 inscription (règles du mot de passe cochées pendant la saisie, case obligatoire, pages provisoires
    des conditions et de la confidentialité, erreurs de l'API sous le bon champ) ;
  - F3.4 mot de passe oublié en 3 étapes (même parcours pour tous les numéros, code de démo seulement s'il
    est donné, code en 6 cases, nouveau code après 60 s, retour Android vers l'étape 1) ;
  - règle « clavier ouvert (300 points) + texte à 130 % : bouton principal atteignable » testée sur les
    trois écrans ;
  - **jalon F3 joué sur l'itel** (débogage sans fil, pilotage `adb` + journaux de l'API) : inscription,
    connexion, déconnexion, mot de passe oublié (code faux, nouveau code, numéro inconnu, limite 429), vraie
    session expirée (jetons d'une minute + `/auth/logout-all` : un seul rafraîchissement refusé), texte à
    130 % et 200 % sur les trois écrans. Défaut trouvé et corrigé : « suivant » depuis le code allait sur
    « Renvoyer le code » ;
  - F3.5 (jalon) : **sans flou par défaut** (mesuré : feuille de paiement 17 ms → 62 ms par image avec le
    flou), flou en option F9 ; premier test d'intégration (`integration_test/glass_perf_test.dart`, aux
    jalons seulement) ; **icône ElecPay** générée par script (adaptative + monochrome) et **lancement navy**
    sans flash blanc ; `apk_check --launcher-icon=custom` ; `tool/telephone.ps1 -Device`.
  - 596 tests ; APK release de l'itel (armeabi-v7a) **15,6 Mo** (14,6 Mo à la fin de F2).
- **F4 ✅ terminé le 19/11/2026** (développement en autonomie, `AUTONOMIE.md` ; rapport
  `rapports/F4.md`) : F4.0 tests d'intégration de F3 sur la base dédiée `elecpay_e2e` ; F4.1 lectures de
  l'accueil (une par carte, chacune échoue seule) ; F4.2 écran Accueil (`lib/features/home/`) et pages
  d'attente des écrans suivants (`/accueil/bientot`) ; F4.3 écran Notifications
  (`lib/features/notifications/`, toucher → onglet concerné, cloche sans interrogation périodique) ;
  F4.4 test d'intégration `integration_test/home_notifications_test.dart` (pas encore joué : jalon après
  F5). 1003 tests ; APK release de l'itel 16,1 Mo.
- **Découpages de F5 à F10 validés** le 19/11/2026 : `DECOUPAGES.md` (avec les précisions de Loick).
- **F5 ✅ terminé le 19/11/2026** (rapport `rapports/F5.md`) : F5.1 lectures des factures (onglets,
  pages de 20, pastilles, détail) ; F5.2 « Mes factures » (`lib/features/bills/bills_screen.dart`,
  groupes par PÉRIODE comme la maquette) ; F5.3 détail bimestriel E²C (`bill_detail_screen.dart`) ;
  F5.4 PDF (`lib/core/documents/`, `share_plus` 13.3.1 et `open_filex` 5.0.0 fixés, autorisations de
  l'APK en liste blanche dans `apk_check`) ; F5.5 test d'intégration `integration_test/bills_test.dart`
  (pas encore joué). 1190 tests ; APK release de l'itel 16,6 Mo.
- **Jalon sur le téléphone REPORTÉ** (itel en panne, 19/11/2026) : il devient un **jalon groupé
  F4 + F5 + F6**, à jouer dès que l'itel revient (voir le tableau des jalons ci-dessous).
- **Prochaine étape : F6** (paiement, reçus, historique), après le « Continue » de Loick. Arrêt prévu
  avant de brancher `POST /payments`.

## Méthode (la même que pour le backend)

- Chaque étape est découpée en sous-étapes (F0.1, F0.2…), expliquées en français et validées une à une
  par Loick avant de passer à la suivante.
- **Chaque sous-étape validée par Loick est commitée et poussée aussitôt** (elle passe en CI) ; décidé le
  16/11/2026 à partir de F1.1. Les tableaux de bord (ce fichier et `CLAUDE.md`) ne sont mis à jour qu'à la
  fin de l'étape, dans un dernier commit. Chaque push est annoncé en tête de message (« ✅ Commit et push
  faits ») avec le résultat de la CI.
- Avant chaque commit : `flutter analyze` sans remarque, format, tests au vert.
- Chaque fonctionnalité livrée avec ses tests (widgets et logique), y compris les cas d'erreur.

### Jalons de vérification sur le téléphone (décidés le 16/11/2026)

Entre deux jalons, on avance avec les tests et la CI, comme pour le backend : **pas de test sur le
téléphone à chaque sous-étape**. Les tests ne voient pas si un écran déborde sur un petit téléphone, si
l'application rame sur l'itel ou si un texte est illisible : d'où ces jalons, sur l'itel A05s de Loick.

| Jalon | Ce qu'on vérifie sur l'itel |
|---|---|
| Fin de F1 | connexion de démo, hors ligne, déconnexion |
| Fin de F3 | premiers vrais écrans : connexion, inscription |
| Mi-parcours, **groupé F4 + F5 + F6** (itel en panne le 19/11/2026 ; à jouer dès son retour) | tests d'intégration F3 + F4 + F5 (+ F6), captures, PDF ouvert et partagé, texte à 130 / 200 %, TalkBack, fluidité, vraie feuille de paiement |
| Fin de F10 | APK release installé à la main + backend en ligne en HTTPS |

Le problème du câble USB se règle une seule fois, au premier jalon : nouveau câble, sinon débogage sans fil.

### Tests d'intégration sur l'itel (validés le 18/11/2026, à écrire au début de F4)

Proposés après le jalon F3, où les parcours ont été rejoués à la main par `adb` (saisie peu fiable :
`adb shell input text` perd des caractères sur l'itel). Des tests `integration_test` rejouent les parcours
**dans l'application** (`frontend/mobile/integration_test/`, lancés par `tool/integration.ps1`), contre
l'API de démo du PC (tunnel `adb reverse`).

Conditions de Loick :
- **lancés seulement aux jalons**, jamais dans la CI (pas de téléphone dans GitHub Actions) ;
- **base remise à zéro avant chaque passage** (`reset_db` + `seed`), pour ne dépendre d'aucun compte
  déjà modifié : la base **dédiée `elecpay_e2e`** (`docker/mysql/init/02-e2e-database.sql`, décidé en
  F4.0), jamais la base de démo `elecpay` ; chaque test crée en plus son propre compte (06 99x xx xx) ;
  captures et journaux dans `build/integration/`, jamais commités (`/build/` ignoré par git) ;
- ils **complètent le regard de Loick sur le téléphone, ils ne le remplacent pas**.

Premier test d'intégration (jalon F3) : `integration_test/glass_perf_test.dart`, temps d'image du
Catalogue avec et sans flou, lancé par `flutter drive --profile --driver=test_driver/perf_driver.dart
--target=integration_test/glass_perf_test.dart -d <téléphone>` (résultats : `build/perf_flou.json`).
Les temps viennent de `FrameTiming` (`addTimingsCallback`) : `watchPerformance` exige le service de
débogage Dart, injoignable en débogage sans fil ; et jamais de `pumpAndSettle` sur un écran qui a une
animation sans fin.

Parcours de F3 à couvrir d'abord : inscription → accueil → déconnexion ; connexion ratée puis réussie ;
mot de passe oublié complet (code de démo lu à l'écran, « suivant » du code au mot de passe) ; retour
Android à l'étape 2 ; session expirée (API en jetons d'une minute, `/auth/logout-all` appelé par le test).
Captures prises par le test aux moments clés. Restent à l'œil : flou, grands textes, fluidité, limite 429
(trop lente à rejouer), remplissage automatique du code SMS par Android.

## Références (elles font foi)

| Quoi | Où |
|---|---|
| Charte, couleurs, typographies, rayons, ombres | `frontend/design/CHARTE.md`, `frontend/design/tokens.json` |
| Composants de référence | `frontend/design/components/*/README.md` |
| Les 16 écrans client, navigation, règles de l'écran Consommation | `frontend/design/maquettes/client/README.md` et `sources/*.dc.html` |
| Contrat d'API | `backend/openapi.json` |
| Guides de l'API pour Flutter | `backend/docs/*.md` (authentification, foyers, consommation, factures, paiements, reçus, notifications) |
| Factures (en cas d'écart avec une maquette) | `backend/docs/FACTURES.md` et `FACTURE_E2C.md` |

## Décisions validées (15/11/2026)

1. **Appareil** : le téléphone Android de Loick, en USB (débogage USB). Pas d'iPhone (un Mac est nécessaire).
2. **Modèles de données** : freezed + json_serializable, **écrits à la main** fonctionnalité par
   fonctionnalité, avec un test qui les compare au contrat `backend/openapi.json`.
3. **Onglet « Direct »** (puissance instantanée) : simulation avec bandeau « Mode démo » **seulement quand
   le mode démo est actif** (lu dans `GET /api/v1/health`) ; sinon le message « Disponible avec un compteur
   communicant (phase 2) », sans aucune donnée.
4. **Maquettes** : les sources `frontend/design/maquettes/client/sources/*.dc.html` (factures
   bimestrielles corrigées) servent de référence visuelle, en plus de la charte.

Rappels du projet : jamais « temps réel » hors de l'onglet Direct ; montants en FCFA entiers ; une donnée
simulée n'est jamais présentée comme réelle (badge « Mode démo ») ; textes en français.

## Les étapes

### F0 — Socle et accès à l'API depuis le téléphone

- Projet Flutter dans `frontend/mobile/` (Android seulement), identifiant **`cg.elecpay.client`**,
  **`minSdk 24`** (Android 7), organisation par fonctionnalité (`lib/features/…`), règles d'analyse
  strictes, dépendances fixées : Riverpod, GoRouter, Dio, freezed / json_serializable,
  flutter_secure_storage, fl_chart, intl, flutter_animate, skeletonizer. **Pas de google_fonts** : les
  polices Poppins et JetBrains Mono sont embarquées (hors ligne, rien à télécharger).
- Thème **Nuit / Jour** construit depuis `tokens.json` (couleurs, typographies Poppins, rayons, espacements).
- Configuration par environnement (adresse de l'API au lancement), badge « Mode démo » lu dans `/health`.
- **Accès à l'API depuis le téléphone** :
  1. **par USB (d'abord)** : `adb reverse tcp:8000 tcp:8000`, l'application appelle `http://127.0.0.1:8000`
     (ni pare-feu ni Wi-Fi) ;
  2. **par Wi-Fi (deuxième option, dans le guide)** : API sur toutes les interfaces du PC, IP du PC sur le
     réseau local, règle du pare-feu Windows (réseau privé seulement, commande lancée par Loick en
     administrateur), téléphone sur le même Wi-Fi.
  HTTP en clair autorisé uniquement en développement.
- CI GitHub (seulement si `frontend/mobile/` ou `tokens.json` change) : `flutter analyze`, `flutter test`,
  fraîcheur des tokens, `flutter build apk --release` avec la taille dans les journaux.

Terminé quand : l'application s'installe sur le téléphone de Loick, affiche l'écran de démarrage au thème
de la charte et montre que l'API de démo répond (badge « Mode démo »).

### F1 — Accès à l'API et cache hors ligne

- Client Dio : jeton d'accès, **un seul rafraîchissement à la fois** (les requêtes attendent), `X-Request-ID`
  (affiché en cas d'erreur, « Référence : … »), erreurs au format commun → messages clairs en français.
- Jetons dans `flutter_secure_storage` ; déconnexion propre si le rafraîchissement échoue.
- Modèles freezed écrits à la main + test contre `backend/openapi.json`.
- **Cache des dernières données** pour le mode hors ligne : la dernière version de chaque écran est
  gardée sur le téléphone et affichée sans réseau, avec la mention de la charte « Hors connexion. Les
  données affichées datent du 12 nov. à 08:15. » (texte « Hors ligne · données du … » jusqu'à F2.1) ;
  jamais d'action d'argent (paiement) hors ligne.

Découpage validé le 16/11/2026 : F1.1 modèles et contrat · F1.2 client Dio et erreurs · F1.3 jetons et
session · F1.4 cache hors ligne · F1.5 page Diagnostic, jalon sur le téléphone et clôture. Ajouts validés
(à ne pas oublier) :
- délais réglés à un seul endroit (`ApiSettings` : 15 s connexion, 30 s réponse) ; `X-Request-ID` envoyé
  par l'application, référence affichée = celle renvoyée par l'API, sinon celle envoyée (F1.2 ✅) ;
- aucune relance automatique d'une requête qui modifie quelque chose, sauf le rejeu après un
  rafraîchissement du jeton (F1.2 ✅, F1.3) ;
- `UserRole.unknown` sans aucun droit (F1.1 ✅) ;
- F1.3 : les deux nouveaux jetons **enregistrés avant** de rejouer les requêtes ;
- `android:allowBackup="false"` (ni le cache ni le stockage sécurisé dans les sauvegardes), vérifié par
  `tool/apk_check.dart` ;
- F1.4 : cache en fichiers JSON (dossier privé, sans chiffrement), **rangé par identifiant d'utilisateur** ;
  une **liste explicite de ce qui n'est jamais mis en cache**, dont `GET /payments/{id}`, avec un test ;
  session expirée : cache gardé, mais **rien ne s'affiche** avant la reconnexion du même compte (test) ;
- F1.5 : page Diagnostic visible en debug et en profile, **jamais en release**, avec un test qui le prouve.

### F2 — Composants de la charte et formats

- Les composants de `frontend/design/components/` : bouton, champ de saisie, badge de statut, squelette,
  bloc d'état (vide, erreur, accès refusé, hors ligne), carte de facture, ligne de facture, feuille de
  paiement, statut de transaction, badge « Mode démo » ; barre du bas à 5 onglets (bouton **Payer** central).
- **Module unique de formats** : FCFA (`40 384 FCFA`), kWh (virgule, décimales utiles), dates et heures
  (heure de Brazzaville, en français), périodes (« Sept.-Oct. 2026 »), numéros `+242 06 123 45 67`.
  Tous les écrans l'utilisent ; testé à part.

Découpage validé le 17/11/2026 :
- **F2.1** module de formats ✅ (Poppins sans U+202F → U+00A0, période bimestrielle de la maquette) ;
- **F2.2** fondations ✅ : mouvement, verre (barre du bas et feuilles seulement, réglage « sans flou »),
  (F2.3, F2.4, F2.5 ✅ : voir le point de reprise)
  statuts testés contre `openapi.json`, `success-text` / `warning-text`, police Lucide embarquée
  (`lucide-static` 1.73.0, codes générés), bouton, champ de saisie ;
- **F2.3** états d'écran : squelettes, bloc d'état (vide, erreur serveur, accès refusé), bannière hors
  connexion branchée sur le cache, feuille « session expirée » ;
- **F2.4** composants métier : badge de statut, ligne de facture, carte de la facture urgente, feuille de
  paiement (apparence), état d'une transaction, bouton Payer désactivé hors ligne ;
- **F2.5** barre du bas (5 onglets, Payer central), page Catalogue (debug / profile), clôture. **À ajouter :
  contrôle `apk_check` « Lucide.ttf réduite dans l'APK release »** (dès que la barre du bas utilise ses
  icônes ; sans icône utilisée, Flutter laisse la police entière, +449 Ko — mesuré le 17/11/2026), en CI.

### F3 — Connexion (écrans 1, 2, 3, 4)

Splash, connexion (téléphone +242, mot de passe), inscription, mot de passe oublié (code affiché en mode
démo), session expirée, déconnexion.

**Pour plus tard, côté backend** (noté le 18/11/2026) : les conditions d'utilisation et la politique de
confidentialité sont pour l'instant des **pages provisoires** (`lib/features/legal/`), et la case cochée à
l'inscription n'est pas enregistrée. Quand les vrais textes existeront : **enregistrer l'acceptation**
(date + version de chaque document) au moment de l'inscription, et la redemander quand une nouvelle version
est publiée.

### F4 — Accueil et notifications (écrans 5, 13)

Facture la plus urgente (carte verre), consommation du mois et estimation, activité récente, cloche avec le
nombre de non lues ; notifications groupées (aujourd'hui, cette semaine, plus tôt), « Tout marquer comme lu »,
ouverture du bon écran.

Limite acceptée par Loick (F4.1, 19/11/2026) : les factures à payer de **tous** les foyers sont lues en
**une seule fois, 100 au plus** (`GET /bills?status=to_pay&size=100`, `toPayPageSize` dans
`lib/features/home/home_data.dart`). Cette lecture sert la carte urgente, le foyer par défaut et le rappel
« 1 facture en retard dans … ». Au-delà de 100 factures ouvertes (irréaliste pour un abonné), les plus
anciennes ne seraient pas vues par l'accueil (l'écran Factures, lui, pagine).

Règle transversale (F4.1) : **aucune relance automatique** d'une lecture en échec (`noAutomaticRetry`,
`lib/app/riverpod_config.dart`, sur tout conteneur Riverpod ; testé).

### F5 — Factures (écrans 6, 7)

Reste à payer tous foyers, filtres, regroupement par mois, état vide ; détail **bimestriel** avec les 6 lignes
E²C, index, comparaison à la facture précédente ; PDF à ouvrir et partager.

Règle validée le 16/11/2026 (aussi pour F6) : en mode hors ligne (factures affichées depuis le cache), le
bouton **Payer** est **désactivé**, avec la mention « Connexion nécessaire pour payer ». Un test le vérifie.

### F6 — Paiement, reçus et historique (écrans 8, 9, 10, 12)

Feuille MTN MoMo / Airtel Money (numéro modifiable : payer pour un proche ; montant non modifiable ;
clé d'idempotence), suivi en 3 étapes, interdiction de repayer pendant un paiement en cours ; reçu (numéro,
code de vérification, Mode démo, télécharger / partager) ; historique par mois avec motifs d'échec.

Règle validée le 16/11/2026 : en cas d'`ApiTimeout` où la requête a pu atteindre l'API
(`mayHaveReachedServer`), ne **jamais** afficher « échoué ». Afficher « Statut à vérifier », consulter
`GET /payments/{id}`, et ne relancer qu'avec **la même clé d'idempotence**.

Hors ligne : bouton **Payer** désactivé, « Connexion nécessaire pour payer » (règle de F5), sur la feuille
de paiement comme sur le bouton central de la barre du bas.

Règles de relance validées le 17/11/2026 (composant `TransactionStatusView` prêt depuis F2.4) :
- après **Échoué** ou **Expiré** : « Réessayer » crée une **nouvelle demande** avec une **nouvelle clé
  d'idempotence** (le premier paiement est définitivement terminé) ;
- après une **réponse inconnue** ou **Vérification en cours** : **jamais de nouvelle demande** ; on
  consulte `GET /payments/{id}`, et un renvoi éventuel se fait avec **la même clé** ;
- **tests obligatoires pour les deux cas** (clé neuve après échec / expiration ; même clé et aucune
  nouvelle demande après une réponse inconnue) ;
- « Vérification en cours » : toujours une sortie qui ne paie rien (« Retour à l'accueil », déjà dans le
  composant, rendue obligatoire par une assertion) et **mise à jour automatique** de l'état (interrogation
  de l'API toutes les 3 s en attente, bascule seule ; après 2 min sans réponse : Vérification en cours).

Mesure à refaire (décidé au jalon F3, 18/11/2026) : **remesurer sur l'itel l'ouverture de la VRAIE
feuille de paiement** (sans flou, réglage par défaut ; et avec l'option « Effet verre »), sur le modèle de
`integration_test/glass_perf_test.dart`. Au jalon F3, avec la feuille du Catalogue : 17 ms sans flou,
62 ms avec flou au 90e centile.

### F7 — Consommation (écran 11)

Année, Mois, Semaine, Jour (fil d'Ariane, flèches ‹ ›, calendrier coloré), graphiques fl_chart, coût de
l'énergie seule ; onglet Direct selon la décision 3.

### F8 — Compteurs et foyers (écran 15)

Une carte par foyer (compteur, puissance, membres, payeur délégué) ; ajout d'un compteur vérifié chez E²C ;
invitation d'un payeur délégué, acceptation d'une invitation.

### F9 — Compte et assistance (écrans 14, 16)

Profil, vérification de l'e-mail (reçus par e-mail), interrupteurs d'alertes, thème Nuit / Jour / Auto,
changement de mot de passe, déconnexion ; assistance (recherche, questions fréquentes, contact, pannes
relevant d'E²C).

Option **« Effet verre »** (décidé au jalon F3, 18/11/2026) : le flou d'arrière-plan de la barre du bas et
des feuilles, **désactivé par défaut** (trop lent sur l'itel), activable ici pour les téléphones plus
puissants, choix gardé d'un lancement à l'autre (aujourd'hui : `glassModeProvider`, en mémoire seulement).

### F10 — Finitions et livraison

Tous les états revus (chargement, vide, hors ligne, erreur réseau, accès refusé, session expirée, paiement
en attente / échoué / inconnu), accessibilité (grands textes, contrastes, lecteur d'écran), test de parcours
complet contre l'API de démo ; **APK optimisé** : `--split-per-abi`, obfuscation (`--obfuscate`
`--split-debug-info`), **objectif < 25 Mo** par APK ; guide d'installation.

Terminé quand : tout le parcours client (inscription → compteur → consommation → facture → paiement →
reçu → historique) se fait sur le téléphone, sans erreur, et l'APK livré fait moins de 25 Mo.
