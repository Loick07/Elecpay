import 'package:elecpay/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('par défaut : 127.0.0.1:8000 (téléphone en USB avec adb reverse)', () {
    final config = AppConfig.parse(defaultApiBaseUrl, release: false);
    expect(config.apiBaseUrl.toString(), 'http://127.0.0.1:8000');
    expect(config.apiRoot, 'http://127.0.0.1:8000/api/v1');
  });

  test('adresse Wi-Fi du PC et adresse de production', () {
    expect(
      AppConfig.parse('http://192.168.1.20:8000', release: false).apiRoot,
      'http://192.168.1.20:8000/api/v1',
    );
    expect(
      AppConfig.parse(' https://api.elecpay.cg/ ', release: true).apiRoot,
      'https://api.elecpay.cg/api/v1',
    );
  });

  test('la version livrée exige https', () {
    expect(
      () => AppConfig.parse('http://api.elecpay.cg', release: true),
      throwsA(isA<ConfigError>().having((e) => e.message, 'message', contains('https'))),
    );
  });

  for (final bad in [
    '',
    'api.elecpay.cg',
    'ftp://api.elecpay.cg',
    'https://api.elecpay.cg/api/v1',
  ]) {
    test('adresse refusée : « $bad »', () {
      expect(() => AppConfig.parse(bad, release: false), throwsA(isA<ConfigError>()));
    });
  }
}
