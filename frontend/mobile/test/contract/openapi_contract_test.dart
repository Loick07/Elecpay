import 'dart:convert';

import 'package:elecpay/core/models/bills.dart';
import 'package:elecpay/core/models/consumption.dart';
import 'package:elecpay/core/models/households.dart';
import 'package:elecpay/core/models/notifications.dart';
import 'package:elecpay/core/models/payments.dart';
import 'package:elecpay/core/models/receipts.dart';
import 'package:elecpay/core/network/models/api_error.dart';
import 'package:elecpay/features/auth/models/auth_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/openapi.dart';

/// Un modèle Dart écrit à la main et le schéma du contrat qu'il doit respecter.
class ContractCase {
  const ContractCase(this.schema, this.fromJson);

  final String schema;
  final Object Function(Map<String, dynamic> json) fromJson;
}

/// TOUS les modèles de l'application, avec leur schéma. Chaque nouveau modèle s'ajoute ici.
const cases = <ContractCase>[
  ContractCase('ErrorResponse', ErrorResponse.fromJson),
  ContractCase('ErrorBody', ErrorBody.fromJson),
  ContractCase('UserPublic', UserPublic.fromJson),
  ContractCase('TokenResponse', TokenResponse.fromJson),
  ContractCase('TwoFactorChallenge', TwoFactorChallenge.fromJson),
  ContractCase('LoginRequest', LoginRequest.fromJson),
  ContractCase('RegisterRequest', RegisterRequest.fromJson),
  ContractCase('ForgotPasswordRequest', ForgotPasswordRequest.fromJson),
  ContractCase('ForgotPasswordResponse', ForgotPasswordResponse.fromJson),
  ContractCase('ResetPasswordRequest', ResetPasswordRequest.fromJson),
  ContractCase('RefreshRequest', RefreshRequest.fromJson),
  // F4 (accueil) : foyers, factures, paiements, consommation, notifications.
  ContractCase('HouseholdSummary', HouseholdSummary.fromJson),
  ContractCase('MeterDetail', MeterDetail.fromJson),
  ContractCase('BillSummary', BillSummary.fromJson),
  ContractCase('Outstanding', Outstanding.fromJson),
  ContractCase('BillList', BillList.fromJson),
  ContractCase('BillLinePublic', BillLinePublic.fromJson),
  ContractCase('TariffPublic', TariffPublic.fromJson),
  ContractCase('PreviousBillComparison', PreviousBillComparison.fromJson),
  ContractCase('BillDetail', BillDetail.fromJson),
  ContractCase('PaymentPublic', PaymentPublic.fromJson),
  ContractCase('Page_PaymentPublic_', PaymentPage.fromJson),
  ContractCase('DayPeak', DayPeak.fromJson),
  ContractCase('MonthSoFar', MonthSoFar.fromJson),
  ContractCase('LastMonth', LastMonth.fromJson),
  ContractCase('MonthEndEstimate', MonthEndEstimate.fromJson),
  ContractCase('ConsumptionSummary', ConsumptionSummary.fromJson),
  ContractCase('ConsumptionPoint', ConsumptionPoint.fromJson),
  ContractCase('ConsumptionTotals', ConsumptionTotals.fromJson),
  ContractCase('ConsumptionComparison', ConsumptionComparison.fromJson),
  ContractCase('ConsumptionSeries', ConsumptionSeries.fromJson),
  ContractCase('DayDetail', DayDetail.fromJson),
  ContractCase('UnreadCount', UnreadCount.fromJson),
  ContractCase('ReceiptPublic', ReceiptPublic.fromJson),
  ContractCase('Page_ReceiptPublic_', ReceiptPage.fromJson),
  ContractCase('NotificationPublic', NotificationPublic.fromJson),
  ContractCase('NotificationList', NotificationList.fromJson),
  ContractCase('ReadAllResult', ReadAllResult.fromJson),
];

/// `toJson()` de chaque modèle freezed, passé par du vrai JSON (comme sur le réseau).
Map<String, dynamic> toJson(Object model) => jsonDecode(jsonEncode(model)) as Map<String, dynamic>;

void main() {
  final api = OpenApi.load();

  for (final c in cases) {
    group('${c.schema} (contrat backend/openapi.json)', () {
      final properties = api.properties(c.schema);
      final required = api.required(c.schema);

      test('lit un exemple conforme et le réécrit avec exactement les champs du contrat', () {
        final model = c.fromJson(api.sample(c.schema));
        final written = toJson(model);
        expect(written.keys.toSet(), properties.keys.toSet());
        expect(c.fromJson(written), model, reason: 'aller-retour JSON sans perte');
      });

      for (final field in properties.keys) {
        final nullable = api.isNullable(c.schema, field);
        final hasDefault = api.hasDefault(c.schema, field);

        if (required.contains(field) && !nullable) {
          test('« $field » obligatoire : son absence est refusée', () {
            final json = api.sample(c.schema)..remove(field);
            expect(() => c.fromJson(json), throwsA(anything));
          });
        }
        if (!required.contains(field)) {
          test('« $field » facultatif : son absence est acceptée', () {
            expect(() => c.fromJson(api.sample(c.schema)..remove(field)), returnsNormally);
          });
        }
        if (nullable) {
          test('« $field » peut valoir null', () {
            expect(() => c.fromJson(api.sample(c.schema)..[field] = null), returnsNormally);
          });
        } else if (!hasDefault) {
          test('« $field » ne peut pas valoir null', () {
            expect(() => c.fromJson(api.sample(c.schema)..[field] = null), throwsA(anything));
          });
        }
      }
    });
  }

  group('UserRole (énumération du contrat)', () {
    test('mêmes valeurs que le contrat, plus « unknown » côté application', () {
      final dartValues = UserRole.values
          .where((r) => r != UserRole.unknown)
          .map(
            (r) => toJson(UserPublic.fromJson(api.sample('UserPublic')).copyWith(role: r))['role'],
          )
          .toSet();
      expect(dartValues, api.enumValues('UserRole').toSet());
    });

    test('un rôle ajouté plus tard par l’API ne fait pas planter l’application', () {
      final json = api.sample('UserPublic')..['role'] = 'nouveau_role';
      expect(UserPublic.fromJson(json).role, UserRole.unknown);
    });
  });

  group('Réponse de POST /auth/login (anyOf du contrat)', () {
    test('des jetons → connexion réussie', () {
      final result = LoginResult.fromJson(api.sample('TokenResponse'));
      expect(result, isA<LoginSucceeded>());
      expect((result as LoginSucceeded).tokens.user.id, 42);
    });

    test('un défi 2FA → code demandé (compte de l’équipe)', () {
      expect(LoginResult.fromJson(api.sample('TwoFactorChallenge')), isA<LoginNeedsTwoFactor>());
    });

    test('le contrat décrit bien ces deux formes et seulement elles', () {
      final login = api.loginResponseSchemas();
      expect(login, {'TokenResponse', 'TwoFactorChallenge'});
    });
  });

  test('les dates de l’API sont lues en UTC', () {
    final tokens = TokenResponse.fromJson(api.sample('TokenResponse'));
    expect(tokens.accessExpiresAt.isUtc, isTrue);
    expect(tokens.accessExpiresAt, DateTime.utc(2026, 11, 16, 12, 30));
  });
}
