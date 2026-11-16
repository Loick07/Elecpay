import 'dart:io';

import 'package:dio/dio.dart';

import 'models/api_error.dart';
import 'request_id.dart';

/// Tout échec d'un appel à l'API, traduit en un cas clair avec son message en français.
///
/// `reference` : identifiant de la requête (`X-Request-ID`), à afficher discrètement
/// (« Référence : … ») pour que l'équipe retrouve la requête dans les journaux.
sealed class ApiFailure implements Exception {
  const ApiFailure({this.reference});

  /// Traduit une erreur de Dio. `DioException` n'est jamais montrée telle quelle.
  factory ApiFailure.fromDio(DioException error) {
    final reference = requestReference(error.requestOptions, error.response);
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return ApiTimeout(mayHaveReachedServer: false, reference: reference);
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout: // réponse reçue, lecture trop longue
        return ApiTimeout(mayHaveReachedServer: true, reference: reference);
      case DioExceptionType.connectionError:
        return NoConnection(reference: reference);
      case DioExceptionType.badCertificate:
        return InsecureConnection(reference: reference);
      case DioExceptionType.cancel:
        return RequestCancelled(reference: reference);
      case DioExceptionType.badResponse:
        return _fromResponse(error.response!, reference);
      case DioExceptionType.unknown:
        final cause = error.error;
        if (cause is SocketException || cause is HttpException) {
          return NoConnection(reference: reference);
        }
        if (cause is HandshakeException || cause is TlsException) {
          return InsecureConnection(reference: reference);
        }
        return UnexpectedResponse(reference: reference);
    }
  }

  final String? reference;

  /// Message pour l'utilisateur, en français.
  String get message;

  static ApiFailure _fromResponse(Response<Object?> response, String? reference) {
    final status = response.statusCode ?? 0;
    if (status >= 500) return ServerUnavailable(statusCode: status, reference: reference);

    final ErrorBody body;
    try {
      body = ErrorResponse.fromJson(response.data! as Map<String, dynamic>).error;
    } on Object {
      // 4xx sans le format commun (ex. page d'un proxy) : on ne devine pas.
      return UnexpectedResponse(statusCode: status, reference: reference);
    }

    if (status == 429) {
      return TooManyRequests(
        body: body,
        retryAfter: _retryAfter(body, response.headers.value('retry-after')),
        reference: reference,
      );
    }
    if (status == 422 && body.code == 'VALIDATION_ERROR') {
      return InvalidFields(body: body, reference: reference);
    }
    return ApiRejected(statusCode: status, body: body, reference: reference);
  }

  static Duration? _retryAfter(ErrorBody body, String? header) {
    final seconds = body.details['retry_after_seconds'];
    if (seconds is int) return Duration(seconds: seconds);
    final fromHeader = int.tryParse(header ?? '');
    return fromHeader == null ? null : Duration(seconds: fromHeader);
  }

  @override
  String toString() => '$runtimeType($message, référence : $reference)';
}

/// Pas de réseau, ou l'API est injoignable (téléphone hors ligne, serveur éteint).
final class NoConnection extends ApiFailure {
  const NoConnection({super.reference});

  @override
  String get message =>
      'Pas de connexion à ElecPay. Vérifiez votre connexion internet puis réessayez.';
}

/// Délai dépassé (15 s pour se connecter, 30 s pour la réponse : `ApiSettings`).
///
/// `mayHaveReachedServer` : la requête a pu être traitée par l'API (délai de réponse dépassé).
/// Une requête qui modifie quelque chose (un paiement…) n'est donc JAMAIS relancée
/// automatiquement : l'écran vérifie d'abord son état.
final class ApiTimeout extends ApiFailure {
  const ApiTimeout({required this.mayHaveReachedServer, super.reference});

  final bool mayHaveReachedServer;

  @override
  String get message => 'ElecPay met trop de temps à répondre. Réessayez dans un instant.';
}

/// Erreur 5xx : l'API (ou sa base) est en panne.
final class ServerUnavailable extends ApiFailure {
  const ServerUnavailable({required this.statusCode, super.reference});

