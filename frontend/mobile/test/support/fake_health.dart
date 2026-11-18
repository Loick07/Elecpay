import 'dart:async';

import 'package:dio/dio.dart';
import 'package:elecpay/core/config/app_config.dart';
import 'package:elecpay/core/network/api_health.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

/// Service de santé de test : renvoie la réponse choisie, sans réseau, et compte les appels.
/// `hang: true` : ne répond JAMAIS (API muette).
class FakeHealthService extends HealthService {
  FakeHealthService(this.answer, {this.hang = false})
    : super(Dio(), AppConfig.parse(defaultApiBaseUrl, release: false));

  ApiHealth answer;
  bool hang;
  int calls = 0;

  @override
  Future<ApiHealth> check() {
    calls++;
    return hang ? Completer<ApiHealth>().future : Future.value(answer);
  }
}

/// À passer à `ProviderScope(overrides: …)` : l'application ne touche jamais le réseau en test.
List<Override> healthOverrides(FakeHealthService service) => [
  healthServiceProvider.overrideWithValue(service),
];

FakeHealthService demoApi() =>
    FakeHealthService(const ApiReachable(demoMode: true, databaseOk: true));

FakeHealthService unreachableApi() =>
    FakeHealthService(const ApiUnreachable('http://127.0.0.1:8000'));

FakeHealthService silentApi() =>
    FakeHealthService(const ApiReachable(demoMode: true, databaseOk: true), hang: true);
