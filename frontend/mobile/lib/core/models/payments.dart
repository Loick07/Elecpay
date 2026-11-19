import 'package:freezed_annotation/freezed_annotation.dart';

part 'payments.freezed.dart';
part 'payments.g.dart';

// Paiements Mobile Money, écrits à la main d'après `backend/openapi.json` (vérifiés par
// test/contract/openapi_contract_test.dart). Guide : backend/docs/PAIEMENTS.md.

/// États d'une transaction (`TransactionStatus`), traduits par `transactionStatus()`.
/// Seul le prestataire passe une transaction à « réussie ».
abstract final class TransactionStatuses {
  static const pending = 'en_attente';
  static const succeeded = 'reussie';
  static const failed = 'echouee';
  static const expired = 'expiree';
}

/// Schéma OpenAPI : `PaymentPublic` (`GET /payments`, `GET /payments/{id}`).
@freezed
abstract class PaymentPublic with _$PaymentPublic {
  const factory PaymentPublic({
    required int id,
    required String reference,
    required int billId,
    required String billReference,
    required String billPeriodLabel,

    /// Période de la facture (dates du calendrier, fin incluse) : le libellé affiché est
    /// construit avec `formats.dart`, jamais repris de `billPeriodLabel`.
    required DateTime billPeriodStart,
    required DateTime billPeriodEnd,
    required int? householdId,
    required String? householdName,
    required int meterId,
    required String meterReference,

    /// Montant, en FCFA entiers (celui de la facture).
    required int amount,
    required String operator,
    required String operatorLabel,

    /// Numéro Mobile Money (masqué par l'API si ce n'est pas le mien).
    required String phoneNumber,
    required int payerId,
    required String payerName,
    required bool isMine,
    required String status,
    required String step,
    required String? failureReason,
    required DateTime initiatedAt,
    required DateTime? pinEnteredAt,
    required DateTime? confirmedAt,
    required DateTime expiresAt,
    required int? receiptId,
    required String? receiptNumber,
    required String source,
  }) = _PaymentPublic;

  factory PaymentPublic.fromJson(Map<String, dynamic> json) => _$PaymentPublicFromJson(json);
}

/// Schéma OpenAPI : `Page_PaymentPublic_` (`GET /payments`).
@freezed
abstract class PaymentPage with _$PaymentPage {
  const factory PaymentPage({
    required List<PaymentPublic> items,
    required int page,
    required int size,
    required int total,
  }) = _PaymentPage;

  factory PaymentPage.fromJson(Map<String, dynamic> json) => _$PaymentPageFromJson(json);
}
