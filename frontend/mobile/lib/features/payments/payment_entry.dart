import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/cache/cached_api.dart';
import '../../core/format/formats.dart';
import '../../core/models/bills.dart';
import '../../core/models/payments.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/bill_row.dart';
import '../../core/widgets/bottom_sheet.dart';
import '../../core/widgets/payment_sheet.dart';
import '../../core/widgets/statuses.dart';
import '../bills/bills_rules.dart';
import '../home/home_data.dart';
import '../home/home_rules.dart';
import 'payment_flow.dart';

/// Ce qu'il faut savoir d'une facture pour la payer (détail, carte de l'accueil, bouton central).
@immutable
class PayableBill {
  const PayableBill({
    required this.id,
    required this.amount,
    required this.periodStart,
    required this.periodEnd,
    required this.householdName,
    required this.online,
  });

  factory PayableBill.fromSummary(BillSummary bill, {required bool online}) => PayableBill(
    id: bill.id,
    amount: bill.amountTotal,
    periodStart: bill.periodStart,
    periodEnd: bill.periodEnd,
    householdName: bill.householdName,
    online: online,
  );

  factory PayableBill.fromDetail(BillDetail bill, {required bool online}) => PayableBill(
    id: bill.id,
    amount: bill.amountTotal,
    periodStart: bill.periodStart,
    periodEnd: bill.periodEnd,
    householdName: bill.householdName,
    online: online,
  );

  final int id;
  final int amount;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String householdName;

  /// `false` : données du cache → Payer désactivé (« Connexion nécessaire pour payer »).
  final bool online;
}

/// Ouvre la feuille de paiement de `bill` (écran 8). « Payer » passe par `PaymentFlow` (clé
/// d'idempotence, un seul envoi) ; dès qu'un paiement existe (ou que la réponse est inconnue),
/// la feuille se ferme et l'écran d'attente (9) s'ouvre. Un refus de l'API reste dans la feuille.
Future<void> startPayment(BuildContext context, WidgetRef ref, PayableBill bill) async {
  String defaultPhone;
  try {
    defaultPhone = (await ref.read(homeUserProvider.future)).data.phone;
  } on Object {
    defaultPhone = '';
  }
  if (!context.mounted) return;
  final router = GoRouter.of(context);
  final flow = ref.read(paymentFlowProvider(bill.id).notifier);
  // Une demande déjà en route pour cette facture : on rouvre son suivi, jamais une 2e demande.
  if (ref.read(paymentFlowProvider(bill.id)) case PaymentTracking() || PaymentUnknown()) {
    await router.push(Routes.payment(bill.id));
    return;
  }
  await showAppSheet<void>(
    context,
    child: Consumer(
      builder: (sheetContext, ref, _) {
        final state = ref.watch(paymentFlowProvider(bill.id));
        return PaymentSheetContent(
          periodLabel: formatBillPeriodShort(bill.periodStart, bill.periodEnd),
          householdName: bill.householdName,
          amount: bill.amount,
          defaultPhone: defaultPhone,
          online: bill.online,
          error: state is PaymentRefused ? state.message : null,
          onPay: (operator, phone) async {
            await flow.pay(PaymentRequest(billId: bill.id, operator: operator, phone: phone));
            if (!sheetContext.mounted) return;
            if (ref.read(paymentFlowProvider(bill.id)).phase != null) {
              Navigator.of(sheetContext).pop();
              await router.push(Routes.payment(bill.id));
            }
          },
        );
      },
    ),
  );
}

/// « Paiement en cours » (accueil, détail) : rouvre le suivi du paiement en attente de la facture,
/// sans jamais en lancer un nouveau. Le paiement est retrouvé par `GET /payments`.
Future<void> openPaymentInProgress(BuildContext context, WidgetRef ref, int billId) async {
  final router = GoRouter.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final flow = ref.read(paymentFlowProvider(billId).notifier);
  if (ref.read(paymentFlowProvider(billId)) is! PaymentTracking) {
    try {
      final page = await ref
          .read(cachedApiProvider)
          .get(
            '/payments',
            PaymentPage.fromJson,
            query: {'bill_id': billId, 'status': TransactionStatuses.pending, 'size': 1},
          );
      final pending = page.data.items.firstOrNull;
      if (pending == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Ce paiement est terminé. Actualisez pour voir la facture.'),
          ),
        );
        return;
      }
      await flow.follow(pending.id);
    } on Object {
      messenger.showSnackBar(
        const SnackBar(content: Text('Impossible de retrouver ce paiement. Réessayez.')),
      );
      return;
    }
  }
  await router.push(Routes.payment(billId));
}

/// Bouton Payer central de la barre du bas (D6.1) : aucune facture → message ; une seule → sa
/// feuille (ou son suivi si un paiement est en cours) ; plusieurs → « Quelle facture payer ? »,
/// les plus urgentes d'abord.
Future<void> payFromBottomBar(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final Fetched<BillList> toPay;
  try {
    toPay = await ref.read(toPayBillsProvider.future);
  } on Object {
    messenger.showSnackBar(
      const SnackBar(content: Text('Impossible de charger vos factures. Réessayez.')),
    );
    return;
  }
  if (!context.mounted) return;
  final online = toPay is FreshData<BillList>;
  final bills = sortedByUrgency(
    toPay.data.items.where((b) => b.canPay || b.status == BillStatuses.pendingPayment),
  );
  if (bills.isEmpty) {
    messenger.showSnackBar(const SnackBar(content: Text('Aucune facture à payer.')));
    return;
  }
  final bill = bills.length == 1
      ? bills.single
      : await showAppSheet<BillSummary>(context, child: _ChooseBill(bills: bills));
  if (bill == null || !context.mounted) return;
  if (bill.status == BillStatuses.pendingPayment) {
    await openPaymentInProgress(context, ref, bill.id);
  } else {
    await startPayment(context, ref, PayableBill.fromSummary(bill, online: online));
  }
}

/// Factures dans l'ordre d'urgence de l'accueil (en retard d'abord, puis l'échéance la plus proche).
List<BillSummary> sortedByUrgency(Iterable<BillSummary> bills) {
  final rest = bills.toList();
  final sorted = <BillSummary>[];
  while (rest.isNotEmpty) {
    final next = mostUrgentBill(rest) ?? rest.first;
    sorted.add(next);
    rest.remove(next);
  }
  return sorted;
}

class _ChooseBill extends StatelessWidget {
  const _ChooseBill({required this.bills});

  final List<BillSummary> bills;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text('Quelle facture payer ?', style: AppText.h2.copyWith(color: c.ink)),
        ),
        const SizedBox(height: Space.s3),
        for (final bill in bills)
          BillRow(
            key: Key('pay.choose.${bill.id}'),
            title:
                '${bill.householdName} · '
                '${formatBillPeriodShort(bill.periodStart, bill.periodEnd)}',
            subtitle: billRowSubtitle(bill),
            amount: bill.amountTotal,
            status: billStatus(bill.status),
            onTap: () => Navigator.of(context).pop(bill),
          ),
      ],
    );
  }
}
