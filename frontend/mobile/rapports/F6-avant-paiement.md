# Rapport F6 — avant de brancher le paiement réel (arrêt prévu)

19/11/2026, branche `f6`. Arrêt obligatoire de `AUTONOMIE.md` (section 3) : **rien n'envoie
`POST /payments` aujourd'hui**. J'attends ton accord pour F6.3.

## Ce qui est fait (intégré dans `main`, CI verte)

- **F6.0 Libellés de période** (ta demande) : plus aucun texte de période repris de l'API. Les libellés
  sont construits avec `formats.dart` à partir des dates (« juil.–août 2026 »), lues sur la facture
  quand le contrat ne les donne pas (`lib/features/bills/bill_periods.dart`, lecture en cache). Dates
  inconnues : « Facture payée », « la facture précédente », jamais le texte de l'API. Testé avec un
  libellé témoin « TEXTE API » qui ne doit jamais apparaître.
- **F6.1 Règles du paiement** (`lib/features/payments/payment_flow.dart`), 19 tests :
  - une clé d'idempotence par tentative (32 caractères hexadécimaux tirés au hasard, format de l'API) ;
  - double toucher = une seule demande ; pendant un suivi ou une réponse inconnue, « Payer » ne fait rien ;
  - après **Échoué** ou **Expiré** : « Réessayer » = nouvelle demande, **nouvelle clé** ;
  - après une **réponse inconnue** (délai dépassé, réseau coupé, panne) : **jamais « Échoué »**, jamais
    de nouvelle demande ; « Vérifier » relit le paiement s'il est connu, sinon renvoie **la même
    demande avec la même clé** (l'API rend la même transaction : jamais un second débit) ;
  - suivi toutes les **3 s** ; après **2 min** sans réponse finale : « Vérification en cours », et le
    suivi **continue toutes les 15 s** tant que l'écran est ouvert, jusqu'à l'état final ;
  - « paiement déjà en cours sur la facture » (409 `PAYMENT_IN_PROGRESS`) : on suit ce paiement-là ;
  - le suivi **s'arrête** quand l'écran d'attente se ferme, et reprend s'il se rouvre (sans repayer).
- **F6.2 Écrans** (16 tests d’écran + 3 pour la règle 2, texte à 100, 130 et 200 %) :
  - **feuille de paiement** (écran 8) : numéro du compte prérempli, **opérateur proposé d'après le
    numéro** (06 → MTN MoMo, 05 / 04 → Airtel Money, D6.2), un numéro d'un autre opérateur est refusé
    **avant** l'envoi (« Ce numéro n'est pas un numéro MTN MoMo (numéros en 06). »), mention « Le
    titulaire de ce numéro recevra la demande de confirmation. » pour un proche (D6.3), refus de l'API
    affiché dans la feuille, montant jamais modifiable, Payer désactivé hors ligne ;
  - **écran d'attente** (écran 9) : les 3 étapes de la maquette (demande envoyée à MTN MoMo · 14:31,
    validation par code PIN, reçu disponible), la référence TX, « Ne relancez pas le paiement »,
    « Vérification en cours » avec « Vérifier le paiement », **toujours « Retour à l'accueil »** (qui ne
    paie rien), jamais de bouton Payer pendant un paiement ; au succès, la facture, l'accueil et les
    listes sont relus (D6.4) ; badge Mode démo ;
  - **points d'entrée** : Payer du détail et de l'accueil ouvrent la feuille ; « Paiement en cours »
    rouvre le suivi du paiement en attente (retrouvé par `GET /payments`), jamais une 2e demande ;
    **bouton Payer central** (D6.1) : aucune facture → « Aucune facture à payer. » ; une seule → sa
    feuille ; plusieurs → « Quelle facture payer ? », la plus urgente d'abord ; une facture en cours de
    paiement → son suivi.
- **La passerelle branchée dans l'application est `NotYetConnectedPaymentGateway`** : toucher Payer
  affiche « Le paiement n'est pas encore activé dans cette version. » **sans aucune requête** (testé).

## Ce que fera F6.3 si tu donnes ton accord

1. Une classe `ApiPaymentGateway`, branchée à la place de la passerelle actuelle :
   - `POST /payments` avec `{bill_id, operator, phone_number}` (jamais le montant) et l'en-tête
     `Idempotency-Key`, par le client authentifié (**aucune relance automatique**) ;
   - `GET /payments/{id}` **toujours en direct, jamais en cache** (règle de `cache_policy.dart`).
2. Tests sur un faux serveur : en-tête et corps envoyés, `200` (même clé déjà reçue) = même
   transaction, `201`, chaque code d'erreur du guide (`OPERATOR_MISMATCH`, `PAYMENT_IN_PROGRESS`,
   `BILL_ALREADY_PAID`, `TOO_MANY_ATTEMPTS`…), délai dépassé.
3. Un test d'intégration avec les numéros de test du simulateur (`06 000 00 02` solde insuffisant,
   `… 03` refus, `… 04` expiré, `… 05` jamais confirmé, `… 06` prestataire injoignable), pour le
   **jalon groupé F4 + F5 + F6** sur l'itel.
