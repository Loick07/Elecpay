import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import 'api_failure.dart';
import 'api_settings.dart';
import 'request_id.dart';

/// Le client HTTP unique de l'application : adresse de l'API, délais (`ApiSettings`),
/// identifiant de requête. Les jetons s'ajoutent en F1.3 (intercepteur de session).
Dio createApiDio(AppConfig config) => Dio(
  BaseOptions(
    baseUrl: config.apiRoot,
    connectTimeout: ApiSettings.connectTimeout,
    receiveTimeout: ApiSettings.receiveTimeout,
    headers: {'Accept': 'application/json'},
  ),
)..interceptors.add(RequestIdInterceptor());

final apiDioProvider = Provider<Dio>((ref) => createApiDio(ref.watch(appConfigProvider)));

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref.watch(apiDioProvider)));

/// Appels à l'API avec une seule règle d'erreur : tout échec devient une [ApiFailure].
///
/// AUCUNE relance automatique ici : une requête qui modifie quelque chose (POST, PATCH, DELETE)
/// part une seule fois. Le seul rejeu permis est celui qui suit un rafraîchissement du jeton (F1.3).
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  /// Lecture d'un objet JSON, décodé par `decode` (ex. `UserPublic.fromJson`).
  Future<T> getObject<T>(
    String path,
    T Function(Map<String, dynamic> json) decode, {
    Map<String, Object?>? query,
  }) => _send(
    () => _dio.get<Object?>(path, queryParameters: query),
    (data) => decode(_asObject(data)),
  );

  /// Envoi d'un corps JSON (`body` : un modèle avec `toJson`, ou une Map), réponse objet.
  Future<T> postObject<T>(
    String path,
    T Function(Map<String, dynamic> json) decode, {
    Object? body,
    Map<String, String>? headers,
  }) => _send(
    () => _dio.post<Object?>(
      path,
      data: _json(body),
      options: Options(headers: headers),
    ),
    (data) => decode(_asObject(data)),
  );

  /// Envoi sans contenu attendu en réponse (ex. 204 de `POST /auth/logout`).
  Future<void> postNoContent(String path, {Object? body, Map<String, String>? headers}) => _send(
    () => _dio.post<Object?>(
      path,
      data: _json(body),
      options: Options(headers: headers),
    ),
    (_) {},
  );

  /// Corps prêt pour le réseau : Dio n'appelle PAS `toJson()` d'un modèle freezed (il enverrait
  /// un corps invalide). On passe donc par `jsonEncode`, qui l'appelle, puis on relit le JSON.
  static Object? _json(Object? body) => body == null ? null : jsonDecode(jsonEncode(body));

  Future<T> _send<T>(
    Future<Response<Object?>> Function() call,
    T Function(Object? data) decode,
  ) async {
    final Response<Object?> response;
    try {
      response = await call();
    } on DioException catch (error) {
      throw error.error is ApiFailure ? error.error! as ApiFailure : ApiFailure.fromDio(error);
    }
    try {
      return decode(response.data);
    } on Object {
      // Réponse 2xx qui ne respecte pas le contrat : on ne l'utilise pas.
      throw UnexpectedResponse(
        statusCode: response.statusCode,
        reference: requestReference(response.requestOptions, response),
      );
    }
  }

  static Map<String, dynamic> _asObject(Object? data) => data! as Map<String, dynamic>;
}
