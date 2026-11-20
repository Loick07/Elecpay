import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/cached_api.dart';
import '../../core/format/formats.dart';
import '../../core/models/payments.dart';
import '../../core/models/receipts.dart';
import '../../core/widgets/statuses.dart';

// Écran 12 : historique des paiements (`GET /payments`, en cache), règles testées dans
// test/features/payments/history_test.dart. Guide : backend/docs/PAIEMENTS.md (« Historique »).

/// Onglets de la maquette : Tous, Réussis, Non aboutis (échoués + expirés).
enum HistoryFilter {
  all('Tous'),
  succeeded('Réussis'),
  notCompleted('Non aboutis');

  const HistoryFilter(this.label);

  final String label;
}

/// Plafond des « Non aboutis » : l'API ne filtre qu'UN statut à la fois ; échoués et expirés sont
/// lus séparément (100 au plus chacun), puis fusionnés. Au-delà (irréaliste), les plus anciens ne
/// seraient pas montrés.
const notCompletedPageSize = 100;

@immutable
class HistoryView {
  const HistoryView({
    required this.items,
    required this.total,
    this.offline,
    this.loadingMore = false,
    this.moreFailure,
  });

  final List<PaymentPublic> items;
  final int total;
  final CachedData<Object?>? offline;
  final bool loadingMore;
  final Object? moreFailure;

  bool get hasMore => items.length < total;
}

class HistoryNotifier extends AsyncNotifier<HistoryView> {
  HistoryNotifier(this.filter);

  final HistoryFilter filter;
  static const pageSize = 20;
  int _page = 1;

  Future<Fetched<PaymentPage>> _fetch(Map<String, Object?> query) =>
      ref.read(cachedApiProvider).get('/payments', PaymentPage.fromJson, query: query);

  @override
  Future<HistoryView> build() async {
    _page = 1;
    if (filter == HistoryFilter.notCompleted) {
      final [failed, expired] = await Future.wait([
        _fetch({'status': TransactionStatuses.failed, 'size': notCompletedPageSize}),
        _fetch({'status': TransactionStatuses.expired, 'size': notCompletedPageSize}),
      ]);
      final items = [...failed.data.items, ...expired.data.items]
        ..sort((a, b) => b.initiatedAt.compareTo(a.initiatedAt));
      return HistoryView(
        items: items,
        total: items.length,
        offline: [failed, expired].whereType<CachedData<Object?>>().firstOrNull,
      );
    }
    final first = await _fetch(_query(1));
    return HistoryView(
      items: first.data.items,
      total: first.data.total,
      offline: first is CachedData<PaymentPage> ? first : null,
    );
  }

  Map<String, Object?> _query(int page) => {
    if (filter == HistoryFilter.succeeded) 'status': TransactionStatuses.succeeded,
    'page': page,
    'size': pageSize,
  };

  /// Page suivante (Tous, Réussis). Sans effet s'il n'y en a plus ou si elle est déjà en route.
  Future<void> loadMore() async {
    final view = state.value;
    if (view == null || !view.hasMore || view.loadingMore) return;
    state = AsyncData(
      HistoryView(items: view.items, total: view.total, offline: view.offline, loadingMore: true),
    );
    try {
      final next = (await _fetch(_query(_page + 1))).data;
      _page++;
      final known = {for (final p in view.items) p.id};
      state = AsyncData(
        HistoryView(
          items: [...view.items, ...next.items.where((p) => !known.contains(p.id))],
          total: next.total,
          offline: view.offline,
        ),
      );
    } on Object catch (failure) {
      state = AsyncData(
        HistoryView(
          items: view.items,
          total: view.total,
          offline: view.offline,
          moreFailure: failure,
        ),
      );
    }
  }
}

final historyProvider = AsyncNotifierProvider.family<HistoryNotifier, HistoryView, HistoryFilter>(
  HistoryNotifier.new,
);

/// Résumé de la maquette « Payé en 2026 » : somme et nombre des REÇUS de l'année (un reçu = un
/// paiement réussi). Lu sur `GET /receipts?year=` (100 au plus : `atLeast` si l'année en a plus).
typedef YearPaid = ({int year, int amount, int count, bool atLeast});

final yearPaidProvider = FutureProvider.family<YearPaid, int>((ref, year) async {
  final page = await ref
      .watch(cachedApiProvider)
      .get('/receipts', ReceiptPage.fromJson, query: {'year': year, 'size': 100});
  final items = page.data.items;
  return (
    year: year,
    amount: items.fold<int>(0, (sum, r) => sum + r.amount),
    count: page.data.total,
    atLeast: page.data.total > items.length,
  );
});

// --- Règles d'affichage ------------------------------------------------------------------------

/// Paiements groupés par MOIS de la demande, à l'heure de Brazzaville (guide : `initiated_at`) :
/// « Novembre 2026 ».
List<({String title, List<PaymentPublic> payments})> groupByMonth(Iterable<PaymentPublic> all) {
  final groups = <({String title, List<PaymentPublic> payments})>[];
  for (final p in all) {
    final local = toBrazzaville(p.initiatedAt);
    final title = formatMonthYear(local.year, local.month);
    if (groups.isEmpty || groups.last.title != title) groups.add((title: title, payments: []));
    groups.last.payments.add(p);
  }
  return groups;
}

/// Note sous une ligne (maquette) : le motif d'un échec, « Code PIN non saisi à temps » pour un
/// paiement expiré, « Payé par Grâce Ngoma » quand un autre membre a payé. `null` : rien.
String? historyNote(PaymentPublic p) => switch (p.status) {
  TransactionStatuses.failed => p.failureReason ?? 'Le paiement n’a pas abouti.',
  TransactionStatuses.expired => p.failureReason ?? 'Code PIN non saisi à temps',
  _ when !p.isMine => 'Payé par ${p.payerName}',
  _ => null,
};

/// Titre d'une ligne : « sept.–oct. 2026 · Maison Mpita » (période à partir des dates).
String historyTitle(PaymentPublic p) =>
    [formatBillPeriodShort(p.billPeriodStart, p.billPeriodEnd), ?p.householdName].join(' · ');

/// Statut affiché, au masculin comme la maquette (« un paiement ») : « Réussi », « Échoué »,
/// « Expiré », « En attente » ; mêmes couleurs et icônes que la table des statuts de la charte.
StatusStyle historyStatus(PaymentPublic p) {
  final base = transactionStatus(p.status);
  final label = switch (p.status) {
    TransactionStatuses.succeeded => 'Réussi',
    TransactionStatuses.failed => 'Échoué',
    TransactionStatuses.expired => 'Expiré',
    _ => base.label,
  };
  return StatusStyle(label, base.tone, base.icon);
}
