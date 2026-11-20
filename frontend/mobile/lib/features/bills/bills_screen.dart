import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/demo/demo_mode.dart';
import '../../core/format/formats.dart';
import '../../core/models/bills.dart';
import '../../core/network/api_failure.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/bill_row.dart';
import '../../core/widgets/demo_badge.dart';
import '../../core/widgets/load_more.dart';
import '../../core/widgets/offline_banner.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/state_block.dart';
import '../../core/widgets/statuses.dart';
import '../home/home_data.dart';
import 'bills_data.dart';
import 'bills_rules.dart';

/// Onglet choisi sur « Mes factures » (gardé tant que l'application est ouverte).
class BillsFilterNotifier extends Notifier<BillsFilter> {
  @override
  BillsFilter build() => BillsFilter.all;

  void choose(BillsFilter filter) => state = filter;
}

final billsFilterProvider = NotifierProvider<BillsFilterNotifier, BillsFilter>(
  BillsFilterNotifier.new,
);

/// Écran 6 : Mes factures (maquette `Factures.dc.html`). Reste à payer tous foyers, onglets Toutes /
/// À payer / Payées / En retard avec leur nombre, factures groupées par période, pages de 20.
class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});

  Future<void> _refresh(WidgetRef ref, BillsFilter filter) async {
    ref
      ..invalidate(billsProvider(filter))
      ..invalidate(billCountsProvider)
      ..invalidate(toPayBillsProvider)
      ..invalidate(householdsProvider);
    try {
      await ref.read(billsProvider(filter).future);
    } on Object {
      // L'état d'erreur s'affiche.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final filter = ref.watch(billsFilterProvider);
    final bills = ref.watch(billsProvider(filter));
    final counts = ref.watch(billCountsProvider).value;
    final householdCount = ref.watch(householdsProvider).value?.data.length ?? 1;
    final toPay = ref.watch(toPayBillsProvider).value?.data.items ?? const <BillSummary>[];
    final firstDue = toPay.isEmpty
        ? null
        : toPay.map((b) => b.dueDate).reduce((a, b) => a.isBefore(b) ? a : b);
    void retry() => unawaited(_refresh(ref, filter));

    final children = <Widget>[
      // Wrap : texte très agrandi, le badge passe sous le titre au lieu de le couper en plein mot
      // (« Mes fa / ctures », vu sur l'itel à 200 %).
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: Space.s3,
        runSpacing: Space.s2,
        children: [
          Semantics(
            header: true,
            child: Text('Mes factures', style: AppText.h1.copyWith(color: c.ink)),
          ),
          if (ref.watch(demoModeProvider).showBadge) const DemoBadge(),
        ],
      ),
      if (bills.value?.offline case final cached?) ...[
        const SizedBox(height: Space.s3),
        OfflineBanner(cached.label),
      ],
      const SizedBox(height: Space.s4),
      if (bills.value?.outstanding case final outstanding?)
        _OutstandingCard(
          title: outstandingTitle(householdCount),
          outstanding: outstanding,
          detail: outstandingDetail(outstanding, firstDue: firstDue),
        )
      else if (bills.isLoading)
        // Squelette SEULEMENT pendant le chargement (en erreur : rien, pas de pulsation sans fin).
        const AppSkeleton(
          loading: true,
          child: _OutstandingCard(
            title: 'Reste à payer',
            outstanding: Outstanding(amount: 57238, count: 2, overdueAmount: 0, overdueCount: 0),
            detail: '2 factures',
          ),
        ),
      const SizedBox(height: Space.s4),
      _FilterChips(
        selected: filter,
        counts: counts,
        onSelect: (f) => ref.read(billsFilterProvider.notifier).choose(f),
      ),
      const SizedBox(height: Space.s4),
      ...switch (bills) {
        AsyncValue(:final value?) => _list(context, ref, value, filter, householdCount),
        AsyncError(:final error) => [
          if (error case final ApiFailure failure)
            stateForFailure(failure, what: 'vos factures', onRetry: retry)
          else
            StateBlock.error(what: 'vos factures', onRetry: retry),
        ],
        _ => [
          AppSkeleton(
            loading: true,
            child: BillRowGroup(
              title: 'Septembre – octobre 2026',
              rows: [
                for (var i = 0; i < 3; i++)
                  BillRow(
                    title: 'Maison Mpita',
                    subtitle: '417,4 kWh · échéance le 18 nov.',
                    amount: 31420,
                    status: billStatus(BillStatuses.unpaid),
                    onTap: () {},
                  ),
              ],
            ),
          ),
        ],
      },
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _refresh(ref, filter),
          child: ListView(
            key: const Key('bills.list'),
            padding: const EdgeInsets.fromLTRB(Space.s4, Space.s5, Space.s4, 120),
            children: children,
          ),
        ),
      ),
    );
  }

  List<Widget> _list(
    BuildContext context,
    WidgetRef ref,
    BillsView view,
    BillsFilter filter,
    int householdCount,
  ) {
    if (view.items.isEmpty) {
      final empty = emptyBills(filter, householdCount);
      final upToDate = filter == BillsFilter.toPay || filter == BillsFilter.overdue;
      return [
        StateBlock.empty(
          key: const Key('bills.empty'),
          icon: upToDate ? AppIcons.check : AppIcons.bill,
          tone: upToDate ? StateTone.success : StateTone.neutral,
          title: empty.title,
          message: empty.message,
        ),
      ];
    }
    return [
      for (final group in groupBillsByPeriod(view.items)) ...[
        BillRowGroup(
          title: group.title,
          rows: [
            for (final bill in group.bills)
              BillRow(
                key: Key('bill.${bill.id}'),
                title: bill.householdName,
                subtitle: billRowSubtitle(bill),
                amount: bill.amountTotal,
                status: billStatus(bill.status),
                onTap: () => context.push(Routes.bill(bill.id)),
              ),
          ],
        ),
        const SizedBox(height: Space.s4),
      ],
      if (view.moreFailure != null)
        LoadMoreFooter(
          key: const Key('bills.more'),
          failed: true,
          onLoad: () => ref.read(billsProvider(filter).notifier).loadMore(),
        )
      else if (view.hasMore)
        LoadMoreFooter(
          key: ValueKey('bills.more.${view.items.length}'),
          onLoad: () => ref.read(billsProvider(filter).notifier).loadMore(),
        ),
    ];
  }
}

