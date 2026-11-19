import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/cached_api.dart';
import '../../core/models/bills.dart';
import 'bills_rules.dart';

// Lectures des écrans 6 et 7, toutes par le cache hors ligne (`/bills` et `/bills/{id}` sont dans
// `cache_policy.dart`). Le PDF, lui, n'est jamais en cache (F5.4).

/// Une page de « Mes factures » : les factures déjà lues d'un onglet, et ce qu'il reste à charger.
@immutable
class BillsView {
  const BillsView({
    required this.items,
    required this.total,
    required this.outstanding,
    this.offline,
    this.loadingMore = false,
    this.moreFailure,
  });

  final List<BillSummary> items;
  final int total;

  /// Reste à payer (tous foyers : ignore l'onglet et la pagination).
  final Outstanding outstanding;

  /// Première page lue dans le cache : bannière « Hors connexion… » et Payer désactivé.
  final CachedData<Object?>? offline;
  final bool loadingMore;
  final Object? moreFailure;

  bool get hasMore => items.length < total;

  BillsView copyWith({
    List<BillSummary>? items,
    int? total,
    Outstanding? outstanding,
    bool? loadingMore,
    Object? moreFailure,
    bool clearMoreFailure = false,
  }) => BillsView(
    items: items ?? this.items,
    total: total ?? this.total,
    outstanding: outstanding ?? this.outstanding,
    offline: offline,
    loadingMore: loadingMore ?? this.loadingMore,
    moreFailure: clearMoreFailure ? null : (moreFailure ?? this.moreFailure),
  );
}

/// Liste d'un onglet, page par page (20).
class BillsNotifier extends AsyncNotifier<BillsView> {
  BillsNotifier(this.filter);

  final BillsFilter filter;
  static const pageSize = 20;
  int _page = 1;

  Future<Fetched<BillList>> _fetch(int page) => ref
      .read(cachedApiProvider)
      .get(
        '/bills',
        BillList.fromJson,
        query: {'status': ?filter.status, 'page': page, 'size': pageSize},
      );

  @override
  Future<BillsView> build() async {
    _page = 1;
    final first = await _fetch(1);
    return BillsView(
      items: first.data.items,
      total: first.data.total,
      outstanding: first.data.outstanding,
      offline: first is CachedData<BillList> ? first : null,
    );
  }

  /// Page suivante (défilement). Sans effet s'il n'y en a plus ou si elle est déjà en route.
  Future<void> loadMore() async {
    final view = state.value;
    if (view == null || !view.hasMore || view.loadingMore) return;
    state = AsyncData(view.copyWith(loadingMore: true, clearMoreFailure: true));
    try {
      final next = (await _fetch(_page + 1)).data;
      _page++;
      final known = {for (final b in view.items) b.id};
      state = AsyncData(
        view.copyWith(
          items: [...view.items, ...next.items.where((b) => !known.contains(b.id))],
          total: next.total,
          outstanding: next.outstanding,
          loadingMore: false,
          clearMoreFailure: true,
        ),
      );
    } on Object catch (failure) {
      state = AsyncData(view.copyWith(loadingMore: false, moreFailure: failure));
    }
  }
}

final billsProvider = AsyncNotifierProvider.family<BillsNotifier, BillsView, BillsFilter>(
  BillsNotifier.new,
);

/// Nombre de factures de chaque onglet (pastilles de la maquette). « À payer » et « En retard »
/// viennent du reste à payer ; « Toutes » et « Payées » d'une lecture d'un seul élément.
final billCountsProvider = FutureProvider<Map<BillsFilter, int>>((ref) async {
  final api = ref.watch(cachedApiProvider);
  final [all, paid] = await Future.wait([
    api.get('/bills', BillList.fromJson, query: {'size': 1}),
    api.get('/bills', BillList.fromJson, query: {'status': BillFilters.paid, 'size': 1}),
  ]);
  final outstanding = all.data.outstanding;
  return {
    BillsFilter.all: all.data.total,
    BillsFilter.toPay: outstanding.count,
    BillsFilter.paid: paid.data.total,
    BillsFilter.overdue: outstanding.overdueCount,
  };
});

/// Détail d'une facture (écran 7).
final billDetailProvider = FutureProvider.family<Fetched<BillDetail>, int>(
  (ref, billId) => ref.watch(cachedApiProvider).get('/bills/$billId', BillDetail.fromJson),
);
