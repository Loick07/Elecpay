import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/payments.dart';
import '../../core/network/api_failure.dart';
import '../../core/widgets/payment_sheet.dart';
import '../../core/widgets/transaction_status_view.dart';

// Paiement Mobile Money d'une facture (écrans 8 et 9), règles de AUTONOMIE.md (section 4) et de
// PLAN.md (F6), toutes testées (test/features/payments/payment_flow_test.dart) :
// - une clé d'idempotence par tentative ; double toucher = une seule demande ;
// - après Échoué ou Expiré : nouvelle demande, NOUVELLE clé ;
// - après une réponse inconnue : JAMAIS de nouvelle demande ; on consulte le paiement, et un
//   renvoi garde LA MÊME clé (l'API rend alors la même transaction : jamais un second débit) ;
// - jamais « Échoué » sur un délai dépassé ;
// - suivi toutes les 3 s ; après 2 min sans réponse finale : « Vérification en cours », et le suivi
//   continue plus lentement (environ toutes les 15 s) tant que l'écran est ouvert.

/// Ce que l'abonné demande : payer `billId` avec `operator`, depuis `phone` (normalisé, « +242… »).
/// Le montant n'est JAMAIS envoyé : c'est celui de la facture.
@immutable
class PaymentRequest {
  const PaymentRequest({required this.billId, required this.operator, required this.phone});

  final int billId;
  final PaymentOperator operator;
  final String phone;

  @override
  bool operator ==(Object other) =>
      other is PaymentRequest &&
      other.billId == billId &&
      other.operator == operator &&
      other.phone == phone;

  @override
  int get hashCode => Object.hash(billId, operator, phone);
}

/// Accès aux paiements de l'API (`POST /payments`, `GET /payments/{id}`), remplacé par un faux
/// dans les tests.
abstract interface class PaymentGateway {
  /// Demande un paiement (`Idempotency-Key: idempotencyKey`). Erreurs : `ApiFailure`.
  Future<PaymentPublic> create(PaymentRequest request, {required String idempotencyKey});

  /// État d'un paiement, toujours lu en direct (jamais en cache).
  Future<PaymentPublic> fetch(int paymentId);
}

/// Le paiement réel n'est PAS encore branché : arrêt prévu par Loick avant `POST /payments`
/// (AUTONOMIE.md, section 3). Aucune requête ne part ; la demande est refusée avec un message clair.
class NotYetConnectedPaymentGateway implements PaymentGateway {
  const NotYetConnectedPaymentGateway();

  static const message = 'Le paiement n’est pas encore activé dans cette version.';

  @override
  Future<PaymentPublic> create(PaymentRequest request, {required String idempotencyKey}) =>
      Future.error(const PaymentNotConnected());

  @override
  Future<PaymentPublic> fetch(int paymentId) => Future.error(const PaymentNotConnected());
}

/// Refus local : paiement pas encore branché (aucune requête envoyée).
final class PaymentNotConnected implements Exception {
  const PaymentNotConnected();

  @override
  String toString() => NotYetConnectedPaymentGateway.message;
}

final paymentGatewayProvider = Provider<PaymentGateway>(
  (ref) => const NotYetConnectedPaymentGateway(),
);

/// Rythme du suivi, remplaçable dans les tests (attente commandée, horloge choisie).
@immutable
class PaymentTiming {
  const PaymentTiming({
    this.fastInterval = const Duration(seconds: 3),
    this.slowInterval = const Duration(seconds: 15),
    this.slowAfter = const Duration(minutes: 2),
    this.now = DateTime.now,
    this.wait = _delay,
  });

  final Duration fastInterval;
  final Duration slowInterval;

  /// Au-delà, « Vérification en cours » et suivi plus lent.
  final Duration slowAfter;
  final DateTime Function() now;
  final Future<void> Function(Duration) wait;

  static Future<void> _delay(Duration d) => Future<void>.delayed(d);
}

final paymentTimingProvider = Provider<PaymentTiming>((ref) => const PaymentTiming());

/// Clé d'idempotence : 32 caractères hexadécimaux tirés au hasard (format de l'API :
/// `^[A-Za-z0-9_-]{8,64}$`).
String newIdempotencyKey([Random? random]) {
  final r = random ?? Random.secure();
  return List.generate(32, (_) => r.nextInt(16).toRadixString(16)).join();
}

final idempotencyKeyProvider = Provider<String Function()>((ref) => newIdempotencyKey);

