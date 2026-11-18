# ElecPay

La charte UI/UX d'ElecPay : l'application mobile des abonnés E²C (Flutter) et le back-office d'administration (Next.js). Elle décrit ce qu'on voit, ce qu'on lit et comment ça se comporte. Les deux interfaces partagent les mêmes couleurs, les mêmes statuts et les mêmes formats ; seules la police et la densité changent.

## Principes

1. **L'argent d'abord, clairement.** Sur chaque écran qui parle d'une facture, le montant, l'échéance et le statut se lisent en moins de trois secondes. Le montant est le plus gros texte de l'écran (`amount-hero`).
2. **Honnête sur les données.** Une consommation estimée porte la mention « Estimation ». Tant que les données sont simulées, le badge **Mode démo** reste visible en haut de l'application et sur chaque reçu. On n'écrit jamais « temps réel ».
3. **Confiance au moment de payer.** Un paiement a toujours un état visible : en attente, réussi, échoué ou inconnu. On ne laisse jamais l'utilisateur devant un écran figé ; on lui dit quoi faire.
4. **Léger.** Pensé pour des Android d'entrée de gamme et un réseau 3G instable : peu d'images, des icônes en trait, du flou seulement là où il compte, des squelettes plutôt que des spinners.
5. **Un seul jaune par écran.** Le jaune `volt` signale l'action principale. S'il est partout, il ne signale plus rien.

## Identité visuelle

