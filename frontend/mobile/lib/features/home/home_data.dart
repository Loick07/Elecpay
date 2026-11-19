import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/cache/cached_api.dart';
import '../../core/models/bills.dart';
import '../../core/models/consumption.dart';
import '../../core/models/households.dart';
import '../../core/models/notifications.dart';
import '../../core/models/payments.dart';
import '../auth/models/auth_models.dart';
import 'home_rules.dart';

// Lectures de l'accueil (écran 5). UNE LECTURE PAR CARTE : chacune se charge et échoue SÉPARÉMENT
// (décision de Loick, F4) ; une lecture en échec n'empêche jamais les autres de s'afficher.
// Toutes passent par le cache hors ligne (cachedApiProvider). Rafraîchir : `ref.invalidate(…)`.

/// Le compte connecté (« Bonjour Loick »).
final homeUserProvider = FutureProvider<Fetched<UserPublic>>(
  (ref) => ref.watch(cachedApiProvider).get('/me', UserPublic.fromJson),
);

/// Mes foyers (sélecteur « Maison Mpita · 2 foyers »).
final householdsProvider = FutureProvider<Fetched<List<HouseholdSummary>>>(
  (ref) => ref.watch(cachedApiProvider).getList('/households', HouseholdSummary.fromJson),
);

/// Plafond de la lecture des factures à payer (au-delà : 100 factures ouvertes, irréaliste).
const toPayPageSize = 100;

/// Factures à payer de TOUS mes foyers (impayées, en retard, paiement en cours) + reste à payer.
/// Une seule lecture sert la carte urgente, le foyer par défaut et le rappel des autres foyers.
final toPayBillsProvider = FutureProvider<Fetched<BillList>>(
  (ref) => ref
      .watch(cachedApiProvider)
      .get(
        '/bills',
        BillList.fromJson,
        query: {'status': BillFilters.toPay, 'size': toPayPageSize},
      ),
);

/// Factures à payer si elles ont pu être lues, sinon aucune : leur échec ne bloque pas les autres
/// cartes (le foyer par défaut retombe alors sur le premier foyer).
Future<List<BillSummary>> _toPayOrNone(Ref ref) async {
  try {
    return (await ref.watch(toPayBillsProvider.future)).data.items;
  } on Object {
    return const [];
  }
}

/// Deux lectures EN MÊME TEMPS ; en cas d'échec, l'erreur d'ORIGINE (`ApiFailure` : message,
/// « Hors connexion », référence), pas une `ParallelWaitError` comme avec `(a, b).wait`.
Future<List<Object?>> _both(Future<Object?> a, Future<Object?> b) => Future.wait([a, b]);

// --- Foyer affiché ---------------------------------------------------------------------------

/// Où est gardé le foyer choisi dans le sélecteur.
abstract interface class HouseholdChoiceStore {
  Future<int?> read();
  Future<void> write(int householdId);
}

/// Dans le stockage sécurisé du téléphone (exclu des sauvegardes, comme le reste).
class SecureHouseholdChoiceStore implements HouseholdChoiceStore {
  SecureHouseholdChoiceStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const key = 'elecpay.home.household';
  final FlutterSecureStorage _storage;

  @override
  Future<int?> read() async {
    try {
      return int.tryParse(await _storage.read(key: key) ?? '');
    } on Object {
      return null; // illisible : le foyer par défaut
    }
  }

  @override
  Future<void> write(int householdId) async {
    try {
      await _storage.write(key: key, value: '$householdId');
    } on Object {
      // Pas grave : le foyer par défaut sera montré au prochain lancement.
    }
  }
}

final householdChoiceStoreProvider = Provider<HouseholdChoiceStore>(
  (ref) => SecureHouseholdChoiceStore(),
);

/// Foyer choisi dans le sélecteur (gardé d'un lancement à l'autre). `null` : jamais choisi.
class SavedHouseholdNotifier extends AsyncNotifier<int?> {
  @override
  Future<int?> build() => ref.read(householdChoiceStoreProvider).read();

  Future<void> choose(int householdId) async {
    // Attendre la lecture du choix gardé : sinon, finie après coup, elle écraserait ce choix.
    try {
      await future;
    } on Object {
      // Lecture en échec : le nouveau choix la remplace.
    }
    state = AsyncData(householdId);
    await ref.read(householdChoiceStoreProvider).write(householdId);
  }
}

final savedHouseholdProvider = AsyncNotifierProvider<SavedHouseholdNotifier, int?>(
  SavedHouseholdNotifier.new,
);

/// Foyer affiché : le choix gardé s'il existe encore, sinon celui de la facture la plus urgente,
/// sinon le premier. `null` : aucun foyer (compte neuf).
final shownHouseholdIdProvider = FutureProvider<int?>((ref) async {
  final households = (await ref.watch(householdsProvider.future)).data;
  final saved = await ref.watch(savedHouseholdProvider.future);
  return effectiveHouseholdId(saved: saved, households: households, toPay: await _toPayOrNone(ref));
});

// --- Carte de la facture la plus urgente --------------------------------------------------------

/// Ce que montre la carte : la facture urgente du foyer affiché (ou « tout est payé »), son action,
/// et le rappel des retards dans les autres foyers.
@immutable
class UrgentBillCard {
  const UrgentBillCard({required this.bills, required this.urgent, required this.elsewhere});

  /// La lecture (fraîche ou du cache : « Hors connexion… »).
  final Fetched<BillList> bills;

  /// `null` : tout est payé dans ce foyer.
  final BillSummary? urgent;
  final List<OverdueElsewhere> elsewhere;

  UrgentBillAction? get action => urgent == null ? null : urgentBillAction(urgent!);
}

