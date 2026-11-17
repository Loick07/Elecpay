# Appeler l'API depuis un écran — guide pour F3 → F10

Tout ce qui parle à l'API est dans `lib/core/` (étape F1). Un écran n'utilise **jamais** Dio
directement : il passe par les fournisseurs ci-dessous.

## Quel client utiliser

| Besoin | Fournisseur | Exemple |
|---|---|---|
| Afficher une donnée (écran) | `cachedApiProvider` → `CachedApi.get` | profil, factures, consommation |
| Envoyer une action (POST, PATCH…) | `authenticatedApiProvider` → `ApiClient.postObject` / `postNoContent` | paiement, invitation |
| Connexion, déconnexion | `sessionManagerProvider` → `login`, `signIn`, `logout` | écrans F3 |
| Savoir si on est connecté | `sessionStateProvider` | redirection, « session expirée » |

Le jeton est ajouté tout seul ; son expiration est absorbée (un seul rafraîchissement, puis la requête
est rejouée une fois). Les nouveaux jetons sont enregistrés avant le rejeu.

## Lire une donnée

```dart
final result = await ref.read(cachedApiProvider).get('/bills/$id', BillDetail.fromJson);
switch (result) {
  case FreshData(:final data):
    // donnée fraîche
  case CachedData(:final data, :final label):
    // API injoignable : afficher `label`
    // (« Hors connexion. Les données affichées datent du 12 nov. à 08:15. »)
}
```

- Une nouvelle route GET doit être rangée dans `lib/core/cache/cache_policy.dart` : dans
  `cacheableRoutes` ou dans `neverCachedRoutes` (avec sa raison). Un test l'exige.
- **Jamais en cache** : `GET /payments/{id}`, la vérification publique d'un reçu, `/health`,
  `/invitations`, `/me/2fa`, les PDF.
- Hors ligne et **sans cache** : l'échec `NoConnection` remonte → état « hors ligne » (F2).
- Un refus de l'API (403, 404, session expirée) n'est jamais masqué par le cache.
- Cache rangé par utilisateur, effacé à la déconnexion, au plus 30 jours. Session expirée : rien
  n'est affiché avant la reconnexion du même compte.

## Envoyer une action

```dart
try {
  await ref.read(authenticatedApiProvider).postObject(
    '/payments',
    PaymentPublic.fromJson,
    body: PaymentCreate(...),                       // modèle freezed : écrit en JSON par le client
    headers: {'Idempotency-Key': key},
  );
} on ApiFailure catch (failure) {
  // afficher failure.message, et « Référence : ${failure.reference} » en petit
}
```

- **Aucune relance automatique** d'une action. L'écran propose « Réessayer ».
- `ApiTimeout(mayHaveReachedServer: true)` : l'action a peut-être été faite. Pour un paiement :
  « Statut à vérifier », lire `GET /payments/{id}`, ne relancer qu'avec la **même** clé d'idempotence.
- Hors ligne : les boutons d'action sont désactivés (« Connexion nécessaire pour payer »).

## Les échecs (`ApiFailure`, `lib/core/network/api_failure.dart`)

| Cas | Quand | À l'écran |
|---|---|---|
| `NoConnection` | pas de réseau, API injoignable | état hors ligne, « Réessayer » |
| `ApiTimeout` | 15 s pour se connecter, 30 s pour la réponse (`ApiSettings`) | « Réessayer » (sauf action d'argent : voir plus haut) |
| `ServerUnavailable` | 5xx | « momentanément indisponible » |
| `SessionExpired` | session terminée | écran de connexion (« session expirée ») |
| `TooManyRequests` | 429 | message avec le délai (« Réessayez dans 3 min ») |
| `InvalidFields` | 422 | `fields` : un type d'erreur par champ, message écrit par l'écran |
| `ApiRejected` | autre 4xx | `code` (stable) pour décider, `message` (français) pour afficher |
| `UnexpectedResponse` | réponse hors contrat | message générique + référence |

Toujours afficher la référence en petit (`failure.reference`) : l'équipe retrouve la requête dans les
journaux de l'API.

## Modèles

Écrits à la main avec freezed (`lib/features/<domaine>/models/`), d'après `backend/openapi.json`.
Chaque modèle s'ajoute à la liste `cases` de `test/contract/openapi_contract_test.dart`, qui vérifie
champs, obligatoires, `null` et aller-retour JSON. Puis : `dart run build_runner build
--delete-conflicting-outputs` (le code généré est commité ; la CI vérifie qu'il est à jour).

## Tests

Jamais de réseau réel dans les tests (`test/flutter_test_config.dart` l'interdit). Outils :
`test/support/fake_server.dart` (faux serveur), `fake_auth_backend.dart` (jetons, rotation,
`SessionHarness`), `memory_cache_store.dart`, `openapi.dart` (exemples conformes au contrat).

## Page Diagnostic

Bouton « Diagnostic » sur l'écran de démarrage, en debug et en profile seulement (constante
`diagnosticsEnabled`) ; absente du code compilé en release (vérifié en CI par `tool/apk_check.dart
--diagnostic=absent`). Pour voir un vrai jeton expiré : lancer l'API avec `ACCESS_TOKEN_MINUTES=1`.
