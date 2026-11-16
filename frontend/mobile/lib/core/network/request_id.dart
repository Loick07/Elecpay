import 'dart:math';

import 'package:dio/dio.dart';

import 'api_settings.dart';

final _random = Random.secure();
const _alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';

/// Nouvel identifiant de requête, ex. `app-k3v9q2x7m1z8c4b6n0p5` (24 caractères, tirés au hasard).
String newRequestId() =>
    'app-${List.generate(20, (_) => _alphabet[_random.nextInt(_alphabet.length)]).join()}';

/// Donne un `X-Request-ID` à chaque requête qui n'en a pas encore.
class RequestIdInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.putIfAbsent(ApiSettings.requestIdHeader, newRequestId);
    handler.next(options);
  }
}

/// Référence à montrer en cas d'erreur (« Référence : … ») : celle que l'API a renvoyée et
/// enregistrée dans ses journaux ; à défaut (pas de réponse), celle que l'application a envoyée.
String? requestReference(RequestOptions request, Response<Object?>? response) {
  final fromServer = response?.headers.value(ApiSettings.requestIdHeader);
  if (fromServer != null && fromServer.isNotEmpty) return fromServer;
  final sent = request.headers[ApiSettings.requestIdHeader];
  return sent is String ? sent : null;
}
