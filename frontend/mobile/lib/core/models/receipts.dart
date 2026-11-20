import 'package:freezed_annotation/freezed_annotation.dart';

part 'receipts.freezed.dart';
part 'receipts.g.dart';

// Reçus, écrits à la main d'après `backend/openapi.json` (vérifiés par
// test/contract/openapi_contract_test.dart). Guide : backend/docs/RECUS.md.
// Un reçu n'existe que pour un paiement réussi ; il n'est jamais modifié.

/// Schéma OpenAPI : `ReceiptPublic` (`GET /receipts/{id}`, écran 10).
@freezed
abstract class ReceiptPublic with _$ReceiptPublic {
  const factory ReceiptPublic({
    required int id,

    /// « EP-2026-000123 ».
    required String number,

    /// Date du paiement confirmé (instant : affiché à l'heure de Brazzaville).
    required DateTime issuedAt,

    /// Montant payé, en FCFA entiers.
    required int amount,

    /// Déjà en groupes de 4 (« 8F3K-2Q9M-7XHT »).
    required String verificationCode,
    required int billId,
    required String billReference,

    /// Texte de l'API : jamais affiché (la période est construite à partir des dates ci-dessous).
    required String billPeriodLabel,
    required DateTime billPeriodStart,
    required DateTime billPeriodEnd,
    required int meterId,
    required String meterReference,
    required int? householdId,
    required String? householdName,
    required int payerId,
    required String payerName,
    required bool isMine,
    required String operator,
    required String operatorLabel,

    /// TOUJOURS masqué par l'API, même pour le payeur (un reçu est fait pour être partagé).
    required String phoneNumber,
    required int transactionId,
    required String transactionReference,

    /// `simulated` (mode démo) ou `e2c`.
    required String source,
  }) = _ReceiptPublic;

  factory ReceiptPublic.fromJson(Map<String, dynamic> json) => _$ReceiptPublicFromJson(json);
}
