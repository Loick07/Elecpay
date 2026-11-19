import '../../core/models/bills.dart';
import '../../core/models/households.dart';
import '../../core/models/payments.dart';

// Règles de l'accueil (écran 5), sans réseau ni affichage : testées une à une
// (test/features/home/home_rules_test.dart). Décidées avec Loick le 19/11/2026 (découpage de F4).

/// Facture la plus urgente : d'abord une facture EN RETARD (la plus ancienne échéance), sinon celle à
/// payer (ou en cours de paiement) dont l'échéance est la plus proche. `null` : tout est payé.
BillSummary? mostUrgentBill(Iterable<BillSummary> bills) {
  const open = {BillStatuses.overdue, BillStatuses.unpaid, BillStatuses.pendingPayment};
  final candidates = bills.where((b) => open.contains(b.status)).toList();
  if (candidates.isEmpty) return null;
  int rank(BillSummary b) => b.status == BillStatuses.overdue ? 0 : 1;
  candidates.sort((a, b) {
    final byRank = rank(a).compareTo(rank(b));
    if (byRank != 0) return byRank;
    final byDue = a.dueDate.compareTo(b.dueDate); // plus ancienne / plus proche échéance d'abord
    if (byDue != 0) return byDue;
    final byPeriod = a.periodStart.compareTo(b.periodStart);
    return byPeriod != 0 ? byPeriod : a.id.compareTo(b.id);
  });
  return candidates.first;
}

/// Foyer montré par défaut : celui de la facture la plus urgente (tous foyers confondus), sinon le
/// premier foyer. `null` : aucun foyer (compte neuf → « Ajoutez votre premier compteur »).
int? defaultHouseholdId(List<HouseholdSummary> households, Iterable<BillSummary> toPay) {
  if (households.isEmpty) return null;
  final urgent = mostUrgentBill(toPay);
  if (urgent != null && households.any((h) => h.id == urgent.householdId)) {
    return urgent.householdId;
  }
  return households.first.id;
}

/// Foyer à montrer : le choix gardé s'il existe encore, sinon le foyer par défaut.
int? effectiveHouseholdId({
  required int? saved,
  required List<HouseholdSummary> households,
  required Iterable<BillSummary> toPay,
}) {
  if (saved != null && households.any((h) => h.id == saved)) return saved;
  return defaultHouseholdId(households, toPay);
}

/// Factures en retard dans UN AUTRE foyer que celui affiché (rappel « 1 facture en retard dans … »).
typedef OverdueElsewhere = ({int householdId, String householdName, int count});

List<OverdueElsewhere> overdueElsewhere(Iterable<BillSummary> toPay, int? shownHouseholdId) {
  final byHousehold = <int, OverdueElsewhere>{};
  for (final bill in toPay) {
    if (bill.status != BillStatuses.overdue || bill.householdId == shownHouseholdId) continue;
    final previous = byHousehold[bill.householdId];
    byHousehold[bill.householdId] = (
      householdId: bill.householdId,
      householdName: bill.householdName,
      count: (previous?.count ?? 0) + 1,
    );
  }
  return byHousehold.values.toList()..sort((a, b) => a.householdName.compareTo(b.householdName));
}

/// Ce que propose la carte de la facture urgente.
enum UrgentBillAction {
  /// Bouton « Payer … FCFA » (`can_pay`).
  pay,

  /// « Paiement en cours » à la place de Payer (jamais deux paiements à la fois).
  paymentInProgress,

  /// Ni l'un ni l'autre (ex. simple lecteur du foyer) : « Détail » seulement.
  none,
}

UrgentBillAction urgentBillAction(BillSummary bill) {
  if (bill.status == BillStatuses.pendingPayment) return UrgentBillAction.paymentInProgress;
  return bill.canPay ? UrgentBillAction.pay : UrgentBillAction.none;
}

/// Compteur de la carte « mois en cours » : celui de la facture urgente s'il est dans le foyer
/// affiché, sinon le premier compteur actif du foyer, sinon le premier. `null` : aucun compteur.
int? consumptionMeterId({required BillSummary? urgent, required List<MeterDetail> meters}) {
  if (meters.isEmpty) return null;
  if (urgent != null && meters.any((m) => m.id == urgent.meterId)) return urgent.meterId;
  return (meters.where((m) => m.status == 'active').firstOrNull ?? meters.first).id;
}

/// Prénom de « Bonjour Loick » : le premier mot du nom (le nom entier s'il n'a qu'un mot).
String greetingName(String fullName) {
  final words = fullName.trim().split(RegExp(r'\s+'));
  return words.first;
}

/// Rappel des retards dans un autre foyer : « 1 facture en retard dans Boutique Tié-Tié ».
String overdueElsewhereText(OverdueElsewhere o) =>
    '${o.count} facture${o.count > 1 ? 's' : ''} en retard dans ${o.householdName}';

/// Une ligne de « Activité récente » : un paiement réussi, ou une facture émise (comme la maquette).
sealed class ActivityItem {
  const ActivityItem();

  DateTime get at;
  int get amount;
}

/// « Facture de juillet–août payée · MTN MoMo · 10 sept. »
final class PaymentActivity extends ActivityItem {
  const PaymentActivity(this.payment);

  final PaymentPublic payment;

  @override
  DateTime get at => payment.confirmedAt ?? payment.initiatedAt;

  @override
  int get amount => payment.amount;
}

/// « Nouvelle facture de sept.–oct. · Maison Mpita · 3 nov. »
final class BillIssuedActivity extends ActivityItem {
  const BillIssuedActivity(this.bill);

  final BillSummary bill;

  @override
  DateTime get at => bill.issuedAt;

  @override
  int get amount => bill.amountTotal;
}

/// Les `limit` derniers événements : paiements RÉUSSIS et factures émises, du plus récent au plus
/// ancien. Une facture annulée n'est pas une « nouvelle facture ».
List<ActivityItem> recentActivity({
  required Iterable<PaymentPublic> payments,
  required Iterable<BillSummary> bills,
  int limit = 3,
}) {
  final items = <ActivityItem>[
    for (final p in payments)
      if (p.status == TransactionStatuses.succeeded) PaymentActivity(p),
    for (final b in bills)
      if (b.status != BillStatuses.cancelled) BillIssuedActivity(b),
  ]..sort((a, b) => b.at.compareTo(a.at));
  return items.take(limit).toList();
}
