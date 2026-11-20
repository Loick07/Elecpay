# Jalon sur le téléphone — groupé F4 + F5 + F6 + F7

Joué le 20/11/2026 sur l'**itel A05s** de Loick (Android, 360 × 800 points), en **débogage sans fil**,
branche `jalon-f4-f7`. Tests d'intégration lancés par `tool/integration.ps1` (autorisation de Loick du
20/11/2026), **uniquement sur la base `elecpay_e2e`**, remise à zéro par le script avant chaque passage.
La base de démo `elecpay` n'a pas été touchée. Les captures sont rangées dans `build/jalon/`, qui n'est
jamais commité.

## En bref

- **Tests d'intégration : 16 sur 16 réussis**, sans aucun échec d'application. Le détail :

  | Fichier | Écrans | Résultat |
  |---|---|---|
  | `auth_flows_test.dart` | connexion, inscription, mot de passe oublié, session expirée (F3) | 6 / 6 |
  | `home_notifications_test.dart` | accueil, choix du foyer, notifications (F4) | 3 / 3 |
  | `bills_test.dart` | factures, onglets, détail (F5) | 3 / 3 |
  | `payments_test.dart` | paiements simulés jusqu'au reçu (F6) | 4 / 4 |

- **Paiements simulés** :
  - solde insuffisant (`06 000 00 02`) : « Paiement échoué · Solde insuffisant », avec « Réessayer » ;
  - prestataire injoignable (`06 000 00 06`) : « Service de paiement injoignable : aucun débit n'a été
    demandé » ;
  - paiement réussi : l'écran d'attente **bascule seul sur le reçu** (EP-2026-000093, 70 238 FCFA,
    numéro masqué `+242 06 *** ** 01`, « Mode démo »).
- **PDF** :
  - facture et reçu s'ouvrent dans le lecteur PDF du téléphone ;
  - le partage propose le bon fichier (`facture-20261103000002.pdf`, `recu-EP-2026-000084.pdf`) ;
  - **aucune demande d'autorisation**. Rien n'a été envoyé : la feuille de partage a été fermée.
- **Fluidité** : dans le budget de 16,7 ms par image, sans flou (le choix par défaut). Le détail est plus
  bas.
