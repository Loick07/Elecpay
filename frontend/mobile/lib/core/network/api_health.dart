import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';

/// État de l'API (`GET /api/v1/health`). Le client complet (jetons, erreurs, cache) arrive en F1 ;
/// ici, seulement de quoi savoir si l'API répond et si elle est en mode démo.
@immutable
sealed class ApiHealth {
  const ApiHealth();
}

/// L'API a répondu. `databaseOk` faux : 503, la base est injoignable côté serveur.
final class ApiReachable extends ApiHealth {
  const ApiReachable({required this.demoMode, required this.databaseOk});

  final bool demoMode;
  final bool databaseOk;
}

/// L'API ne répond pas (téléphone non relié au PC, API arrêtée, mauvaise adresse…).
final class ApiUnreachable extends ApiHealth {
  const ApiUnreachable(this.address);

  final String address;
}

class HealthService {
  HealthService(this._dio, this._config);

  final Dio _dio;
  final AppConfig _config;

  Future<ApiHealth> check() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${_config.apiRoot}/health',
        // 503 = API en vie mais base injoignable : c'est une réponse, pas une panne réseau.
        options: Options(validateStatus: (status) => status == 200 || status == 503),
      );
      final body = response.data ?? const {};
      return ApiReachable(
        demoMode: body['demo_mode'] == true,
        databaseOk: body['database'] == 'ok',
      );
    } on DioException {
      return ApiUnreachable(_config.apiBaseUrl.toString());
    }
  }
}

/// Client HTTP minimal de F0 (délais courts : on veut savoir vite si l'API répond).
final healthDioProvider = Provider<Dio>(
  (ref) => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Accept': 'application/json'},
    ),
  ),
);

final healthServiceProvider = Provider<HealthService>(
  (ref) => HealthService(ref.watch(healthDioProvider), ref.watch(appConfigProvider)),
);

/// État de l'API au démarrage ; `ref.invalidate(apiHealthProvider)` pour réessayer.
final apiHealthProvider = FutureProvider.autoDispose<ApiHealth>(
  (ref) => ref.watch(healthServiceProvider).check(),
);
