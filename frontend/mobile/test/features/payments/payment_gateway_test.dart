import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:elecpay/app/riverpod_config.dart';
import 'package:elecpay/core/cache/cache_policy.dart';
import 'package:elecpay/core/models/payments.dart';
import 'package:elecpay/core/network/api_failure.dart';
import 'package:elecpay/core/widgets/payment_sheet.dart';
import 'package:elecpay/core/widgets/transaction_status_view.dart';
import 'package:elecpay/features/payments/payment_flow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_home_backend.dart';
import '../../support/fake_payments.dart';
import '../../support/fake_server.dart';

const request = PaymentRequest(billId: 101, operator: PaymentOperator.mtn, phone: '+242061234567');

/// La VRAIE passerelle (`ApiPaymentGateway`) sur le faux serveur : seul le réseau est simulé.
class Harness {
  Harness() {
    container = ProviderContainer(
      retry: noAutomaticRetry,
      overrides: [
        ...backend.overrides(),
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

  final backend = FakeHomeBackend();
  final timing = FakeTiming();
  late final ProviderContainer container;
  late final ProviderSubscription<PaymentFlowState> subscription;
  var _keys = 0;

  PaymentGateway get gateway => container.read(paymentGatewayProvider);
  PaymentFlow get flow => container.read(paymentFlowProvider(101).notifier);
  PaymentFlowState get state => container.read(paymentFlowProvider(101));

  List<RequestOptions> get posts =>
      backend.server.requests.where((r) => r.path == '/payments' && r.method == 'POST').toList();

  /// Corps JSON des demandes de paiement envoyées, dans l'ordre.
  List<Map<String, dynamic>> get postedBodies => [
    for (final (i, r) in backend.server.requests.indexed)
      if (r.path == '/payments' && r.method == 'POST')
        jsonDecode(backend.server.sentBodies[i]!) as Map<String, dynamic>,
  ];
}

void main() {
  test('la passerelle de l’application est celle de l’API (plus de passerelle « inactive »)', () {
    expect(Harness().gateway, isA<ApiPaymentGateway>());
  });

  group('POST /payments', () {
    test('corps : facture, opérateur, numéro — JAMAIS le montant ; clé en en-tête', () async {
      final h = Harness();
      final created = await h.gateway.create(request, idempotencyKey: 'cle-abc-12345678');
      expect(created.status, TransactionStatuses.pending);
      expect(h.postedBodies.single, {
        'bill_id': 101,
        'operator': 'mtn',
        'phone_number': '+242061234567',
      });
      expect(h.postedBodies.single.containsKey('amount'), isFalse);
      expect(h.posts.single.headers['Idempotency-Key'], 'cle-abc-12345678');
    });

    test('200 (même clé déjà reçue) : la même transaction, rien de nouveau', () async {
      final h = Harness();
      h.backend.paymentReplies.add(
        JsonReply(200, FakeHomeBackend.paymentJson(500, TransactionStatuses.pending)),
      );
      final again = await h.gateway.create(request, idempotencyKey: 'cle-abc-12345678');
      expect(again.id, 500);
    });

    final refusals = <String, (int, String)>{
      'numéro d’un autre opérateur': (422, 'OPERATOR_MISMATCH'),
      'facture déjà payée': (409, 'BILL_ALREADY_PAID'),
      'facture annulée': (409, 'BILL_NOT_PAYABLE'),
      'lecteur du foyer': (403, 'PAYMENT_FORBIDDEN'),
      'clé déjà utilisée pour une autre demande': (409, 'IDEMPOTENCY_KEY_REUSED'),
    };
    for (final MapEntry(key: name, value: (status, code)) in refusals.entries) {
      test('refus « $name » ($status $code) : message de l’API, rien n’est suivi', () async {
        final h = Harness();
        h.backend.paymentReplies.add(JsonReply(status, apiError(code, 'Refus : $name.')));
        await h.flow.pay(request);
        expect(h.state, isA<PaymentRefused>());
        expect((h.state as PaymentRefused).message, 'Refus : $name.');
        expect(h.backend.server.requests.where((r) => r.path.startsWith('/payments/')), isEmpty);
      });
    }

    test('trop de demandes (429) : refus, sans relance automatique', () async {
      final h = Harness();
      h.backend.paymentReplies.add(
        JsonReply(
          429,
          apiError('TOO_MANY_ATTEMPTS', 'Trop de demandes.'),
          headers: {'Retry-After': '60'},
        ),
      );
      await h.flow.pay(request);
      expect(h.state, isA<PaymentRefused>());
      expect((h.state as PaymentRefused).failure, isA<TooManyRequests>());
      expect(h.posts, hasLength(1));
    });

    test('paiement déjà en cours (409 + transaction_id) : on suit celui-là, par GET', () async {
      final h = Harness();
      h.backend
        ..paymentReplies.add(
          JsonReply(
            409,
            apiError('PAYMENT_IN_PROGRESS', 'Paiement en cours.', {'transaction_id': 77}),
          ),
        )
        ..paymentStates[77] = FakeHomeBackend.paymentJson(77, TransactionStatuses.pending);
      await h.flow.pay(request);
      expect(h.state, isA<PaymentTracking>());
      expect((h.state as PaymentTracking).payment.id, 77);
      expect(h.posts, hasLength(1));
    });

    test('délai dépassé : « Vérification en cours », renvoi avec la MÊME clé', () async {
      final h = Harness();
      h.backend.paymentReplies.add(const FailReply(DioExceptionType.receiveTimeout));
      await h.flow.pay(request);
      expect(h.state, isA<PaymentUnknown>());
      expect(h.state.phase, TransactionPhase.unknown, reason: 'jamais « Échoué » sur un délai');
      await h.flow.checkAgain();
      expect(h.posts, hasLength(2));
      expect(h.posts[1].headers['Idempotency-Key'], h.posts[0].headers['Idempotency-Key']);
      expect(h.state, isA<PaymentTracking>());
    });

    test(
      'prestataire injoignable (201 « échouée ») : Échoué, « Réessayer » = nouvelle clé',
      () async {
        final h = Harness();
        h.backend.paymentReplies.add(
          JsonReply(
            201,
            FakeHomeBackend.paymentJson(
              501,
              TransactionStatuses.failed,
              reason: 'Service de paiement injoignable : aucun débit n’a été demandé.',
            ),
          ),
        );
        await h.flow.pay(request);
        expect(h.state.phase, TransactionPhase.failed);
        await h.flow.retry();
        expect(h.posts, hasLength(2));
        expect(h.posts[1].headers['Idempotency-Key'], isNot(h.posts[0].headers['Idempotency-Key']));
      },
    );
  });

  group('GET /payments/{id} : toujours en direct', () {
    test('jamais rangé dans le cache hors ligne (règle de cache_policy.dart)', () {
      expect(isCacheable('/payments/500'), isFalse);
      expect(neverCachedRoutes, contains('/payments/{payment_id}'));
    });

    test('suivi de bout en bout : demande, puis lectures jusqu’au succès', () async {
      final h = Harness();
      unawaited(h.flow.pay(request));
      await pumpEventQueue();
      expect(h.state, isA<PaymentTracking>());
      h.backend.paymentStates[500] = FakeHomeBackend.paymentJson(
        500,
        TransactionStatuses.succeeded,
      );
      await h.timing.tick();
      expect(h.state.phase, TransactionPhase.succeeded);
      expect(h.backend.requestsTo('/payments/500'), hasLength(1));
      expect(h.posts, hasLength(1));
    });

    test('lecture impossible (réseau coupé) : rien du cache, le suivi continue', () async {
      final h = Harness();
      unawaited(h.flow.pay(request));
      await pumpEventQueue();
      await h.timing.tick(); // une lecture réussie : elle n'est PAS gardée pour le hors ligne
      h.backend.down.add('/payments/500');
      await h.timing.tick();
      expect(h.state, isA<PaymentTracking>());
      expect(h.state.phase, TransactionPhase.pending);
      expect(
        (h.backend.store.users[42]?.keys ?? const <String>[]).where(
          (k) => k.startsWith('/payments/'),
        ),
        isEmpty,
        reason: 'GET /payments/{id} jamais en cache',
      );
    });
  });
}
