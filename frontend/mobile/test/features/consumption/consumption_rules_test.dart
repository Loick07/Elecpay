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
}
