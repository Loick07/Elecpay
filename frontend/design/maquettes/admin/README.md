# ElecPay — Maquettes du back-office admin (validées)

11 écrans validés par Loick le 12/11/2026. Ils appliquent la charte (`../../CHARTE.md`) et font foi pour le back-office Next.js (`frontend/admin/`).

- **Version interactive** : page « ElecPay — Maquettes back-office admin » sur Claude.
- **Sources** : `sources/*.dc.html` (un fichier par écran, plus `Menu.dc.html`, le menu latéral commun) et `sources/canvas.json`. Références visuelles, pas du code à reprendre.

## Style

Thème Jour par défaut, police Inter, menu latéral bleu nuit (thème Nuit), largeur de référence 1440 px. Sur petit écran : le menu passe au-dessus, les tableaux défilent horizontalement. Mêmes statuts, couleurs et formats que l'application mobile.

## Les 11 écrans

| # | Écran | Fichier | Contenu et comportement |
|---|---|---|---|
| A1 | Tableau de bord | `Main.dc.html` | 4 indicateurs (encaissé du mois, factures impayées, taux de paiements non aboutis sur 7 jours, transactions en attente), encaissements des 30 derniers jours, factures du mois par statut, liste « À surveiller » (paiement bloqué, échecs répétés, relevés anormaux, retards > 30 jours), activité récente de l'équipe. |
| A2 | Utilisateurs | `Utilisateurs.dc.html` | Recherche nom / téléphone, filtres par rôle (clients, payeurs délégués, équipe), colonnes foyers, impayés, dernière connexion, statut, export CSV, pagination. |
| A3 | Détail d'un utilisateur | `Utilisateur.dc.html` | Identité, foyers et compteurs, transactions récentes, résumé financier, sessions ouvertes, journal du compte. Désactivation avec motif obligatoire (ferme les sessions), réactivation, lien de réinitialisation du mot de passe. |
| A4 | Compteurs | `Compteurs.dc.html` | Relevés reçus du jour, anomalies (index en baisse, relevé manquant), compteurs inactifs ; panneau de détail : index d'hier et d'aujourd'hui, explication, « Demander un relevé de contrôle » / « Classer sans suite ». |
| A5 | Factures | `Factures.dc.html` | Totaux du mois (émis, facturé, encaissé, reste), filtres par statut, recherche, export. |
| A6 | Détail d'une facture | `Facture.dc.html` | Lignes, période, index, tarif appliqué, source des relevés, payeurs autorisés, historique, transactions liées. « Annuler la facture » : motif ≥ 10 caractères, jamais de suppression, impossible si payée. Montants jamais modifiables à la main. |
| A7 | Transactions | `Transactions.dc.html` | Indicateurs du jour (encaissé, réussies, échouées, en attente, délai moyen), filtres par statut, numéro masqué, motif d'échec. |
| A8 | Détail et rapprochement | `Transaction.dc.html` | Comparaison ElecPay ↔ opérateur (montant, numéro, références, statut), chronologie, clé d'idempotence, verrou de facture. Seule action : « Relancer la vérification auprès de l'opérateur ». **Aucun bouton « Marquer comme payée ».** « Ouvrir un litige » si le client affirme avoir été débité. |
| A9 | Notifications | `Notifications.dc.html` | Rédaction d'une annonce (destinataires : tous, factures en retard, un quartier, un client), aperçu sur le téléphone, envoi ou programmation ; alertes automatiques activables ; annonces envoyées avec taux de lecture. Push : phase 2. |
| A10 | Journal d'activité | `Journal.dc.html` | Toutes les actions sensibles (équipe et système), filtres par type, détail avant / après dépliable, métadonnées (IP, navigateur). Ni modifiable ni supprimable. |
| A11 | Paramètres et rôles | `Parametres.dc.html` | Onglets Équipe (membres, rôle, double authentification), Permissions (matrice par rôle), Tarifs datés, Intégrations (simulateurs MTN / Airtel / E²C, push en phase 2, mode démo). |

## Permissions affichées (à appliquer côté serveur)

| Action | Support | Admin | Super admin |
|---|---|---|---|
| Consulter clients, factures, transactions | Oui | Oui | Oui |
| Consulter le journal | — | Oui | Oui |
| Désactiver / réactiver un compte | — | Oui | Oui |
| Annuler une facture (motif) | — | Oui | Oui |
| Relancer la vérification d'une transaction | — | Oui | Oui |
| Envoyer une annonce | — | Oui | Oui |
| Modifier les tarifs | — | — | Oui |
| Attribuer des rôles, inviter un membre | — | — | Oui |
| Marquer une transaction comme réussie | Jamais | Jamais | Jamais |

## Ce que ces écrans demandent au backend (étape B10)

`GET /admin/stats` (indicateurs, séries 30 jours, factures par statut, points à surveiller) · utilisateurs (liste filtrée, détail, désactivation / réactivation avec motif, fermeture des sessions) · compteurs (relevés du jour, anomalies, demande de relevé de contrôle) · factures (liste, détail, annulation avec motif, historique) · transactions (liste, détail, relance de vérification chez l'opérateur, litiges) · annonces et réglages des alertes automatiques · journal filtré · équipe, rôles, tarifs datés, état des intégrations. Chaque écriture crée une ligne dans `audit_logs`.

Une règle ajoutée par ces maquettes : une transaction dont le code PIN a été saisi mais dont le débit n'est pas confirmé reste « en attente » (pas d'expiration automatique) jusqu'à la réponse de l'opérateur ou une relance.

## À fixer

Tarif réel et structure des taxes (5 à 10 factures E²C), durée de conservation du journal (loi congolaise sur les données personnelles), noms réels de l'équipe (ceux des maquettes sont des exemples).
