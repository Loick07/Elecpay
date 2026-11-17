import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show CheckedState;

import 'package:elecpay/core/format/numbers.dart';
import 'package:elecpay/core/theme/app_icons.dart';
import 'package:elecpay/core/theme/app_theme.dart';
import 'package:elecpay/core/widgets/app_button.dart';
import 'package:elecpay/core/widgets/glass.dart';
import 'package:elecpay/core/widgets/pay_button.dart';
import 'package:elecpay/core/widgets/payment_sheet.dart';
import 'package:elecpay/core/widgets/transaction_status_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/itel_screen.dart';

final pay31420 = 'Payer ${formatFcfa(31420)}';

Set<String> contractEnum(String name) {
  final doc =
      jsonDecode(File('../../backend/openapi.json').readAsStringSync()) as Map<String, dynamic>;
  final schemas = (doc['components'] as Map<String, dynamic>)['schemas'] as Map<String, dynamic>;
  return ((schemas[name] as Map<String, dynamic>)['enum'] as List<dynamic>).cast<String>().toSet();
}

/// État « coché » d'un moyen de paiement, tel que le lecteur d'écran le lit.
CheckedState checked(WidgetTester tester, String operator) =>
    tester.getSemantics(find.bySemanticsLabel(RegExp('^$operator,'))).flagsCollection.isChecked;

PaymentSheetContent sheet({
  bool online = true,
  Future<void> Function(PaymentOperator operator, String phone)? onPay,
}) => PaymentSheetContent(
  periodLabel: 'sept.–oct. 2026',
  householdName: 'Maison Mpita',
  amount: 31420,
  defaultPhone: '+242061234567',
  online: online,
  onPay: onPay ?? (operator, phone) async {},
);

