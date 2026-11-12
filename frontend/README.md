# ElecPay — Frontend

Tout ce que l'utilisateur voit : le design, l'application client et le back-office.
Le frontend ne contient **aucune** règle métier : il affiche ce que renvoie l'API du dossier `backend/`.

| Dossier | Contenu | État |
|---|---|---|
| `design/` | Charte UI/UX validée : couleurs, typographie, statuts, formats, textes, composants | ✅ charte v1 validée |
| `design/maquettes/` | Maquettes des 16 écrans client | ✅ validées · admin (11 écrans) : prochaine étape |
| `mobile/` | Application client Flutter (16 écrans) | après la fin du backend (B11) |
| `admin/` | Back-office web Next.js (11 écrans) | après l'application mobile |

## design/

- `CHARTE.md` — la charte complète (principes, couleurs, typographie, formats, statuts, voix, états d'écran, navigation, mouvement, accessibilité, correspondance Flutter).
- `tokens.json` — la source unique des valeurs (couleurs des thèmes Nuit et Jour, polices, espacements, rayons, ombres).
- `tokens.css` — les mêmes valeurs en variables CSS, générées depuis `tokens.json` (servira au back-office Next.js).
- `components.css` + `components/<Composant>/` — 14 composants de référence : un `README.md` (règles) et un `preview.html` (aperçu à ouvrir dans un navigateur).
- Version interactive de la charte : page « ElecPay Design System » sur Claude.

Règle : si une valeur change, on la change dans `tokens.json`, puis partout ailleurs.

## Ordre de construction

1. Design : charte ✅ → maquettes client 16/16 ✅ → maquettes back-office (11 écrans)
2. Mobile Flutter : F0 socle → F7 finition (quand le backend est terminé)
3. Back-office Next.js
