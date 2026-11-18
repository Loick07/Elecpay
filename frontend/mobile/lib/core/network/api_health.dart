import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import 'api_client.dart';

/// État de l'API (`GET /api/v1/health`) : l'API répond-elle, et est-elle en mode démo ?
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

  @visibleForTesting
  Dio get dio => _dio;

  /// Adresse de l'API (aide au développement quand elle ne répond pas).
  String get address => _config.apiBaseUrl.toString();

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

/// Même client HTTP que le reste de l'application (mêmes délais, même identifiant de requête).
final healthServiceProvider = Provider<HealthService>(
  (ref) => HealthService(ref.watch(apiDioProvider), ref.watch(appConfigProvider)),
);
