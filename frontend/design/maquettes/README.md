# ElecPay — Maquettes de l'application client (validées)

16 écrans validés par Loick le 12/11/2026. Ils appliquent la charte de `../CHARTE.md` et font foi pour l'application Flutter.

- **Version interactive** : page « ElecPay — Maquettes application client » sur Claude (prototype cliquable, bouton Lecture).
- **Sources** : `sources/*.dc.html` (un fichier par écran) et `sources/canvas.json` (disposition). Ce sont des références visuelles, pas du code à réutiliser : l'application est écrite en Flutter.

## Les 16 écrans

| # | Écran | Fichier | Contenu et comportement |
|---|---|---|---|
| 1 | Splash | `Splash.dc.html` | Logo (éclair sur fond jaune), phrase d'accroche, barre de chargement, badge Mode démo. |
| 2 | Connexion | `Connexion.dc.html` | Téléphone +242 et mot de passe (afficher / masquer), lien « Mot de passe oublié ? », « Se connecter », « Créer un compte ». |
| 3 | Inscription | `Inscription.dc.html` | Nom, téléphone, e-mail facultatif, mot de passe (8 caractères, un chiffre), conditions d'utilisation. Le compteur s'ajoute ensuite. |
| 4 | Mot de passe oublié | `MotDePasse.dc.html` | 3 étapes : numéro → code à 6 chiffres + nouveau mot de passe (code affiché en mode démo) → confirmation, autres appareils déconnectés. |
| 5 | Accueil | `Main.dc.html` | Carte verre de la facture la plus urgente (montant, échéance, Détail / Payer), consommation du mois en cours + estimation, activité récente, cloche des notifications. |
| 6 | Mes factures | `Factures.dc.html` | Reste à payer tous foyers, filtres Toutes / À payer / Payées / En retard (état vide), factures groupées par mois. |
| 7 | Détail de la facture | `Facture.dc.html` | Montant, échéance, période, ancien / nouvel index, référence, détail ligne par ligne, comparaison au mois précédent, PDF et Payer collés en bas. |
| 8 | Paiement | `Paiement.dc.html` | Feuille du bas : MTN MoMo / Airtel Money, numéro modifiable (payer pour un proche), montant non modifiable. |
| 9 | Confirmation en attente | `Attente.dc.html` | « Confirmez sur votre téléphone », 3 étapes, référence TX, interdiction de repayer. |
| 10 | Reçu | `Recu.dc.html` | Paiement réussi, reçu numéroté EP-…, code de vérification, Mode démo, Télécharger / Partager. |
| 11 | Consommation | `Consommation.dc.html` | Onglets Direct · Jour · Semaine · Mois · Année (détail ci-dessous). |
| 12 | Historique des paiements | `Historique.dc.html` | Paiements par mois, statuts Réussi / Échoué / Expiré avec le motif, paiement par un payeur délégué, filtres. |
| 13 | Notifications | `Notifications.dc.html` | Groupées Aujourd'hui / Cette semaine / Plus tôt, non lues mises en avant, « Tout marquer comme lu ». |
| 14 | Compte | `Profil.dc.html` | Profil, liens (compteurs, paiements, sécurité), interrupteurs d'alertes, thème Nuit / Jour / Auto, assistance, déconnexion. |
| 15 | Compteurs et foyers | `Compteurs.dc.html` | Une carte par foyer (compteur, puissance, membres, payeur délégué), feuille « Ajouter un compteur » avec vérification de la référence. |
| 16 | Assistance | `Assistance.dc.html` | Recherche, 5 questions fréquentes dépliables, contact support, rappel que les pannes relèvent d'E²C. |

## Navigation

- Barre du bas (écrans 5, 6, 11, 14) : Accueil · Factures · **Payer** (bouton central) · Conso · Compte.
- Parcours principal : Splash → Connexion → Accueil → Mes factures → Détail → Paiement → Confirmation → Reçu.
- Les écrans poussés (7, 9, 10, 12, 13, 15, 16) ont un bouton retour en haut et pas de barre du bas.

## Écran Consommation (11) : règles

- **Année** : 12 barres mensuelles, total, comparaison à l'année précédente sur la même période, liste « Mois par mois ». Toucher un mois → Mois.
- **Mois** : une barre par jour, moyenne par jour, jour le plus élevé, estimation de fin de mois pour le mois en cours, liste « Semaine par semaine », lien vers la facture du mois. Toucher un jour → Jour, une semaine → Semaine.
- **Semaine** : 7 barres avec valeurs, comparaison à la semaine précédente, liste « Jour par jour » avec les index. Toucher un jour → Jour.
- **Jour** : calendrier du mois coloré selon la consommation (accès direct à n'importe quel jour), puis le détail du jour : kWh, coût, index de début et de fin, moyenne du même jour de la semaine, classement dans le mois, relevé ou estimation.
- Fil d'Ariane (2026 › Octobre › Sem. du 12 oct. › Mer. 14) pour remonter, flèches ‹ › pour la période précédente ou suivante.
- Le coût affiché est l'énergie seule (kWh × tarif en vigueur), sans frais fixes ni taxes.
- **Direct** : puissance instantanée (kW) toutes les 2 s, jauge par rapport à la puissance souscrite, courbe des 80 dernières secondes, consommation depuis minuit, coût par heure. **Nécessite un compteur communicant ou un capteur** : simulé en mode démo, à prévoir en phase 2 (nouvelle source de données côté backend).

## Ce que ces maquettes demandent au backend

| Besoin | Étape du backend |
|---|---|
| Connexion téléphone + mot de passe, code de réinitialisation | B3 |
| Foyers, membres, payeur délégué, ajout de compteur vérifié | B4 |
| Agrégats jour / semaine / mois / année, index par jour, moyenne par jour de semaine, classement, estimation fin de mois | B5 |
| Factures avec lignes, filtres par statut, tous foyers | B6 |
| Paiement, états de transaction, motif d'échec | B7 |
| Reçu numéroté, code de vérification | B8 |
| Notifications groupées, lu / non lu | B9 |
| Puissance en direct | phase 2 |

## Données de démonstration

Foyers « Maison Mpita » (compteur 0412-8833, 6 kVA) et « Boutique Tié-Tié » (0377-1209, 9 kVA, Grâce Ngoma payeuse déléguée). Facture d'octobre 2026 = 212,4 kWh × 49,08 FCFA + 1 000 frais fixes + 1 075 taxes = 12 500 FCFA. Index 18 452,0 → 18 664,4. Tarif et lignes de facture à confirmer sur de vraies factures E²C.