/// Un paiement terminé (réussi, échoué, expiré) ne bouge plus.
bool isFinalStatus(String status) =>
    status == TransactionStatuses.succeeded ||
    status == TransactionStatuses.failed ||
    status == TransactionStatuses.expired;

// --- États ------------------------------------------------------------------------------------

sealed class PaymentFlowState {
  const PaymentFlowState();

  /// Phase montrée par l'écran 9 (`TransactionStatusView`), `null` : pas d'écran de suivi.
  TransactionPhase? get phase;
}

/// Rien de lancé.
final class PaymentIdle extends PaymentFlowState {
  const PaymentIdle();

  @override
  TransactionPhase? get phase => null;
}

/// Demande envoyée, réponse attendue (le bouton reste en chargement : un seul envoi).
final class PaymentSending extends PaymentFlowState {
  const PaymentSending(this.request, this.key);

  final PaymentRequest request;
  final String key;

  @override
  TransactionPhase? get phase => null;
}

/// Paiement créé, en attente du code PIN puis de l'opérateur ; suivi en cours.
final class PaymentTracking extends PaymentFlowState {
  const PaymentTracking(this.payment, {required this.slow});

  final PaymentPublic payment;

  /// Plus de 2 min sans réponse finale : « Vérification en cours », suivi plus lent.
  final bool slow;

  @override
  TransactionPhase get phase => slow ? TransactionPhase.unknown : TransactionPhase.pending;
}

/// Réponse inconnue (délai dépassé, réseau coupé, panne) : on ne sait pas si le paiement est
/// parti. JAMAIS « Échoué », jamais de nouvelle demande : on vérifie, avec la même clé.
final class PaymentUnknown extends PaymentFlowState {
  const PaymentUnknown(this.request, this.key, {required this.failure, this.paymentId});

  /// La demande envoyée (`null` : paiement suivi depuis ailleurs, connu par son identifiant).
  final PaymentRequest? request;
  final String key;
  final Object failure;

  /// Connu si le paiement a été créé (sinon, la vérification renvoie la demande, même clé).
  final int? paymentId;

  @override
  TransactionPhase get phase => TransactionPhase.unknown;
}

/// Réponse finale de l'opérateur : réussi, échoué (motif), expiré.
final class PaymentFinished extends PaymentFlowState {
  const PaymentFinished(this.payment, this.request);

  final PaymentPublic payment;
  final PaymentRequest? request;

  @override
  TransactionPhase get phase => TransactionPhase.fromStatus(payment.status);

  bool get canRetry =>
      payment.status == TransactionStatuses.failed || payment.status == TransactionStatuses.expired;
}

/// L'API a refusé la demande AVANT de créer un paiement (numéro d'un autre opérateur, facture déjà
/// payée, trop de demandes…), ou le paiement n'est pas encore branché. Rien n'a été débité.
final class PaymentRefused extends PaymentFlowState {
  const PaymentRefused(this.request, this.failure);

  final PaymentRequest request;
  final Object failure;

  String get message => switch (failure) {
    final ApiFailure f => f.message,
    _ => '$failure',
  };

  @override
  TransactionPhase? get phase => null;
}

// --- Déroulement --------------------------------------------------------------------------------

/// Le paiement d'UNE facture, de la feuille (écran 8) au suivi (écran 9). Le suivi s'arrête quand
/// plus personne n'écoute (écran fermé) : aucune interrogation en arrière-plan.
class PaymentFlow extends Notifier<PaymentFlowState> {
  PaymentFlow(this.billId);

  final int billId;
  int _generation = 0;
  bool _disposed = false;

  PaymentGateway get _gateway => ref.read(paymentGatewayProvider);
  PaymentTiming get _timing => ref.read(paymentTimingProvider);

