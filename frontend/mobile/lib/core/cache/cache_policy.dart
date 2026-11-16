/// Ce qui peut être gardé sur le téléphone pour le mode hors ligne, et ce qui ne l'est JAMAIS.
///
/// Seules les lectures (GET) peuvent l'être. Toute route GET du contrat (`backend/openapi.json`) doit
/// figurer dans l'une des deux listes : un test le vérifie, pour qu'une nouvelle route oblige à
/// décider. Les chemins sont relatifs à `/api/v1`, avec `{…}` pour les paramètres.
library;

/// Lectures gardées en cache : affichées hors ligne avec la date de la donnée.
const cacheableRoutes = <String>{
  '/me',
  '/me/notification-preferences',
  '/households',
  '/households/{household_id}',
  '/households/{household_id}/members',
  '/households/{household_id}/meters',
  '/meters/{meter_id}',
  '/meters/{meter_id}/readings',
  '/meters/{meter_id}/consumption',
  '/meters/{meter_id}/consumption/summary',
  '/meters/{meter_id}/consumption/days/{day}',
  '/bills',
  '/bills/{bill_id}',
  '/payments',
  '/receipts',
  '/receipts/{receipt_id}',
  '/notifications',
  '/notifications/unread-count',
};

/// Lectures JAMAIS mises en cache, et pourquoi.
const neverCachedRoutes = <String, String>{
  '/payments/{payment_id}':
      'état d’un paiement en cours : toujours lu en direct, jamais une version ancienne',
  '/receipts/verify/{code}': 'vérification publique d’un reçu : un résultat ancien serait trompeur',
  '/health': 'état de l’API à l’instant présent',
  '/invitations': 'invitations à accepter ou refuser : en direct seulement',
  '/me/2fa': 'réglage de sécurité (équipe)',
  '/bills/{bill_id}/pdf': 'document PDF : téléchargé à la demande, pas un écran',
  '/receipts/{receipt_id}/pdf': 'document PDF : téléchargé à la demande, pas un écran',
};

/// Modèle de route (`/bills/{bill_id}`) correspondant à un chemin réel (`/bills/12`), ou `null`.
String? routeOf(String path) {
  final clean = path.split('?').first;
  for (final route in {...cacheableRoutes, ...neverCachedRoutes.keys}) {
    final pattern = RegExp('^${route.replaceAll(RegExp(r'\{[^}]+\}'), '[^/]+')}\$');
    if (pattern.hasMatch(clean)) return route;
  }
  return null;
}

/// Ce chemin (lecture GET) peut-il être gardé en cache ? Une route inconnue : non.
bool isCacheable(String path) => cacheableRoutes.contains(routeOf(path));
