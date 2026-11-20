import 'package:dio/dio.dart';
import 'package:elecpay/core/cache/cached_api.dart';
import 'package:elecpay/core/config/app_config.dart';
import 'package:elecpay/core/models/bills.dart';
import 'package:elecpay/core/models/payments.dart';
import 'package:elecpay/core/network/api_client.dart';
import 'package:elecpay/core/session/session_providers.dart';
import 'package:elecpay/features/home/home_data.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'fake_server.dart';
import 'memory_cache_store.dart';
import 'openapi.dart';

/// Faux backend des lectures de l'accueil : deux foyers, leurs factures, compteurs, consommation,
/// paiements et notifications, avec la forme exacte du contrat (exemples de `openapi.json`).
///
/// [down] : routes rendues injoignables (réseau coupé), pour vérifier que chaque carte se charge et
/// échoue SÉPARÉMENT.
class FakeHomeBackend {
  FakeHomeBackend() {
    server = FakeServer(_handle);
  }

  static final _api = OpenApi.load();
  late final FakeServer server;
  final store = MemoryCacheStore();

  /// Routes coupées : le chemin exact et ses sous-chemins (`/me` coupe `/me/…`, pas `/meters`).
  final Set<String> down = {};

  /// Réponses forcées par route exacte (prioritaires).
  final Map<String, FakeReply> forced = {};

  /// Maison Mpita (1, compteurs 10 et 11) et Boutique Tié-Tié (2, compteur 20).
  List<Map<String, Object?>> households = [
    {..._api.sample('HouseholdSummary'), 'id': 1, 'name': 'Maison Mpita'},
    {..._api.sample('HouseholdSummary'), 'id': 2, 'name': 'Boutique Tié-Tié'},
  ];

  Map<int, List<Map<String, Object?>>> meters = {
    1: [_meter(10, 1), _meter(11, 1)],
    2: [_meter(20, 2)],
  };

  /// Factures à payer de tous les foyers (`GET /bills?status=to_pay`).
  List<Map<String, Object?>> toPay = [
    bill(101, household: 1, meter: 11, due: '2026-11-18'),
    bill(201, household: 2, meter: 20, status: BillStatuses.overdue, due: '2026-10-20'),
  ];

  /// Dernières factures émises (`GET /bills` sans filtre).
  List<Map<String, Object?>> latestBills = [
    bill(101, household: 1, meter: 11, issued: '2026-11-03T08:00:00Z'),
  ];

  /// Factures payées (`GET /bills?status=paid`).
  List<Map<String, Object?>> paidBills = [
    bill(90, household: 1, meter: 11, status: BillStatuses.paid, due: '2026-09-18'),
  ];

  /// Détails (`GET /bills/{id}`) : la facture de la maquette de l'écran 7 sous l'identifiant 101.
  Map<int, Map<String, Object?>> billDetails = {
    101: billDetail(101),
    90: billDetail(90, periodStart: '2026-07-01', periodEnd: '2026-08-31', withPrevious: false),
  };