**Bleu nuit + jaune électrique + bleu courant.** Le fond `bg` (#050D1A) évoque la ville la nuit, le jaune `volt` la lumière qu'on paie, le bleu `current` l'énergie consommée. Le thème **Nuit** est le thème par défaut ; le thème **Jour** existe pour le plein soleil et pour le back-office.

| Rôle | Token | Exemple d'usage |
|---|---|---|
| Fond | `bg` | Tous les écrans |
| Cartes | `surface-1`, `surface-2` | Liste des factures, détail |
| Verre | par défaut **opaque** `surface-2` + `glass-border` ; en option (« Effet verre ») `glass` + flou `blur-glass` | Barre de navigation, feuilles du bas (paiement, filtres) |
| Action principale | `volt` / `on-volt` | Bouton « Payer 12 500 FCFA », onglet Payer |
| Données de consommation | `current` | Barres et courbes kWh |
| Statuts | fond `success-soft`, `warning-soft`, `error-soft`, `current-soft` ; texte `success-text`, `warning-text`, `error-text`, `current-text` | Badges de facture et de transaction |

Les couleurs `*-text` sont celles du **texte** : plus foncées que la couleur de base dans le thème Jour pour rester
lisibles (≥ 4,5:1) sur le fond doux du badge (`success-text` et `warning-text` ajoutés le 17/11/2026 : le vert et
l'orange de base n'atteignaient que 4,26 et 4,25 en thème Jour). Les icônes gardent la couleur de base.

### Liquid Glass, avec retenue

Le verre (fond translucide, flou d'arrière-plan, liseré 1px `glass-border`) est réservé à **deux éléments** (décision du 17/11/2026) : la barre de navigation flottante et les feuilles du bas (paiement, filtres). La carte héros du tableau de bord, les listes et les cartes ordinaires sont opaques (`surface-1`) : c'est plus lisible et beaucoup moins coûteux pour un téléphone modeste.

**Sans flou par défaut** (décision du 18/11/2026, jalon F3) : le verre est un fond **opaque** `surface-2`, avec le liseré `glass-border` et la même forme. Le flou d'arrière-plan (`glass` + `blur-glass`) est une **option « Effet verre »** de l'écran Compte, pour les téléphones plus puissants ; il reste désactivé si le téléphone demande un contraste élevé. Mesure sur l'itel A05s (profile, temps de dessin par image au 90e centile) : ouverture de la feuille de paiement **17 ms sans flou, 62 ms avec flou** (au-delà de 16,7 ms, l'image saute) ; défilement 9,7 ms contre 13,1 ms, avec des pics à 262 ms avec flou.

## Typographie

- **Poppins** dans l'application mobile, **Inter** dans le back-office, **JetBrains Mono** pour les références (facture, transaction, reçu, compteur). Polices Google Fonts (licence SIL OFL) : **embarquées** dans l'application Flutter (Poppins + JetBrains Mono dans `frontend/mobile/assets/fonts/`, pas de `google_fonts`, donc aucun téléchargement et un affichage correct hors ligne), `next/font` en Next.js.
- Tous les montants et chiffres alignés utilisent les **chiffres tabulaires** (`FontFeature.tabularFigures()` en Flutter, `tabular-nums` en CSS).
- L'échelle est fixe : `amount-hero`, `display`, `h1`, `h2`, `amount`, `body`, `body-strong`, `body-sm`, `caption`, `overline`. On n'invente pas de taille intermédiaire.
- L'application suit la taille de texte du téléphone jusqu'à 130 % sans casser la mise en page.

## Formats (à respecter partout)

| Donnée | Format | Exemple |
|---|---|---|
| Montant | entier, espace insécable entre milliers, « FCFA » après | 12 500 FCFA |
| Énergie | 1 décimale max, virgule | 245,3 kWh |
| Variation | signe + %, couleur selon le sens | −12 % (vert), +8 % (orange) |
| Date | jour mois abrégé année (« 1er » le premier du mois) | 25 nov. 2026 · 1er sept. 2026 |
| Date et heure | heure de Brazzaville ; année seulement si ce n'est pas l'année en cours | 12 nov. à 08:15 |
| Période de facture | **bimestrielle** : premier jour – dernier jour · nombre de mois | 1er sept. – 31 oct. 2026 · 2 mois |
| Période de facture (liste) | mois abrégés, tiret demi-cadratin | sept.–oct. 2026 |
| Mois (consommation) | mois en toutes lettres année | Octobre 2026 |
| Téléphone | +242 + 9 chiffres groupés | +242 06 123 45 67 |
| Référence | majuscules, mono | 20261103000127 · EP-2026-000123 |

Les montants sont des entiers : on n'affiche jamais de centimes. La facture E²C est **bimestrielle**
(`backend/docs/FACTURE_E2C.md`) : sa période couvre toujours deux mois.

Caractères : l'espace fine insécable (U+202F) serait idéale entre les milliers, mais **Poppins ne la
contient pas** ; l'application utilise l'espace insécable normale (U+00A0), aussi devant l'unité
(« FCFA », « kWh », « % ») pour que le nombre ne s'en sépare jamais. Le signe moins est le vrai signe
« − » (U+2212), présent dans Poppins. Vérifié par un test qui lit les fichiers de police
(`frontend/mobile/test/core/format/typography_test.dart`).

## Statuts

Un statut a toujours **une couleur, une icône et un mot**. La couleur seule ne suffit jamais (daltonisme, plein soleil).

| Objet | Statut | Libellé | Couleur | Icône |
|---|---|---|---|---|
| Facture | unpaid | À payer | `current` | horloge |
| Facture | pending_payment | Paiement en cours | `warning` (texte `warning-text`) | sablier |
| Facture | paid | Payée | `success` (texte `success-text`) | coche |
| Facture | overdue | En retard | `error` | alerte |
| Facture | cancelled | Annulée | `ink-muted` | barre |
| Transaction | en_attente | En attente | `warning` (texte `warning-text`) | sablier |
| Transaction | reussie | Réussie | `success` (texte `success-text`) | coche |
| Transaction | echouee | Échouée | `error` | croix |
| Transaction | expiree | Expirée | `ink-muted` | horloge barrée |
| Transaction | inconnu (pas de réponse) | Vérification en cours | `warning` (texte `warning-text`) | point d'interrogation |

## Voix et ton

- On **vouvoie**. Phrases courtes, verbes d'action : « Payer », « Télécharger le reçu », « Réessayer ».
- Un bouton dit exactement ce qui va se passer : « Payer 12 500 FCFA », pas « Valider ».
- Une erreur dit ce qui s'est passé et quoi faire : « Le paiement a échoué : solde Mobile Money insuffisant. Rechargez votre compte puis réessayez. » Pas d'excuses vagues, pas de code technique.
- Les mots de l'utilisateur, pas ceux du système : « compteur », « foyer », « reçu », pas « meter_id » ou « webhook ».

## États d'écran

Chaque écran prévoit ces états, avec ces textes de départ :

| État | Rendu | Texte |
|---|---|---|
| Chargement | squelettes (`surface-3`) à la forme du contenu | — |
| Vide | illustration en trait + une action | « Aucune facture pour l'instant. Ajoutez un compteur pour les voir ici. » |
| Hors connexion | bannière en haut, contenu en cache conservé | « Hors connexion. Les données affichées datent du 12 nov. à 08:15. » |
| Erreur serveur | bloc centré + Réessayer | « Impossible de charger vos factures. Réessayez dans un instant. » |
| Accès refusé | bloc centré | « Ce foyer ne vous est plus partagé. » |
| Session expirée | feuille du bas → connexion | « Votre session a expiré. Reconnectez-vous pour continuer. » |
| Paiement en attente | écran de transaction, sablier animé | « Confirmez le paiement sur votre téléphone (code PIN Mobile Money). » |
| Paiement échoué | écran de transaction, croix | motif + « Réessayer » |
| Statut inconnu | écran de transaction, point d'interrogation | « Nous vérifions votre paiement. Ne payez pas une deuxième fois : vous serez notifié. » |

## Navigation (application)

Barre de navigation **flottante en verre**, 5 entrées : **Accueil · Factures · Payer · Conso · Compte**. L'entrée centrale **Payer** est un disque `volt` de 56px légèrement surélevé (`shadow-volt`) ; il ouvre la feuille de paiement de la facture la plus urgente. Zone tactile minimale 48 × 48 (`space-12`).

## Mouvement

- 150 ms pour une pression, 250 ms pour une apparition ou un changement d'onglet, 400 ms pour le compteur du montant et la montée des barres de graphique.
- Courbe « ease-out » ; pas de rebond sur les écrans d'argent.
- Si l'utilisateur réduit les animations, tout apparaît sans mouvement.

## Iconographie

Icônes en trait de **2 px** (trait par défaut de Lucide), coins arrondis. Flutter : police officielle Lucide
**embarquée** (`lucide-static` 1.73.0, licence ISC + MIT pour les icônes issues de Feather), réduite à la
compilation aux seules icônes utilisées ; codes générés par `tool/generate_icons.dart` (pas de paquet
d'icônes : celui essayé ajoutait 1,9 Mo à l'APK). Next.js : `lucide-react`. Taille 20 dans les listes, 24 dans la navigation. Couleur `ink-muted` au repos, `ink` ou la couleur du statut quand elles portent un sens. Pas de logos d'opérateurs dessinés à la main : MTN MoMo et Airtel Money sont écrits en toutes lettres tant que les logos officiels ne sont pas fournis par les opérateurs.

## Back-office

Même palette, thème **Jour** par défaut (travail prolongé sur écran), police Inter, densité plus forte : tableaux en `admin-table`, lignes de 44px, filtres en haut, détail dans un panneau latéral. Les actions sensibles (annuler une facture, changer un rôle) demandent un motif et une confirmation dans la page ; elles apparaissent ensuite dans le journal d'activité.

## Accessibilité

- Contraste texte ≥ 4,5:1 dans les deux thèmes (vérifié pour chaque token de texte ; `ink-faint` seulement sur `bg` et `surface-1`).
- Le jaune n'est jamais du texte sur fond clair : on utilise `volt-text`.
- Focus clavier visible (`focus`, 2px) dans le back-office.
- Les graphiques ont toujours une valeur lisible en texte à côté (total, moyenne).

## Correspondance Flutter

Les tokens deviennent une classe `ElecPayColors` (ThemeExtension) et un `TextTheme` : `bg` → `scaffoldBackgroundColor`, `volt` → `colorScheme.primary`, `current` → `colorScheme.secondary`, `error` → `colorScheme.error`, `surface-1` → `colorScheme.surface`. Les espacements et rayons deviennent des constantes (`Space.s4 = 16`, `Radii.lg = 20`). Le verre : par défaut `surface-2` opaque + bordure `glass-border` ; avec l'option « Effet verre », `ClipRRect` + `BackdropFilter(ImageFilter.blur(sigmaX: 12, sigmaY: 12))` + couleur `glass` + bordure `glass-border` (`GlassSurface`, `lib/core/widgets/glass.dart`).