  @override
  PaymentFlowState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _generation++;
    });
    return const PaymentIdle();
  }

  /// « Payer » : une NOUVELLE demande, avec une NOUVELLE clé, seulement si rien n'est en route.
  /// Pendant un envoi, un suivi ou une réponse inconnue : sans effet (jamais deux paiements).
  Future<void> pay(PaymentRequest request) async {
    switch (state) {
      case PaymentSending() || PaymentTracking() || PaymentUnknown():
        return;
      case PaymentFinished(:final canRetry) when !canRetry:
        return; // réussi : rien à repayer
      case PaymentIdle() || PaymentFinished() || PaymentRefused():
        await _send(request, ref.read(idempotencyKeyProvider)());
    }
  }

  /// « Réessayer » après Échoué ou Expiré (ou un refus) : nouvelle demande, nouvelle clé.
  Future<void> retry() async {
    final current = state;
    final request = switch (current) {
      PaymentFinished(:final request?, canRetry: true) => request,
      PaymentRefused(:final request) => request,
      _ => null,
    };
    if (request != null) await pay(request);
  }

  /// Après une réponse inconnue : vérifier. Paiement connu → on le relit ; sinon → la MÊME
  /// demande est renvoyée avec la MÊME clé (l'API rend la même transaction).
  Future<void> checkAgain() async {
    final current = state;
    if (current is! PaymentUnknown) return;
    final id = current.paymentId;
    final request = current.request;
    if (id == null) {
      // Jamais créé de notre point de vue : renvoi de la MÊME demande avec la MÊME clé.
      if (request != null) await _send(request, current.key);
      return;
    }
    try {
      _startTracking(await _gateway.fetch(id), request);
    } on Object catch (failure) {
      if (!_disposed) {
        state = PaymentUnknown(request, current.key, failure: failure, paymentId: id);
      }
    }
  }

  /// Suivre un paiement déjà en cours (lancé ailleurs, ou rouvert depuis l'accueil).
  Future<void> follow(int paymentId) async {
    if (state is PaymentSending || state is PaymentTracking) return;
    try {
      _startTracking(await _gateway.fetch(paymentId), null);
    } on Object catch (failure) {
      if (!_disposed) state = PaymentUnknown(null, '', failure: failure, paymentId: paymentId);
    }
  }

  Future<void> _send(PaymentRequest request, String key) async {
    state = PaymentSending(request, key);
    final PaymentPublic created;
    try {
      created = await _gateway.create(request, idempotencyKey: key);
    } on PaymentNotConnected catch (failure) {
      if (!_disposed) state = PaymentRefused(request, failure);
      return;
    } on ApiRejected catch (failure) {
      if (_disposed) return;
      // Un paiement de cette facture attend déjà sa confirmation : on suit celui-là.
      final inProgress = failure.body.details['transaction_id'];
      if (failure.code == 'PAYMENT_IN_PROGRESS' && inProgress is int) {
        state = PaymentUnknown(request, key, failure: failure, paymentId: inProgress);
        await checkAgain();
        return;
      }
      state = PaymentRefused(request, failure);
      return;
    } on Object catch (failure) {
      // Pas de réponse (délai, réseau, panne) : le paiement est peut-être parti. On vérifie.
      if (!_disposed) state = PaymentUnknown(request, key, failure: failure);
      return;
    }
    _startTracking(created, request);
  }

  /// Démarre le suivi SANS l'attendre : l'état « suivi » est posé tout de suite, et l'action
  /// (Payer, Vérifier, Suivre) rend la main ; le suivi continue jusqu'à l'état final.
  void _startTracking(PaymentPublic payment, PaymentRequest? request) =>
      unawaited(_track(payment, request));

  /// Suivi : toutes les 3 s, puis (après 2 min) toutes les 15 s en « Vérification en cours »,
  /// jusqu'à une réponse finale ou la fermeture de l'écran. Une lecture en échec ne change rien.
  Future<void> _track(PaymentPublic payment, PaymentRequest? request) async {
    if (_disposed) return;
    final generation = ++_generation;
    if (isFinalStatus(payment.status)) {
      state = PaymentFinished(payment, request);
      return;
    }
    final started = _timing.now();
    bool slow() => _timing.now().difference(started) >= _timing.slowAfter;
    var current = payment;
    state = PaymentTracking(current, slow: false);
    while (true) {
      await _timing.wait(slow() ? _timing.slowInterval : _timing.fastInterval);
      if (_disposed || generation != _generation) return;
      try {
        current = await _gateway.fetch(current.id);
      } on Object {
        // Lecture impossible : on garde le dernier état connu, sans jamais conclure à l'échec.
      }
      if (_disposed || generation != _generation) return;
      if (isFinalStatus(current.status)) {
        state = PaymentFinished(current, request);
        return;
      }
      state = PaymentTracking(current, slow: slow());
    }
  }
}

final paymentFlowProvider = NotifierProvider.autoDispose.family<PaymentFlow, PaymentFlowState, int>(
  PaymentFlow.new,
);