  /// Détail de la maquette de l'écran 7 (Maison Mpita, sept.–oct. 2026, 31 420 FCFA).
  static Map<String, Object?> billDetail(
    int id, {
    String status = BillStatuses.unpaid,
    bool canPay = true,
    bool tariffAssumption = true,
    bool withPrevious = true,
    String? cancelledReason,
    String periodStart = '2026-09-01',
    String periodEnd = '2026-10-31',
  }) {
    Map<String, Object?> line(
      int position,
      String kind,
      String label,
      int amount, {
      double? quantity,
      String? unit,
      double? unitPrice,
      double? rate,
    }) => {
      'position': position,
      'kind': kind,
      'label': label,
      'quantity_milli': quantity == null ? null : (quantity * 1000).round(),
      'quantity': quantity,
      'unit': unit,
      'unit_price_milli': unitPrice == null ? null : (unitPrice * 1000).round(),
      'unit_price': unitPrice,
      'rate_bp': rate == null ? null : (rate * 100).round(),
      'rate_percent': rate,
      'base_amount': null,
      'amount': amount,
    };
    return {
      ..._api.sample('BillDetail'),
      'id': id,
      'reference': '20261103000127',
      'household_id': 1,
      'household_name': 'Maison Mpita',
      'meter_id': 11,
      'meter_reference': '0412-8833',
      'meter_label': null,
      'period_start': periodStart,
      'period_end': periodEnd,
      'period_label': 'TEXTE API',
      'months_count': 2,
      'consumption_wh': 417400,
      'consumption_kwh': 417.4,
      'amount_total': 31420,
      'issued_at': '2026-11-03T07:00:00Z',
      'due_date': '2026-11-18',
      'status': status,
      'days_overdue': 0,
      'paid_at': status == BillStatuses.paid ? '2026-11-10T09:00:00Z' : null,
      'my_role': 'owner',
      'can_pay': canPay,
      'source': 'simulated',
      'previous_index_wh': 18247000,
      'current_index_wh': 18664400,
      'previous_index_kwh': 18247.0,
      'current_index_kwh': 18664.4,
      'amount_ht': 25585,
      'amount_tax': 4835,
      'amount_fees': 1000,
      'lines': [
        line(
          1,
          'energy',
          'Montant consommation',
          20485,
          quantity: 417.4,
          unit: 'kWh',
          unitPrice: 49.08,
        ),
        line(
          2,
          'fixed_fee',
          'Droit à la consommation',
          5100,
          quantity: 2,
          unit: 'mois',
          unitPrice: 2550,
        ),
        line(3, 'vat', 'T.V.A.', 4605, rate: 18),
        line(4, 'additional_tax', 'Centimes additionnels (C.A.)', 230, rate: 5),
        line(5, 'audiovisual_fee', 'Redevance audiovisuelle (RAV)', 1000),
        line(6, 'stamp', 'Timbre électronique', 0),
      ],
      'tariff': {..._api.sample('TariffPublic'), 'is_assumption': tariffAssumption},
      'previous_bill': withPrevious
          ? {
              ..._api.sample('PreviousBillComparison'),
              'bill_id': 90,
              'period_label': 'TEXTE API',
              'period_start': '2026-07-01',
              'period_end': '2026-08-31',
              'consumption_kwh': 415.0,
              'amount_total': 31281,
              'consumption_change_percent': 0.58,
            }
          : null,
      'cancelled_at': cancelledReason == null ? null : '2026-11-05T09:00:00Z',
      'cancelled_reason': cancelledReason,
    };
  }

  List<Map<String, Object?>> payments = [
    {
      ..._api.sample('PaymentPublic'),
      'id': 7,
      'status': TransactionStatuses.succeeded,
      'confirmed_at': '2026-09-10T09:00:00Z',
      'operator_label': 'MTN MoMo',
      'amount': 31281,
      'bill_id': 90,
      // Libellé de l'API : JAMAIS affiché (l'écran construit la période à partir des dates).
      'bill_period_label': 'TEXTE API',
      'bill_period_start': '2026-07-01',
      'bill_period_end': '2026-08-31',
    },
  ];

  int unread = 3;

  /// Réponses de `POST /payments`, dans l'ordre (vide : un paiement « en attente » n° 500).
  final paymentReplies = <FakeReply>[];

  /// État renvoyé par `GET /payments/{id}` (absent : 404 `PAYMENT_NOT_FOUND`).
  final Map<int, Map<String, Object?>> paymentStates = {};

  /// Consommation d'un jour (Wh) pour les séries de jour : 9 kWh par défaut, plus le week-end.
  int Function(DateTime day) dailyWh = (day) => day.weekday >= DateTime.saturday ? 11000 : 9000;

  /// Dernier jour relevé (les jours après n'ont pas de relevé).
  DateTime measuredUntil = DateTime(2026, 11, 11);

  /// Jours estimés (relevé manquant).
  final Set<DateTime> estimatedDays = {DateTime(2026, 10, 7)};