- **Huit défauts trouvés sur le téléphone, tous corrigés** sur cette branche, avec un test qui échoue
  sans la correction (vérifié pour chacun des tests d'affichage).
- Après les corrections : **1484 tests** de l'application au vert (1478 à la fin de F7), analyse et
  format comme en CI.

## Incidents pendant le jalon (pas des défauts de l'application)

- **ElecPay n'était plus installé** sur l'itel (téléphone revenu de réparation). `flutter drive`
  l'installe lui-même. Pour les étapes à la main, l'APK profile a été installé
  (`flutter build apk --profile`, puis `adb install`).
- **Le débogage sans fil a changé de port deux fois** : `42519`, puis `45083`, puis `41693` après le
  déplacement de Loick. Retrouvé avec `adb mdns services`. Les tests F5 ont été relancés une fois pour
  cette raison : **l'appareil était « offline », pas un échec de test**.
- **Taille de police** : le réglage de l'itel s'arrête à **115 %**. Avec l'accord de Loick, les tailles
  130 % et 200 % ont été réglées depuis le PC (`settings put system font_scale`), puis remises à
  **1.0**. La valeur a été vérifiée sur le téléphone à la fin.
- Avant chaque action à la main, un contrôle refusait d'agir si ElecPay n'était pas au premier plan. Il
  a bloqué deux fois, comme prévu : feuille de partage encore ouverte, puis retour à l'écran d'accueil du
  téléphone.
- Android a proposé d'**enregistrer le mot de passe de démo dans le compte Google** de Loick : **refusé**
  (« Pas maintenant »).

## Fluidité (temps d'image du moteur, en millisecondes)

Budget : 16,7 ms par image (60 Hz). « Hors budget » : images où la construction ou le dessin dépasse
16,7 ms.

| Mesure | Images | Dessin moyen | Dessin p90 | Dessin pire | Hors budget |
|---|---|---|---|---|---|
| Feuille de paiement, **sans flou** (par défaut) | 333 | 12,1 | 16,6 | 23,9 | 28 |
| Feuille de paiement, avec flou | 129 | 39,9 | 75,2 | 733,8 | 62 |
| Défilement du Catalogue, sans flou | 2809 | 9,0 | 10,9 | 33,8 | 67 |
| Consommation : changements d'onglet ×3 | 1014 | 11,5 | 13,1 | 34,4 | 21 |
| Consommation : défilement du mois | 703 | 11,5 | 13,2 | 120,7 | 11 |
| Consommation : 4 mois précédents | 266 | 9,8 | 11,0 | 20,7 | 10 |
| Consommation : Direct pendant 20 s | 1209 | 12,0 | 12,2 | 19,0 | 9 |

- **Les graphiques fl_chart sont fluides sur l'itel** : 10 à 12 ms en moyenne, 11 à 13 ms au 90ᵉ
  centile, simulation Direct comprise.
- Le pire (120 ms) arrive une seule fois, au premier défilement du mois.
- Le flou reste **3 fois plus lent** (40 ms par image en moyenne) : le **verre sans flou par défaut**
  (décision de F3) est confirmé.
- Fichiers : `build/jalon/perf/perf_flou.json` et `perf_conso.json`.

## Défauts trouvés et corrigés

| # | Défaut vu sur l'itel | Correction | Test qui le garde |
|---|---|---|---|
| 1 | Graphique du mois : un jour **relevé à 0 kWh** (boutique fermée) n'avait **aucune barre** et ressemblait à un trou | barre bleue de 3 points au minimum, distincte du trait gris « pas de relevé » | `consumption_chart_test.dart` |
| 2 | Vue Année : **un seul jour estimé** mettait tout le mois en pointillé ; 7 mois sur 11 avaient l'air « estimés » | pointillé et « Estimé » seulement pour le mois **incomplet** (maquette) | `consumption_rules_test.dart` (mois complet avec un jour estimé) |
| 3 | TalkBack lisait « 19.3 **KWAT** » | ce que lit TalkBack dit « kilowattheures » (et « kilowatt », « kilovoltampères ») ; l'écran garde « kWh » | `numbers_test.dart` (`spokenUnits`) ; étiquettes des écrans |
| 4 | Accueil à 200 % : « Vendr / edi », « Bon / jour / Arn / aud » coupés en plein mot | texte très agrandi : badge et cloche **au-dessus**, salut sur toute la largeur | `home_screen_test.dart` |
| 5 | « Mes factures » à 200 % : « Mes fa / ctures » | titre et badge en `Wrap` : le badge passe dessous | `bills_screen_test.dart` |
| 6 | Carte du jour à 200 % : « 15 555,7 k / Wh », « Classemen / t du mois » | une seule colonne quand le texte est très agrandi | `consumption_screen_test.dart` |
| 7 | Historique : titre coupé « Historique des paieme… » (à 100 %) | titre rétréci plutôt que coupé | à revoir à l'œil au prochain jalon |
| 8 | Test d'intégration du paiement réussi périmé depuis F6.4 (il attendait « Voir le reçu ») | il vérifie maintenant la bascule seule sur le reçu, Télécharger et Partager, puis Terminé | `integration_test/payments_test.dart`, joué sur l'itel : 4 / 4 |

Pour chacun des tests d'affichage (4, 5, 6), j'ai remis l'ancien code et vérifié que le test
**échoue**. Le premier test de l'accueil passait même avec l'ancien code : je l'ai renforcé (« la date
prend toute la largeur ») jusqu'à ce qu'il échoue sans la correction.

## TalkBack

- Loick a écouté deux cases du calendrier :
  - 3 novembre : « 3 novembre, 19.3 KWAT » ;
  - 19 novembre : « 18.9 KWAT ».
- J'ai lu l'arbre d'accessibilité d'ElecPay (`uiautomator dump`) : **les étiquettes sont complètes**,
  par exemple :
  - « 3 novembre, 19,3 kWh, consommation élevée » ;
  - « 19 novembre, 18,9 kWh, consommation normale, estimation, jour affiché » ;
  - « 20 novembre, pas encore de données » ;
  - les onglets, les flèches « Période précédente / suivante » et le fil d'Ariane « Voir Novembre ».
- Le niveau de consommation est donc bien présent. Il vient après une courte pause, et TalkBack a
  sans doute été interrompu avant.
