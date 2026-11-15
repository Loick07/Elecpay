# Back-office — guide pour l'application d'administration (Next.js)

Complète le contrat OpenAPI (`/docs`). Écrans concernés : maquettes admin A1 à A11
(`frontend/design/maquettes/admin/README.md`). Routes préfixées par `/api/v1/admin`, toutes connectées.

## Connexion et droits

- Le back-office se connecte par **cookies** (`elecpay_access`, `SameSite=Strict`) : appeler l'API
  depuis le serveur Next et recopier le cookie `elecpay_csrf` dans l'en-tête `X-CSRF-Token` pour
  toute requête qui modifie des données (voir `docs/AUTHENTIFICATION.md`).
- Trois niveaux, contrôlés **côté serveur** sur chaque route (le contrat OpenAPI les indique dans
  `x-permission`) :

| Niveau | Rôles | Exemples |
|---|---|---|
| `staff` | support, admin, super admin | consulter clients, compteurs, factures, transactions, annonces, tarifs |
| `admin` | admin, super admin | journal, équipe, intégrations, toutes les actions (désactiver, annuler, relancer…) |
| `super_admin` | super admin | inviter un membre, changer un rôle, créer un tarif |

- `GET /permissions` → mes niveaux et la matrice de l'onglet « Permissions » (A11) : sert à
  **afficher ou masquer** les boutons ; le serveur refuse de toute façon (`403 FORBIDDEN`).
- « Marquer une transaction comme réussie » : **n'existe pas**, pour personne.
- Toute écriture laisse une ligne au journal (A10), avec IP et navigateur.

## Écran par écran

| Écran | Lecture | Actions |
|---|---|---|
| A1 Tableau de bord | `GET /stats` | — |
| A2 Utilisateurs | `GET /users?q=&kind=&status=&page=` | `GET /users/export.csv` (admin) |
| A3 Détail utilisateur | `GET /users/{id}` | `POST /users/{id}/deactivate` · `/reactivate` · `/reset-code` |
| A4 Compteurs | `GET /meters?q=&today=&attached=` · `GET /meters/{id}` | `POST /meters/{id}/anomalies/{reading_id}/control` · `/dismiss` · `POST /meters/{id}/detach` · `/attach` |
| A5 Factures | `GET /bills?q=&status=&month=&meter_id=` | `GET /bills/export.csv` (admin) |
| A6 Détail facture | `GET /bills/{id}` | `POST /bills/{id}/cancel` · `/reissue` |
| A7 Transactions | `GET /transactions?q=&status=&operator=&day=` | — |
| A8 Détail / rapprochement | `GET /transactions/{id}` | `POST /transactions/{id}/recheck` · `/disputes` · `/disputes/{d}/close` |
| A9 Notifications | `GET /announcements` · `/announcements/audience` · `/announcements/districts` · `GET /alert-settings` | `POST /announcements` · `/announcements/{id}/cancel` · `PUT /alert-settings` |
| A10 Journal | `GET /audit-logs?domain=&action=&actor=&from=&to=` · `/audit-logs/domains` | — (lecture seule) |
| A11 Paramètres | `GET /team` · `GET /permissions` · `GET /tariffs` · `GET /integrations` | `POST /team/invite` · `PUT /team/{id}/role` · `POST /tariffs` |

Listes : pagination `page` / `size`, réponse `{items, total, page, size, …}`. Dates en UTC (ISO 8601) ;
journées et mois en **heure de Brazzaville**. Montants en **FCFA entiers**, énergies en **Wh entiers**.

## Règles à afficher clairement

- **Numéros de téléphone** : masqués pour le support dans les écrans clients ; **toujours** masqués dans
  les transactions ; la recherche par numéro marche quand même (au moins 3 chiffres).
- **Désactiver un compte** : motif obligatoire (5 caractères), ferme toutes ses sessions ; personne ne se
  désactive soi-même ; seul un super admin agit sur un compte de l'équipe.
- **Anomalie de relevé** : le relevé n'est jamais modifié (il reste exclu des factures) ; « Relevé de
  contrôle » (note facultative, une seule fois) ou « Classer sans suite » (note obligatoire). Le compteur
  du haut « anomalies à traiter » porte sur les **30 derniers jours** ; le détail les montre toutes.
- **Détacher un compteur** : possible avec des factures à payer (elles suivent le compteur ; la réponse
  donne `unpaid_bills` pour prévenir) ; refusé pendant un paiement en cours ; 5 compteurs par foyer.
