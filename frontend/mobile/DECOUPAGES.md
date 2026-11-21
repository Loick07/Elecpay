# Découpages de F5 à F10 (validés)

Proposé le 19/11/2026, **validé par Loick le 19/11/2026** (deuxième accord de `AUTONOMIE.md`,
section 3) : toutes les recommandations, avec les précisions ci-dessous, qui **l'emportent** sur le
texte des décisions plus bas.

## Précisions de Loick (19/11/2026)

- **D5.1** : `share_plus` et `open_filex` en **versions fixes**. `tool/apk_check.dart` contrôle en plus
  les **autorisations finales de l'APK release** : aucune autorisation sensible, notamment
  `REQUEST_INSTALL_PACKAGES` (contrôle en CI).
- **D5.2** (correction du 19/11/2026) : factures groupées par **période**, comme la maquette.
- **Jalon sur le téléphone** (19/11/2026) : l'itel est indisponible ; le jalon de mi-parcours devient un
  **jalon groupé F4 + F5 + F6**, à jouer dès que l'itel revient.
- **F6** : après 2 min, « Vérification en cours » **continue d'interroger plus lentement** (environ
  toutes les 15 s) tant que l'écran est ouvert, jusqu'à un état final (le backend n'expire qu'à 10 min).
- **D7.3** : la couleur n'est **jamais** le seul moyen de comprendre : une **légende**, et le niveau
  annoncé par TalkBack sur chaque jour du calendrier.
- **D9.3** : Loick donne les contacts du support avant F9. Sans eux : « Contacts du support : bientôt
  disponibles », **jamais de faux numéro**.
- **D9.4** : a) maintenant, b) (route client des litiges, backend) **après F10**.
- **D10.2** : hébergeur choisi : **Oracle Cloud Always Free + Caddy (HTTPS automatique) + DuckDNS**,
  **Cloudflare Tunnel** en secours. Nouvelle sous-étape **« Mise en ligne » pendant F9** (F9.5) : guide
  et fichiers de production rédigés ; **arrêt pour l'accord de Loick avant de toucher `backend/`** et
  pour les actions qu'il doit faire lui-même (compte Oracle).
  **Remplacé le 21/11/2026** : mise en ligne reportée en **M1** (après F10), par **ngrok** sur le PC
  (voir la section M1 plus bas).
- **F9 ou F10** : remplacer les pages provisoires des conditions d'utilisation et de la confidentialité
  quand Loick fournit les vrais textes.
Chaque étape suit la même méthode que F4 : sous-étapes commitées une à une sur la branche de l'étape,
intégrées dans `main` (`--ff-only`) avec une CI verte, rapport `rapports/FX.md` à la fin.

Règles valables partout (rappel, non rediscutées ici) : maquettes et charte font foi ; `formats.dart` seul
endroit des formats ; badge Mode démo ; jamais « temps réel » ; aucune écriture hors ligne ; toute route GET
rangée dans `cache_policy.dart` ; tout modèle au test de contrat ; règle 2 (360 × 800, texte à 100, 130 et
200 %, clavier ouvert) sur chaque écran ; aucun test sur le réseau réel.

**Comment répondre** : pour chaque décision (D5.1, D5.2…), « OK » suffit si ma recommandation te va ; sinon
indique l'option choisie. Une décision sans réponse = ma recommandation.

**Aucune décision ne touche le backend** sauf D9.4 (marquée ⚠️) : là, je m'arrête et je te demande avant
de modifier quoi que ce soit dans `backend/`.

---

## F5 — Factures (écrans 6 et 7)

### Découpage

- **F5.1 Modèles et lectures** : détail de facture (lignes, index, comparaison), liste paginée avec filtres ;
  routes dans `cache_policy.dart` (liste et détail en cache, PDF jamais en cache) ; test de contrat.
- **F5.2 Mes factures (écran 6)** : « Reste à payer » tous foyers, filtres Toutes / À payer / Payées / En
  retard (paramètre `status` de `GET /bills`), regroupement par mois, état vide par filtre, défilement par
  pages, tirer pour actualiser, Payer désactivé hors ligne (« Connexion nécessaire pour payer », testé).
