# AdminTable

Le tableau de données du back-office (transactions, factures, utilisateurs).

- Police Inter `admin-table`, chiffres tabulaires, montants alignés à droite, références en mono.
- Lignes de 44px, séparateur `line`, survol `surface-2`, toute la ligne ouvre le détail dans un panneau latéral.
- Filtres et recherche au-dessus ; pagination en bas (20 lignes par défaut).
- Les badges de statut sont les mêmes que dans l'application.
- Construit avec TanStack Table + shadcn/ui ; aucune action sur une ligne ne peut passer une transaction en « Réussie ».
