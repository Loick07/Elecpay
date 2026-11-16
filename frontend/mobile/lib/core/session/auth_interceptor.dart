import 'package:dio/dio.dart';

import '../network/api_client.dart';
import '../network/api_failure.dart';
import 'session_manager.dart';

/// Ajoute le jeton d'accès à chaque requête et absorbe son expiration.
///
/// Sur `401 TOKEN_EXPIRED` : un rafraîchissement (partagé entre les requêtes simultanées), puis la
/// requête est rejouée UNE fois avec le nouveau jeton. C'est le SEUL rejeu de l'application : sans
/// risque, même pour un POST, car l'API a refusé la requête avant de la traiter.
///
/// Sur `401` avec `TOKEN_INVALID`, `REFRESH_TOKEN_REUSED`, `NOT_AUTHENTICATED`, ou un second
/// `TOKEN_EXPIRED` après rejeu : la session est terminée et l'appel échoue en [SessionExpired].
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._session, this._dio);

  final SessionManager _session;
  final Dio _dio;

  static const _sentToken = 'elecpay.sentAccessToken';
  static const _replayed = 'elecpay.replayed';
  static const _endSession = {
    'TOKEN_EXPIRED',
    'TOKEN_INVALID',
    'REFRESH_TOKEN_REUSED',
    'NOT_AUTHENTICATED',
  };

  static bool _isPublic(RequestOptions request) => request.extra[ApiClient.publicRequest] == true;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (_isPublic(options)) return handler.next(options);
    final tokens = await _session.currentTokens();
    if (tokens != null) {
      options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      options.extra[_sentToken] = tokens.accessToken;
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    if (err.response?.statusCode != 401 || _isPublic(request)) return handler.next(err);

    final code = _errorCode(err.response?.data);
    if (code == 'TOKEN_EXPIRED' && request.extra[_replayed] != true) {
      try {
        await _session.freshAccessToken(failedAccessToken: request.extra[_sentToken] as String?);
      } on ApiFailure catch (failure) {
        // Refus (session terminée) ou panne réseau (session gardée) : l'appel échoue avec ce motif.
        return handler.next(_wrap(request, failure));
      }
      try {
        // Rejeu : `onRequest` repasse et pose le NOUVEAU jeton (déjà enregistré).
        final replay = request.copyWith(extra: {...request.extra, _replayed: true});
        return handler.resolve(await _dio.fetch<Object?>(replay));
      } on DioException catch (replayError) {
        return handler.next(replayError);
      }
    }

    if (_endSession.contains(code)) {
      await _session.end(SessionEndReason.expired);
      return handler.next(_wrap(request, SessionExpired(reference: _reference(err))));
    }
    handler.next(err);
  }

  static DioException _wrap(RequestOptions request, ApiFailure failure) =>
      DioException(requestOptions: request, error: failure);

  static String? _reference(DioException err) => ApiFailure.fromDio(err).reference;

  static String? _errorCode(Object? body) => switch (body) {
    {'error': {'code': final String code}} => code,
    _ => null,
  };
}