- **F5.3 Détail (écran 7)** : facture bimestrielle comme E²C (montant, échéance, période de 2 mois, ancien /
  nouvel index, N°, date d'émission, les 6 lignes et le total HT, comparaison à la précédente), PDF et Payer
  collés en bas. Facture annulée : bandeau avec le motif, pas de Payer. Payer mène à la page d'attente de F6.
- **F5.4 PDF** : téléchargement de `GET /bills/{id}/pdf` dans un dossier temporaire, ouverture et partage
  (voir D5.1), erreurs (hors ligne, échec) avec référence.
- **F5.5 Clôture + jalon de mi-parcours** sur l'itel si connecté (`tool/integration.ps1`, base
  `elecpay_e2e`) : parcours accueil → factures → détail → PDF ; rapport `rapports/F5.md`.

### Décisions

- **D5.1 Ouvrir et partager le PDF** — il faut un paquet (aucun n'est dans `pubspec.yaml`).
  - a) `share_plus` seul : un bouton « Partager » ouvre la feuille Android (WhatsApp, e-mail, Fichiers,
    ou un lecteur PDF pour l'ouvrir) ;
  - b) `share_plus` + `open_filex` : « Ouvrir » dans le lecteur PDF du téléphone, « Partager » à part ;
  - c) lecteur PDF dans l'application (`pdfx`) : plus lourd (+ plusieurs Mo dans l'APK).
  - **Recommandation : b)**, deux petits paquets ; si le téléphone n'a aucun lecteur PDF, message « Aucune
    application pour ouvrir le PDF » et on propose Partager. Même solution pour le reçu (F6).
- **D5.2 Regroupement** — **corrigé le 19/11/2026 avec l'accord de Loick : par PÉRIODE de
  facturation** (« Septembre – octobre 2026 »), comme la maquette `Factures.dc.html` et le guide
  `backend/docs/FACTURES.md` (« grouper par `period_start` »). La recommandation d'origine (« mois
  d'émission, comme la maquette ») était une erreur de lecture de la maquette.
- **D5.3 Filtre par foyer sur Mes factures** : la maquette n'en montre pas (« tous foyers »). Ajouter un
  sélecteur de foyer quand il y en a plusieurs ? **Recommandation : non en F5** (fidèle à la maquette) ; le
  nom du foyer est écrit sur chaque ligne. À revoir après le jalon si c'est confus.
- **D5.4 PDF hors ligne** : le PDF n'est jamais en cache (binaire, données personnelles). Hors ligne, le
  bouton PDF est désactivé avec « Connexion nécessaire ». **Recommandation : oui.**

---

## F6 — Paiement, reçus et historique (écrans 8, 9, 10, 12)

### Découpage

- **F6.1 Modèles et règles du paiement, sans envoi réel** : modèles (transaction, reçu, historique), routes
  dans `cache_policy.dart` (`GET /payments/{id}` jamais en cache), contrôleur de paiement avec un faux
  client : clé d'idempotence, double toucher = une seule demande, nouvelle clé après Échoué / Expiré, même
  clé et aucune nouvelle demande après une réponse inconnue, jamais « Échoué » sur un délai dépassé,
  interrogation toutes les 3 s, « Vérification en cours » après 2 min. Tous ces cas testés.
- **F6.2 Feuille de paiement (écran 8) et attente (écran 9)**, branchées sur le faux client : opérateur,
  numéro modifiable (payer pour un proche), montant non modifiable, 3 étapes, référence TX, sortie qui ne
  paie rien, interdiction de repayer pendant un paiement en cours. Remesure de la fluidité de la vraie
  feuille (sans flou et avec flou) prévue au prochain passage sur l'itel.
- **⏸ ARRÊT** : rapport `rapports/F6-avant-paiement.md` et **attente de ta validation** avant de brancher
  `POST /payments` (AUTONOMIE.md, section 3).
- **F6.3 Branchement réel** de `POST /payments` et `GET /payments/{id}` (prestataire simulé, numéros de
  test « … 00 00 0N ») ; parcours réussi / échoué / expiré / inconnu contre l'API de démo (tests avec un
  faux serveur, et un test d'intégration pour le jalon).
- **F6.4 Reçu (écran 10)** : numéro EP-…, code de vérification, Mode démo, Télécharger / Partager (même
  solution que D5.1).
- **F6.5 Historique (écran 12)** : paiements par mois, statuts Réussi / Échoué / Expiré avec le motif,
  paiement par un payeur délégué, filtres, pages ; clôture et rapport `rapports/F6.md`.

### Décisions

