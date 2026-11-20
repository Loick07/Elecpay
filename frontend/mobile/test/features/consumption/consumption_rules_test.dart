import 'package:elecpay/core/format/formats.dart';
import 'package:elecpay/core/models/consumption.dart';
import 'package:elecpay/features/consumption/consumption_rules.dart';
import 'package:flutter_test/flutter_test.dart';

/// Jeudi 12 novembre 2026.
final today = DateTime(2026, 11, 12);

void main() {
  test('onglets dans l’ordre de la maquette ; Mois par défaut, jamais Direct (D7.1)', () {
    expect(ConsumptionLevel.values.map((l) => l.label), [
      'Direct',
      'Jour',
      'Semaine',
      'Mois',
      'Année',
    ]);
    final initial = ConsumptionCursor.initial(today);
    expect(initial.level, ConsumptionLevel.month);
    expect(initial.anchor, DateTime(2026, 11));
  });

  group('périodes', () {
    test('année, mois, semaine (lundi → dimanche), jour', () {
      final year = ConsumptionCursor.of(ConsumptionLevel.year, today);
      expect((year.anchor, year.end), (DateTime(2026), DateTime(2026, 12, 31)));
      final month = ConsumptionCursor.of(ConsumptionLevel.month, DateTime(2026, 2, 14));
      expect((month.anchor, month.end), (DateTime(2026, 2), DateTime(2026, 2, 28)));
      final week = ConsumptionCursor.of(ConsumptionLevel.week, DateTime(2026, 10, 14));
      expect((week.anchor, week.end), (DateTime(2026, 10, 12), DateTime(2026, 10, 18)));
      final day = ConsumptionCursor.of(ConsumptionLevel.day, DateTime(2026, 10, 14, 17));
      expect(day.anchor, DateTime(2026, 10, 14), reason: 'une date, sans heure');
    });

    test('précédente / suivante, sur les changements d’année', () {
      final jan = ConsumptionCursor.of(ConsumptionLevel.month, DateTime(2026));
      expect(jan.previous.anchor, DateTime(2025, 12));
      expect(jan.previous.next, jan);
      final week = ConsumptionCursor.of(ConsumptionLevel.week, DateTime(2026, 1, 1));
      expect(week.anchor, DateTime(2025, 12, 29));
      expect(week.next.anchor, DateTime(2026, 1, 5));
    });

    test('jamais de période dans le futur', () {
      expect(ConsumptionCursor.initial(today).canGoNext(today), isFalse);
      expect(ConsumptionCursor.initial(today).previous.canGoNext(today), isTrue);
      final day = ConsumptionCursor.of(ConsumptionLevel.day, today);
      expect(day.canGoNext(today), isFalse);
    });

    test('changer de niveau : vers plus fin, le dernier jour passé de la période', () {
      final year2025 = ConsumptionCursor.of(ConsumptionLevel.year, DateTime(2025, 6));
      expect(year2025.withLevel(ConsumptionLevel.month, today).anchor, DateTime(2025, 12));
      final thisYear = ConsumptionCursor.of(ConsumptionLevel.year, today);
      expect(thisYear.withLevel(ConsumptionLevel.month, today).anchor, DateTime(2026, 11));
      expect(thisYear.withLevel(ConsumptionLevel.day, today).anchor, today);
      final oct = ConsumptionCursor.of(ConsumptionLevel.month, DateTime(2026, 10));
      expect(oct.withLevel(ConsumptionLevel.year, today).anchor, DateTime(2026));
    });
  });

  group('plages demandées à l’API', () {
    test('année : 12 mois ; mois et semaine : leurs jours ; jour : les jours du mois', () {
      final year = ConsumptionCursor.of(ConsumptionLevel.year, today).chartRange;
      expect(year, (granularity: 'month', from: DateTime(2026), to: DateTime(2026, 12, 31)));
      final month = ConsumptionCursor.of(ConsumptionLevel.month, DateTime(2026, 10)).chartRange;
      expect(month, (granularity: 'day', from: DateTime(2026, 10), to: DateTime(2026, 10, 31)));
      final day = ConsumptionCursor.of(ConsumptionLevel.day, DateTime(2026, 10, 14)).chartRange;
      expect(day, (granularity: 'day', from: DateTime(2026, 10), to: DateTime(2026, 10, 31)));
    });

    test('semaine par semaine : du lundi au dimanche, alignées', () {
      final oct = ConsumptionCursor.of(ConsumptionLevel.month, DateTime(2026, 10)).weeksRange!;
      expect(oct, (granularity: 'week', from: DateTime(2026, 9, 28), to: DateTime(2026, 11, 1)));
      expect(oct.from.weekday, DateTime.monday);
      expect(oct.to.weekday, DateTime.sunday);
      expect(ConsumptionCursor.of(ConsumptionLevel.year, today).weeksRange, isNull);
    });
  });

  test('titres et fil d’Ariane de la maquette (2026 › Octobre › Sem. du 12 oct. › Mer. 14)', () {
    final day = ConsumptionCursor.of(ConsumptionLevel.day, DateTime(2026, 10, 14));
    expect(day.title, 'Mer. 14 oct.');
    expect(day.breadcrumb.map((c) => c.label), ['2026', 'Octobre', 'Sem. du 12 oct.', 'Mer. 14']);
    expect(day.breadcrumb.map((c) => c.cursor.level), [
      ConsumptionLevel.year,
      ConsumptionLevel.month,
      ConsumptionLevel.week,
      ConsumptionLevel.day,
    ]);
    final week = ConsumptionCursor.of(ConsumptionLevel.week, DateTime(2026, 10, 14));
    expect(week.title, 'Sem. du 12 oct.');
    // Semaine à cheval sur deux mois : celui de son jeudi.
    final across = ConsumptionCursor.of(ConsumptionLevel.week, DateTime(2026, 9, 28));
    expect(across.breadcrumb.map((c) => c.label), ['2026', 'Octobre', 'Sem. du 28 sept.']);
    expect(ConsumptionCursor.of(ConsumptionLevel.month, DateTime(2026, 10)).title, 'Octobre 2026');
    expect(ConsumptionCursor.of(ConsumptionLevel.year, today).breadcrumb.map((c) => c.label), [
      '2026',
    ]);
  });

  group('calendrier : niveaux par rapport à la moyenne (D7.3)', () {
    test('faible, normale, élevée, très élevée', () {
      expect(dayLevel(7000, 10000), DayLevel.low);
      expect(dayLevel(7500, 10000), DayLevel.normal);
      expect(dayLevel(12400, 10000), DayLevel.normal);
      expect(dayLevel(12500, 10000), DayLevel.high);
      expect(dayLevel(15900, 10000), DayLevel.high);
      expect(dayLevel(16000, 10000), DayLevel.veryHigh);
      expect(dayLevel(500, 0), DayLevel.normal, reason: 'moyenne nulle');
    });

    test('chaque niveau a un mot (la couleur n’est jamais seule)', () {
      expect(DayLevel.values.map((l) => l.label), ['Faible', 'Normale', 'Élevée', 'Très élevée']);
    });
  });

  test('comparaisons : « +6 % vs 2025 », « −3 % vs sem. préc. »', () {
    expect(comparisonText(6.2, 'last_year', ConsumptionLevel.month, 2026), '+6\u00A0% vs 2025');
    expect(
      comparisonText(-3.4, 'previous', ConsumptionLevel.week, 2026),
      '−3\u00A0% vs sem. préc.',
    );
    expect(comparisonText(null, 'previous', ConsumptionLevel.week, 2026), isNull);
  });

  test('pas avant la pose du compteur (date inconnue : pas de limite)', () {
    final oct = ConsumptionCursor.of(ConsumptionLevel.month, DateTime(2026, 10));
    expect(oct.canGoPrevious(null), isTrue);
    expect(oct.canGoPrevious(DateTime(2026, 9, 20)), isTrue, reason: 'septembre a des relevés');
    expect(oct.canGoPrevious(DateTime(2026, 10, 3)), isFalse);
    expect(oct.canGoPrevious(DateTime.utc(2026, 9, 30, 23)), isTrue, reason: 'date seule');
  });

  group('total de la période (maquette : « DU 1ER AU 12 NOVEMBRE »)', () {
    ConsumptionPoint point(DateTime day, int wh, {int days = 1}) => ConsumptionPoint(
      start: day,
      end: day,
      label: '',
      consumptionWh: wh,
      consumptionKwh: wh / 1000,
      daysWithData: days,
      dailyAverageWh: wh,
      energyCost: days == 0 ? null : wh * 49 ~/ 1000,
      estimatedTotal: null,
      isCurrent: false,
      isPartial: false,
      isEstimated: false,
      hasAnomaly: false,
    );
    ConsumptionSeries series(
      List<ConsumptionPoint> points, {
      DateTime? until,
      double? percent,
      String mode = 'last_year',
    }) => ConsumptionSeries(
      meterId: 11,
      granularity: 'day',
      start: points.first.start,
      end: points.last.end,
      measuredUntil: until,
      points: points,
      comparison: percent == null
          ? null
          : ConsumptionComparison(
              mode: mode,
              current: ConsumptionTotals(
                start: points.first.start,
                end: points.last.end,
                consumptionWh: 0,
                consumptionKwh: 0,
                daysWithData: 0,
                energyCost: 0,
              ),
              reference: ConsumptionTotals(
                start: points.first.start,
                end: points.last.end,
                consumptionWh: 0,
                consumptionKwh: 0,
                daysWithData: 0,
                energyCost: 0,
              ),
              variationPercent: percent,
            ),
      tariffIsAssumption: false,
      source: 'simulated',
    );
    final nov = ConsumptionCursor.initial(today);
    List<ConsumptionPoint> novDays() => [
      for (var d = 1; d <= 30; d++)
        point(DateTime(2026, 11, d), d <= 11 ? 9000 : 0, days: d <= 11 ? 1 : 0),
    ];

    test('mois en cours : jours relevés seulement, coût d’énergie additionné', () {
      final t = periodTotals(nov, series(novDays(), until: DateTime(2026, 11, 11), percent: 6.2));
      expect(t.label, 'Du 1er au 11 novembre');
      expect((t.wh, t.daysWithData, t.energyCost), (99000, 11, 11 * 441));
      expect(t.comparison, '+6\u00A0% vs 2025');
      expect(t.trend, Trend.up);
    });

    test('mois complet ; année complète et année en cours', () {
      final oct = ConsumptionCursor.of(ConsumptionLevel.month, DateTime(2026, 10));
      final octDays = [for (var d = 1; d <= 31; d++) point(DateTime(2026, 10, d), 7000)];
      expect(
        periodTotals(oct, series(octDays, until: DateTime(2026, 11, 11))).label,
        'Octobre 2026',
      );
      final y2025 = ConsumptionCursor.of(ConsumptionLevel.year, DateTime(2025, 3));
      expect(
        periodTotals(y2025, series(octDays, until: DateTime(2026, 11, 11))).label,
        'Année 2025',
      );
      final y2026 = ConsumptionCursor.of(ConsumptionLevel.year, today);
      expect(
        periodTotals(y2026, series(octDays, until: DateTime(2026, 11, 11))).label,
        'Du 1er janv. au 11 nov. 2026',
      );
    });

    test('semaine : complète, en cours, début des relevés ; baisse en vert', () {
      final week = ConsumptionCursor.of(ConsumptionLevel.week, DateTime(2026, 11, 9));
      List<ConsumptionPoint> days(int n) => [
        for (var i = 0; i < 7; i++) point(DateTime(2026, 11, 9 + i), 9000, days: i < n ? 1 : 0),
      ];
      final current = periodTotals(week, series(days(3), until: DateTime(2026, 11, 11)));
      expect(current.label, 'Semaine en cours · 3 jours');
      final last = ConsumptionCursor.of(ConsumptionLevel.week, DateTime(2026, 11, 2));
      final full = periodTotals(
        last,
        series(days(7), until: DateTime(2026, 11, 11), percent: -3, mode: 'previous'),
      );
      expect(full.label, 'Semaine complète');
      expect(full.comparison, '−3\u00A0% vs sem. préc.');
      expect(full.trend, Trend.down);
      final first = periodTotals(last, series(days(1), until: DateTime(2026, 11, 11)));
      expect(first.label, 'Début des relevés · 1 jour');
    });

    test('un jour relevé sans tarif connu : pas de coût (jamais un faux zéro)', () {
      final points = [
        point(DateTime(2026, 11, 1), 9000),
        point(DateTime(2026, 11, 2), 9000).copyWith(energyCost: null),
      ];
      final t = periodTotals(nov, series(points, until: DateTime(2026, 11, 2)));
      expect(t.energyCost, isNull);
      expect(t.wh, 18000);
    });

    test('jour : le total du jour seul (la série est celle du mois), sans comparaison du mois', () {
      final day = ConsumptionCursor.of(ConsumptionLevel.day, DateTime(2026, 11, 3));
      final t = periodTotals(day, series(novDays(), until: DateTime(2026, 11, 11), percent: 6.2));
      expect((t.label, t.wh, t.daysWithData), ('Consommation du jour', 9000, 1));
      expect(t.comparison, isNull);
    });

    test('aucun relevé dans la période : rien à totaliser', () {
      final empty = [for (var d = 1; d <= 30; d++) point(DateTime(2026, 11, d), 0, days: 0)];
      final t = periodTotals(nov, series(empty, until: DateTime(2026, 10, 31)));
      expect(t.daysWithData, 0);
      expect(t.label, 'Novembre 2026');
    });
  });
}
