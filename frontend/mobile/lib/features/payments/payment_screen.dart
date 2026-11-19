import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/demo/demo_mode.dart';
import '../../core/format/formats.dart';
import '../../core/models/payments.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/bottom_nav.dart';
import '../../core/widgets/demo_badge.dart';
import '../../core/widgets/state_block.dart';
import '../../core/widgets/transaction_status_view.dart';
import '../bills/bills_data.dart';
import '../bills/bills_rules.dart';
import '../home/home_data.dart';
import 'payment_flow.dart';

/// Écran 9 : suivi d'un paiement (maquette `Attente.dc.html`). Tant qu'il est ouvert, le paiement
/// est suivi (3 s, puis 15 s après 2 min) ; fermé, le suivi s'arrête. Toujours une sortie qui ne
/// paie rien (« Retour à l'accueil »), jamais « Payer » pendant un paiement en cours.
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({required this.billId, super.key});

  final int billId;

  /// Intervalle de vérification automatique quand seul l'identifiant du paiement est connu.
  static const recheckEvery = Duration(seconds: 15);

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  late final PaymentFlow _flow = ref.read(paymentFlowProvider(widget.billId).notifier);
  Timer? _recheck;

  @override
  void initState() {
    super.initState();
    _flow.resume();
    // Réponse inconnue, paiement connu : on relit (lecture seule) régulièrement, écran ouvert.
    _recheck = Timer.periodic(PaymentScreen.recheckEvery, (_) {
      if (ref.read(paymentFlowProvider(widget.billId)) case PaymentUnknown(paymentId: _?)) {
        unawaited(_flow.checkAgain());
      }
    });
  }

  @override
  void dispose() {
    _recheck?.cancel();
    _flow.stop();
    super.dispose();
  }

  void _refreshBills() {
    ref
      ..invalidate(toPayBillsProvider)
      ..invalidate(billDetailProvider(widget.billId))
      ..invalidate(billCountsProvider)
      ..invalidate(recentActivityProvider);
    for (final filter in BillsFilter.values) {
      ref.invalidate(billsProvider(filter));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Réponse finale : la facture, l'accueil et les listes sont relus (D6.4).
    ref.listen(paymentFlowProvider(widget.billId), (previous, next) {
      if (next is PaymentFinished && previous is! PaymentFinished) _refreshBills();
    });
    final state = ref.watch(paymentFlowProvider(widget.billId));
    final bill = ref.watch(billDetailProvider(widget.billId)).value?.data;
    final c = context.colors;
    final payment = switch (state) {
      PaymentTracking(:final payment) || PaymentFinished(:final payment) => payment,
      _ => null,
    };
    final request = switch (state) {
      PaymentUnknown(:final request) => request,
      PaymentFinished(:final request) => request,
      PaymentSending(:final request) => request,
      _ => null,
    };
    final phase = state.phase;
    final showDemo =
        payment?.source == 'simulated' || ref.watch(demoModeProvider).showBadge;

    return Scaffold(
      appBar: AppBar(
        title: Text(phase == TransactionPhase.pending ? 'Paiement en cours' : 'Paiement'),
        actions: [
          if (showDemo)
            const Padding(padding: EdgeInsets.only(right: Space.s4), child: DemoBadge()),
        ],
      ),
      body: SafeArea(
        child: phase == null
            ? ListView(
                children: [
                  StateBlock.empty(
                    icon: AppIcons.securePay,
                    title: 'Aucun paiement en cours',
                    message: 'Ouvrez une facture pour la payer.',
                    actionLabel: 'Retour à l’accueil',
                    onAction: () => context.go(AppTab.home.path),
                  ),
                ],
              )
            : ListView(
                key: const Key('payment.screen'),
                padding: const EdgeInsets.symmetric(vertical: Space.s6),
                children: [
                  TransactionStatusView(
                    phase: phase,
                    amount: payment?.amount ?? bill?.amountTotal ?? 0,
                    operatorLabel: payment?.operatorLabel ?? request?.operator.label ?? 'Mobile Money',
                    phone: payment?.phoneNumber ?? request?.phone ?? '',
                    reference: payment?.reference ?? 'Référence en attente',
                    failureReason: payment?.failureReason,
                    onViewReceipt: () => context.push(Routes.pending('Reçu', 'F6.4')),
                    onRetry: state is PaymentFinished && state.canRetry ? _flow.retry : null,
                    onHome: () => context.go(AppTab.home.path),
                  ),
                  if (state case PaymentUnknown(paymentId: null)) ...[
                    const SizedBox(height: Space.s4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Space.s6),
                      child: AppButton(
                        key: const Key('payment.check'),
                        label: 'Vérifier le paiement',
                        icon: AppIcons.retry,
                        variant: ButtonVariant.secondary,
                        onPressed: _flow.checkAgain,
                      ),
                    ),
                    const SizedBox(height: Space.s2),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Space.s6),
                      child: Text(
                        'La vérification renvoie la même demande : vous ne serez jamais débité '
                        'deux fois.',
                        textAlign: TextAlign.center,
                        style: AppText.caption.copyWith(color: c.inkMuted),
                      ),
                    ),
                  ],
                  if (payment != null) ...[
                    const SizedBox(height: Space.s6),
                    _Steps(payment: payment),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Les 3 étapes de la maquette : demande envoyée, validation par code PIN, reçu disponible.
class _Steps extends StatelessWidget {
  const _Steps({required this.payment});

  final PaymentPublic payment;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    String time(DateTime? t) => t == null ? '' : formatTime(t);
    final succeeded = payment.status == TransactionStatuses.succeeded;
    final ended = isFinalStatus(payment.status);
    final steps = <(String, String, bool)>[
      ('Demande envoyée à ${payment.operatorLabel}', time(payment.initiatedAt), true),
      (
        'Validation avec votre code PIN',
        payment.pinEnteredAt != null ? time(payment.pinEnteredAt) : (ended ? '' : 'En attente'),
        payment.pinEnteredAt != null,
      ),
      ('Reçu disponible', succeeded ? time(payment.confirmedAt) : '', succeeded),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, (label, at, done)) in steps.indexed)
            Semantics(
              container: true,
              label: '${i + 1}. $label${at.isEmpty ? '' : ', $at'}${done ? ', fait' : ''}',
              excludeSemantics: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.s2),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: done ? c.successSoft : c.surface2,
                        shape: BoxShape.circle,
                      ),
                      child: done ? AppIcon(AppIcons.check, size: 14, color: c.success) : null,
                    ),
                    const SizedBox(width: Space.s3),
                    Expanded(
                      child: Text(
                        label,
                        style: AppText.bodySm.copyWith(color: done ? c.ink : c.inkMuted),
                      ),
                    ),
                    if (at.isNotEmpty)
                      Text(at, style: AppText.caption.copyWith(color: c.inkMuted)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