- **D6.1 Bouton Payer central de la barre du bas** :
  - une seule facture à payer → feuille de paiement de cette facture ;
  - plusieurs → une feuille « Quelle facture payer ? » (les plus urgentes d'abord) ;
  - aucune → « Aucune facture à payer » ;
  - une facture avec un paiement en cours → l'écran d'attente de ce paiement, jamais une nouvelle demande.
  - **Recommandation : ces quatre règles.**
- **D6.2 Opérateur et numéro par défaut** : numéro du compte prérempli ; opérateur **proposé d'après le
  préfixe** (06 → MTN MoMo, 05 / 04 → Airtel Money), modifiable. Si le numéro saisi ne correspond pas à
  l'opérateur choisi : message sous le champ, pas d'envoi. **Recommandation : oui** ; mêmes règles que le
  backend (`backend/docs/PAIEMENTS.md` : 06 = MTN, 05 et 04 = Airtel, « hypothèse à confirmer » chez les
  opérateurs).
- **D6.3 Paiement pour un proche** : un numéro différent de celui du compte affiche « Le titulaire de ce
  numéro recevra la demande de confirmation ». **Recommandation : oui.**
- **D6.4 Après « Réussi »** : l'écran d'attente bascule seul sur le reçu ; la facture, l'accueil et
  l'historique sont relus. **Recommandation : oui.**
- **D6.5 Application fermée pendant un paiement** : au retour, l'accueil et la facture affichent
  « Paiement en cours » (déjà prévu en F4.1) et un toucher rouvre l'écran d'attente. **Recommandation :
  oui** (rien n'est gardé sur le téléphone : l'état vient toujours de l'API).

---

## F7 — Consommation (écran 11)

### Découpage

- **F7.1 Modèles et lectures** : séries (7 granularités de B5), résumé, détail d'un jour, relevés ; cache ;
  contrat.
- **F7.2 Navigation de l'écran** : onglets Direct · Jour · Semaine · Mois · Année, fil d'Ariane, flèches
  ‹ ›, sélecteur de compteur, états (chargement, vide, hors ligne, erreur).
- **F7.3 Année et Mois** : barres fl_chart, totaux, comparaisons, estimation de fin de mois, listes « Mois
  par mois » et « Semaine par semaine », lien vers la facture.
- **F7.4 Semaine et Jour** : 7 barres avec valeurs, calendrier coloré, détail du jour (kWh, coût énergie
  seule, index, moyenne du même jour, classement, relevé ou estimation).
- **F7.5 Direct et clôture** : onglet Direct (D7.2), rapport `rapports/F7.md`.

### Décisions

- **D7.1 Onglet ouvert par défaut** : **Mois** (mois en cours) ; Direct n'est jamais l'onglet par défaut.
  **Recommandation : Mois.**
- **D7.2 Onglet Direct en mode démo** : le backend n'a **aucune** route de puissance instantanée (phase 2).
  - a) simulation **dans l'application**, seulement si `/health` dit mode démo, avec le bandeau « Mode démo ·
    simulation » toujours visible, puissance tirée autour de la moyenne horaire réelle du compteur, toutes
    les 2 s, et rien n'est enregistré ;
  - b) message « Disponible avec un compteur communicant (phase 2) » même en démo.
  - **Recommandation : a)**, conforme à la décision 3 de `PLAN.md` ; hors mode démo : b).
- **D7.3 Couleurs du calendrier (vue Jour)** : 4 niveaux par rapport à la moyenne du mois (bas, normal,
  élevé, très élevé), jours estimés hachurés. **Recommandation : oui**, couleurs prises dans la charte.

---

## F8 — Compteurs et foyers (écran 15)

### Découpage

- **F8.1 Modèles et lectures** : foyers, membres, compteurs, invitations ; cache ; contrat.
- **F8.2 Écran Compteurs et foyers** : une carte par foyer (compteur, puissance, membres, payeur délégué),
  rôle de l'utilisateur dans chaque foyer, invitations reçues en haut (Accepter / Refuser).
- **F8.3 Ajouter un compteur** : feuille « Ajouter un compteur » (N° branchement + N° client vérifiés via
  `BillingSource`), choix ou création du foyer, erreurs du backend sous le bon champ.
