# Foyers, membres et compteurs — guide pour l'application mobile

Complète le contrat OpenAPI (`/docs`). Écran concerné : « Compteurs et foyers » (maquette client 15).
Toutes les routes sont préfixées par `/api/v1` et exigent d'être connecté.

## Rôles dans un foyer

Distincts du rôle du compte (client, admin…).

| Action | Propriétaire (`owner`) | Payeur délégué (`payer`) | Lecteur (`viewer`) |
|---|:---:|:---:|:---:|
| Voir le foyer, ses compteurs, ses membres | ✅ | ✅ | ✅ |
| Payer les factures (B7) | ✅ | ✅ | ❌ |
| Modifier le foyer, ajouter / renommer un compteur | ✅ | ❌ | ❌ |
| Inviter, retirer des membres | ✅ | ❌ | ❌ |
| Quitter le foyer | — | ✅ | ✅ |

Chaque réponse de foyer porte `my_role`, `can_pay` et `can_manage` : l'application s'en sert pour
afficher ou masquer les boutons, sans recalculer les droits elle-même (le serveur les vérifie de toute façon).

## Routes

| Action | Route |
|---|---|
| Mes foyers (possédés + membre actif) | `GET /households` |
| Créer un foyer (comptes clients) | `POST /households` (`name`, `city`, `district?`, `address?`) |
| Carte d'un foyer : compteurs, membres, droits | `GET /households/{id}` |
| Modifier un foyer | `PATCH /households/{id}` (`null` efface quartier ou adresse) |
| Membres | `GET /households/{id}/members` |
| Inviter (payeur ou lecteur) | `POST /households/{id}/members` (`phone`, `role`) |
| Retirer un membre / annuler une invitation | `DELETE /households/{id}/members/{member_id}` |
| Quitter un foyer | `POST /households/{id}/leave` |
| Mes invitations reçues | `GET /invitations` |
| Accepter (renvoie le foyer) / refuser | `POST /invitations/{id}/accept` · `POST /invitations/{id}/decline` |
| Compteurs d'un foyer | `GET /households/{id}/meters` |
| Ajouter un compteur | `POST /households/{id}/meters` (`reference`, `customer_number`, `label?`) |
| Détail / renommer un compteur | `GET /meters/{id}` · `PATCH /meters/{id}` (`label`) |

## Ajouter un compteur (feuille « Ajouter un compteur »)

- Demander les **deux** numéros imprimés sur la facture E²C : le **N° de branchement** (ex. `0018 09 5408`)
  et le **N° client** (ex. `0758340H`). Espaces, tirets et minuscules sont acceptés.
- Police, centre E²C et puissance souscrite viennent d'E²C : ne pas les demander à l'abonné.
- En mode démo, la réponse contient `history` : `{"readings": …, "bills": …, "source": "simulated"}`.
  Les anciennes factures importées sont payées (hors ElecPay) ; la dernière reste à payer.
- Démo : `0018 09 5408` + `0758340H` fonctionne ; un branchement finissant par `0000` est « introuvable ».
  La vérification réelle du couple sera faite par E²C quand son API sera branchée.

## Invitations

- La personne invitée doit déjà avoir un compte ElecPay. Sinon : `INVITEE_NOT_FOUND`
  (« demandez-lui d'installer l'application »).
- Elle reçoit une notification (`invitation_received`, avec `household_id` et `invitation_id`) et un SMS.
- Tant qu'elle n'a pas accepté, elle n'a **aucun** accès au foyer.
- Le propriétaire voit les invitations en attente dans `members` (`status: "invited"`) ; les autres membres non.

## Confidentialité

- Un foyer ou un compteur auquel on n'a pas accès répond **404**, exactement comme s'il n'existait pas.
  Afficher « introuvable », jamais « accès refusé ».
- Les numéros des autres personnes sont toujours masqués (`phone_masked` : `+242 06 *** ** 67`).

## Codes d'erreur

| Code | Statut | Quand |
|---|---|---|
| `HOUSEHOLD_NOT_FOUND` / `METER_NOT_FOUND` | 404 | n'existe pas, ou pas d'accès (identiques) |
| `HOUSEHOLD_FORBIDDEN` | 403 | membre qui tente une action de propriétaire |
| `HOUSEHOLD_LIMIT_REACHED` | 409 | plus de 10 foyers possédés |
| `INVITEE_NOT_FOUND` | 404 | numéro sans compte actif |
| `INVALID_INVITEE` | 400 | s'inviter soi-même, inviter un compte de l'équipe |
| `ALREADY_MEMBER` | 409 | déjà membre ou déjà invité |
| `MEMBER_LIMIT_REACHED` | 409 | plus de 10 membres |
| `MEMBER_NOT_FOUND` / `INVITATION_NOT_FOUND` | 404 | membre ou invitation introuvable, ou déjà traitée |
| `OWNER_CANNOT_LEAVE` | 400 | le propriétaire veut quitter son foyer |
| `E2C_METER_NOT_FOUND` | 404 | couple branchement / client inconnu d'E²C |
| `METER_ALREADY_LINKED` | 409 | compteur déjà rattaché à un foyer |
| `METER_LIMIT_REACHED` | 409 | plus de 5 compteurs dans le foyer |
| `TOO_MANY_ATTEMPTS` | 429 | plus de 20 invitations / jour, ou 10 ajouts de compteur / heure |
