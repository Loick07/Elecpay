import 'dart:math';

import 'package:elecpay/core/models/consumption.dart';
import 'package:elecpay/features/consumption/consumption_direct.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/openapi.dart';

void main() {
  test('simulation : 40 valeurs (80 s) autour de la moyenne, bornées', () {
    final sim = DirectSimulator(averageKw: 0.4, todayKwh: 5, random: Random(3));
    expect(sim.history, hasLength(directHistory));
    for (final kw in sim.history) {
      expect(kw, inInclusiveRange(0.4 * 0.3, 0.4 * 3));
    }
  });

  test('une valeur de plus toutes les 2 s ; l’énergie du jour avance d’autant', () {
    final sim = DirectSimulator(averageKw: 0.4, todayKwh: 5, random: Random(3));
    final before = [...sim.history];
    sim.tick();
    expect(sim.history, hasLength(directHistory));
    expect(sim.history.sublist(0, directHistory - 1), before.sublist(1));
    expect(sim.todayKwh, closeTo(5 + sim.current * 2 / 3600, 1e-9));
  });

  test('même hasard, mêmes valeurs (tests reproductibles)', () {
    final a = DirectSimulator(averageKw: 1, todayKwh: 0, random: Random(9))..tick();
    final b = DirectSimulator(averageKw: 1, todayKwh: 0, random: Random(9))..tick();
    expect(a.history, b.history);
  });

  test('niveau de la puissance (maquette) : sous 0,8 kW, sous 2 kW, au-delà', () {
    expect(powerLevel(0.5), PowerLevel.low);
    expect(powerLevel(0.8), PowerLevel.normal);
    expect(powerLevel(1.99), PowerLevel.normal);
    expect(powerLevel(2), PowerLevel.high);
    expect(PowerLevel.high.label, startsWith('Élevée'));
  });

  test('énergie depuis minuit au démarrage : la moyenne au prorata de l’heure', () {
    expect(energySinceMidnight(9.6, DateTime.utc(2026, 11, 12, 12)), closeTo(4.8, 1e-9));
    expect(energySinceMidnight(9.6, DateTime.utc(2026, 11, 12)), 0);
  });

  test('moyenne d’un jour : mois en cours, sinon mois dernier, sinon 6 kWh', () {
    final api = OpenApi.load();
    ConsumptionSummary summary({int days = 11, int average = 9000, int lastWh = 300000}) =>
        ConsumptionSummary.fromJson({
          ...api.sample('ConsumptionSummary'),
          'this_month': {
            ...api.sample('MonthSoFar'),
            'days_with_data': days,
            'daily_average_wh': average,
          },
          'last_month': {
            ...api.sample('LastMonth'),
            'days_with_data': 30,
            'consumption_wh': lastWh,
          },
        });
    expect(dailyAverageKwh(summary()), 9);
    expect(dailyAverageKwh(summary(days: 0, average: 0)), 10);
    expect(dailyAverageKwh(summary(days: 0, average: 0, lastWh: 0)), 6);
  });
}