- **F8.4 Gérer** : inviter un payeur délégué (numéro d'un compte existant), retirer un membre, quitter un
  foyer, renommer un foyer ou un compteur (D8.1) ; clôture et rapport `rapports/F8.md`.

### Décisions

- **D8.1 Actions de gestion** (renommer, retirer un membre, quitter un foyer) : le backend les a déjà.
  **Recommandation : les inclure**, chacune avec une confirmation ; seul le propriétaire voit celles qui lui
  sont réservées (le backend décide, l'écran suit).
- **D8.2 Inviter quelqu'un qui n'a pas de compte** : le backend exige un compte existant. Message « Ce
  numéro n'a pas encore de compte ElecPay. Demandez-lui de s'inscrire, puis invitez-le. » (sans envoi de
  SMS). **Recommandation : oui.**
- **D8.3 Accès à l'écran 15** : depuis Compte (lien « Compteurs et foyers ») et depuis l'état « Ajoutez
  votre premier compteur » de l'accueil. **Recommandation : oui.**

---

## F9 — Compte et assistance (écrans 14 et 16)

### Découpage

- **F9.1 Profil et réglages enregistrés** : nom, e-mail, vérification de l'e-mail par code (reçus par
  e-mail) ; enregistrement local des réglages (D9.1).
- **F9.2 Alertes et apparence** : interrupteurs (`/me/notification-preferences`), thème Nuit / Jour / Auto,
  option « Effet verre » (désactivée par défaut, gardée d'un lancement à l'autre).
- **F9.3 Sécurité** : changement de mot de passe, « Déconnecter mes autres appareils », déconnexion.
- **F9.4 Assistance (écran 16)** : recherche, 5 questions fréquentes de la maquette, contacts (D9.3, D9.4),
  rappel que les pannes relèvent d'E²C.
- ~~F9.5 Mise en ligne~~ : **reportée** (décision de Loick du 21/11/2026) → étape **M1**, après F10.
  F9 se clôt sans elle (rapport `rapports/F9.md`).

### Décisions

- **D9.1 Où garder le thème et l'effet verre** : petit fichier JSON dans le dossier privé de l'application
  (`path_provider`, déjà présent), hors du cache par utilisateur, **sans nouveau paquet**.
  **Recommandation : oui** (pas de `shared_preferences`).
- **D9.2 Thème par défaut** : **Auto** (suit le téléphone) ou **Nuit** (couleur de la marque) ?
  **Recommandation : Nuit**, la charte est pensée d'abord en navy ; Auto et Jour au choix.
- **D9.3 « Écrire au support »** : la maquette dit « Réponse dans l'application », mais **l'API n'a pas de
  messagerie** client.
  - a) en attendant : ouvre l'e-mail ou WhatsApp du support (paquet `url_launcher`), avec le numéro de
    compte et la version de l'application préremplis ; sous-texte « Réponse par e-mail » ;
  - b) messagerie dans l'application : demande du backend (nouvelle table et nouvelles routes) → après F10.
  - **Recommandation : a)**. ⚠️ Il me faut **les vrais contacts du support** (adresse e-mail, numéro
    WhatsApp). Sans eux, j'affiche « Contacts du support : bientôt disponibles » sans aucun faux numéro.
- **D9.4 ⚠️ « Problème de paiement » (litige)** : les litiges (`payment_disputes`) existent, mais
  **seul le back-office peut en créer** ; aucune route client.
  - a) même canal que D9.3 avec la référence TX préremplie ;
  - b) ajouter au backend une route client `POST /payments/{id}/disputes` (petite, la table et l'écran
    admin existent) → **modification du backend : je ne la ferai qu'avec ton accord explicite**.
  - **Recommandation : a) maintenant, b) noté pour après F10.**
- **D9.5 Suppression du compte** : absente de l'API et des maquettes. **Recommandation : rien en F9**,
  noté pour plus tard (obligatoire pour le Play Store : à prévoir avant une publication).

---

## F10 — Finitions et livraison (APK)

### Découpage

- **F10.1 Revue de tous les états** sur les 16 écrans (chargement, vide, hors ligne, erreur réseau, accès
  refusé, session expirée, paiement en attente / échoué / inconnu), avec un test par état manquant.
- **F10.2 Accessibilité** : libellés pour le lecteur d'écran (TalkBack), contrastes vérifiés contre la
  charte, cibles de 48 points, texte à 200 % sur tous les écrans.
- **F10.3 Parcours complet** en test d'intégration : inscription → compteur → consommation → facture →
  paiement → reçu → historique (base `elecpay_e2e`).
