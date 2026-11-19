import 'dart:async';
import 'dart:math';

import 'package:elecpay/app/riverpod_config.dart';
import 'package:elecpay/core/models/payments.dart';
import 'package:elecpay/core/network/api_failure.dart';
import 'package:elecpay/core/network/models/api_error.dart';
import 'package:elecpay/core/widgets/payment_sheet.dart';
import 'package:elecpay/core/widgets/transaction_status_view.dart';
import 'package:elecpay/features/payments/payment_flow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/openapi.dart';

PaymentPublic payment(int id, String status, {String? reason}) => PaymentPublic.fromJson({
  ...OpenApi.load().sample('PaymentPublic'),
  'id': id,
  'status': status,
  'failure_reason': reason,
});

const request = PaymentRequest(billId: 101, operator: PaymentOperator.mtn, phone: '+242061234567');

/// Fausse passerelle : réponses programmées, demandes notées (avec leur clé).
class FakeGateway implements PaymentGateway {
  final creates = <(PaymentRequest, String)>[];
  final fetches = <int>[];

  /// Réponse de la prochaine demande : un paiement, ou une erreur à lever.
  final createReplies = <Object>[];

  /// État renvoyé par `fetch` (par défaut : toujours en attente).
  Object Function(int id) onFetch = (id) => payment(id, TransactionStatuses.pending);
  Completer<void>? createGate;

  @override
  Future<PaymentPublic> create(PaymentRequest request, {required String idempotencyKey}) async {
    creates.add((request, idempotencyKey));
    await createGate?.future;
    final reply = createReplies.isEmpty
        ? payment(1, TransactionStatuses.pending)
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

  PaymentTiming get timing => PaymentTiming(now: () => now, wait: wait);
}

class Harness {
  Harness() {
    container = ProviderContainer(
      retry: noAutomaticRetry,
      overrides: [
        paymentGatewayProvider.overrideWithValue(gateway),
        paymentTimingProvider.overrideWithValue(timing.timing),
        idempotencyKeyProvider.overrideWithValue(() => 'cle-${++_keys}-0000000'),
      ],
    );
    subscription = container.listen(paymentFlowProvider(101), (_, _) {});
    addTearDown(() {
      subscription.close();
      container.dispose();
    });
  }

  final gateway = FakeGateway();
  final timing = FakeTiming();
  late final ProviderContainer container;
  late final ProviderSubscription<PaymentFlowState> subscription;
  var _keys = 0;