- « kWh » se lit maintenant « kilowattheures » (défaut 3). **À réécouter au prochain jalon.**

## Texte agrandi

| Taille | Résultat |
|---|---|
| 115 % (maximum du réglage de l'itel) | tout lisible, rien ne déborde |
| 130 % | tout lisible ; les onglets de Consommation passent sur deux lignes (prévu) ; dans la barre du bas, « Accueil » et « Factures » se touchent presque |
| 200 % | rien ne sort de l'écran, mais des mots coupés en plein milieu (défauts 4, 5 et 6, corrigés) ; calendrier, légende, filtres et barre du bas tiennent |

Rappel : les tests automatiques utilisent une police carrée, qui ne coupe pas les mots comme Poppins.
Ces coupures ne se voient que sur le téléphone ou dans une capture avec les vraies polices.

## Captures (dans `build/jalon/`, jamais commitées)

- **Automatiques** :
  - `auth/` (8) et `home/` (6) ;
  - `bills/` (8) et `pay/` (7) ;
  - `conso/` (2 : après les onglets, Direct).
- **À la main** :
  - Accueil et détail de facture ;
  - PDF de la facture, partage de la facture ;
  - Historique, reçu, PDF du reçu, partage du reçu ;
  - Conso Année, Semaine et Jour, dont le calendrier et la carte du jour ;
  - Accueil, Factures et Conso à 115, 130 et 200 % ;
  - arbre d'accessibilité `a11y.xml`.

## Points à surveiller

- **Lien de vérification du reçu** : il pointe vers `http://127.0.0.1:8000/...`, car
  `RECEIPT_VERIFY_URL` n'est pas réglé dans l'API de test. À régler au déploiement (F10).
- **Barre du bas à 130 % et plus** : « Accueil » et « Factures » se touchent presque. Rien ne déborde,
  mais c'est à revoir en F10 (finitions).
- **Activité récente de l'accueil** : les lignes ne s'ouvrent pas. C'est conforme à la maquette, où ce
  ne sont pas des liens. On pourrait ouvrir le reçu ou la facture : à décider.
- La **numérotation des factures de démo** change à chaque remise à zéro de `elecpay_e2e` ; c'est
  normal.
- Les fichiers `test/zz_*_tmp_test.dart` sont **encore présents sur ce PC**, mais pas dans le dépôt. Ils
  sont peut-être supprimés ailleurs : à vérifier de ton côté.

## Ce qui a été modifié en dehors des écrans de consommation

- `lib/features/home/home_cards.dart` : disposition de l'en-tête quand le texte est très agrandi.
- `lib/features/bills/bills_screen.dart` : titre et badge en `Wrap`.
- `lib/features/bills/bill_detail_screen.dart` : étiquettes TalkBack (`spokenUnits`).
- `lib/features/payments/history_screen.dart` : titre rétréci.
- `lib/core/format/numbers.dart` : `spokenUnits`.
- `integration_test/payments_test.dart` : paiement réussi jusqu'au reçu.
- Documents : `AUTONOMIE.md` (autorisation de `integration.ps1`), `PLAN.md` et `JOURNAL.md`.
- **Rien n'a été supprimé.**

## Tests modifiés, et pourquoi

- `integration_test/payments_test.dart` : « paiement réussi … puis « Paiement réussi » » devient
  « … puis bascule seule sur le reçu ». Le test était périmé depuis F6.4 (D6.4) et aurait échoué ;
  il vérifie maintenant **plus** (reçu, Télécharger, Partager, Terminé).
- **Quatre étiquettes TalkBack attendues** passent de « kWh » à « kilowattheures » (défaut 3) :
  - `consumption_screen_test.dart` : « 1er novembre : 11 … », « Lundi 9 novembre : 9 … »,
    « 3 novembre, 9 …, consommation » ;
  - `bill_detail_screen_test.dart` : « Ancien index » et « Nouvel index ».
- `consumption_rules_test.dart` (vue Année) : la série de test a maintenant un mois complet avec un jour
  estimé. Deux vérifications sont ajoutées : il n'est **pas** en pointillé, et pas « Estimé ».
- **Rien n'a été affaibli** : chaque test modifié vérifie autant ou plus qu'avant.
