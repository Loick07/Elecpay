import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/cache/cached_api.dart';
import '../../core/format/formats.dart';
import '../../core/models/bills.dart';
import '../../core/network/api_failure.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/demo_badge.dart';
import '../../core/widgets/offline_banner.dart';
import '../../core/widgets/pay_button.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/state_block.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/statuses.dart';
import '../home/home_screen.dart' show homeClockProvider;
import 'bills_data.dart';
import 'bills_rules.dart';

/// Écran 7 : détail d'une facture (maquette `Facture.dc.html`), facture BIMESTRIELLE comme E²C :
/// montant et échéance, période, compteur, index, N° et date d'émission, les 6 lignes E²C avec le
/// total hors taxes, comparaison à la précédente ; Payer collé en bas (désactivé hors ligne).
class BillDetailScreen extends ConsumerWidget {
  const BillDetailScreen({required this.billId, super.key});

  final int billId;

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(billDetailProvider(billId));
    try {
      await ref.read(billDetailProvider(billId).future);
    } on Object {
      // L'état d'erreur s'affiche.
    }
  }

  void _pay(BuildContext context) => context.push(Routes.pending('Paiement', 'F6'));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(billDetailProvider(billId));
    final fetched = detail.value;
    void retry() => unawaited(_refresh(ref));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facture'),
        actions: [
          if (fetched?.data.source == 'simulated')
            const Padding(
              padding: EdgeInsets.only(right: Space.s4),
              child: DemoBadge(),
            ),
        ],
      ),
      bottomNavigationBar: fetched == null
          ? null
          : _Footer(fetched: fetched, onPay: () => _pay(context)),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: switch (detail) {
            AsyncValue(value: final f?) => _Content(fetched: f),
            AsyncError(:final error) => ListView(
              children: [
                if (error case final ApiFailure failure)
                  stateForFailure(failure, what: 'cette facture', onRetry: retry)
                else
                  StateBlock.error(what: 'cette facture', onRetry: retry),
              ],
            ),
            _ => ListView(
              padding: const EdgeInsets.all(Space.s4),
              children: [
                AppSkeleton(
                  loading: true,
                  child: _Hero(
                    bill: BillDetail.fromJson(_skeletonBill),
                    now: DateTime.utc(2026, 11, 12),
                  ),
                ),
              ],
            ),
          },
        ),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.fetched});

  final Fetched<BillDetail> fetched;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final bill = fetched.data;
    final now = ref.read(homeClockProvider)();
    return ListView(
      key: const Key('bill.detail'),
      padding: const EdgeInsets.fromLTRB(Space.s4, Space.s2, Space.s4, Space.s6),
      children: [
        if (fetched case final CachedData<BillDetail> cached) ...[
          OfflineBanner(cached.label),
          const SizedBox(height: Space.s3),
        ],
        if (bill.status == BillStatuses.cancelled) ...[
          _CancelledBanner(reason: bill.cancelledReason),
          const SizedBox(height: Space.s3),
        ],
        _Hero(bill: bill, now: now),
        const SizedBox(height: Space.s5),
        _Facts(bill: bill),
        const SizedBox(height: Space.s3),
        _Lines(bill: bill),
        const SizedBox(height: Space.s3),
        _Comparison(previous: bill.previousBill),
        if (bill.meterContractNumber != null || bill.meterCustomerNumber != null) ...[
          const SizedBox(height: Space.s3),
          Text(
            [
              if (bill.meterContractNumber case final n?) 'N° Police $n',
              if (bill.meterCustomerNumber case final n?) 'N° Client $n',
              ?bill.e2cCenter,
            ].join(' · '),
            style: AppText.caption.copyWith(color: c.inkMuted),
          ),
        ],
      ],
    );
  }
}

/// Haut de l'écran : période et foyer, statut, montant, échéance (ou date de paiement).
class _Hero extends StatelessWidget {
  const _Hero({required this.bill, required this.now});

  final BillDetail bill;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final overline =
        '${formatBillPeriodShort(bill.periodStart, bill.periodEnd)} · ${bill.householdName}';
    final countdown = dueCountdown(bill.dueDate, now: now);
    final countdownColor = switch (countdown.urgency) {
      DueUrgency.normal => c.inkMuted,
      DueUrgency.soon => c.warningText,
      DueUrgency.overdue => c.errorText,
    };
    final open =
        bill.status == BillStatuses.unpaid ||
        bill.status == BillStatuses.overdue ||
        bill.status == BillStatuses.pendingPayment;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: Space.s2,
          runSpacing: Space.s2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(overline, style: AppText.bodySm.copyWith(color: c.inkMuted)),
            StatusBadge(billStatus(bill.status)),
          ],
        ),
        const SizedBox(height: Space.s2),
        Semantics(
          label: formatFcfa(bill.amountTotal),
          excludeSemantics: true,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: formatFcfaValue(bill.amountTotal),
                  style: AppText.amountHero.copyWith(color: c.ink),
                ),
                TextSpan(
                  text: '${unitSpace}FCFA',
                  style: AppText.body.copyWith(color: c.inkMuted, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Space.s1),
        if (open)
          Text.rich(
            key: const Key('bill.due'),
            TextSpan(
              children: [
                const TextSpan(text: 'À régler avant le '),
                TextSpan(
                  text: formatCalendarDate(bill.dueDate),
                  style: TextStyle(color: c.ink, fontWeight: FontWeight.w600),
                ),
                const TextSpan(text: ' · '),
                TextSpan(
                  text: countdown.text,
                  style: TextStyle(
                    color: countdownColor,
                    fontWeight: countdown.urgency == DueUrgency.normal ? null : FontWeight.w600,
                  ),
                ),
              ],
            ),
            style: AppText.bodySm.copyWith(color: c.inkMuted),
          )
        else if (bill.paidAt case final paidAt?)
          Text(
            'Payée le ${formatDate(paidAt)}',
            style: AppText.bodySm.copyWith(color: c.successText),
          ),
      ],
    );
  }
}

