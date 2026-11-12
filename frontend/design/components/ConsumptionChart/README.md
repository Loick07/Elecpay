# ConsumptionChart

Le graphique de consommation montre les kWh par jour, semaine, mois ou année, avec le total et le coût estimé.

- Barres `current` (rayon 6px), barre estimée en pointillés `warning` avec la légende « Estimation ». Fond de carte `surface-1`.
- Au-dessus du graphique, toujours la valeur en texte : total de la période, coût estimé en FCFA (tarif en vigueur) et variation par rapport à la période précédente (baisse = `success`, hausse = `warning`).
- Sélecteur de période en segments (Jour · Semaine · Mois · Année). Les barres montent en 400 ms à l'arrivée.
- Mention de fraîcheur obligatoire : « Dernier relevé : … ». Jamais « temps réel ».
- Flutter : `fl_chart` (BarChart) ; Next.js : Recharts.
