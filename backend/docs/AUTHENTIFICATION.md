# Authentification ElecPay — guide pour l'application mobile et le back-office

Complète le contrat OpenAPI (`/docs`) : il dit *quelles* routes existent, ce guide dit *comment*
les enchaîner correctement. Toutes les routes sont préfixées par `/api/v1`.

## Les deux jetons

| | Jeton d'accès | Jeton de rafraîchissement |
|---|---|---|
| Durée | 15 min | 30 jours |
| Sert à | appeler l'API | obtenir une nouvelle paire de jetons |
| Rotation | — | **chaque usage en donne un nouveau** ; l'ancien devient invalide |

Si un jeton de rafraîchissement **déjà utilisé** est présenté, l'API considère qu'il a été volé :
toutes les sessions de cette connexion sont fermées (`401 REFRESH_TOKEN_REUSED`).

## Application mobile (Flutter) — jetons dans le JSON

| Action | Route |
|---|---|
| Inscription (client uniquement) | `POST /auth/register` → jetons + profil |
| Connexion | `POST /auth/login` (`phone`, `password`) → jetons + profil |
| Appels | en-tête `Authorization: Bearer <access_token>` |
| Rafraîchir | `POST /auth/refresh` (`refresh_token`) |
| Déconnexion | `POST /auth/logout` (`refresh_token`) → 204, toujours |
| Déconnecter tous mes appareils | `POST /auth/logout-all` (connecté) |
| Mot de passe oublié | `POST /auth/password/forgot` puis `POST /auth/password/reset` |
| Profil | `GET /me`, `PATCH /me` (nom, e-mail) |
| Changer de mot de passe | `POST /me/password` → **nouveaux jetons** à enregistrer |

Règles pour l'application :
- Stocker les jetons dans `flutter_secure_storage`, jamais ailleurs.
- **Un seul rafraîchissement à la fois.** Si deux requêtes reçoivent `401 TOKEN_EXPIRED` en même
  temps, une seule appelle `/auth/refresh` ; les autres attendent son résultat. Sinon, le second
  rafraîchissement présente un jeton déjà utilisé et toute la session est fermée par sécurité.
- Sur `401` de `/auth/refresh` (quel que soit le code) : effacer les jetons, retour à la connexion.
- Le numéro peut être saisi librement (`06 123 45 67`) : l'API le normalise en `+242061234567`.
- En mode démo, `forgot` renvoie `demo_code` : l'afficher (maquette « code affiché en mode démo »).

## Back-office (Next.js) — jetons dans des cookies httpOnly

Réservé à l'équipe (support, admin, super admin) : un client reçoit `403 FORBIDDEN`.

| Action | Route |
|---|---|
| Connexion | `POST /auth/web/login` → dépose les cookies, renvoie le profil (jamais les jetons) |
| Rafraîchir | `POST /auth/web/refresh` (cookie + en-tête CSRF) |
| Déconnexion | `POST /auth/web/logout` (cookie + en-tête CSRF) → efface les cookies |

Cookies déposés : `elecpay_access` et `elecpay_refresh` (httpOnly, illisibles par le JavaScript),
`elecpay_csrf` (lisible). Tous `Secure` et `SameSite=Strict`.

Règles pour le back-office :
- **Toute requête qui modifie** (POST, PATCH, PUT, DELETE) doit porter l'en-tête
  `X-CSRF-Token` avec la valeur du cookie `elecpay_csrf`. Sinon : `403 CSRF_INVALID`.
  Les lectures (GET) n'en ont pas besoin.
- Avec `SameSite=Strict`, le navigateur n'envoie les cookies qu'au **même site** : le serveur
  Next.js doit relayer les appels vers l'API (proxy / rewrites), au lieu que le navigateur
  appelle directement une autre adresse.
- Envoyer les requêtes avec les cookies (`credentials: "include"` côté navigateur).

## Codes d'erreur (format commun `{"error": {"code", "message", "details"}}`)

| Code | Statut | Quand | Que faire |
|---|---|---|---|
| `INVALID_CREDENTIALS` | 401 | numéro inconnu **ou** mauvais mot de passe (volontairement identiques) | afficher le message |
| `ACCOUNT_DISABLED` | 403 | compte désactivé | message + lien assistance |
| `NOT_AUTHENTICATED` | 401 | aucun jeton | écran de connexion |
| `TOKEN_EXPIRED` | 401 | jeton d'accès expiré | rafraîchir puis rejouer la requête |
| `TOKEN_INVALID` | 401 | jeton illisible ou falsifié | écran de connexion |
| `REFRESH_TOKEN_REUSED` | 401 | jeton de rafraîchissement rejoué | écran de connexion |
| `FORBIDDEN` | 403 | rôle insuffisant | écran « accès refusé » |
| `CSRF_INVALID` | 403 | back-office : en-tête CSRF absent ou faux | recharger la page |
| `PHONE_ALREADY_USED` / `EMAIL_ALREADY_USED` | 409 | inscription, profil | message sur le champ |
| `WRONG_CURRENT_PASSWORD` / `SAME_PASSWORD` | 400 | changement de mot de passe | message sur le champ |
| `RESET_CODE_INVALID` | 400 | code faux, expiré, déjà utilisé ou trop d'essais | proposer un nouveau code |
| `TOO_MANY_ATTEMPTS` | 429 | trop de tentatives | afficher `details.retry_after_seconds` |
| `VALIDATION_ERROR` | 422 | champ invalide | `details.fields[]` : un message par champ |

## Limites de tentatives

| Action | Limite |
|---|---|
| Connexion | 5 échecs par numéro / 15 min ; 20 tentatives par IP / 15 min |
| Mot de passe oublié | 3 par numéro / heure ; 10 par IP / heure |
| Réinitialisation | 10 par IP / 15 min (et 5 essais par code) |
| Inscription | 5 par IP / heure |

Les connexions mobile et back-office partagent les mêmes compteurs.

## Règles des mots de passe et des codes

- Mot de passe : 8 caractères minimum, au moins une lettre et un chiffre, 128 au maximum.
- Code de réinitialisation : 6 chiffres, valable 10 minutes, 5 essais, un seul usage ;
  en demander un nouveau annule le précédent. Après réinitialisation, tous les appareils
  sont déconnectés.