/// Facture annulée : elle reste consultable, avec le motif ; elle ne se paie pas.
class _CancelledBanner extends StatelessWidget {
  const _CancelledBanner({required this.reason});

  final String? reason;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      child: Container(
        key: const Key('bill.cancelled'),
        padding: const EdgeInsets.all(Space.s4),
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: const BorderRadius.all(Radius.circular(Radii.md)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcon(AppIcons.cancelled, color: c.inkMuted),
            const SizedBox(width: Space.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Facture annulée', style: AppText.bodyStrong.copyWith(color: c.ink)),
                  Text(
                    reason == null || reason!.trim().isEmpty
                        ? 'Motif non précisé.'
                        : 'Motif : $reason',
                    style: AppText.bodySm.copyWith(color: c.inkMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Période, compteur, index, N° de facture, date d'émission (2 colonnes, maquette).
class _Facts extends StatelessWidget {
  const _Facts({required this.bill});

  final BillDetail bill;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final facts = <(String, String, bool)>[
      ('Période', formatBillPeriod(bill.periodStart, bill.periodEnd), false),
      (
        'Compteur',
        bill.meterLabel == null
            ? bill.meterReference
            : '${bill.meterLabel} · ${bill.meterReference}',
        false,
      ),
      ('Ancien index', formatIndexKwh(bill.previousIndexKwh), false),
      ('Nouvel index', formatIndexKwh(bill.currentIndexKwh), false),
      ('N° facture', formatReference(bill.reference), true),
      ('Émise le', formatDate(bill.issuedAt), false),
    ];
    return Container(
      padding: const EdgeInsets.all(Space.s4),
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.lg)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Texte très agrandi : une seule colonne (sinon les valeurs se coupent mot à mot).
          final columns = MediaQuery.textScalerOf(context).scale(1) > 1.3 ? 1 : 2;
          final width = (constraints.maxWidth - Space.s3 * (columns - 1)) / columns;
          return Wrap(
            spacing: Space.s3,
            runSpacing: Space.s4,
            children: [
              for (final (label, value, mono) in facts)
                SizedBox(
                  width: width,
                  child: Semantics(
                    container: true,
                    label: '$label : $value',
                    excludeSemantics: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: AppText.caption.copyWith(color: c.inkMuted)),
                        Text(
                          value,
                          style: (mono ? AppText.reference : AppText.bodySm).copyWith(
                            color: c.ink,
                            fontWeight: mono ? null : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// « Détail du montant » : les 6 lignes E²C, « Total hors taxes » après le droit à la
/// consommation, le total, et la note de calcul.
class _Lines extends StatelessWidget {
  const _Lines({required this.bill});

  final BillDetail bill;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final lines = [...bill.lines]..sort((a, b) => a.position.compareTo(b.position));
    final subtotalIndex = subtotalAfter(lines);
    final note = [
      'Calcul identique à la facture E²C : décimales coupées à chaque ligne.',
      if (bill.tariff.isAssumption)
        bill.source == 'simulated' ? 'Tarif à confirmer (mode démo).' : 'Tarif à confirmer.',
    ].join(' ');
    return Container(
      padding: const EdgeInsets.all(Space.s4),
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.lg)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text('Détail du montant', style: AppText.bodyStrong.copyWith(color: c.ink)),
          ),
          for (final (i, line) in lines.indexed) ...[
            const SizedBox(height: Space.s3),
            _AmountRow(
              key: Key('bill.line.${line.kind}'),
              label: line.label,
              detail: billLineDetail(line),
              amount: line.amount,
            ),
            if (i == subtotalIndex) ...[
              const SizedBox(height: Space.s3),
              _AmountRow(
                key: const Key('bill.subtotal'),
                label: 'Total hors taxes',
                amount: bill.amountHt,
                emphasis: true,
              ),
            ],
          ],
          const SizedBox(height: Space.s3),
          Divider(height: 1, color: c.line),
          const SizedBox(height: Space.s3),
          _AmountRow(
            key: const Key('bill.total'),
            label: 'Total',
            amount: bill.amountTotal,
            emphasis: true,
          ),
          const SizedBox(height: Space.s3),
          Text(note, style: AppText.caption.copyWith(color: c.inkFaint)),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.amount,
    this.detail,
    this.emphasis = false,
    super.key,
  });

  final String label;
  final String? detail;
  final int amount;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final amountText = formatFcfa(amount);
    return Semantics(
      container: true,
      label: [label, ?detail, amountText].join(', '),
      excludeSemantics: true,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.start,
        spacing: Space.s3,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: (emphasis ? AppText.bodyStrong : AppText.bodySm).copyWith(color: c.ink),
              ),
              if (detail != null) Text(detail!, style: AppText.caption.copyWith(color: c.inkMuted)),
            ],
          ),
          Text(
            amountText,
            style: (emphasis ? AppText.bodyStrong : AppText.bodySm).copyWith(
              color: c.ink,
              fontWeight: emphasis ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Comparaison à la facture précédente du même compteur (consommation) : hausse en orange,
/// baisse en vert, toujours avec le signe et le mot (jamais la couleur seule).
class _Comparison extends StatelessWidget {
  const _Comparison({required this.previous});

  final PreviousBillComparison? previous;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = previous;
    final Widget text;
    if (p == null) {
      text = Text(
        'Première facture de ce compteur : pas encore de comparaison.',
        style: AppText.bodySm.copyWith(color: c.inkMuted),
      );
    } else {
      final reference =
          '${p.periodLabel} (${formatIndexKwh(p.consumptionKwh)} · '
          '${formatFcfa(p.amountTotal)})';
      final percent = p.consumptionChangePercent;
      if (percent == null) {
        text = Text(
          'Facture précédente : $reference.',
          style: AppText.bodySm.copyWith(color: c.inkMuted),
        );
      } else {
        final variation = formatVariation(percent, decimals: 1);
        final color = switch (variation.trend) {
          Trend.up => c.warningText,
          Trend.down => c.successText,
          Trend.flat => c.ink,
        };
        text = Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: variation.text,
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
              TextSpan(text: ' par rapport à $reference.'),
            ],
          ),
          style: AppText.bodySm.copyWith(color: c.inkMuted),
        );
      }
    }
    return Container(
      key: const Key('bill.comparison'),
      padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s3),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.md)),
      ),
      child: Row(
        children: [
          AppIcon(AppIcons.energy, color: c.inkMuted),
          const SizedBox(width: Space.s3),
          Expanded(child: text),
        ],
      ),
    );
  }
}

/// Bas de l'écran, collé : Payer (si `can_pay`), « Paiement en cours », ou rien (payée, annulée,
/// simple lecteur). Hors ligne : Payer désactivé avec « Connexion nécessaire pour payer ».
class _Footer extends StatelessWidget {
  const _Footer({required this.fetched, required this.onPay});

  final Fetched<BillDetail> fetched;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bill = fetched.data;
    final Widget? action = switch (bill) {
      BillDetail(status: BillStatuses.pendingPayment) => const AppButton(
        label: 'Paiement en cours',
        icon: AppIcons.hourglass,
        variant: ButtonVariant.secondary,
        onPressed: null,
      ),
      BillDetail(canPay: true) => PayButton(
        amount: bill.amountTotal,
        online: fetched is FreshData<BillDetail>,
        onPay: onPay,
      ),
      _ => null,
    };
    if (action == null) return const SizedBox.shrink();
    return Container(
      key: const Key('bill.footer'),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.line)),
      ),
      padding: const EdgeInsets.fromLTRB(Space.s4, Space.s3, Space.s4, Space.s3),
      child: SafeArea(top: false, child: action),
    );
  }
}

