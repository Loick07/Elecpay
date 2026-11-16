import 'package:elecpay/core/format/dates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('heure de Brazzaville (UTC+1)', () {
    expect(formatDateTime(DateTime.utc(2026, 11, 16, 12, 20)), '16/11/2026 à 13:20');
  });

  test('changement de jour à minuit, heure de Brazzaville', () {
    expect(formatDateTime(DateTime.utc(2026, 12, 31, 23, 5)), '01/01/2027 à 00:05');
  });

  test('une heure locale du téléphone est d’abord ramenée en UTC', () {
    final utc = DateTime.utc(2026, 3, 1, 8);
    expect(formatDateTime(utc.toLocal()), formatDateTime(utc));
  });

  test('mention hors ligne', () {
    expect(
      offlineLabel(DateTime.utc(2026, 11, 16, 12, 20)),
      'Hors ligne · données du 16/11/2026 à 13:20',
    );
  });
}
