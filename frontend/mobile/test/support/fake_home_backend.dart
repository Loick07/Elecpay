import 'package:dio/dio.dart';
import 'package:elecpay/core/cache/cached_api.dart';
import 'package:elecpay/core/config/app_config.dart';
import 'package:elecpay/core/models/bills.dart';
import 'package:elecpay/core/models/payments.dart';
import 'package:elecpay/core/network/api_client.dart';
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

  List<Map<String, Object?>> payments = [
    {
      ..._api.sample('PaymentPublic'),
      'id': 7,
      'status': TransactionStatuses.succeeded,
      'confirmed_at': '2026-09-10T09:00:00Z',
      'operator_label': 'MTN MoMo',
      'amount': 31281,
    },
  ];

  int unread = 3;

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
    if (path == '/me') return JsonReply(200, _api.sample('UserPublic'));
    if (path == '/households') return JsonReply(200, households);
    if (householdMeters != null) {
      return JsonReply(200, meters[int.parse(householdMeters.group(1)!)] ?? <Object>[]);
    }
    if (path == '/bills') {
      return JsonReply(200, _billList(query['status'] == BillFilters.toPay ? toPay : latestBills));
    }
    if (meterMatch != null && meterMatch.group(2) != null) {
      return JsonReply(200, {
        ..._api.sample('ConsumptionSummary'),
        'meter_id': int.parse(meterMatch.group(1)!),
      });
    }
    if (meterMatch != null) {
      return JsonReply(200, {
        ..._api.sample('ConsumptionSeries'),
        'meter_id': int.parse(meterMatch.group(1)!),
      });
    }
    if (path == '/payments') {
      return JsonReply(200, {'items': payments, 'page': 1, 'size': 3, 'total': payments.length});
    }
    if (path == '/notifications/unread-count') return JsonReply(200, {'unread_count': unread});
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
