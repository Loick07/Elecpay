import 'package:elecpay/core/format/formats.dart';
import 'package:elecpay/core/models/consumption.dart';
import 'package:elecpay/features/consumption/consumption_rules.dart';
import 'package:flutter_test/flutter_test.dart';

/// Jeudi 12 novembre 2026.
final today = DateTime(2026, 11, 12);

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

  group('vue Année (F7.3)', () {
    // 2026 : janvier → octobre complets (octobre le plus fort), novembre commencé, décembre vide.
    final months = [
      for (var m = 1; m <= 12; m++)
        point(
          DateTime(2026, m),
          m == 12 ? 0 : (m == 10 ? 212400 : (m == 11 ? 99000 : 200000)),
          days: m == 12 ? 0 : (m == 11 ? 11 : 30),
        ).copyWith(end: DateTime(2026, m + 1, 0), isPartial: m >= 11, isCurrent: m == 11),
    ];
    final s = series(months, until: DateTime(2026, 11, 11));

    test('12 barres : initiales, mois commencé en pointillé, mois vide sans toucher', () {
      final bars = yearBars(s);
      expect(bars.map((b) => b.axis).join(), 'JFMAMJJASOND');
      expect(bars[9].spoken, 'Octobre 2026 : 212,4\u00A0kWh');
      expect(bars[10].estimated, isTrue);
      expect(bars[10].spoken, 'Novembre 2026 : 99\u00A0kWh, estimation');
      expect((bars[11].hasData, bars[11].target), (false, null));
      expect(bars[11].spoken, 'Décembre 2026 : pas encore de données');
      expect(bars[9].target, ConsumptionCursor.of(ConsumptionLevel.month, DateTime(2026, 10)));
    });

    test('moyenne et pic des mois COMPLETS seulement', () {
      final stats = yearStats(s);
      expect(stats.map((x) => x.label), ['Moyenne', 'Pic']);
      expect(stats[0].value, '201,2\u00A0kWh/mois');
      expect(stats[1].value, 'Octobre · 212,4\u00A0kWh');
      expect(yearStats(series([months[10]], until: DateTime(2026, 11, 11))), isEmpty);
    });

    test('« Mois par mois » : du plus récent, mois en cours « Du 1er au 11 »', () {
      final rows = yearRows(s);
      expect(rows, hasLength(11));
      expect(rows.first.title, 'Novembre 2026');
      expect(rows.first.subtitle, 'Du 1er au 11 · ≈\u00A04\u00A0851\u00A0FCFA');
      expect(rows.first.estimated, isTrue);
      expect(rows[1].title, 'Octobre 2026');
      expect(rows[1].subtitle, '30 jours · ≈\u00A010\u00A0407\u00A0FCFA');
      expect(rows[1].estimated, isFalse);
    });
  });

  group('vue Mois (F7.3)', () {
    // Novembre 2026 : relevés du 1er au 11 (9 kWh ; le 4 : 12 kWh, estimé).
    final days = [
      for (var d = 1; d <= 30; d++)
        point(
          DateTime(2026, 11, d),
          d > 11 ? 0 : (d == 4 ? 12000 : 9000),
          days: d > 11 ? 0 : 1,
        ).copyWith(isEstimated: d == 4),
    ];
    final s = series(days, until: DateTime(2026, 11, 11));

    test('une barre par jour, étiquettes 1, 8, 15, 22, 29 ; estimé en pointillé', () {
      final bars = monthBars(s);
      expect(bars, hasLength(30));
      expect(
        [
          for (final b in bars)
            if (b.axis.isNotEmpty) b.axis,
        ],
        ['1', '8', '15', '22', '29'],
      );
      expect(bars[3].estimated, isTrue);
      expect(bars[0].spoken, '1er novembre : 9\u00A0kWh');
      expect(bars[3].spoken, '4 novembre : 12\u00A0kWh, estimation');
      expect(bars[11].spoken, '12 novembre : pas encore de données');
      expect(bars[0].target, ConsumptionCursor.of(ConsumptionLevel.day, DateTime(2026, 11)));
    });

    test('pastilles : moyenne, pic, estimation de fin de mois (mois en cours)', () {
      const estimate = MonthEndEstimate(
        consumptionWh: 279300,
        consumptionKwh: 279.3,
        energyCost: 13708,
        estimatedTotal: 18000,
        remainingDays: 19,
        basis: 'current_month',
      );
      final stats = monthStats(s, estimate: estimate);
      expect(stats.map((x) => (x.label, x.value, x.estimate)), [
        ('Moyenne', '9,3\u00A0kWh/jour', false),
        ('Pic', 'Mer. 4 · 12\u00A0kWh', false),
        ('Fin de mois estimée', '≈\u00A0279\u00A0kWh · ≈\u00A013\u00A0700\u00A0FCFA', true),
      ]);
      expect(monthStats(s), hasLength(2), reason: 'mois passé : pas d’estimation');
    });

    test('« Semaine par semaine » : semaines coupées au mois, jours relevés seulement', () {
      final rows = monthWeekRows(s);
      // Dim. 1er seul (semaine du 26 oct.), du 2 au 8, du 9 au 11 (la suite n’est pas relevée).
      expect(rows.map((r) => r.title), ['Dimanche 1er nov.', 'Du 2 au 8 nov.', 'Du 9 au 15 nov.']);
      expect(rows.map((r) => r.subtitle), [
        '1 jour · ≈\u00A0441\u00A0FCFA',
        '7 jours · ≈\u00A03\u00A0234\u00A0FCFA',
        '3 jours · ≈\u00A01\u00A0323\u00A0FCFA',
      ]);
      expect(rows[1].estimated, isTrue);
      expect(rows[1].wh, 66000);
      expect(rows[1].target, ConsumptionCursor.of(ConsumptionLevel.week, DateTime(2026, 11, 2)));
    });
  });
}
