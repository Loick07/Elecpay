import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Ce que le faux serveur fait pour une requête.
sealed class FakeReply {
  const FakeReply();
}

/// Répond `status` + corps JSON. `requestId` : `echo` (reprend celui reçu, comme l'API),
/// une valeur précise, ou `null` (pas d'en-tête).
final class JsonReply extends FakeReply {
  const JsonReply(this.status, this.body, {this.requestId = echo, this.headers = const {}});

  static const echo = '<echo>';

  final int status;
  final Object? body;
  final String? requestId;
  final Map<String, String> headers;
}

/// Répond un corps brut (ex. une page HTML de proxy).
final class RawReply extends FakeReply {
  const RawReply(this.status, this.text, {this.contentType = 'text/html'});

  final int status;
  final String text;
  final String contentType;
}

/// Échec avant toute réponse (coupure réseau, délai dépassé…).
final class FailReply extends FakeReply {
  const FailReply(this.type, {this.error});

  final DioExceptionType type;
  final Object? error;
}

/// Faux serveur branché à la place du réseau : chaque requête reçue est notée dans [requests],
/// et la réponse est choisie par [handler].
class FakeServer implements HttpClientAdapter {
  FakeServer(this.handler);

  FakeReply Function(RequestOptions request) handler;
  final List<RequestOptions> requests = [];

  /// Corps réellement envoyés sur le réseau (octets décodés), `null` si aucun corps.
  final List<String?> sentBodies = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    sentBodies.add(
      requestStream == null ? null : utf8.decode(await requestStream.expand((c) => c).toList()),
    );
    switch (handler(options)) {
      case FailReply(:final type, :final error):
        throw DioException(requestOptions: options, type: type, error: error);
      case RawReply(:final status, :final text, :final contentType):
        return ResponseBody.fromString(
          text,
          status,
          headers: {
            Headers.contentTypeHeader: [contentType],
          },
        );
      case JsonReply(:final status, :final body, :final requestId, :final headers):
        final sent = options.headers['X-Request-ID'] as String?;
        final id = requestId == JsonReply.echo ? sent : requestId;
        return ResponseBody.fromString(
          body == null ? '' : jsonEncode(body),
          status,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
            if (id != null) 'x-request-id': [id],
            for (final h in headers.entries) h.key.toLowerCase(): [h.value],
          },
        );
    }
  }

  @override
  void close({bool force = false}) {}
}

/// Corps d'erreur au format commun de l'API.
Map<String, Object?> apiError(String code, String message, [Map<String, Object?>? details]) => {
  'error': {'code': code, 'message': message, 'details': details ?? <String, Object?>{}},
};
