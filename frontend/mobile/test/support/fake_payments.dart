import 'dart:async';

import 'package:elecpay/core/models/payments.dart';
import 'package:elecpay/features/payments/payment_flow.dart';
import 'package:flutter_test/flutter_test.dart';

import 'openapi.dart';

/// Un paiement au format du contrat (`PaymentPublic`).
PaymentPublic fakePayment(
  int id,
  String status, {
  String? reason,
  int amount = 31420,
  String step = 'requested',
  DateTime? pinEnteredAt,
}) => PaymentPublic.fromJson({
  ...OpenApi.load().sample('PaymentPublic'),
  'id': id,
  'status': status,
  'step': step,
  'failure_reason': reason,
  'amount': amount,
  'reference': 'TX-${id.toString().padLeft(8, '0')}',
  'operator_label': 'MTN MoMo',
  'phone_number': '+242061234567',
  'initiated_at': '2026-11-12T13:31:00Z',
  'pin_entered_at': pinEnteredAt?.toIso8601String(),
  'confirmed_at': status == TransactionStatuses.succeeded ? '2026-11-12T13:32:00Z' : null,
  'source': 'simulated',
});

/// Fausse passerelle de paiement : réponses programmées, demandes notées (avec leur clé).
/// Aucun réseau : elle remplace `paymentGatewayProvider` dans les tests.
class FakeGateway implements PaymentGateway {
  final creates = <(PaymentRequest, String)>[];
  final fetches = <int>[];

  /// Réponse de la prochaine demande : un paiement, ou une erreur à lever.
  final createReplies = <Object>[];

  /// État renvoyé par `fetch` (par défaut : toujours en attente).
  Object Function(int id) onFetch = (id) => fakePayment(id, TransactionStatuses.pending);
  Completer<void>? createGate;

  List<String> get keys => [for (final (_, key) in creates) key];

  @override
  Future<PaymentPublic> create(PaymentRequest request, {required String idempotencyKey}) async {
    creates.add((request, idempotencyKey));
    await createGate?.future;
    final reply = createReplies.isEmpty
        ? fakePayment(1, TransactionStatuses.pending)
        : createReplies.removeAt(0);
    if (reply is PaymentPublic) return reply;
    throw reply;
  }

  @override
  Future<PaymentPublic> fetch(int paymentId) async {
    fetches.add(paymentId);
    final reply = onFetch(paymentId);
    if (reply is PaymentPublic) return reply;
    throw reply;
  }
}

/// Horloge et attentes commandées par le test : chaque attente avance l'horloge et attend `tick()`.
class FakeTiming {
  DateTime now = DateTime.utc(2026, 11, 12, 9);
  final waits = <Duration>[];
  Completer<void>? _pending;

  Future<void> wait(Duration d) {
    waits.add(d);
    now = now.add(d);
    return (_pending = Completer<void>()).future;
  }

  /// Libère l'attente en cours, puis laisse le suivi avancer.
  Future<void> tick() async {
    final c = _pending;
    _pending = null;
    c?.complete();
    await pumpEventQueue();
  }

  /// Comme `tick`, sans attendre (tests d'écran : `tester.pump()` fait avancer ensuite).
  void release() {
    final c = _pending;
    _pending = null;
    c?.complete();
  }

  PaymentTiming get timing => PaymentTiming(now: () => now, wait: wait);
}