- **Annuler une facture** : motif d'au moins 10 caractères, jamais de suppression ni de changement de
  montant ; impossible si payée, déjà annulée ou paiement en cours (`can_cancel`). **Réémettre**
  (`can_reissue`) : nouvelle facture recalculée, numérotée et datée du jour, 15 jours pour payer ; le
  titulaire et les payeurs délégués reçoivent « Facture corrigée ». Erreur de calcul (relevé manquant…)
  renvoyée telle quelle (`BILLING_*`).
- **Relancer la vérification** : demande l'état à l'opérateur et l'applique comme un webhook ; afficher
  `message`. Une réponse contradictoire ne change rien et met la transaction « à rapprocher ».
  `503 PAYMENT_PROVIDER_UNAVAILABLE` : réessayer plus tard. La comparaison ElecPay ↔ opérateur de A8
  vient de la **dernière** vérification (`operator_view` vide : jamais vérifiée).
- **Litige** : un dossier de suivi, ne change ni la transaction ni la facture ; un seul ouvert par
  transaction ; clos avec `no_debit`, `refunded` ou `debit_confirmed` + note. « À rapprocher » =
  anomalie signalée par l'opérateur et aucun litige clos.
- **Annonces** : cibles `all`, `overdue`, `district`, `client` ; afficher l'aperçu
  (`/announcements/audience`) avant d'envoyer. Programmation 5 min à 90 jours (UTC), envoyée par la
  tâche `scripts.send_announcements` ; destinataires calculés **à l'envoi**. Taux de lecture dans la
  liste. Push : phase 2.
- **Alertes automatiques** : couper une alerte arrête les notifications pour toute la plateforme ;
  une facture échue passe quand même « en retard ».
- **Équipe** : l'invité reçoit un code par SMS pour choisir son mot de passe (jamais montré à l'équipe) ;
  `invitation_pending` tant qu'il ne s'est pas connecté.
- **Double authentification** (obligatoire pour admin et super admin, facultative pour le support) :
  - connexion : si la réponse de `POST /auth/web/login` contient `two_factor_required: true`, afficher
    la saisie du code puis `POST /auth/web/login/2fa` avec `challenge_token` (5 min) et le code à 6
    chiffres ou un code de secours ;
  - `403 TWO_FACTOR_SETUP_REQUIRED` sur `/admin` : envoyer vers « Sécurité » —
    `POST /me/2fa/setup` (QR code `qr_svg`), puis `POST /me/2fa/enable` (premier code) ; afficher les
    10 codes de secours **une seule fois** ;
  - onglet Équipe : `two_factor` = enabled / pending / disabled ; téléphone perdu :
    `POST /admin/team/{id}/2fa/reset` (super admin, motif ; ferme les sessions du membre).
- **Tarifs** : nouvelle version d'un tarif existant, au plus tôt demain ; la version en cours s'arrête à
  cette date. Les factures émises ne changent jamais.
- **Intégrations** : simulateurs en démo (`simulated`), push `phase_2` ; aucun secret renvoyé.

## « À surveiller » du tableau de bord (A1)

`kind` : `stuck_payment` (paiement en attente > 10 min), `repeated_failures` (≥ 2 échecs
aujourd'hui pour une personne), `reading_anomalies` (relevés anormaux, relevés manquants),
`long_overdue` (retard > 30 jours), `unissued_bills` (facture que le relevé quotidien n'a pas pu
émettre, B11.5), `failed_emails` (reçu par e-mail abandonné après 6 essais, B11.5). Ouvrir l'écran
indiqué par `entity_type` / `entity_id`. Guide de mise en ligne : `docs/DEPLOIEMENT.md`.

## Tâches planifiées (production)

| Commande | Fréquence |
|---|---|
| `python -m scripts.check_pending_payments` | toutes les minutes |
| `python -m scripts.send_announcements` | toutes les minutes |
| `python -m scripts.send_emails` | toutes les minutes (reçus par e-mail, B11.4) |
| `python -m scripts.daily_alerts` | chaque matin |

## Comptes de démo

Mot de passe `Demo2026!` : super admin `+242060000001`, admin `+242060000002`, support `+242060000003`.
Admin et super admin de démo : double authentification déjà active, secret de démonstration
`ELECPAYDEMO2FASECRETPOURLESTESTS` (imprimé par `scripts.seed`) à ajouter une fois dans
l'application d'authentification.