void main() {
  group('feuille de paiement', () {
    test('opérateurs : exactement MobileOperator du contrat, écrits en toutes lettres', () {
      expect(PaymentOperator.values.map((o) => o.apiValue).toSet(), contractEnum('MobileOperator'));
      expect(PaymentOperator.mtn.label, 'MTN MoMo');
      expect(PaymentOperator.airtel.label, 'Airtel Money');
    });

    testWidgets('textes de la maquette ; montant affiché, jamais saisi', (tester) async {
      await pumpOnItel(tester, sheet());
      expect(find.text('FACTURE DE SEPT.–OCT. 2026 · MAISON MPITA'), findsOneWidget);
      expect(find.text(formatFcfa(31420)), findsOneWidget);
      expect(find.text('MOYEN DE PAIEMENT'), findsOneWidget);
      expect(find.text('Vous pouvez payer depuis le numéro d’un proche.'), findsOneWidget);
      expect(
        find.text('Le montant est celui de la facture ; il ne peut pas être modifié.'),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsOneWidget, reason: 'seul le numéro se saisit');
    });

    testWidgets('numéro du compte prérempli ; MTN MoMo choisi par défaut', (tester) async {
      await pumpOnItel(tester, sheet());
      expect(find.text('06 123 45 67'), findsOneWidget);
      expect(find.text('Numéro MTN MoMo'), findsOneWidget);
      expect(checked(tester, 'MTN MoMo'), CheckedState.isTrue);
      expect(checked(tester, 'Airtel Money'), CheckedState.isFalse);
    });

    testWidgets('choix exclusif : Airtel Money choisi → libellé du numéro suit', (tester) async {
      await pumpOnItel(tester, sheet());
      await tester.tap(find.text('Airtel Money'));
      await tester.pump();
      expect(find.text('Numéro Airtel Money'), findsOneWidget);
      expect(find.text('Numéro MTN MoMo'), findsNothing);
      expect(checked(tester, 'Airtel Money'), CheckedState.isTrue);
      expect(checked(tester, 'MTN MoMo'), CheckedState.isFalse);
    });

    testWidgets('numéro invalide : message sous le champ, aucun paiement lancé', (tester) async {
      var calls = 0;
      await pumpOnItel(tester, sheet(onPay: (operator, phone) async => calls++));
      await tester.enterText(find.byType(TextField), '07 123 45 67');
      await tester.tap(find.text(pay31420));
      await tester.pump();
      expect(find.text('Numéro invalide : il doit commencer par 04, 05, 06 ou 22'), findsOneWidget);
      expect(calls, 0);
    });

    testWidgets('paiement pour un proche : opérateur et numéro normalisé ; UN seul envoi', (
      tester,
    ) async {
      final sent = <(PaymentOperator, String)>[];
      final pending = Completer<void>();
      await pumpOnItel(
        tester,
        sheet(
          onPay: (operator, phone) {
            sent.add((operator, phone));
            return pending.future;
          },
        ),
      );
      await tester.tap(find.text('Airtel Money'));
      await tester.enterText(find.byType(TextField), '05 555 44 33');
      await tester.tap(find.text(pay31420));
      await tester.pump();
      await tester.tap(find.byType(PayButton));
      await tester.tap(find.byType(PayButton));
      await tester.pump();
      expect(sent, [(PaymentOperator.airtel, '+242055554433')]);
      pending.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('hors ligne : Payer désactivé, « Connexion nécessaire pour payer »', (
      tester,
    ) async {
      var calls = 0;
      await pumpOnItel(tester, sheet(online: false, onPay: (operator, phone) async => calls++));
      expect(find.text(PayButton.offlineHint), findsOneWidget);
      await tester.tap(find.text(pay31420));
      expect(calls, 0);
    });

    testWidgets('ouverte dans une feuille du bas en verre', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showPaymentSheet(
                    context,
                    periodLabel: 'sept.–oct. 2026',
                    householdName: 'Maison Mpita',
                    amount: 31420,
                    defaultPhone: '+242061234567',
                    online: true,
                    onPay: (operator, phone) async {},
                  ),
                  child: const Text('Payer'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Payer'));
      await tester.pumpAndSettle();
      expect(find.byType(GlassSurface), findsOneWidget);
      expect(find.text(pay31420), findsOneWidget);
    });

    for (final scale in textScales) {
      testWidgets('texte × $scale : la feuille tient sur l’itel (défile au besoin)', (
        tester,
      ) async {
        tester.view.physicalSize = itelPhysicalSize;
        tester.view.devicePixelRatio = itelPixelRatio;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.dark,
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => showPaymentSheet(
                      context,
                      periodLabel: 'sept.–oct. 2026',
                      householdName: 'Boutique Tié-Tié',
                      amount: 1250000,
                      defaultPhone: '+242061234567',
                      online: false,
                      onPay: (operator, phone) async {},
                    ),
                    child: const Text('Ouvrir'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Ouvrir'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('état d’un paiement', () {
    TransactionStatusView view(
      TransactionPhase phase, {
      VoidCallback? onReceipt,
      VoidCallback? onRetry,
      String? reason,
    }) => TransactionStatusView(
      phase: phase,
      amount: 31420,
      operatorLabel: 'MTN MoMo',
      phone: '+242061234567',
      reference: 'TX-2026-004812',
      failureReason: reason,
      onViewReceipt: onReceipt ?? () {},
      onRetry: onRetry ?? () {},
      onHome: () {},
    );

    test('phase depuis le statut de l’API ; sans réponse → vérification, jamais « échoué »', () {
      expect(TransactionPhase.fromStatus('en_attente'), TransactionPhase.pending);
      expect(TransactionPhase.fromStatus('reussie'), TransactionPhase.succeeded);
      expect(TransactionPhase.fromStatus('echouee'), TransactionPhase.failed);
      expect(TransactionPhase.fromStatus('expiree'), TransactionPhase.expired);
      expect(TransactionPhase.fromStatus(null), TransactionPhase.unknown);
      expect(TransactionPhase.fromStatus('nouveau'), TransactionPhase.unknown);
      for (final status in contractEnum('TransactionStatus')) {
        expect(
          TransactionPhase.fromStatus(status),
          isNot(TransactionPhase.unknown),
          reason: status,
        );
      }
    });

    testWidgets('en attente : texte de la maquette, « Ne relancez pas », aucune action', (
      tester,
    ) async {
      await pumpOnItel(tester, view(TransactionPhase.pending));
      expect(find.text('Confirmez sur votre téléphone'), findsOneWidget);
      expect(find.textContaining('Un message MTN MoMo est arrivé sur le'), findsOneWidget);
      expect(find.textContaining('Ne relancez pas le paiement.'), findsOneWidget);
      expect(find.text('TX-2026-004812'), findsOneWidget);
      expect(find.text('Réessayer'), findsNothing);
      expect(find.text('Voir le reçu'), findsNothing);
    });

    testWidgets('réussi : « Voir le reçu », légère vibration', (tester) async {
      final haptics = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
        call,
      ) async {
        if (call.method == 'HapticFeedback.vibrate') haptics.add(call.arguments as String);
        return null;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      var receipts = 0;
      await pumpOnItel(tester, view(TransactionPhase.succeeded, onReceipt: () => receipts++));
      await tester.pumpAndSettle();
      expect(find.text('Paiement réussi'), findsOneWidget);
      expect(haptics, ['HapticFeedbackType.lightImpact']);
      await tester.tap(find.text('Voir le reçu'));
      expect(receipts, 1);
    });

    testWidgets('échoué : motif précis de l’API + Réessayer', (tester) async {
      var retries = 0;
      const reason =
          'Le paiement a échoué : solde Mobile Money insuffisant. Rechargez votre compte puis '
          'réessayez.';
      await pumpOnItel(
        tester,
        view(TransactionPhase.failed, reason: reason, onRetry: () => retries++),
      );
      expect(find.text('Paiement échoué'), findsOneWidget);
      expect(find.text(reason), findsOneWidget);
      await tester.tap(find.text('Réessayer'));
      expect(retries, 1);
    });

    testWidgets('expiré : explication + Réessayer', (tester) async {
      await pumpOnItel(tester, view(TransactionPhase.expired));
      expect(find.text('Paiement expiré'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
    });

    testWidgets('vérification en cours : interdiction de repayer, AUCUN bouton de paiement', (
      tester,
    ) async {
      await pumpOnItel(tester, view(TransactionPhase.unknown));
      expect(find.text('Vérification en cours'), findsOneWidget);
      expect(
        find.text(
          'Nous vérifions votre paiement. Ne payez pas une deuxième fois : vous serez notifié.',
        ),
        findsOneWidget,
      );
      expect(find.text('Réessayer'), findsNothing);
      expect(find.textContaining('Payer'), findsNothing);
      expect(find.byIcon(AppIcons.question), findsOneWidget);
      final buttons = tester.widgetList<AppButton>(find.byType(AppButton)).map((b) => b.label);
      expect(buttons, ['Retour à l’accueil']);
    });

    testWidgets('vérification en cours : la sortie « Retour à l’accueil » ne paie rien', (
      tester,
    ) async {
      var home = 0;
      var retries = 0;
      await pumpOnItel(
        tester,
        TransactionStatusView(
          phase: TransactionPhase.unknown,
          amount: 31420,
          operatorLabel: 'MTN MoMo',
          phone: '+242061234567',
          reference: 'TX-2026-004812',
          onRetry: () => retries++,
          onHome: () => home++,
        ),
      );
      await tester.tap(find.text('Retour à l’accueil'));
      expect(home, 1);
      expect(retries, 0, reason: 'aucune relance possible depuis cet état');
    });

    test('vérification en cours SANS sortie : refusé (assertion)', () {
      expect(
        () => TransactionStatusView(
          phase: TransactionPhase.unknown,
          amount: 31420,
          operatorLabel: 'MTN MoMo',
          phone: '+242061234567',
          reference: 'TX-2026-004812',
        ),
        throwsAssertionError,
      );
    });

    for (final scale in textScales) {
      testWidgets('texte × $scale : chaque état tient sur l’itel', (tester) async {
        for (final phase in TransactionPhase.values) {
          await pumpOnItel(tester, view(phase, reason: 'Motif donné par l’API.'), textScale: scale);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$phase');
        }
      });
    }
  });
}
