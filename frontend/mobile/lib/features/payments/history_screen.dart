import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/format/formats.dart';
import '../../core/models/payments.dart';
import '../../core/network/api_failure.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/load_more.dart';
import '../../core/widgets/offline_banner.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/state_block.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/statuses.dart';
import '../home/home_screen.dart' show homeClockProvider;
import 'history_data.dart';
import 'payment_flow.dart';

/// Onglet choisi sur l'historique (gardé tant que l'application est ouverte).
class HistoryFilterNotifier extends Notifier<HistoryFilter> {
  @override
  HistoryFilter build() => HistoryFilter.all;

  void choose(HistoryFilter filter) => state = filter;
}

final historyFilterProvider = NotifierProvider<HistoryFilterNotifier, HistoryFilter>(
  HistoryFilterNotifier.new,
);

/// Écran 12 : historique des paiements (maquette `Historique.dc.html`). Payé dans l'année, onglets
/// Tous / Réussis / Non aboutis, paiements groupés par mois, motif des échecs, « Payé par … ».
/// Toucher : le reçu (réussi), le suivi (en attente), la facture (échoué ou expiré : la repayer).
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  Future<void> _refresh(WidgetRef ref, HistoryFilter filter, int year) async {
    ref
      ..invalidate(historyProvider(filter))
      ..invalidate(yearPaidProvider(year));
    try {
      await ref.read(historyProvider(filter).future);
    } on Object {
      // L'état d'erreur s'affiche.
    }
  }

  Future<void> _open(BuildContext context, WidgetRef ref, PaymentPublic p) async {
    switch (p.status) {
      case TransactionStatuses.succeeded when p.receiptId != null:
        await context.push(Routes.receipt(p.receiptId!));
      case TransactionStatuses.pending:
        await ref.read(paymentFlowProvider(p.billId).notifier).follow(p.id);
        if (context.mounted) await context.push(Routes.payment(p.billId));
      default:
        await context.push(Routes.bill(p.billId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final now = ref.watch(homeClockProvider)();
    final year = toBrazzaville(now).year;
    final filter = ref.watch(historyFilterProvider);
    final history = ref.watch(historyProvider(filter));
    final paid = ref.watch(yearPaidProvider(year)).value;
    void retry() => unawaited(_refresh(ref, filter, year));

    final children = <Widget>[
      if (history.value?.offline case final cached?) ...[
        OfflineBanner(cached.label),
        const SizedBox(height: Space.s3),
      ],
      _YearSummary(year: year, paid: paid),
      const SizedBox(height: Space.s4),
      Semantics(
        label: 'Filtrer les paiements',
        container: true,
        child: Wrap(
          spacing: Space.s2,
          runSpacing: Space.s2,
          children: [
            for (final f in HistoryFilter.values)
              Semantics(
                selected: f == filter,
                button: true,
                label: f.label,
                excludeSemantics: true,
                child: Material(
                  color: f == filter ? c.voltSoft : c.surface1,
                  shape: StadiumBorder(side: BorderSide(color: f == filter ? c.volt : c.line)),
                  child: InkWell(
                    key: Key('history.filter.${f.name}'),
                    customBorder: const StadiumBorder(),
                    onTap: () => ref.read(historyFilterProvider.notifier).choose(f),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: Space.s2),
                        child: Text(
                          f.label,
                          style: AppText.bodySm.copyWith(color: c.ink, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: Space.s4),
      ...switch (history) {
        AsyncValue(:final value?) => _list(context, ref, value, filter, now),
        AsyncError(:final error) => [
          if (error case final ApiFailure failure)
            stateForFailure(failure, what: 'vos paiements', onRetry: retry)
          else
            StateBlock.error(what: 'vos paiements', onRetry: retry),
        ],
        _ => [
          AppSkeleton(
            loading: true,
            child: _Group(
              title: 'Novembre 2026',
              rows: [
                for (var i = 0; i < 3; i++)
                  _Row(
                    title: 'sept.–oct. 2026 · Maison Mpita',
                    subtitle: 'MTN MoMo · 12 nov. à 14:32',
                    note: null,
                    noteIsError: false,
                    amount: 31420,
                    succeeded: true,
                    status: transactionStatus(TransactionStatuses.succeeded),
                    onTap: null,
                  ),
              ],
            ),
          ),
        ],
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Historique des paiements')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refresh(ref, filter, year),
          child: ListView(
            key: const Key('history.list'),
            padding: const EdgeInsets.fromLTRB(Space.s4, Space.s2, Space.s4, Space.s8),
            children: children,
          ),
        ),
      ),
    );
  }

  List<Widget> _list(
    BuildContext context,
    WidgetRef ref,
    HistoryView view,
    HistoryFilter filter,
    DateTime now,
  ) {
    if (view.items.isEmpty) {
      return [
        StateBlock.empty(
          key: const Key('history.empty'),
          icon: AppIcons.securePay,
          title: switch (filter) {
            HistoryFilter.all => 'Aucun paiement',
            HistoryFilter.succeeded => 'Aucun paiement réussi',
            HistoryFilter.notCompleted => 'Aucun paiement non abouti',
          },
          message: filter == HistoryFilter.notCompleted
              ? 'Tous vos paiements ont abouti.'
              : 'Vos paiements Mobile Money apparaîtront ici, avec leur reçu.',
        ),
      ];
    }
    return [
      for (final group in groupByMonth(view.items)) ...[
        _Group(
          title: group.title,
          rows: [
            for (final p in group.payments)
              _Row(
                key: Key('history.${p.id}'),
                title: historyTitle(p),
                subtitle: '${p.operatorLabel} · ${formatDateTime(p.initiatedAt, now: now)}',
                note: historyNote(p),
                noteIsError: p.status == TransactionStatuses.failed,
                amount: p.amount,
                succeeded: p.status == TransactionStatuses.succeeded,
                status: historyStatus(p),
                onTap: () => _open(context, ref, p),
              ),
          ],
        ),
        const SizedBox(height: Space.s4),
      ],
      if (view.moreFailure != null)
        LoadMoreFooter(
          failed: true,
          onLoad: () => ref.read(historyProvider(filter).notifier).loadMore(),
        )
      else if (view.hasMore)
        LoadMoreFooter(
          key: ValueKey('history.more.${view.items.length}'),
          onLoad: () => ref.read(historyProvider(filter).notifier).loadMore(),
        ),
    ];
  }
}

/// « Payé en 2026 : 261 471 FCFA » et « Paiements réussis : 9 » (reçus de l'année).
class _YearSummary extends StatelessWidget {
  const _YearSummary({required this.year, required this.paid});

  final int year;
  final YearPaid? paid;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = paid;
    final amount = p == null ? '…' : formatFcfa(p.amount);
    final count = p == null ? '…' : '${p.atLeast ? 'plus de ' : ''}${p.count}';
    return Semantics(
      container: true,
      label: 'Payé en $year : $amount. Paiements réussis : $count',
      excludeSemantics: true,
      child: Container(
        key: const Key('history.summary'),
        padding: const EdgeInsets.all(Space.s4),
        decoration: BoxDecoration(
          color: c.surface1,
          borderRadius: const BorderRadius.all(Radius.circular(Radii.lg)),
          boxShadow: context.shadows.card,
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: Space.s4,
          runSpacing: Space.s3,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('PAYÉ EN $year', style: AppText.overline.copyWith(color: c.inkMuted)),
                Text(amount, style: AppText.amount.copyWith(color: c.ink)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('PAIEMENTS RÉUSSIS', style: AppText.overline.copyWith(color: c.inkMuted)),
                Text(count, style: AppText.amount.copyWith(color: c.ink)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(title.toUpperCase(), style: AppText.overline.copyWith(color: c.inkMuted)),
        ),
        const SizedBox(height: Space.s2),
        Material(
          color: c.surface1,
          borderRadius: const BorderRadius.all(Radius.circular(Radii.lg)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) Divider(height: 1, thickness: 1, color: c.line),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Une ligne : icône du statut, période et foyer, opérateur et date, note (motif, « Payé par… »),
/// montant (barré s'il n'a pas été payé) et badge du statut.
class _Row extends StatelessWidget {
  const _Row({
    required this.title,
    required this.subtitle,
    required this.note,
    required this.noteIsError,
    required this.amount,
    required this.succeeded,
    required this.status,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final String? note;
  final bool noteIsError;
  final int amount;
  final bool succeeded;
  final StatusStyle status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final amountText = formatFcfa(amount);
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final amountAndStatus = Column(
      crossAxisAlignment: stacked ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          amountText,
          style: AppText.bodyStrong.copyWith(
            color: succeeded ? c.ink : c.inkMuted,
            decoration: succeeded ? null : TextDecoration.lineThrough,
          ),
        ),
        const SizedBox(height: Space.s1),
        StatusBadge(status),
      ],
    );
    return Semantics(
      button: onTap != null,
      label: [title, subtitle, ?note, amountText, status.label].join(', '),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 68),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s3),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppText.bodyStrong.copyWith(color: c.ink)),
                      Text(subtitle, style: AppText.bodySm.copyWith(color: c.inkMuted)),
                      if (note != null)
                        Text(
                          note!,
                          style: AppText.caption.copyWith(
                            color: noteIsError ? c.errorText : c.inkFaint,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (stacked) ...[const SizedBox(height: Space.s2), amountAndStatus],
                    ],
                  ),
                ),
                if (!stacked) ...[const SizedBox(width: Space.s3), amountAndStatus],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
