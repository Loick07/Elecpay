import 'package:dio/dio.dart';
import 'package:elecpay/core/config/app_config.dart';
import 'package:elecpay/core/network/api_health.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

/// Service de santé de test : renvoie la réponse choisie, sans réseau, et compte les appels.
class FakeHealthService extends HealthService {
  FakeHealthService(this.answer) : super(Dio(), AppConfig.parse(defaultApiBaseUrl, release: false));

  ApiHealth answer;
  int calls = 0;

  @override
  Future<ApiHealth> check() async {
    calls++;
    return answer;
  }
}

/// À passer à `ProviderScope(overrides: …)` : l'application ne touche jamais le réseau en test.
List<Override> healthOverrides(FakeHealthService service) => [
  healthServiceProvider.overrideWithValue(service),
];

FakeHealthService demoApi() =>
    FakeHealthService(const ApiReachable(demoMode: true, databaseOk: true));