  final int statusCode;

  @override
  String get message => 'ElecPay est momentanément indisponible. Réessayez dans quelques minutes.';
}

/// Certificat refusé : la connexion n'est pas sûre, rien n'est envoyé.
final class InsecureConnection extends ApiFailure {
  const InsecureConnection({super.reference});

  @override
  String get message => 'La connexion à ElecPay n’est pas sécurisée. Opération annulée.';
}

/// Requête annulée par l'application (écran quitté…) : rien à afficher en général.
final class RequestCancelled extends ApiFailure {
  const RequestCancelled({super.reference});

  @override
  String get message => 'Opération annulée.';
}

/// La session a pris fin (rafraîchissement refusé, jeton invalide ou rejoué) : jetons effacés,
/// retour à l'écran de connexion (F3 : écran « session expirée »).
final class SessionExpired extends ApiFailure {
  const SessionExpired({super.reference});

  @override
  String get message => 'Votre session a expiré. Reconnectez-vous pour continuer.';
}

/// Réponse illisible ou différente du contrat d'API.
final class UnexpectedResponse extends ApiFailure {
  const UnexpectedResponse({this.statusCode, super.reference});

  final int? statusCode;

  @override
  String get message =>
      'Réponse inattendue d’ElecPay. Réessayez ; si le problème continue, contactez l’assistance.';
}

/// L'API a refusé la demande (4xx, format commun). `code` est stable : c'est lui qu'on teste
/// (ex. `INVALID_CREDENTIALS`, `TOKEN_EXPIRED`). Le message de l'API est déjà en français.
base class ApiRejected extends ApiFailure {
  const ApiRejected({required this.statusCode, required this.body, super.reference});

  final int statusCode;
  final ErrorBody body;

  String get code => body.code;

  @override
  String get message => body.message.trim().isNotEmpty ? body.message : _fallback(statusCode);

  static String _fallback(int status) => switch (status) {
    401 => 'Votre session a pris fin. Reconnectez-vous.',
    403 => 'Vous n’avez pas accès à cette information.',
    404 => 'Élément introuvable.',
    409 => 'Cette opération est en conflit avec une autre.',
    _ => 'Demande refusée par ElecPay.',
  };
}

/// 429 : trop de tentatives. `retryAfter` vient de `details.retry_after_seconds` ou `Retry-After`.
final class TooManyRequests extends ApiRejected {
  const TooManyRequests({required super.body, this.retryAfter, super.reference})
    : super(statusCode: 429);

  final Duration? retryAfter;

  @override
  String get message => retryAfter == null
      ? 'Trop de tentatives. Réessayez plus tard.'
      : 'Trop de tentatives. Réessayez dans ${formatWait(retryAfter!)}.';
}

/// 422 : un ou plusieurs champs refusés par l'API (`details.fields[]`).
final class InvalidFields extends ApiRejected {
  const InvalidFields({required super.body, super.reference}) : super(statusCode: 422);

  /// Champ (sans le préfixe `body.` / `query.` / `path.`) → type d'erreur de l'API
  /// (ex. `phone` → `string_too_short`). Les écrans affichent leur propre message en français.
  Map<String, String> get fields {
    final raw = body.details['fields'];
    if (raw is! List<Object?>) return const {};
    return {
      for (final item in raw.whereType<Map<String, Object?>>())
        if (item['field'] case final String field)
          field.replaceFirst(RegExp(r'^(body|query|path)\.'), ''):
              (item['type'] as String?) ?? 'invalid',
    };
  }

  @override
  String get message => 'Certaines informations sont invalides. Vérifiez les champs signalés.';
}

/// Durée d'attente lisible : « 45 s », « 3 min », « 1 h », « 1 h 30 min ».
String formatWait(Duration wait) {
  final seconds = wait.inSeconds;
  if (seconds < 60) return '${seconds < 1 ? 1 : seconds} s';
  final minutes = (seconds / 60).ceil();
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0 ? '$hours h' : '$hours h $rest min';
}
