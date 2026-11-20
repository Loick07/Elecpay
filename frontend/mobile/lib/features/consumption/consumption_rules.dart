import 'package:flutter/foundation.dart';

import '../../core/format/formats.dart';
import '../../core/models/consumption.dart';

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

  /// Peut-on reculer ? Pas au-delà de la pose du compteur (`since` ; `null` : date inconnue → oui).
  bool canGoPrevious(DateTime? since) => since == null || !previous.end.isBefore(_date(since));

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

/// Bloc du total de la période (maquette : « DU 1ER AU 12 NOVEMBRE · 82,6 kWh · ≈ 4 054 FCFA
/// d'énergie », pastille de comparaison à droite).
typedef PeriodTotals = ({
  String label,
  int wh,
  int daysWithData,

  /// Énergie seule (FCFA entiers) ; `null` si un jour relevé n'a pas de tarif connu.
  int? energyCost,
  String? comparison,
  Trend? trend,
});

/// Total d'une période depuis sa série (année, mois, semaine). Les jours sans relevé ne comptent
/// pas ; une période commencée n'est comparée que sur ses jours relevés (règle de l'API).
PeriodTotals periodTotals(ConsumptionCursor cursor, ConsumptionSeries series) {
  // Vue Jour : la série est celle du mois (calendrier) ; le total est celui du jour affiché.
  final points = cursor.level == ConsumptionLevel.day
      ? series.points.where((p) => p.start == cursor.anchor)
      : series.points;
  final withData = points.where((p) => p.daysWithData > 0).toList();
  final wh = withData.fold(0, (s, p) => s + p.consumptionWh);
  final days = withData.fold(0, (s, p) => s + p.daysWithData);
  final costs = withData.map((p) => p.energyCost).toList();
  final cost = costs.contains(null) ? null : costs.fold(0, (s, c) => s + c!);
  final until = series.measuredUntil;
  final started = until != null && cursor.end.isAfter(until);
  final a = cursor.anchor;
  final label = switch (cursor.level) {
    ConsumptionLevel.year when started && days > 0 =>
      'Du 1er janv. au ${formatDayMonth(until)} ${a.year}',
    ConsumptionLevel.year => 'Année ${a.year}',
    ConsumptionLevel.month when started && days > 0 =>
      'Du 1er au ${until.day == 1 ? '1er' : until.day} ${formatMonthName(a.month).toLowerCase()}',
    ConsumptionLevel.month => formatMonthYear(a.year, a.month),
    ConsumptionLevel.week when days >= 7 => 'Semaine complète',
    ConsumptionLevel.week =>
      '${started ? 'Semaine en cours' : 'Début des relevés'} · $days jour${days > 1 ? 's' : ''}',
    _ => 'Consommation du jour',
  };
  // Jour : la comparaison est celle du détail du jour (moyenne du même jour), pas celle du mois.
  final percent = cursor.level == ConsumptionLevel.day ? null : series.comparison?.variationPercent;
  return (
    label: label,
    wh: wh,
    daysWithData: days,
    energyCost: cost,
    comparison: comparisonText(percent, series.comparison?.mode ?? '', cursor.level, a.year),
    trend: percent == null ? null : formatVariation(percent).trend,
  );
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

// --- Graphiques et listes (F7.3, F7.4) ------------------------------------------------------------

/// Une barre du graphique. `hasData` faux : barre plate grise, rien à toucher.
/// `estimated` : en pointillé (valeur estimée, ou période incomplète).
typedef ChartBar = ({
  int wh,
  bool hasData,
  bool estimated,

  /// Étiquette sous la barre (« O », « 15 », « Lun 9 ») ; vide : pas d'étiquette.
  String axis,

  /// Valeur écrite au-dessus de la barre (vue Semaine), sinon `null`.
  String? value,

  /// Ce que lit TalkBack : « Octobre 2026 : 212,4 kWh ».
  String spoken,

  /// Période ouverte en touchant la barre (`null` sans relevé).
  ConsumptionCursor? target,
});

/// Une ligne de « Mois par mois », « Semaine par semaine » ou « Jour par jour ».
typedef PeriodRow = ({
  String title,
  String subtitle,
  int wh,
  bool estimated,
  ConsumptionCursor target,
});

/// Une pastille sous le total (« Moyenne 6,9 kWh/jour », « Pic Mer. 14 · 9,4 kWh »).
/// `estimate` : pastille d'estimation (fond orange pâle).
typedef PeriodStat = ({String label, String value, bool estimate});

String _dayInMonth(DateTime d) =>
    '${d.day == 1 ? '1er' : d.day} ${formatMonthName(d.month).toLowerCase()}';

String _spokenValue(ConsumptionPoint p, {required bool estimated}) => p.daysWithData == 0
    ? 'pas encore de données'
    : '${formatKwh(p.consumptionWh / 1000)}${estimated ? ', estimation' : ''}';

/// « · ≈ 10 409 FCFA » d'énergie, ou rien si le tarif est inconnu.
String _cost(int? energyCost) => energyCost == null ? '' : ' · ${formatAboutFcfa(energyCost)}';

/// Somme des coûts d'énergie, `null` si un seul manque (jamais un faux total).
int? _sumCosts(Iterable<ConsumptionPoint> points) {
  var total = 0;
  for (final p in points) {
    final cost = p.energyCost;
    if (cost == null) return null;
    total += cost;
  }
  return total;
}

String _days(int n) => '$n jour${n > 1 ? 's' : ''}';

/// Vue Année : 12 barres (initiales des mois), mois incomplet en pointillé.
List<ChartBar> yearBars(ConsumptionSeries series) => [
  for (final p in series.points)
    (
      wh: p.consumptionWh,
      hasData: p.daysWithData > 0,
      estimated: p.daysWithData > 0 && (p.isPartial || p.isEstimated),
      axis: formatMonthInitial(p.start.month),
      value: null,
      spoken:
          '${formatMonthYear(p.start.year, p.start.month)} : '
          '${_spokenValue(p, estimated: p.isPartial || p.isEstimated)}',
      target: p.daysWithData > 0 ? ConsumptionCursor.of(ConsumptionLevel.month, p.start) : null,
    ),
];

/// Vue Mois : une barre par jour, étiquettes les 1er, 8, 15, 22 et 29 (maquette).
List<ChartBar> monthBars(ConsumptionSeries series) => [
  for (final p in series.points)
    (
      wh: p.consumptionWh,
      hasData: p.daysWithData > 0,
      estimated: p.daysWithData > 0 && p.isEstimated,
      axis: const [1, 8, 15, 22, 29].contains(p.start.day) ? '${p.start.day}' : '',
      value: null,
      spoken: '${_dayInMonth(p.start)} : ${_spokenValue(p, estimated: p.isEstimated)}',
      target: p.daysWithData > 0 ? ConsumptionCursor.of(ConsumptionLevel.day, p.start) : null,
    ),
];

/// Pastilles de l'année : moyenne et pic des mois COMPLETS (un mois commencé fausserait tout).
List<PeriodStat> yearStats(ConsumptionSeries series) {
  final full = series.points.where((p) => p.daysWithData > 0 && !p.isPartial).toList();
  if (full.isEmpty) return const [];
  final average = full.fold(0, (s, p) => s + p.consumptionWh) / full.length;
  final peak = full.reduce((a, b) => b.consumptionWh > a.consumptionWh ? b : a);
  return [
    (label: 'Moyenne', value: '${formatKwh(average / 1000)}/mois', estimate: false),
    (
      label: 'Pic',
      value: '${formatMonthName(peak.start.month)} · ${formatKwh(peak.consumptionWh / 1000)}',
      estimate: false,
    ),
  ];
}

/// Pastilles du mois : moyenne des jours relevés, jour le plus consommé, et pour le mois en
/// cours l'estimation de fin de mois (`estimate`, du résumé de l'API).
List<PeriodStat> monthStats(ConsumptionSeries series, {MonthEndEstimate? estimate}) {
  final days = series.points.where((p) => p.daysWithData > 0).toList();
  if (days.isEmpty) return const [];
  final total = days.fold(0, (s, p) => s + p.consumptionWh);
  final peak = days.reduce((a, b) => b.consumptionWh > a.consumptionWh ? b : a);
  return [
    (label: 'Moyenne', value: '${formatKwh(total / days.length / 1000)}/jour', estimate: false),
    (
      label: 'Pic',
      value: '${formatDayCrumb(peak.start)} · ${formatKwh(peak.consumptionWh / 1000)}',
      estimate: false,
    ),
    if (estimate != null)
      (
        label: 'Fin de mois estimée',
        value: [
          formatApproxKwh(estimate.consumptionWh / 1000),
          if (estimate.energyCost case final cost?) formatApproxFcfa(cost),
        ].join(' · '),
        estimate: true,
      ),
  ];
}

/// « Mois par mois » : du plus récent au plus ancien, mois relevés seulement. Mois en cours :
/// « Du 1er au 11 » ; sinon le nombre de jours relevés.
List<PeriodRow> yearRows(ConsumptionSeries series) {
  final until = series.measuredUntil;
  return [
    for (final p in series.points.reversed)
      if (p.daysWithData > 0)
        (
          title: formatMonthYear(p.start.year, p.start.month),
          subtitle:
              (p.isCurrent && until != null
                  ? 'Du 1er au ${until.day == 1 ? '1er' : until.day}'
                  : _days(p.daysWithData)) +
              _cost(p.energyCost),
          wh: p.consumptionWh,
          estimated: p.isPartial || p.isEstimated,
          target: ConsumptionCursor.of(ConsumptionLevel.month, p.start),
        ),
  ];
}

/// « Semaine par semaine » d'un mois, depuis ses jours : semaines du lundi au dimanche COUPÉES au
/// mois (« Du 1er au 2 nov. », « Lundi 30 nov. »), jours relevés seulement.
List<PeriodRow> monthWeekRows(ConsumptionSeries series) {
  final weeks = <DateTime, List<ConsumptionPoint>>{};
  for (final p in series.points) {
    weeks.putIfAbsent(_monday(p.start), () => []).add(p);
  }
  final rows = <PeriodRow>[];
  for (final days in weeks.values) {
    final read = days.where((p) => p.daysWithData > 0).toList();
    if (read.isEmpty) continue;
    final first = days.first.start;
    final last = days.last.start;
    rows.add((
      title: first == last
          ? '${formatWeekdayName(first)} ${formatDayMonth(first)}'
          : 'Du ${first.day == 1 ? '1er' : first.day} au ${formatDayMonth(last)}',
      subtitle: _days(read.length) + _cost(_sumCosts(read)),
      wh: read.fold(0, (s, p) => s + p.consumptionWh),
      estimated: read.any((p) => p.isEstimated),
      target: ConsumptionCursor.of(ConsumptionLevel.week, first),
    ));
  }
  return rows;
}
