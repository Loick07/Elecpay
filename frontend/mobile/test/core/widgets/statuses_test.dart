import 'dart:convert';
import 'dart:io';

import 'package:elecpay/core/theme/app_icons.dart';
import 'package:elecpay/core/theme/tokens.g.dart';
import 'package:elecpay/core/widgets/statuses.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/contrast.dart';

/// Valeurs d'une énumération de `backend/openapi.json`.
Set<String> contractEnum(String name) {
  final doc =
      jsonDecode(File('../../backend/openapi.json').readAsStringSync()) as Map<String, dynamic>;
  final schemas = (doc['components'] as Map<String, dynamic>)['schemas'] as Map<String, dynamic>;
  return ((schemas[name] as Map<String, dynamic>)['enum'] as List<dynamic>).cast<String>().toSet();
}

void main() {
  group('contre le contrat (backend/openapi.json)', () {
    test('factures : exactement les valeurs de BillStatus', () {
      expect(billStatuses.keys.toSet(), contractEnum('BillStatus'));
    });

    test('transactions : exactement les valeurs de TransactionStatus', () {
      expect(transactionStatuses.keys.toSet(), contractEnum('TransactionStatus'));
    });
  });

  test('libellés, couleurs et icônes de la table « Statuts » de la charte', () {
    final expected = {
      'unpaid': ('À payer', StatusTone.current, AppIcons.clock),
      'pending_payment': ('Paiement en cours', StatusTone.warning, AppIcons.hourglass),
      'paid': ('Payée', StatusTone.success, AppIcons.check),
      'overdue': ('En retard', StatusTone.error, AppIcons.alert),
      'cancelled': ('Annulée', StatusTone.muted, AppIcons.cancelled),
      'en_attente': ('En attente', StatusTone.warning, AppIcons.hourglass),
      'reussie': ('Réussie', StatusTone.success, AppIcons.check),
      'echouee': ('Échouée', StatusTone.error, AppIcons.cross),
      'expiree': ('Expirée', StatusTone.muted, AppIcons.expired),
    };
    final all = {...billStatuses, ...transactionStatuses};
    for (final MapEntry(key: status, value: (label, tone, icon)) in expected.entries) {
      expect(all[status]!.label, label, reason: status);
      expect(all[status]!.tone, tone, reason: status);
      expect(all[status]!.icon, icon, reason: status);
    }
  });

  group('valeur absente ou inconnue', () {
    test('transaction sans réponse : « Vérification en cours », JAMAIS « Échouée »', () {
      for (final status in [null, 'inconnu', 'nouveau_statut']) {
        final style = transactionStatus(status);
        expect(style.label, 'Vérification en cours');
        expect(style.tone, StatusTone.warning);
        expect(style.icon, AppIcons.question);
      }
    });

    test('facture : statut ajouté plus tard par l’API → neutre, sans deviner', () {
      expect(billStatus('nouveau_statut').label, 'Statut à vérifier');
      expect(billStatus('nouveau_statut').tone, StatusTone.muted);
      expect(billStatus('paid').label, 'Payée');
    });
  });

  test('chaque libellé est unique dans sa liste (jamais deux statuts confondus)', () {
    expect(billStatuses.values.map((s) => s.label).toSet(), hasLength(billStatuses.length));
    expect({
      ...transactionStatuses.values.map((s) => s.label),
      transactionUnknown.label,
    }, hasLength(transactionStatuses.length + 1));
  });

  test('le jaune volt n’est jamais une couleur de statut', () {
    for (final c in [ElecPayColors.dark, ElecPayColors.light]) {
      for (final style in [...billStatuses.values, ...transactionStatuses.values]) {
        expect(style.foreground(c), isNot(c.volt));
        expect(style.background(c), isNot(c.volt));
      }
    }
  });

  final allStyles = [
    ...billStatuses.values,
    ...transactionStatuses.values,
    transactionUnknown,
    billUnknown,
  ];

  test('texte du badge lisible (≥ 4,5:1) sur son fond, dans les deux thèmes', () {
    for (final (theme, c) in [('Nuit', ElecPayColors.dark), ('Jour', ElecPayColors.light)]) {
      for (final style in allStyles) {
        expect(
          contrast(style.foreground(c), style.background(c), over: c.surface1),
          greaterThanOrEqualTo(4.5),
          reason: '$theme : ${style.label}',
        );
      }
    }
  });

  test('thème Jour : vert et orange lisibles grâce à success-text / warning-text (17/11/2026)', () {
    const c = ElecPayColors.light;
    for (final style in allStyles.where(
      (s) => s.tone == StatusTone.success || s.tone == StatusTone.warning,
    )) {
      expect(
        contrast(style.foreground(c), style.background(c), over: c.surface1),
        greaterThanOrEqualTo(4.5),
        reason: style.label,
      );
    }
    expect(c.successText, isNot(c.success), reason: 'texte plus foncé que la couleur de base');
    expect(c.warningText, isNot(c.warning));
  });

  test('icônes de statut visibles (≥ 3:1, règle des éléments graphiques) sur leur fond', () {
    for (final (theme, c) in [('Nuit', ElecPayColors.dark), ('Jour', ElecPayColors.light)]) {
      for (final style in allStyles) {
        expect(
          contrast(style.iconColor(c), style.background(c), over: c.surface1),
          greaterThanOrEqualTo(3),
          reason: '$theme : icône ${style.label}',
        );
      }
    }
  });
}