/// Carte « Reste à payer · 2 foyers » : montant à gauche, « 2 factures avant le 18 nov. » à droite.
class _OutstandingCard extends StatelessWidget {
  const _OutstandingCard({required this.title, required this.outstanding, required this.detail});

  final String title;
  final Outstanding outstanding;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final late = outstanding.overdueCount > 0;
    return Semantics(
      container: true,
      label: '$title : ${formatFcfa(outstanding.amount)}. $detail',
      excludeSemantics: true,
      child: Container(
        key: const Key('bills.outstanding'),
        padding: const EdgeInsets.all(Space.s4),
        decoration: BoxDecoration(
          color: c.surface1,
          borderRadius: const BorderRadius.all(Radius.circular(Radii.lg)),
          boxShadow: context.shadows.card,
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: Space.s3,
          runSpacing: Space.s2,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title.toUpperCase(), style: AppText.overline.copyWith(color: c.inkMuted)),
                const SizedBox(height: Space.s1),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: formatFcfaValue(outstanding.amount),
                        style: AppText.amount.copyWith(color: c.ink),
                      ),
                      TextSpan(
                        text: '${unitSpace}FCFA',
                        style: AppText.bodySm.copyWith(
                          color: c.inkMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Text(
              detail,
              style: AppText.bodySm.copyWith(
                color: late ? c.errorText : c.inkMuted,
                fontWeight: late ? FontWeight.w600 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Onglets de filtre (pastilles), avec le nombre de factures de chacun.
class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.counts, required this.onSelect});

  final BillsFilter selected;
  final Map<BillsFilter, int>? counts;
  final ValueChanged<BillsFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: 'Filtrer les factures',
      container: true,
      child: Wrap(
        spacing: Space.s2,
        runSpacing: Space.s2,
        children: [
          for (final f in BillsFilter.values)
            Semantics(
              selected: f == selected,
              button: true,
              label: [
                f.label,
                if (counts?[f] case final n?) '$n facture${n > 1 ? 's' : ''}',
              ].join(', '),
              excludeSemantics: true,
              child: Material(
                color: f == selected ? c.voltSoft : c.surface1,
                shape: StadiumBorder(side: BorderSide(color: f == selected ? c.volt : c.line)),
                child: InkWell(
                  key: Key('bills.filter.${f.name}'),
                  customBorder: const StadiumBorder(),
                  onTap: () => onSelect(f),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: Space.s2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            f.label,
                            style: AppText.bodySm.copyWith(
                              color: c.ink,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (counts?[f] case final n?) ...[
                            const SizedBox(width: 6),
                            Container(
                              constraints: const BoxConstraints(minWidth: 20),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: f == selected ? c.volt : c.surface2,
                                borderRadius: const BorderRadius.all(Radius.circular(Radii.full)),
                              ),
                              child: Text(
                                '$n',
                                textAlign: TextAlign.center,
                                style: AppText.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: f == selected ? c.onVolt : c.inkMuted,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