  /// Série au format du contrat, construite depuis `dailyWh` (jour, semaine ou mois).
  Map<String, Object?> seriesJson(int meterId, Map<String, dynamic> query) {
    final granularity = query['granularity'] as String? ?? 'month';
    final from = DateTime.parse(query['from'] as String);
    final to = DateTime.parse(query['to'] as String);
    String iso(DateTime x) =>
        '${x.year}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}';
    Map<String, Object?> point(DateTime start, DateTime end, String label) {
      var wh = 0;
      var days = 0;
      var estimated = false;
      for (var x = start; !x.isAfter(end); x = DateTime(x.year, x.month, x.day + 1)) {
        if (x.isAfter(measuredUntil)) continue;
        wh += dailyWh(x);
        days++;
        estimated = estimated || estimatedDays.contains(x);
      }
      return {
        'start': iso(start),
        'end': iso(end),
        'label': label,
        'consumption_wh': wh,
        'consumption_kwh': wh / 1000,
        'days_with_data': days,
        'daily_average_wh': days == 0 ? 0 : wh ~/ days,
        'energy_cost': wh * 49 ~/ 1000,
        'estimated_total': null,
        'is_current': !start.isAfter(measuredUntil) && !end.isBefore(measuredUntil),
        'is_partial': end.isAfter(measuredUntil),
        'is_estimated': estimated,
        'has_anomaly': false,
      };
    }

    final points = <Map<String, Object?>>[];
    var cursor = from;
    while (!cursor.isAfter(to)) {
      final end = switch (granularity) {
        'week' => cursor.add(const Duration(days: 6)),
        'month' => DateTime(cursor.year, cursor.month + 1, 0),
        _ => cursor,
      };
      points.add(point(cursor, end, iso(cursor)));
      cursor = DateTime(end.year, end.month, end.day + 1);
    }
    final total = points.fold<int>(0, (s, x) => s + (x['consumption_wh']! as int));
    final days = points.fold<int>(0, (s, x) => s + (x['days_with_data']! as int));
    return {
      'meter_id': meterId,
      'granularity': granularity,
      'start': iso(from),
      'end': iso(to),
      'measured_until': iso(measuredUntil),
      'points': points,
      'comparison': {
        'mode': granularity == 'month' ? 'last_year' : 'previous',
        'current': {
          'start': iso(from),
          'end': iso(to),
          'consumption_wh': total,
          'consumption_kwh': total / 1000,
          'days_with_data': days,
          'energy_cost': total * 49 ~/ 1000,
        },
        'reference': {
          'start': iso(from),
          'end': iso(to),
          'consumption_wh': total,
          'consumption_kwh': total / 1000,
          'days_with_data': days,
          'energy_cost': total * 49 ~/ 1000,
        },
        'variation_percent': 6.2,
      },
      'tariff_is_assumption': true,
      'source': 'simulated',
    };
  }

  /// Index du compteur à la fin d'un jour (Wh) : 18 000 kWh au 31 déc. 2025, puis `dailyWh`.
  int indexAtEndOf(DateTime day) {
    var index = 18000000;
    for (var x = DateTime(2026); !x.isAfter(day); x = DateTime(x.year, x.month, x.day + 1)) {
      index += dailyWh(x);
    }
    return index;
  }

  /// Relevés (`GET /meters/{id}/readings?from&to`) : un par jour relevé, lu le lendemain à 06:00
  /// (Brazzaville).
  Map<String, Object?> readingsJson(Map<String, dynamic> query) {
    final from = DateTime.parse(query['from'] as String);
    final to = DateTime.parse(query['to'] as String);
    String iso(DateTime x) =>
        '${x.year}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}';
    final items = <Map<String, Object?>>[
      for (var x = from; !x.isAfter(to); x = DateTime(x.year, x.month, x.day + 1))
        if (!x.isAfter(measuredUntil))
          {
            'id': x.day,
            'read_at': '${iso(DateTime(x.year, x.month, x.day + 1))}T05:00:00Z',
            'day': iso(x),
            'index_wh': indexAtEndOf(x),
            'consumption_wh': dailyWh(x),
            'consumption_kwh': dailyWh(x) / 1000,
            'source': 'simulated',
            'is_estimated': estimatedDays.contains(x),
            'is_anomaly': false,
            'anomaly_reason': null,
          },
    ];
    return {'items': items, 'page': 1, 'size': 31, 'total': items.length};
  }