4. Ensuite F6.4 (reçu, écran 10) et F6.5 (historique, écran 12), puis le rapport `rapports/F6.md`.

En mode démo, l'API utilise le prestataire **simulé** : aucun débit réel n'est possible, même après F6.3.

## Une décision de plus (backend, ton accord nécessaire)

Les **paiements**, les **reçus** et la **« facture précédente »** n'ont pas les dates de la période
dans le contrat (seulement `bill_period_label`). Aujourd'hui, je lis la facture pour les obtenir :
une lecture par facture citée (3 au plus sur l'accueil, 1 dans le détail). Pour l'**historique**
(F6.5, 20 paiements par page), ce serait jusqu'à 20 lectures de plus par page.
- **Recommandation** : ajouter `bill_period_start` et `bill_period_end` à `PaymentPublic` et
  `ReceiptPublic`, et `period_start` / `period_end` à `PreviousBillComparison` (ajout simple au
  contrat, aucun champ retiré). **C'est une modification de `backend/` : je ne la ferai qu'avec ton
  accord.**
- Sinon : je garde les lectures (en cache, une seule par facture même si plusieurs paiements la citent).

## Défauts trouvés et corrigés pendant F6.0 → F6.2

| Défaut | Trouvé par | Correction |
|---|---|---|
| `pay` / `Vérifier` / `Suivre` attendaient la FIN de tout le suivi (qui ne finit qu'à l'état final) : l'écran restait bloqué | tests du suivi (blocage) | le suivi démarre sans être attendu ; l'état « suivi » est posé tout de suite |
| Suivi « libéré quand personne n'écoute » : le paiement pouvait se perdre entre la fermeture de la feuille et l'ouverture de l'écran d'attente | relecture du parcours | suivi arrêté / repris explicitement par l'écran d'attente ; l'état est gardé |
| Reprise du suivi pendant la construction de l'écran d'attente (interdit par Riverpod) | tests d'écran | reprise juste après le premier affichage |
| Lecture de la période de la précédente encore en cours en fin de test | tests du détail | les tests attendent la fin des lectures (aucun défaut de l'écran) |

## Ce qui a été modifié ou supprimé en dehors de l'étape

- **Supprimé** : rien.
- `lib/core/widgets/payment_sheet.dart` (F2) : opérateur proposé d'après le numéro, refus d'un numéro
  d'un autre opérateur, mention « proche », affichage d'un refus ; signature `onPay` inchangée.
- `lib/core/format/dates.dart` : `formatTime` (« 14:31 »).
- `lib/features/home/` et `lib/features/bills/bill_detail_screen.dart` : libellés de période à partir
  des dates ; Payer et « Paiement en cours » ouvrent le vrai parcours ; `lib/app/app_shell.dart` :
  bouton Payer central (D6.1).
- `PLAN.md` et `rapports/F5.md` : tes décisions sur le rapport de F5 (recherche après F10,
  « charger la suite » en F10, CI passagère).

## Tests modifiés ou supprimés, et pourquoi

- **Supprimé** : aucun test.
- `test/app/app_shell_test.dart` : « Payer (avant F6) : un message » devient « Payer central, factures
  illisibles : un message, aucun paiement envoyé » (vérifie l'absence de tout `POST /payments`).
- `test/features/bills/bill_detail_screen_test.dart` et `test/features/home/home_screen_test.dart` :
  « Payer → page d'attente » devient « Payer → feuille de paiement » ; la comparaison attend
  « juil.–août 2026 » (dates) au lieu du libellé de l'API, plus un cas « précédente illisible ».
- `test/features/payments/payment_flow_test.dart` (écrit en F6.1) : le cas « écran fermé » suit le
  nouveau fonctionnement (arrêt / reprise) ; les faux (passerelle, horloge) sont partagés dans
  `test/support/fake_payments.dart`.
- `test/support/fake_home_backend.dart` : libellés de l'API remplacés par « TEXTE API », facture
  précédente datée, `GET /payments` filtré par statut et facture ; aucune réponse retirée.

## Chiffres

- **1233 tests** au vert dans le dépôt (1190 à la fin de F5).
- APK : pas reconstruit pour cet arrêt (aucune dépendance ni autorisation ajoutée depuis F5 : 16,6 Mo
  pour l'itel) ; il sera mesuré à la fin de F6.

## À regarder sur le téléphone (jalon groupé F4 + F5 + F6)

- La **vraie feuille de paiement** : fluidité à l'ouverture, sans flou (par défaut) et avec flou
  (mesure à refaire, décidé au jalon F3), clavier ouvert, texte à 200 %.
- L'écran d'attente avec un vrai paiement simulé (≈ 5 s pour le PIN, ≈ 10 s pour le succès), et
  chaque numéro de test.
- Le choix « Quelle facture payer ? » du bouton central.

## Points à surveiller

- Lien « Mode démo : simuler la confirmation » de la maquette : **pas fait** (aucune route client ;
  le simulateur confirme seul en ≈ 10 s). À décider si tu le veux (il faudrait une route de démo côté
  backend).
- « Voir le reçu » mène encore à une page d'attente (F6.4).
- `test/_debug/pages_debug_test.dart` est **toujours présent** sur le disque ; jamais commité.