  PaymentFlow get flow => container.read(paymentFlowProvider(101).notifier);
  PaymentFlowState get state => container.read(paymentFlowProvider(101));
  List<String> get keys => [for (final (_, key) in gateway.creates) key];
}

ApiRejected rejected(int status, String code, [Map<String, Object?> details = const {}]) =>
    ApiRejected(
      statusCode: status,
      body: ErrorBody(code: code, message: 'Refus $code.', details: details),
    );

void main() {
  test('clé d’idempotence : format de l’API, une différente à chaque fois', () {
    final pattern = RegExp(r'^[A-Za-z0-9_-]{8,64}$');
    final keys = {for (var i = 0; i < 50; i++) newIdempotencyKey()};
    expect(keys, hasLength(50));
    expect(keys.every(pattern.hasMatch), isTrue);
    expect(newIdempotencyKey(Random(1)), newIdempotencyKey(Random(1)));
  });

  test('par défaut, AUCUN paiement réel ne part (arrêt avant POST /payments)', () async {
    final container = ProviderContainer(retry: noAutomaticRetry);
    addTearDown(container.dispose);
    final sub = container.listen(paymentFlowProvider(101), (_, _) {});
    addTearDown(sub.close);
    await container.read(paymentFlowProvider(101).notifier).pay(request);
    final state = container.read(paymentFlowProvider(101));
    expect(state, isA<PaymentRefused>());
    expect((state as PaymentRefused).message, NotYetConnectedPaymentGateway.message);
  });

  group('parcours réussi', () {
    test('une demande, suivie toutes les 3 s, jusqu’au succès', () async {
      final h = Harness();
      var calls = 0;
      h.gateway.onFetch = (id) =>
          payment(id, ++calls < 3 ? TransactionStatuses.pending : TransactionStatuses.succeeded);
      unawaited(h.flow.pay(request));
      await pumpEventQueue();
      expect(h.state, isA<PaymentTracking>());
      expect(h.state.phase, TransactionPhase.pending);
      for (var i = 0; i < 3; i++) {
        await h.timing.tick();
      }
      expect(h.state, isA<PaymentFinished>());
      expect(h.state.phase, TransactionPhase.succeeded);
      expect(h.gateway.creates, hasLength(1));
      expect(h.timing.waits.toSet(), {const Duration(seconds: 3)});
    });

    test('réussi : « Payer » ne relance rien', () async {
      final h = Harness();
      h.gateway.createReplies.add(payment(1, TransactionStatuses.succeeded));
      await h.flow.pay(request);
      await h.flow.pay(request);
      await h.flow.retry();
      expect(h.gateway.creates, hasLength(1));
    });
  });

  group('jamais deux paiements', () {
    test('double toucher : une seule demande', () async {
      final h = Harness();
      h.gateway.createGate = Completer<void>();
      unawaited(h.flow.pay(request));
      unawaited(h.flow.pay(request));
      await pumpEventQueue();
      expect(h.state, isA<PaymentSending>());
      h.gateway.createGate!.complete();
      await pumpEventQueue();
      expect(h.gateway.creates, hasLength(1));
    });

    test('pendant le suivi : « Payer » ne crée aucune nouvelle demande', () async {
      final h = Harness();
      unawaited(h.flow.pay(request));
      await pumpEventQueue();
      await h.flow.pay(request);
      await h.flow.retry();
      expect(h.gateway.creates, hasLength(1));
    });
  });

  group('après Échoué ou Expiré : NOUVELLE demande, NOUVELLE clé', () {
    for (final status in [TransactionStatuses.failed, TransactionStatuses.expired]) {
      test(status, () async {
        final h = Harness();
        h.gateway.createReplies.add(payment(1, status, reason: 'Solde insuffisant'));
        await h.flow.pay(request);
        expect(h.state.phase, TransactionPhase.fromStatus(status));
        expect((h.state as PaymentFinished).canRetry, isTrue);
        h.gateway.createReplies.add(payment(2, TransactionStatuses.succeeded));
        await h.flow.retry();
        expect(h.gateway.creates, hasLength(2));
        expect(h.keys[0], isNot(h.keys[1]));
        expect(h.state.phase, TransactionPhase.succeeded);
      });
    }
  });

  group('réponse inconnue : JAMAIS « Échoué », jamais de nouvelle demande, même clé', () {
    final unknowns = <String, Object>{
      'délai dépassé (la demande a pu arriver)': const ApiTimeout(mayHaveReachedServer: true),
      'réseau coupé': const NoConnection(),
      'panne du serveur': const ServerUnavailable(statusCode: 503),
    };
    for (final MapEntry(key: name, value: failure) in unknowns.entries) {
      test(name, () async {
        final h = Harness();
        h.gateway.createReplies.add(failure);
        await h.flow.pay(request);
        expect(h.state, isA<PaymentUnknown>());
        expect(h.state.phase, TransactionPhase.unknown, reason: 'jamais « Échoué »');
        // « Payer » de nouveau : rien (jamais une nouvelle demande).
        await h.flow.pay(request);
        await h.flow.retry();
        expect(h.gateway.creates, hasLength(1));
        // Vérifier : la MÊME demande, avec la MÊME clé (l'API rend la même transaction).
        h.gateway.createReplies.add(payment(1, TransactionStatuses.pending));
        await h.flow.checkAgain();
        expect(h.gateway.creates, hasLength(2));
        expect(h.keys[1], h.keys[0]);
        expect(h.gateway.creates[1].$1, request);
        expect(h.state, isA<PaymentTracking>());
      });
    }

    test('paiement connu : on le relit, sans rien renvoyer', () async {
      final h = Harness();
      h.gateway.createReplies.add(rejected(409, 'PAYMENT_IN_PROGRESS', {'transaction_id': 77}));
      h.gateway.onFetch = (id) => const NoConnection();
      await h.flow.pay(request);
      expect(h.state, isA<PaymentUnknown>());
      expect((h.state as PaymentUnknown).paymentId, 77);
      h.gateway.onFetch = (id) => payment(id, TransactionStatuses.pending);
      await h.flow.checkAgain();
      expect(h.gateway.creates, hasLength(1));
      expect(h.gateway.fetches.last, 77);
      expect(h.state, isA<PaymentTracking>());
    });
  });

  test('paiement déjà en cours sur la facture (409) : on suit celui-là', () async {
    final h = Harness();
    h.gateway.createReplies.add(rejected(409, 'PAYMENT_IN_PROGRESS', {'transaction_id': 77}));
    await h.flow.pay(request);
    expect(h.gateway.fetches, [77]);
    expect(h.state, isA<PaymentTracking>());
    expect((h.state as PaymentTracking).payment.id, 77);
  });

  test('refus de l’API (numéro d’un autre opérateur) : message, puis nouvelle clé', () async {
    final h = Harness();
    h.gateway.createReplies.add(rejected(422, 'OPERATOR_MISMATCH'));
    await h.flow.pay(request);
    expect(h.state, isA<PaymentRefused>());
    expect((h.state as PaymentRefused).message, 'Refus OPERATOR_MISMATCH.');
    expect(h.state.phase, isNull, reason: 'rien n’a été débité : pas d’écran de suivi');
    const fixed = PaymentRequest(
      billId: 101,
      operator: PaymentOperator.airtel,
      phone: '+242051234567',
    );
    await h.flow.pay(fixed);
    expect(h.gateway.creates, hasLength(2));
    expect(h.keys[0], isNot(h.keys[1]));
  });

  group('après 2 min : « Vérification en cours », suivi toutes les 15 s', () {
    test('le suivi continue jusqu’à l’état final', () async {
      final h = Harness();
      var calls = 0;
      // 40 lectures « en attente » × 3 s = 2 min, puis encore 3 lectures lentes, puis expiré.
      h.gateway.onFetch = (id) =>
          payment(id, ++calls < 44 ? TransactionStatuses.pending : TransactionStatuses.expired);
      unawaited(h.flow.pay(request));
      await pumpEventQueue();
      for (var i = 0; i < 40; i++) {
        await h.timing.tick();
      }
      expect(h.state, isA<PaymentTracking>());
      expect((h.state as PaymentTracking).slow, isTrue);
      expect(h.state.phase, TransactionPhase.unknown);
      for (var i = 0; i < 4; i++) {
        await h.timing.tick();
      }
      expect(h.state.phase, TransactionPhase.expired);
      expect(h.timing.waits.take(40).toSet(), {const Duration(seconds: 3)});
      expect(h.timing.waits.skip(40).toSet(), {const Duration(seconds: 15)});
    });

    test('lectures en échec pendant le suivi : jamais « Échoué », on continue', () async {
      final h = Harness();
      h.gateway.onFetch = (id) => const ApiTimeout(mayHaveReachedServer: true);
      unawaited(h.flow.pay(request));
      await pumpEventQueue();
      for (var i = 0; i < 5; i++) {
        await h.timing.tick();
      }
      expect(h.state, isA<PaymentTracking>());
      expect(h.state.phase, TransactionPhase.pending);
      h.gateway.onFetch = (id) => payment(id, TransactionStatuses.succeeded);
      await h.timing.tick();
      expect(h.state.phase, TransactionPhase.succeeded);
    });
  });

  test('écran d’attente fermé : le suivi s’arrête ; rouvert : il reprend', () async {
    final h = Harness();
    unawaited(h.flow.pay(request));
    await pumpEventQueue();
    await h.timing.tick();
    final before = h.gateway.fetches.length;
    h.flow.stop();
    await h.timing.tick();
    await h.timing.tick();
    expect(h.gateway.fetches.length, before, reason: 'aucune interrogation écran fermé');
    expect(h.state, isA<PaymentTracking>(), reason: 'l’état connu est gardé');
    h.flow.resume();
    await pumpEventQueue();
    await h.timing.tick();
    expect(h.gateway.fetches.length, before + 1);
    expect(h.gateway.creates, hasLength(1), reason: 'reprendre ne paie jamais une 2e fois');
  });

  test('l’état survit à la fermeture de la feuille (personne n’écoute un instant)', () async {
    final h = Harness();
    h.gateway.createReplies.add(payment(1, TransactionStatuses.failed));
    await h.flow.pay(request);
    h.subscription.close();
    await pumpEventQueue();
    expect(h.container.read(paymentFlowProvider(101)), isA<PaymentFinished>());
  });

  test('suivre un paiement lancé ailleurs (rouvert depuis l’accueil)', () async {
    final h = Harness();
    await h.flow.follow(55);
    expect(h.gateway.fetches, [55]);
    expect(h.gateway.creates, isEmpty);
    expect(h.state, isA<PaymentTracking>());
  });
}
