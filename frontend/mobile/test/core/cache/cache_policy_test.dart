import 'dart:convert';
import 'dart:io';

import 'package:elecpay/core/cache/cache_policy.dart';
import 'package:flutter_test/flutter_test.dart';

/// Routes GET du contrat utilisables par l'application client (le back-office `/admin` est à part).
Set<String> contractGetRoutes() {
  final doc =
      jsonDecode(File('../../backend/openapi.json').readAsStringSync()) as Map<String, dynamic>;
  final paths = doc['paths'] as Map<String, dynamic>;
  return {
    for (final entry in paths.entries)
      if ((entry.value as Map<String, dynamic>).containsKey('get') &&
          !entry.key.startsWith('/api/v1/admin'))
        entry.key.replaceFirst('/api/v1', ''),
  };
}

void main() {
  test('chaque route GET du contrat est classée : en cache OU jamais en cache', () {
    final contract = contractGetRoutes();
    final classified = {...cacheableRoutes, ...neverCachedRoutes.keys};
    expect(
      contract.difference(classified),
      isEmpty,
      reason: 'nouvelle route GET : la ranger dans cacheableRoutes ou neverCachedRoutes',
    );
    expect(classified.difference(contract), isEmpty, reason: 'route absente du contrat');
    expect(cacheableRoutes.intersection(neverCachedRoutes.keys.toSet()), isEmpty);
  });

  test('GET /payments/{id} n’est JAMAIS mis en cache (état d’un paiement en cours)', () {
    expect(neverCachedRoutes, contains('/payments/{payment_id}'));
    expect(isCacheable('/payments/42'), isFalse);
    expect(isCacheable('/payments/42?refresh=1'), isFalse);
    // L'historique, lui, peut l'être (affiché avec sa date).
    expect(isCacheable('/payments'), isTrue);
  });

  test('vérification publique d’un reçu et PDF : jamais en cache', () {
    expect(isCacheable('/receipts/verify/ABCD2345EFGH'), isFalse);
    expect(isCacheable('/bills/12/pdf'), isFalse);
    expect(isCacheable('/receipts/3/pdf'), isFalse);
    expect(isCacheable('/receipts/3'), isTrue);
  });

  test('chaque route jamais mise en cache a sa raison écrite', () {
    for (final reason in neverCachedRoutes.values) {
      expect(reason.trim(), isNotEmpty);
    }
  });

  test('route inconnue : jamais en cache', () {
    expect(isCacheable('/inconnue'), isFalse);
    expect(routeOf('/inconnue'), isNull);
  });

  test('paramètres de chemin reconnus, segment par segment', () {
    expect(
      routeOf('/meters/5/consumption/days/2026-11-16'),
      '/meters/{meter_id}/consumption/days/{day}',
    );
    expect(routeOf('/meters/5/consumption'), '/meters/{meter_id}/consumption');
    expect(routeOf('/bills/7'), '/bills/{bill_id}');
    expect(routeOf('/bills/7/autre'), isNull);
  });
}