/// Facture d'exemple du squelette de chargement (forme seulement, jamais affichée en clair).
const _skeletonBill = <String, Object?>{
  'id': 0,
  'reference': '20261103000127',
  'meter_id': 0,
  'meter_reference': '0412-8833',
  'meter_label': null,
  'household_id': 0,
  'household_name': 'Maison Mpita',
  'period_start': '2026-09-01',
  'period_end': '2026-10-31',
  'period_label': 'Sept.-Oct. 2026',
  'months_count': 2,
  'consumption_wh': 417400,
  'consumption_kwh': 417.4,
  'amount_total': 31420,
  'issued_at': '2026-11-03T07:00:00Z',
  'due_date': '2026-11-18',
  'status': 'unpaid',
  'days_overdue': 0,
  'paid_at': null,
  'my_role': 'owner',
  'can_pay': false,
  'source': 'simulated',
  'meter_contract_number': null,
  'meter_customer_number': null,
  'e2c_center': null,
  'previous_index_wh': 0,
  'current_index_wh': 0,
  'previous_index_kwh': 0.0,
  'current_index_kwh': 0.0,
  'billed_power_va': null,
  'amount_ht': 0,
  'amount_tax': 0,
  'amount_fees': 0,
  'lines': <Object?>[],
  'tariff': {'id': 0, 'code': '', 'label': '', 'price_per_kwh_milli': 0, 'is_assumption': false},
  'previous_bill': null,
  'cancelled_at': null,
  'cancelled_reason': null,
};
