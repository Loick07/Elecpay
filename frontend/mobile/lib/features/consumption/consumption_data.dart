import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/cached_api.dart';
import '../../core/format/formats.dart';
import '../../core/models/bills.dart';
import '../../core/models/consumption.dart';
import '../../core/models/households.dart';
import '../home/home_data.dart';
import '../home/home_screen.dart' show homeClockProvider;
import 'consumption_rules.dart';

// Lectures de l'écran 11, toutes par le cache hors ligne (routes de consommation rangées dans
// `cache_policy.dart`). Relevés journaliers ou estimés : jamais « temps réel ».

/// Un compteur proposé dans le sélecteur, avec son foyer.
typedef MeterChoice = ({MeterDetail meter, HouseholdSummary household});

/// Tous mes compteurs, foyer par foyer (sélecteur de l'écran).
final allMetersProvider = FutureProvider<List<MeterChoice>>((ref) async {
  final households = (await ref.watch(householdsProvider.future)).data;
  final lists = await Future.wait([
    for (final h in households) ref.watch(householdMetersProvider(h.id).future),
  ]);
  return [
    for (final (i, h) in households.indexed)
      for (final m in lists[i].data) (meter: m, household: h),
  ];
});

/// Compteur choisi sur l'écran Consommation (gardé tant que l'application est ouverte).
/// `null` : pas encore choisi → celui de la carte du mois de l'accueil.
class ConsumptionMeterNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void choose(int meterId) => state = meterId;
}

final chosenConsumptionMeterProvider = NotifierProvider<ConsumptionMeterNotifier, int?>(
  ConsumptionMeterNotifier.new,
);

/// Compteur affiché : le choix de l'écran, sinon celui de l'accueil (facture la plus urgente),
/// sinon le premier compteur. `null` : aucun compteur.
final consumptionMeterIdProvider = FutureProvider<int?>((ref) async {
  final chosen = ref.watch(chosenConsumptionMeterProvider);
  if (chosen != null) return chosen;
  try {
    final fromHome = await ref.watch(shownMeterIdProvider.future);
    if (fromHome != null) return fromHome;
  } on Object {
    // Accueil illisible : on retombe sur la liste des compteurs.
  }
  final meters = await ref.watch(allMetersProvider.future);
  return meters.firstOrNull?.meter.id;
});

/// Date du jour à Brazzaville (les périodes de consommation sont des dates de Brazzaville).
DateTime consumptionToday(Ref ref) => toBrazzaville(ref.read(homeClockProvider)());

/// Période affichée (onglet + date), gardée tant que l'application est ouverte. À l'ouverture :
/// le mois en cours (D7.1).
class ConsumptionCursorNotifier extends Notifier<ConsumptionCursor> {
  @override
  ConsumptionCursor build() => ConsumptionCursor.initial(consumptionToday(ref));

  void show(ConsumptionCursor cursor) => state = cursor;

  /// Changer d'onglet en gardant la date (Direct : toujours aujourd'hui).
  void level(ConsumptionLevel level) {
    final today = consumptionToday(ref);
    state = level == ConsumptionLevel.direct
        ? ConsumptionCursor.of(level, today)
        : state.withLevel(level, today);
  }
}

final consumptionCursorProvider = NotifierProvider<ConsumptionCursorNotifier, ConsumptionCursor>(
  ConsumptionCursorNotifier.new,
);

/// Clé d'une série : compteur + plage.
typedef SeriesKey = ({int meterId, String granularity, DateTime from, DateTime to});

final consumptionSeriesProvider = FutureProvider.family<Fetched<ConsumptionSeries>, SeriesKey>(
  (ref, key) => ref
      .watch(cachedApiProvider)
      .get(
        '/meters/${key.meterId}/consumption',
        ConsumptionSeries.fromJson,
        query: {
          'granularity': key.granularity,
          'from': formatApiDate(key.from),
          'to': formatApiDate(key.to),
        },
      ),
);

SeriesKey seriesKey(int meterId, SeriesRange range) =>
    (meterId: meterId, granularity: range.granularity, from: range.from, to: range.to);

/// Résumé du compteur (estimation de fin du mois en cours, vue Mois).
final consumptionSummaryProvider = FutureProvider.family<Fetched<ConsumptionSummary>, int>(
  (ref, meterId) => ref
      .watch(cachedApiProvider)
      .get('/meters/$meterId/consumption/summary', ConsumptionSummary.fromJson),
);

/// Détail d'un jour (vue Jour) : index, coût, moyenne du même jour, classement, relevé ou estimé.
final dayDetailProvider = FutureProvider.family<Fetched<DayDetail>, ({int meterId, DateTime day})>(
  (ref, key) => ref
      .watch(cachedApiProvider)
      .get('/meters/${key.meterId}/consumption/days/${formatApiDate(key.day)}', DayDetail.fromJson),
);

/// Facture du compteur qui couvre un mois (lien « Facture de sept.–oct. » de la vue Mois), ou
/// `null`. Factures BIMESTRIELLES : la seule officielle ; les vues mois restent des estimations.
final billForMonthProvider = FutureProvider.family<BillSummary?, ({int meterId, DateTime month})>((
  ref,
  key,
) async {
  final list = await ref
      .watch(cachedApiProvider)
      .get(
        '/bills',
        BillList.fromJson,
        // Sans filtre d'année : une facture déc.–janv. appartient à l'année de son DÉBUT.
        // 50 dernières factures bimestrielles = plus de 8 ans d'historique.
        query: {'meter_id': key.meterId, 'size': 50},
      );
  final first = DateTime(key.month.year, key.month.month);
  final last = DateTime(key.month.year, key.month.month + 1, 0);
  return list.data.items
      .where((b) => b.status != BillStatuses.cancelled)
      .where((b) => !b.periodStart.isAfter(last) && !b.periodEnd.isBefore(first))
      .firstOrNull;
});