- **F10.4 APK livré** : `--split-per-abi`, `--obfuscate --split-debug-info`, signature release (D10.1),
  objectif < 25 Mo, `apk_check` sur l'APK livré, guide d'installation.
- **F10.5 Rapport final et vérification avec toi sur l'itel**, **en local** (décision du 21/11/2026) :
  **APK profile** branché sur l'API du PC, comme aux jalons. L'APK release est construit, signé et
  contrôlé en CI, mais **utilisable seulement après M1** (il exige le HTTPS) : le rapport de F10 le dit.

### Décisions

- **D10.1 Clé de signature release** : elle doit rester chez toi, jamais dans le dépôt
  (`key.properties` et `*.jks` déjà ignorés). Je rédige le guide et la configuration Gradle ; **tu crées la
  clé** avec `keytool` et tu la sauvegardes hors du PC. Sans clé, l'APK de F10 reste signé en debug et le
  rapport le dit. **Recommandation : oui.**
- **D10.2 Backend en ligne en HTTPS pour la vérification finale** : c'est une décision d'hébergement (VPS,
  ou service géré type Render / Railway) qui sort de l'application ; `backend/docs/DEPLOIEMENT.md` est prêt.
  **Recommandation : choisir l'hébergeur pendant F9** pour que F10.5 ne bloque pas ; sinon, vérification
  finale avec l'API du PC (`adb reverse`) et un APK profile, notée comme incomplète.
  **Décidé le 21/11/2026** : la mise en ligne est **reportée en M1**, après F10, et passe par **ngrok**
  (`omnivore-pardon-sixth.ngrok-free.dev`, API du PC sur le port 8000). La vérification finale de F10 se fait **en local**
  (APK profile sur l'API du PC) ; l'APK release, construit, signé et contrôlé en CI, ne sera
  utilisable qu'après M1 (il exige le HTTPS).
- **D10.3 Suivi des plantages** (Sentry, Firebase Crashlytics) : **Recommandation : aucun pour le MVP**
  (aucun service tiers, aucune donnée envoyée) ; journal local seulement.
- **D10.4 Version** : `1.0.0+1` pour l'APK livré, nom affiché « ElecPay ». **Recommandation : oui.**

---

## M1 — Mise en ligne (après F10)

Reportée de F9 (ancienne F9.5) : **tout reste en local jusqu'à la fin de F10**.
**Décision de Loick (21/11/2026) : M1 passe par ngrok**, à la place d'Oracle Cloud + Caddy + DuckDNS (qui
restent une piste pour plus tard, si l'API doit tourner sans le PC).

- **Domaine ngrok gratuit (fixe) : `omnivore-pardon-sixth.ngrok-free.dev`** ; l'API tourne **sur le PC, port 8000**
  (`uvicorn` écoute **seulement `127.0.0.1`**), ngrok fournit le HTTPS. Valeurs à utiliser :
  - `RECEIPT_VERIFY_URL=https://omnivore-pardon-sixth.ngrok-free.dev/api/v1/receipts/verify` ;
  - `CORS_ORIGINS=https://omnivore-pardon-sixth.ngrok-free.dev` (seule origine autorisée ; le back-office web ajoutera la sienne) ;
  - `API_BASE_URL=https://omnivore-pardon-sixth.ngrok-free.dev/api/v1` pour l'**APK release** (vérifié par `tool/apk_check.dart`) ;
  - `TRUSTED_PROXIES=127.0.0.1/32,::1/128` (l'agent ngrok se connecte depuis le PC : l'IP réelle est
    lue dans `X-Forwarded-For`, pour les limites de tentatives) ;
  - `APP_ENV=production`, `DEMO_MODE=true` (tout est encore simulé), `AUTH_COOKIE_SECURE=true`.
- **Rien n'est installé aujourd'hui.** Le guide fera installer ngrok à Loick (**Microsoft Store**, ou
  **WinGet** : `winget install ngrok -s msstore`), puis **Loick ajoute lui-même l'authtoken**
  (`ngrok config add-authtoken …`, enregistré dans son fichier de configuration ngrok, jamais dans le dépôt).
  **L'authtoken n'est jamais transmis à Claude**, ni écrit dans un fichier du dépôt ou une conversation.
- **Ordre imposé : ngrok seulement après M1.1** (seed sécurisé, testé, intégré, CI verte). Avant M1.1,
  aucune API n'est exposée sur Internet.
- **Base dédiée** à l'API publique (proposée : `elecpay_public`), jamais `elecpay`, `elecpay_test` ni
  `elecpay_e2e` ; secrets (`JWT_SECRET`, `TWO_FACTOR_KEY`, `PAYMENT_WEBHOOK_SECRET`, mot de passe MySQL)
  **générés sur le PC** par une commande du guide, dans un `.env` de production jamais commité.
- Fichiers dans **`backend/deploy/`** (avec accord) : `.env.production.example` (sans secret, avec le
  domaine ngrok), scripts PowerShell pour lancer l'API et le tunnel
  (`ngrok http --url=omnivore-pardon-sixth.ngrok-free.dev 8000`), tâches planifiées Windows (`check_pending_payments`,
  `send_emails`, `send_announcements` chaque minute ; `daily_alerts` à 6 h ; `daily_tick` si
  `DEMO_MODE=true`), sauvegarde MySQL quotidienne (14 jours).
- **Guide pas à pas** dans `backend/docs/DEPLOIEMENT.md` (section « ngrok sur le PC ») : base, secrets,
  seed sécurisé, lancer l'API, **puis** installer ngrok, ajouter l'authtoken, ouvrir le tunnel, vérifier
  `https://omnivore-pardon-sixth.ngrok-free.dev/api/v1/health`, arrêter, sauvegarder et restaurer.
- **Limites à connaître** (offre gratuite) : l'API n'est joignable **que si le PC est allumé**, l'API et
  le tunnel lancés ; ngrok affiche une **page d'avertissement aux navigateurs** (pas à l'application, qui
  n'est pas un navigateur) : le lien du QR code d'un reçu, ouvert dans un navigateur, passera d'abord par
  cette page ; quotas mensuels de l'offre gratuite.

**Condition de sécurité (obligatoire, testée)** : le mot de passe de démo `Demo2026!` et le secret 2FA de
démo sont **publics** (dépôt, documentation). En production, le seed devra :
- **exiger un mot de passe fourni par le serveur** (variable d'environnement), et **refuser `Demo2026!`** ;
- **générer les secrets 2FA de l'équipe au hasard** (jamais le secret de démo) ;
- tout cela **couvert par des tests** du backend.
Décision encore ouverte : autoriser `seed` et `daily_tick` en production **seulement si `DEMO_MODE=true`**
(recommandé, environ 10 lignes + tests, jamais `reset_db`). **Aucune modification de `backend/` sans
l'accord de Loick.**

Terminé quand : `https://omnivore-pardon-sixth.ngrok-free.dev/api/v1/health` répond, le seed de production refuse `Demo2026!` (test),
les tâches planifiées tournent, une sauvegarde a été restaurée avec succès, et l'APK release (construit et
contrôlé en CI, `API_BASE_URL` = le domaine ngrok) fonctionne sur l'itel contre cette API.

### Découpage proposé (à valider au moment de M1)

- **M1.1 Seed de production sûr** (backend, avec accord) : mot de passe fourni par le serveur, refus de
  `Demo2026!`, secrets 2FA tirés au hasard, tests ; décision `seed` / `daily_tick` si `DEMO_MODE=true`.
  **Rien n'est exposé avant la fin de M1.1.**
- **M1.2 Fichiers `backend/deploy/` et guide pas à pas** (avec accord), domaine ngrok inscrit.
- **M1.3 Mise en ligne avec Loick, sur le PC** : base dédiée, secrets générés sur le PC, seed sécurisé ;
  **puis** Loick installe ngrok (Microsoft Store ou WinGet) et ajoute lui-même l'authtoken ; tunnel
  ouvert, `/health` vérifié, première sauvegarde restaurée.
- **M1.4 APK release sur l'itel** (`API_BASE_URL` = domaine ngrok, contrôlé par `apk_check`) contre
  l'API en HTTPS ; rapport `rapports/M1.md`.

---

## Ce qui reste attendu de Loick

1. Les contacts réels du support, avant F9 (D9.3).
2. Les vrais textes des conditions et de la confidentialité (F9 ou F10).
3. Son accord en F6 (avant `POST /payments`, donné) et en M1 (avant `backend/` ; installation de
   ngrok et ajout de l'authtoken par Loick lui-même, après M1.1).
4. Sa clé de signature release (D10.1) et sa présence pour la vérification finale sur l'itel.