  /// Détail d'un jour (`GET /meters/{id}/consumption/days/{day}`) ; jour sans relevé : 404.
  Map<String, Object?>? dayDetailJson(int meterId, DateTime day) {
    if (day.isAfter(measuredUntil)) return null;
    final wh = dailyWh(day);
    return {
      'meter_id': meterId,
      'day':
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
      'label': 'jour',
      'consumption_wh': wh,
      'consumption_kwh': wh / 1000,
      'energy_cost': wh * 49 ~/ 1000,
      'index_start_wh': indexAtEndOf(day) - wh,
      'index_end_wh': indexAtEndOf(day),
      'is_estimated': estimatedDays.contains(day),
      'is_anomaly': false,
      'anomaly_reason': null,
      'weekday_average_wh': 9500,
      'weekday_samples': 4,
      'rank_in_month': 3,
      'days_ranked': 30,
      'source': 'simulated',
    };
  }

  /// Reçus (`GET /receipts/{id}`) : celui de la maquette de l'écran 10 sous l'identifiant 3.
  Map<int, Map<String, Object?>> receipts = {3: receiptJson(3)};

  /// Reçu de la maquette (Maison Mpita, sept.–oct. 2026, 31 420 FCFA, numéro masqué).
  static Map<String, Object?> receiptJson(int id, {String source = 'simulated'}) => {
    ..._api.sample('ReceiptPublic'),
    'id': id,
    'number': 'EP-2026-000123',
    'issued_at': '2026-11-12T13:32:00Z',
    'amount': 31420,
    'verification_code': '8F3K-2Q9M-7XHT',
    'bill_id': 101,
    'bill_reference': '20261103000127',
    'bill_period_label': 'TEXTE API',
    'bill_period_start': '2026-09-01',
    'bill_period_end': '2026-10-31',
    'meter_reference': '0412-8833',
    'household_name': 'Maison Mpita',
    'payer_name': 'Loick Makosso',
    'operator_label': 'MTN MoMo',
    'phone_number': '+242 06 *** 45 67',
    'transaction_reference': 'TX-00000500',
    'source': source,
  };

  /// Un paiement au format du contrat (`PaymentPublic`).
  static Map<String, Object?> paymentJson(int id, String status, {String? reason}) => {
    ..._api.sample('PaymentPublic'),
    'id': id,
    'reference': 'TX-${id.toString().padLeft(8, '0')}',
    'bill_id': 101,
    'status': status,
    'failure_reason': reason,
    'amount': 31420,
    'operator_label': 'MTN MoMo',
    'phone_number': '+242061234567',
    'bill_period_start': '2026-09-01',
    'bill_period_end': '2026-10-31',
    'source': 'simulated',
  };

  /// Notifications (`GET /notifications`), de la plus récente à la plus ancienne.
  List<Map<String, Object?>> notifications = [
    notification(1, type: 'payment_succeeded', group: 'today', title: 'Paiement réussi'),
    notification(2, type: 'payment_failed', group: 'today', title: 'Paiement échoué'),
    notification(
      3,
      type: 'high_consumption',
      group: 'this_week',
      title: 'Consommation inhabituelle',
    ),
    notification(4, type: 'bill_issued', group: 'earlier', title: 'Nouvelle facture', read: true),
  ];

  static Map<String, Object?> notification(
    int id, {
    required String type,
    required String group,
    required String title,
    bool read = false,
    String createdAt = '2026-11-12T08:00:00Z',
  }) => {
    ..._api.sample('NotificationPublic'),
    'id': id,
    'type': type,
    'group': group,
    'title': title,
    'body': 'Texte de la notification $id.',
    'is_read': read,
    'read_at': read ? '2026-11-12T09:00:00Z' : null,
    'created_at': createdAt,
  };

  int get _unreadNotifications => notifications.where((n) => n['is_read'] != true).length;

  Map<String, Object?> user = {..._api.sample('UserPublic'), 'full_name': 'Loick Makosso'};

  static Map<String, Object?> _meter(int id, int household) => {
    ..._api.sample('MeterDetail'),
    'id': id,
    'household_id': household,
    'status': 'active',
  };

  static Map<String, Object?> bill(
    int id, {
    required int household,
    required int meter,
    String status = BillStatuses.unpaid,
    String due = '2026-11-18',
    String issued = '2026-11-03T08:00:00Z',
  }) => {
    ..._api.sample('BillSummary'),
    'id': id,
    'household_id': household,
    'household_name': household == 1 ? 'Maison Mpita' : 'Boutique Tié-Tié',
    'meter_id': meter,
    'status': status,
    'due_date': due,
    'issued_at': issued,
    'amount_total': 31420,
    'can_pay': status != BillStatuses.pendingPayment,
  };

