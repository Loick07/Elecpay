import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_health.dart';
import '../../core/session/session_manager.dart';
import '../../core/session/session_providers.dart';

/// Ce que fait le splash après sa vérification.
@immutable
sealed class StartupDecision {
  const StartupDecision();
}

/// Session enregistrée : l'accueil (même si l'API ne répond pas : cache + bannière hors connexion).
final class GoHome extends StartupDecision {
  const GoHome();
}

/// Pas de session, API joignable : l'écran de connexion.
final class GoLogin extends StartupDecision {
  const GoLogin();
}

/// Pas de session et API injoignable : bloc « Hors connexion » (réservé à ce cas) avec Réessayer.
final class ShowUnreachable extends StartupDecision {
  const ShowUnreachable(this.address);

  final String address;
}

/// Pas de session, l'API répond mais sa base est en panne (503) : « momentanément indisponible ».
final class ShowUnavailable extends StartupDecision {
  const ShowUnavailable();
}

/// Durée MAXIMALE du splash (règle de Loick, 17/11/2026).
const splashBudget = Duration(seconds: 2);

/// Décide où aller au démarrage, en [budget] au plus.
///
/// - session enregistrée → [GoHome] AUSSITÔT, sans attendre l'API ;
/// - sans session → l'état de l'API, attendu [budget] au plus (au-delà : injoignable).
Future<StartupDecision> decideStart({
  required SessionManager session,
  required HealthService health,
  Duration budget = splashBudget,
}) async {
  final tokens = await session.currentTokens();
  if (tokens != null) return const GoHome();
  final state = await health.check().timeout(
    budget,
    onTimeout: () => ApiUnreachable(health.address),
  );
  return switch (state) {
    ApiReachable(databaseOk: true) => const GoLogin(),
    ApiReachable() => const ShowUnavailable(),
    ApiUnreachable(:final address) => ShowUnreachable(address),
  };
}

/// La décision du splash ; `ref.invalidate(startupDecisionProvider)` pour réessayer.
final startupDecisionProvider = FutureProvider.autoDispose<StartupDecision>(
  (ref) => decideStart(
    session: ref.watch(sessionManagerProvider),
    health: ref.watch(healthServiceProvider),
  ),
);