final urgentBillProvider = FutureProvider<UrgentBillCard>((ref) async {
  final bills = await ref.watch(toPayBillsProvider.future);
  final items = bills.data.items;
  // Foyers illisibles : la carte reste utile (facture la plus urgente, tous foyers confondus).
  int? shown;
  try {
    shown = await ref.watch(shownHouseholdIdProvider.future);
  } on Object {
    return UrgentBillCard(bills: bills, urgent: mostUrgentBill(items), elsewhere: const []);
  }
  return UrgentBillCard(
    bills: bills,
    urgent: mostUrgentBill(items.where((b) => b.householdId == shown)),
    elsewhere: overdueElsewhere(items, shown),
  );
});

// --- Carte du mois en cours ---------------------------------------------------------------------

/// Compteurs d'un foyer.
final householdMetersProvider = FutureProvider.family<Fetched<List<MeterDetail>>, int>(
  (ref, householdId) =>
      ref.watch(cachedApiProvider).getList('/households/$householdId/meters', MeterDetail.fromJson),
);

/// Compteur montré par la carte du mois. `null` : aucun foyer ou aucun compteur → « Ajoutez votre
/// premier compteur ».
final shownMeterIdProvider = FutureProvider<int?>((ref) async {
  final householdId = await ref.watch(shownHouseholdIdProvider.future);
  if (householdId == null) return null;
  final meters = (await ref.watch(householdMetersProvider(householdId).future)).data;
  final toPay = await _toPayOrNone(ref);
  return consumptionMeterId(
    urgent: mostUrgentBill(toPay.where((b) => b.householdId == householdId)),
    meters: meters,
  );
});

/// Nombre de jours des petites barres de la carte (maquette : 12).
const homeChartDays = 12;

/// Carte « Novembre, du 1er au 12 » : résumé du mois + estimation, et les 12 derniers jours.
@immutable
class MonthConsumption {
  const MonthConsumption({
    required this.summary,
    required this.days,
    this.meter,
    this.meterCount = 1,
  });

  final Fetched<ConsumptionSummary> summary;
  final Fetched<ConsumptionSeries> days;

  /// Compteur montré, et nombre de compteurs du foyer (plusieurs : son nom est écrit sur la carte).
  final MeterDetail? meter;
  final int meterCount;
}

/// `null` : aucun compteur. Les dates sont celles du téléphone (la carte montre des relevés
/// périodiques et des estimations, jamais du « temps réel »).
final monthConsumptionProvider = FutureProvider<MonthConsumption?>((ref) async {
  final meterId = await ref.watch(shownMeterIdProvider.future);
  if (meterId == null) return null;
  final householdId = (await ref.watch(shownHouseholdIdProvider.future))!;
  final meters = (await ref.watch(householdMetersProvider(householdId).future)).data;
  final api = ref.watch(cachedApiProvider);
  final today = DateTime.now();
  String day(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  final [summary as Fetched<ConsumptionSummary>, days as Fetched<ConsumptionSeries>] = await _both(
    api.get('/meters/$meterId/consumption/summary', ConsumptionSummary.fromJson),
    api.get(
      '/meters/$meterId/consumption',
      ConsumptionSeries.fromJson,
      query: {
        'granularity': 'day',
        'from': day(today.subtract(const Duration(days: homeChartDays - 1))),
        'to': day(today),
      },
    ),
  );
  return MonthConsumption(
    summary: summary,
    days: days,
    meter: meters.where((m) => m.id == meterId).firstOrNull,
    meterCount: meters.length,
  );
});

// --- Activité récente ---------------------------------------------------------------------------

/// Nombre de lignes de « Activité récente ».
const homeActivityCount = 3;

@immutable
class RecentActivity {
  const RecentActivity({required this.items, required this.offline});

  final List<ActivityItem> items;

  /// Une des deux lectures vient du cache (« Hors connexion… ») ; `null` : tout est frais.
  final CachedData<Object?>? offline;
}

/// Paiements réussis + dernières factures émises (comme la maquette), du plus récent.
final recentActivityProvider = FutureProvider<RecentActivity>((ref) async {
  final api = ref.watch(cachedApiProvider);
  final [payments as Fetched<PaymentPage>, bills as Fetched<BillList>] = await _both(
    api.get(
      '/payments',
      PaymentPage.fromJson,
      query: {'status': TransactionStatuses.succeeded, 'size': homeActivityCount},
    ),
    api.get('/bills', BillList.fromJson, query: {'size': homeActivityCount}),
  );
  final cached = [payments, bills].whereType<CachedData<Object?>>().toList()
    ..sort((a, b) => a.savedAt.compareTo(b.savedAt)); // la plus ancienne des deux
  return RecentActivity(
    items: recentActivity(
      payments: payments.data.items,
      bills: bills.data.items,
      limit: homeActivityCount,
    ),
    offline: cached.firstOrNull,
  );
});

// --- Cloche des notifications -------------------------------------------------------------------

/// Nombre de notifications non lues (point rouge de la cloche). Mis à jour au retour sur
/// l'application et sur l'accueil (`refresh`), JAMAIS par interrogation périodique.
class UnreadCountNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async =>
      (await ref.watch(cachedApiProvider).get('/notifications/unread-count', UnreadCount.fromJson))
          .data
          .unreadCount;

  /// Relit le compteur (au retour sur l'application, à l'arrivée sur l'accueil). En cas d'échec,
  /// la dernière valeur connue reste affichée.
  Future<void> refresh() async {
    final previous = state;
    final next = await AsyncValue.guard(build);
    state = next.hasError && previous.hasValue ? previous : next;
  }
}

final unreadCountProvider = AsyncNotifierProvider<UnreadCountNotifier, int>(
  UnreadCountNotifier.new,
);
