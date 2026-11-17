# ElecPay — Plan de construction de l'application mobile (Flutter)

Application **client** ElecPay (le back-office est un site Next.js à part, `frontend/admin/`).
Ce document est la feuille de route de l'application. On le suit **dans l'ordre**, une étape à la fois.
Une étape n'est terminée que quand **tous** ses critères « Terminé quand » sont vrais.

## Tableau de bord

| Étape | Nom | État |
|---|---|---|
| F0 | Socle et accès à l'API depuis le téléphone | ✅ terminé le 16/11/2026 |
| F1 | Accès à l'API et cache hors ligne | ✅ terminé le 17/11/2026 |
| F2 | Composants de la charte et formats | prochaine étape |
| F3 | Connexion | à faire |
| F4 | Accueil et notifications | à faire |
| F5 | Factures | à faire |
| F6 | Paiement, reçus et historique | à faire |
| F7 | Consommation | à faire |
| F8 | Compteurs et foyers | à faire |
| F9 | Compte et assistance | à faire |
| F10 | Finitions et livraison (APK) | à faire |

Après F10 : le back-office Next.js (`frontend/admin/`).

## Point de reprise (mis à jour le 17/11/2026)

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
- **Prochaine étape : F2** (composants de la charte et formats). Proposer d'abord son découpage.

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
| Mi-parcours (tableau de bord, factures : F4–F5) | rendu, fluidité, lisibilité |
| Fin de F10 | APK release installé à la main + backend en ligne en HTTPS |

Le problème du câble USB se règle une seule fois, au premier jalon : nouveau câble, sinon débogage sans fil.

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

### F4 — Accueil et notifications (écrans 5, 13)

Facture la plus urgente (carte verre), consommation du mois et estimation, activité récente, cloche avec le
nombre de non lues ; notifications groupées (aujourd'hui, cette semaine, plus tôt), « Tout marquer comme lu »,
ouverture du bon écran.

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

### F10 — Finitions et livraison

Tous les états revus (chargement, vide, hors ligne, erreur réseau, accès refusé, session expirée, paiement
en attente / échoué / inconnu), accessibilité (grands textes, contrastes, lecteur d'écran), test de parcours
complet contre l'API de démo ; **APK optimisé** : `--split-per-abi`, obfuscation (`--obfuscate`
`--split-debug-info`), **objectif < 25 Mo** par APK ; guide d'installation.

Terminé quand : tout le parcours client (inscription → compteur → consommation → facture → paiement →
reçu → historique) se fait sur le téléphone, sans erreur, et l'APK livré fait moins de 25 Mo.
