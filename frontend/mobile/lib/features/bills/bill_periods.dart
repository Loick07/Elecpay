import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format/formats.dart';
import 'bills_data.dart';

// Libellés de période construits à partir des DATES, avec `formats.dart` (charte : « juil.–août
// 2026 »), jamais le texte de l'API (`bill_period_label`, `period_label`) : décision de Loick du
// 19/11/2026. Les paiements, reçus et la « facture précédente » n'ont pas les dates dans le contrat :
// on les lit sur la facture elle-même (`GET /bills/{id}`, en cache).

/// Période d'une facture (dates du calendrier, fin incluse).
typedef BillPeriod = ({DateTime start, DateTime end});

/// Période de la facture `billId`, lue sur son détail. `null` si elle est illisible (hors ligne sans
/// cache, facture d'un compteur détaché…) : l'écran écrit alors un texte sans période.
final billPeriodProvider = FutureProvider.family<BillPeriod?, int>((ref, billId) async {
  try {
    final bill = (await ref.watch(billDetailProvider(billId).future)).data;
    return (start: bill.periodStart, end: bill.periodEnd);
  } on Object {
    return null;
  }
});

/// « juil.–août 2026 », ou `null` si la période n'est pas connue.
String? billPeriodText(BillPeriod? period) =>
    period == null ? null : formatBillPeriodShort(period.start, period.end);
