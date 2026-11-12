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
| Verre | `glass` + `glass-border` + flou `blur-glass` | Barre de navigation, carte héros, feuille de paiement |
| Action principale | `volt` / `on-volt` | Bouton « Payer 12 500 FCFA », onglet Payer |
| Données de consommation | `current` | Barres et courbes kWh |
| Statuts | `success`, `warning`, `error` (+ `-soft`) | Badges de facture et de transaction |

### Liquid Glass, avec retenue

Le verre (fond translucide, flou d'arrière-plan 24px, liseré 1px `glass-border`) est réservé à **trois éléments** : la barre de navigation flottante, la carte héros du tableau de bord et les feuilles du bas (paiement, filtres). Les listes et les cartes ordinaires sont opaques (`surface-1`) : c'est plus lisible et beaucoup moins coûteux pour un téléphone modeste. Si l'appareil est lent ou si l'utilisateur réduit les effets, le verre devient `glass-strong` sans flou.

## Typographie

- **Poppins** dans l'application mobile, **Inter** dans le back-office, **JetBrains Mono** pour les références (facture, transaction, reçu, compteur). Polices Google Fonts (`google_fonts` en Flutter, `next/font` en Next.js).
- Tous les montants et chiffres alignés utilisent les **chiffres tabulaires** (`FontFeature.tabularFigures()` en Flutter, `tabular-nums` en CSS).
- L'échelle est fixe : `amount-hero`, `display`, `h1`, `h2`, `amount`, `body`, `body-strong`, `body-sm`, `caption`, `overline`. On n'invente pas de taille intermédiaire.
- L'application suit la taille de texte du téléphone jusqu'à 130 % sans casser la mise en page.

## Formats (à respecter partout)

| Donnée | Format | Exemple |
|---|---|---|
| Montant | entier, espace fine insécable entre milliers, « FCFA » après | 12 500 FCFA |
| Énergie | 1 décimale max, virgule | 245,3 kWh |
| Variation | signe + %, couleur selon le sens | −12 % (vert), +8 % (orange) |
| Date | jour mois abrégé année | 25 nov. 2026 |
| Période de facture | mois année | Octobre 2026 |
| Téléphone | +242 + 9 chiffres groupés | +242 06 123 45 67 |
| Référence | majuscules, mono | FAC-2026-10-004512 · TX-2026-004812 · EP-2026-000123 |

Les montants sont des entiers : on n'affiche jamais de centimes.

## Statuts

Un statut a toujours **une couleur, une icône et un mot**. La couleur seule ne suffit jamais (daltonisme, plein soleil).

| Objet | Statut | Libellé | Couleur | Icône |
|---|---|---|---|---|
| Facture | unpaid | À payer | `current` | horloge |
| Facture | pending_payment | Paiement en cours | `warning` | sablier |
| Facture | paid | Payée | `success` | coche |
| Facture | overdue | En retard | `error` | alerte |
| Facture | cancelled | Annulée | `ink-muted` | barre |
| Transaction | en_attente | En attente | `warning` | sablier |
| Transaction | reussie | Réussie | `success` | coche |
| Transaction | echouee | Échouée | `error` | croix |
| Transaction | expiree | Expirée | `ink-muted` | horloge barrée |
| Transaction | inconnu (pas de réponse) | Vérification en cours | `warning` | point d'interrogation |

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

Icônes en trait de 1,75 px, coins arrondis (Lucide : `lucide_icons` en Flutter, `lucide-react` en Next.js). Taille 20 dans les listes, 24 dans la navigation. Couleur `ink-muted` au repos, `ink` ou la couleur du statut quand elles portent un sens. Pas de logos d'opérateurs dessinés à la main : MTN MoMo et Airtel Money sont écrits en toutes lettres tant que les logos officiels ne sont pas fournis par les opérateurs.

## Back-office

Même palette, thème **Jour** par défaut (travail prolongé sur écran), police Inter, densité plus forte : tableaux en `admin-table`, lignes de 44px, filtres en haut, détail dans un panneau latéral. Les actions sensibles (annuler une facture, changer un rôle) demandent un motif et une confirmation dans la page ; elles apparaissent ensuite dans le journal d'activité.

## Accessibilité

- Contraste texte ≥ 4,5:1 dans les deux thèmes (vérifié pour chaque token de texte ; `ink-faint` seulement sur `bg` et `surface-1`).
- Le jaune n'est jamais du texte sur fond clair : on utilise `volt-text`.
- Focus clavier visible (`focus`, 2px) dans le back-office.
- Les graphiques ont toujours une valeur lisible en texte à côté (total, moyenne).

## Correspondance Flutter

Les tokens deviennent une classe `ElecPayColors` (ThemeExtension) et un `TextTheme` : `bg` → `scaffoldBackgroundColor`, `volt` → `colorScheme.primary`, `current` → `colorScheme.secondary`, `error` → `colorScheme.error`, `surface-1` → `colorScheme.surface`. Les espacements et rayons deviennent des constantes (`Space.s4 = 16`, `Radii.lg = 20`). Le verre : `ClipRRect` + `BackdropFilter(ImageFilter.blur(sigmaX: 12, sigmaY: 12))` + bordure `glass-border`.
