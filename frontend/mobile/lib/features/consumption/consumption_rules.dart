import 'package:flutter/foundation.dart';

import '../../core/format/formats.dart';

// Règles de l'écran 11 (Consommation), sans réseau ni affichage : testées une à une
// (test/features/consumption/consumption_rules_test.dart). Guide : backend/docs/CONSOMMATION.md.
// Valeurs PÉRIODIQUES (un relevé par jour) ou estimées : jamais « temps réel ».

/// Onglets de la maquette, dans l'ordre. `Mois` est l'onglet ouvert par défaut (D7.1).
enum ConsumptionLevel {
  direct('Direct'),
  day('Jour'),
  week('Semaine'),
  month('Mois'),
  year('Année');

  const ConsumptionLevel(this.label);

  final String label;
}

/// Date du calendrier sans heure (les périodes sont des dates, pas des instants).
DateTime _date(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime _monday(DateTime d) => _date(d).subtract(Duration(days: d.weekday - 1));

DateTime _lastOfMonth(DateTime d) => DateTime(d.year, d.month + 1, 0);

/// Ce que demander à `GET /meters/{id}/consumption` (dates incluses, alignées sur les périodes).
typedef SeriesRange = ({String granularity, DateTime from, DateTime to});

/// La période affichée : un niveau et sa date de départ (1er janvier, 1er du mois, lundi, jour).
/// `today` : la date du jour à Brazzaville (on ne va jamais au-delà).
@immutable
class ConsumptionCursor {
  const ConsumptionCursor._(this.level, this.anchor);

  /// Une période de `level` contenant `day`.
  factory ConsumptionCursor.of(ConsumptionLevel level, DateTime day) {
    final d = _date(day);
    return ConsumptionCursor._(level, switch (level) {
      ConsumptionLevel.year => DateTime(d.year),
      ConsumptionLevel.month => DateTime(d.year, d.month),
      ConsumptionLevel.week => _monday(d),
      ConsumptionLevel.day || ConsumptionLevel.direct => d,
    });
  }

  /// À l'ouverture : le MOIS en cours (D7.1), jamais Direct.
  factory ConsumptionCursor.initial(DateTime today) =>
      ConsumptionCursor.of(ConsumptionLevel.month, today);

  final ConsumptionLevel level;

  /// Premier jour de la période.
  final DateTime anchor;

  /// Dernier jour de la période (inclus).
  DateTime get end => switch (level) {
    ConsumptionLevel.year => DateTime(anchor.year, 12, 31),
    ConsumptionLevel.month => _lastOfMonth(anchor),
    ConsumptionLevel.week => anchor.add(const Duration(days: 6)),
    ConsumptionLevel.day || ConsumptionLevel.direct => anchor,
  };

  /// Période précédente / suivante du même niveau.
  ConsumptionCursor get previous => switch (level) {
    ConsumptionLevel.year => ConsumptionCursor._(level, DateTime(anchor.year - 1)),
    ConsumptionLevel.month => ConsumptionCursor._(level, DateTime(anchor.year, anchor.month - 1)),
    ConsumptionLevel.week => ConsumptionCursor._(level, anchor.subtract(const Duration(days: 7))),
    _ => ConsumptionCursor._(level, anchor.subtract(const Duration(days: 1))),
  };

  ConsumptionCursor get next => switch (level) {
    ConsumptionLevel.year => ConsumptionCursor._(level, DateTime(anchor.year + 1)),
    ConsumptionLevel.month => ConsumptionCursor._(level, DateTime(anchor.year, anchor.month + 1)),
    ConsumptionLevel.week => ConsumptionCursor._(level, anchor.add(const Duration(days: 7))),
    _ => ConsumptionCursor._(level, anchor.add(const Duration(days: 1))),
  };

  /// La période suivante a-t-elle commencé ? (Jamais de période dans le futur.)
  bool canGoNext(DateTime today) => !next.anchor.isAfter(_date(today));

  /// Changer de niveau en gardant le jour (ex. Mois → Année : l'année de ce mois).
  /// Vers un niveau plus fin : le dernier jour PASSÉ de la période (Année 2025 → Décembre 2025 ;
  /// année en cours → le mois en cours). Vers un niveau plus large : la période qui la contient.
  ConsumptionCursor withLevel(ConsumptionLevel level, DateTime today) {
    final t = _date(today);
    final reference = end.isAfter(t) ? t : end;
    return ConsumptionCursor.of(level, level.index < this.level.index ? reference : anchor);
  }

  /// Séries à lire pour le graphique.
  /// - Année : 12 mois ; Mois : ses jours ; Semaine : 7 jours ; Jour : les jours du mois (calendrier).
  SeriesRange get chartRange => switch (level) {
    ConsumptionLevel.year => (granularity: 'month', from: anchor, to: end),
    ConsumptionLevel.month || ConsumptionLevel.week => (granularity: 'day', from: anchor, to: end),
    _ => (granularity: 'day', from: DateTime(anchor.year, anchor.month), to: _lastOfMonth(anchor)),
  };

  /// Liste « Semaine par semaine » du mois (semaines du lundi au dimanche qui touchent le mois).
  /// `null` pour les autres niveaux (leur liste vient du graphique).
  SeriesRange? get weeksRange => level == ConsumptionLevel.month
      ? (granularity: 'week', from: _monday(anchor), to: _monday(end).add(const Duration(days: 6)))
      : null;

  /// Titre au milieu des flèches : « 2026 », « Octobre 2026 », « Sem. du 12 oct. », « Mer. 14 oct. ».
  String get title => switch (level) {
    ConsumptionLevel.year => '${anchor.year}',
    ConsumptionLevel.month => formatMonthYear(anchor.year, anchor.month),
    ConsumptionLevel.week => formatWeekTitle(anchor),
    _ => formatDayTitle(anchor),
  };

  /// Fil d'Ariane (2026 › Octobre › Sem. du 12 oct. › Mer. 14) : chaque élément ramène à son niveau.
  /// Le mois d'une semaine est celui de son jeudi (règle ISO : la semaine appartient à ce mois).
  List<({String label, ConsumptionCursor cursor})> get breadcrumb {
    final day = level == ConsumptionLevel.week ? anchor.add(const Duration(days: 3)) : anchor;
    final crumbs = <({String label, ConsumptionCursor cursor})>[
      (label: '${day.year}', cursor: ConsumptionCursor.of(ConsumptionLevel.year, day)),
    ];
    if (level.index <= ConsumptionLevel.month.index) {
      crumbs.add((
        label: formatMonthName(day.month),
        cursor: ConsumptionCursor.of(ConsumptionLevel.month, day),
      ));
    }
    if (level.index <= ConsumptionLevel.week.index) {
      crumbs.add((
        label: formatWeekTitle(_monday(anchor)),
        cursor: ConsumptionCursor.of(ConsumptionLevel.week, anchor),
      ));
    }
    if (level.index <= ConsumptionLevel.day.index) {
      crumbs.add((label: formatDayCrumb(anchor), cursor: this));
    }
    return crumbs;
  }

  @override
  bool operator ==(Object other) =>
      other is ConsumptionCursor && other.level == level && other.anchor == anchor;

  @override
  int get hashCode => Object.hash(level, anchor);

  @override
  String toString() => 'ConsumptionCursor($level, ${formatApiDate(anchor)})';
}

/// Niveaux du calendrier de la vue Jour (D7.3), par rapport à la moyenne journalière du mois.
/// La couleur n'est JAMAIS le seul repère : légende sous le calendrier, et le niveau est lu par
/// TalkBack sur chaque jour.
enum DayLevel {
  low('Faible'),
  normal('Normale'),
  high('Élevée'),
  veryHigh('Très élevée');

  const DayLevel(this.label);

  final String label;
}

/// Niveau d'un jour : moins de 75 % de la moyenne → faible ; jusqu'à 125 % → normale ; jusqu'à
/// 160 % → élevée ; au-delà → très élevée. Moyenne nulle : normale.
DayLevel dayLevel(int consumptionWh, num averageWh) {
  if (averageWh <= 0) return DayLevel.normal;
  final ratio = consumptionWh / averageWh;
  if (ratio < 0.75) return DayLevel.low;
  if (ratio < 1.25) return DayLevel.normal;
  if (ratio < 1.6) return DayLevel.high;
  return DayLevel.veryHigh;
}

/// Comparaison d'une période (« +6 % vs 2025 », « −3 % vs sem. préc. ») : `mode` de l'API
/// (`last_year` ou `previous`), pourcentage arrondi. `null` : pas de comparaison possible.
String? comparisonText(num? percent, String mode, ConsumptionLevel level, int year) {
  if (percent == null) return null;
  final variation = formatVariation(percent).text;
  final against = switch ((mode, level)) {
    ('last_year', _) => 'vs ${year - 1}',
    (_, ConsumptionLevel.week) => 'vs sem. préc.',
    (_, ConsumptionLevel.month) => 'vs mois préc.',
    _ => 'vs période préc.',
  };
  return '$variation $against';
}
