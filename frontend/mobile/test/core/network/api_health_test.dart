import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:elecpay/core/config/app_config.dart';
import 'package:elecpay/core/network/api_health.dart';
import 'package:flutter_test/flutter_test.dart';

/// Faux serveur : répond `status` + `body`, ou lève une erreur de connexion.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter({this.status = 200, this.body, this.fail = false});

  final int status;
  final Map<String, dynamic>? body;
  final bool fail;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    if (fail) {
      throw DioException.connectionError(requestOptions: options, reason: 'refused');
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

HealthService service(FakeAdapter adapter) => HealthService(
  Dio()..httpClientAdapter = adapter,
  AppConfig.parse('http://127.0.0.1:8000', release: false),
);

void main() {
  test('API joignable en mode démo', () async {
    final adapter = FakeAdapter(body: {'status': 'ok', 'database': 'ok', 'demo_mode': true});
    final health = await service(adapter).check();
    expect(adapter.lastRequest!.uri.toString(), 'http://127.0.0.1:8000/api/v1/health');
    expect(health, isA<ApiReachable>());
    expect((health as ApiReachable).demoMode, isTrue);
    expect(health.databaseOk, isTrue);
  });

  test('503 : l’API répond mais sa base est injoignable', () async {
    final adapter = FakeAdapter(
      status: 503,
      body: {'status': 'degraded', 'database': 'error', 'demo_mode': false},
    );
    final health = await service(adapter).check() as ApiReachable;
    expect((health.databaseOk, health.demoMode), (false, false));
  });

  test('API injoignable : l’adresse est gardée pour l’aide au développement', () async {
    final health = await service(FakeAdapter(fail: true)).check();
    expect(health, isA<ApiUnreachable>());
    expect((health as ApiUnreachable).address, 'http://127.0.0.1:8000');
  });

  test('erreur 500 : traitée comme une API injoignable', () async {
    final health = await service(FakeAdapter(status: 500, body: {})).check();
    expect(health, isA<ApiUnreachable>());
  });
}