  /// Requêtes reçues sur un chemin exact.
  List<RequestOptions> requestsTo(String path) =>
      server.requests.where((r) => r.path == path).toList();

  Map<String, Object?> _billList(List<Map<String, Object?>> items) => {
    'items': items,
    'outstanding': {
      ..._api.sample('Outstanding'),
      'count': toPay.length,
      'overdue_count': toPay.where((b) => b['status'] == BillStatuses.overdue).length,
    },
    'page': 1,
    'size': items.length,
    'total': items.length,
  };

  FakeReply _handle(RequestOptions request) {
    final path = request.path;
    final forcedReply = forced[path];
    if (forcedReply != null) return forcedReply;
    if (down.any((d) => path == d || path.startsWith('$d/'))) {
      return const FailReply(DioExceptionType.connectionError);
    }
    final query = request.queryParameters;
    final meterMatch = RegExp(r'^/meters/(\d+)/consumption(/summary)?$').firstMatch(path);
    final householdMeters = RegExp(r'^/households/(\d+)/meters$').firstMatch(path);
    if (path == '/me') return JsonReply(200, user);
    if (path == '/households') return JsonReply(200, households);
    if (householdMeters != null) {
      return JsonReply(200, meters[int.parse(householdMeters.group(1)!)] ?? <Object>[]);
    }
    if (path == '/bills') {
      final items = switch (query['status']) {
        BillFilters.toPay => toPay,
        BillFilters.overdue => toPay.where((b) => b['status'] == BillStatuses.overdue).toList(),
        BillFilters.paid => paidBills,
        _ => latestBills,
      };
      final page = query['page'] as int? ?? 1;
      final size = query['size'] as int? ?? 20;
      return JsonReply(200, {
        ..._billList(items.skip((page - 1) * size).take(size).toList()),
        'page': page,
        'size': size,
        'total': items.length,
      });
    }
    final pdfMatch = RegExp(r'^/bills/(\d+)/pdf$').firstMatch(path);
    if (pdfMatch != null) {
      if (!billDetails.containsKey(int.parse(pdfMatch.group(1)!))) {
        return JsonReply(404, apiError('BILL_NOT_FOUND', 'Facture introuvable.'));
      }
      return const RawReply(
        200,
        '%PDF-1.4 facture de démonstration',
        contentType: 'application/pdf',
      );
    }
    final billMatch = RegExp(r'^/bills/(\d+)$').firstMatch(path);
    if (billMatch != null) {
      final id = int.parse(billMatch.group(1)!);
      final detail = billDetails[id];
      if (detail == null) return JsonReply(404, apiError('BILL_NOT_FOUND', 'Facture introuvable.'));
      return JsonReply(200, detail);
    }
    if (meterMatch != null && meterMatch.group(2) != null) {
      return JsonReply(200, {
        ..._api.sample('ConsumptionSummary'),
        'meter_id': int.parse(meterMatch.group(1)!),
      });
    }
    if (meterMatch != null) {
      final meterId = int.parse(meterMatch.group(1)!);
      // Avec une plage (écran Consommation) : une vraie série ; sinon l'exemple du contrat.
      if (query['from'] != null && query['to'] != null) {
        return JsonReply(200, seriesJson(meterId, query));
      }
      return JsonReply(200, {..._api.sample('ConsumptionSeries'), 'meter_id': meterId});
    }
    final dayMatch = RegExp(r'^/meters/(\d+)/consumption/days/(\d{4}-\d{2}-\d{2})$')
        .firstMatch(path);
    if (dayMatch != null) {
      final detail = dayDetailJson(
        int.parse(dayMatch.group(1)!),
        DateTime.parse(dayMatch.group(2)!),
      );
      if (detail == null) {
        return JsonReply(404, apiError('CONSUMPTION_DAY_NOT_FOUND', 'Journée non relevée.'));
      }
      return JsonReply(200, detail);
    }
    if (RegExp(r'^/meters/\d+/readings$').hasMatch(path)) {
      return JsonReply(200, readingsJson(query));
    }
    if (path == '/payments' && request.method == 'POST') {
      if (paymentReplies.isNotEmpty) return paymentReplies.removeAt(0);
      final created = paymentJson(500, TransactionStatuses.pending);
      paymentStates[500] ??= created;
      return JsonReply(201, created);
    }
    final receiptMatch = RegExp(r'^/receipts/(\d+)$').firstMatch(path);
    if (receiptMatch != null) {
      final receipt = receipts[int.parse(receiptMatch.group(1)!)];
      if (receipt == null) {
        return JsonReply(404, apiError('RECEIPT_NOT_FOUND', 'Reçu introuvable.'));
      }
      return JsonReply(200, receipt);
    }
    final paymentMatch = RegExp(r'^/payments/(\d+)$').firstMatch(path);
    if (paymentMatch != null) {
      final state = paymentStates[int.parse(paymentMatch.group(1)!)];
      if (state == null) {
        return JsonReply(404, apiError('PAYMENT_NOT_FOUND', 'Paiement introuvable.'));
      }
      return JsonReply(200, state);
    }
    if (path == '/payments') {
      // Filtres de l'API : `status` et `bill_id` (comme GET /payments).
      final items = [
        for (final p in payments)
          if ((query['status'] == null || p['status'] == query['status']) &&
              (query['bill_id'] == null || p['bill_id'] == query['bill_id']))
            p,
      ];
      final page = query['page'] as int? ?? 1;
      final size = query['size'] as int? ?? 20;
      return JsonReply(200, {
        'items': items.skip((page - 1) * size).take(size).toList(),
        'page': page,
        'size': size,
        'total': items.length,
      });
    }
    if (path == '/receipts') {
      // Reçus de l'année demandée (`year`), comme GET /receipts.
      final year = query['year'] as int?;
      final items = [
        for (final r in receipts.values)
          if (year == null || (r['issued_at']! as String).startsWith('$year')) r,
      ];
      return JsonReply(200, {'items': items, 'page': 1, 'size': 100, 'total': items.length});
    }
    if (path == '/notifications/unread-count') return JsonReply(200, {'unread_count': unread});
    if (path == '/notifications' && request.method == 'GET') {
      final page = query['page'] as int? ?? 1;
      final size = query['size'] as int? ?? 20;
      return JsonReply(200, {
        'items': notifications.skip((page - 1) * size).take(size).toList(),
        'total': notifications.length,
        'page': page,
        'size': size,
        'unread_count': _unreadNotifications,
      });
    }
    final readOne = RegExp(r'^/notifications/(\d+)/read$').firstMatch(path);
    if (readOne != null && request.method == 'POST') {
      final id = int.parse(readOne.group(1)!);
      final index = notifications.indexWhere((n) => n['id'] == id);
      if (index < 0) return JsonReply(404, apiError('NOTIFICATION_NOT_FOUND', 'Introuvable.'));
      notifications[index] = {...notifications[index], 'is_read': true};
      unread = _unreadNotifications;
      return JsonReply(200, notifications[index]);
    }
    if (path == '/notifications/read-all' && request.method == 'POST') {
      final marked = _unreadNotifications;
      notifications = [
        for (final n in notifications) {...n, 'is_read': true},
      ];
      unread = 0;
      return JsonReply(200, {'marked': marked, 'unread_count': 0});
    }
    return JsonReply(404, apiError('NOT_FOUND', 'Route inconnue du faux backend : $path'));
  }

  /// Surcharges Riverpod : lectures de l'accueil branchées sur ce faux backend (utilisateur 42).
  List<Override> overrides({HouseholdChoiceStore? choices}) {
    final dio = createApiDio(AppConfig.parse('http://127.0.0.1:8000', release: false))
      ..httpClientAdapter = server;
    return [
      cachedApiProvider.overrideWithValue(
        CachedApi(api: ApiClient(dio), store: store, currentUserId: () async => 42),
      ),
      authenticatedApiProvider.overrideWithValue(ApiClient(dio)),
      householdChoiceStoreProvider.overrideWithValue(choices ?? MemoryHouseholdChoiceStore()),
    ];
  }
}

/// Foyer choisi, gardé en mémoire (au lieu du stockage sécurisé du téléphone).
class MemoryHouseholdChoiceStore implements HouseholdChoiceStore {
  MemoryHouseholdChoiceStore([this.saved]);

  int? saved;

  @override
  Future<int?> read() async => saved;

  @override
  Future<void> write(int householdId) async => saved = householdId;
}
