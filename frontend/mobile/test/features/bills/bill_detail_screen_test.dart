import 'package:elecpay/app/riverpod_config.dart';
import 'package:elecpay/app/routes.dart';
import 'package:elecpay/core/models/bills.dart';
import 'package:elecpay/core/theme/app_theme.dart';
import 'package:elecpay/core/widgets/pay_button.dart';
import 'package:elecpay/core/widgets/payment_sheet.dart';
import 'package:elecpay/core/widgets/skeleton.dart';
import 'package:elecpay/features/bills/bill_detail_screen.dart';
import 'package:elecpay/features/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/fake_home_backend.dart';
import '../../support/itel_screen.dart';

/// Jeudi 12 novembre 2026 : échéance du 18 « dans 6 jours » (maquette).
final _now = DateTime.utc(2026, 11, 12, 9);

Future<void> pumpDetail(
  WidgetTester tester,
  FakeHomeBackend backend, {
  int billId = 101,
  double textScale = 1.0,
  bool wait = true,
  ThemeData? theme,
}) async {
  tester.view.physicalSize = itelPhysicalSize;
  tester.view.devicePixelRatio = itelPixelRatio;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final router = GoRouter(
    initialLocation: Routes.bill(billId),
    routes: [
      GoRoute(
        path: Routes.billPath,
        builder: (context, state) =>
            BillDetailScreen(billId: int.parse(state.pathParameters['billId']!)),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      retry: noAutomaticRetry,
      overrides: [...backend.overrides(), homeClockProvider.overrideWithValue(() => _now)],
      child: MaterialApp.router(theme: theme ?? AppTheme.dark, routerConfig: router),
    ),
  );
  if (wait) await settle(tester);
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> scrollThrough(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.drag(find.byKey(const Key('bill.detail')), const Offset(0, -400));
    await tester.pump();
  }
  // La comparaison lit la période de la facture précédente quand elle apparaît : on attend.
  await settle(tester);
}

String label(WidgetTester tester, String key) => tester.getSemantics(find.byKey(Key(key))).label;

void main() {
  // F10.1 : état « chargement » de l'écran.
  testWidgets('chargement : squelettes, puis le contenu', (tester) async {
    await pumpDetail(tester, FakeHomeBackend(), wait: false);
    expect(find.byType(AppSkeleton), findsWidgets);
    await settle(tester);
    expect(find.byType(AppSkeleton), findsNothing);
    expect(find.text('À payer'), findsOneWidget);
  });

  testWidgets('maquette : montant, échéance, période, compteur, index, N°, émission', (
    tester,
  ) async {
    await pumpDetail(tester, FakeHomeBackend());
    expect(find.text('Facture'), findsOneWidget);
    expect(find.text('MODE DÉMO'), findsOneWidget);
    expect(find.text('sept.–oct. 2026 · Maison Mpita'), findsOneWidget);
    expect(find.text('À payer'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('bill.due'))).textSpan!.toPlainText(),
      'À régler avant le 18 nov. 2026 · dans 6 jours',
    );
    final semantics = find.bySemanticsLabel(
      RegExp('^(Période|Compteur|Ancien index|Nouvel index|N° facture|Émise le) : '),
    );
    expect(semantics, findsNWidgets(6));
    expect(find.bySemanticsLabel('Période : 1er sept. – 31 oct. 2026 · 2 mois'), findsOneWidget);
    expect(find.bySemanticsLabel('Ancien index : 18\u00A0247,0 kilowattheures'), findsOneWidget);
    expect(find.bySemanticsLabel('Nouvel index : 18\u00A0664,4 kilowattheures'), findsOneWidget);
    expect(find.bySemanticsLabel('N° facture : 20261103000127'), findsOneWidget);
    expect(find.bySemanticsLabel('Émise le : 3 nov. 2026'), findsOneWidget);
  });

  testWidgets('les 6 lignes E²C, le total hors taxes, le total, la note (maquette)', (
    tester,
  ) async {
    await pumpDetail(tester, FakeHomeBackend());
    await scrollThrough(tester);
    expect(
      label(tester, 'bill.line.energy'),
      'Montant consommation, 417,4\u00A0kWh × 49,08\u00A0FCFA, 20\u00A0485\u00A0FCFA',
    );
    expect(
      label(tester, 'bill.line.fixed_fee'),
      'Droit à la consommation, 2\u00A0mois × 2\u00A0550\u00A0FCFA, 5\u00A0100\u00A0FCFA',
    );
    expect(label(tester, 'bill.subtotal'), 'Total hors taxes, 25\u00A0585\u00A0FCFA');
    expect(label(tester, 'bill.line.vat'), 'T.V.A., 18\u00A0% du hors taxes, 4\u00A0605\u00A0FCFA');
    expect(
      label(tester, 'bill.line.additional_tax'),
      'Centimes additionnels (C.A.), 5\u00A0% de la TVA, 230\u00A0FCFA',
    );
    expect(
      label(tester, 'bill.line.audiovisual_fee'),
      'Redevance audiovisuelle (RAV), Montant fixe, sans TVA, 1\u00A0000\u00A0FCFA',
    );
    expect(label(tester, 'bill.line.stamp'), 'Timbre électronique, 0\u00A0FCFA');
    expect(label(tester, 'bill.total'), 'Total, 31\u00A0420\u00A0FCFA');
    expect(
      find.text(
        'Calcul identique à la facture E²C : décimales coupées à chaque ligne. '
        'Tarif à confirmer (mode démo).',
      ),
      findsOneWidget,
    );
    // L'ordre de la facture E²C : le total hors taxes entre le droit à la consommation et la TVA.
    final y = [
      'bill.line.fixed_fee',
      'bill.subtotal',
      'bill.line.vat',
    ].map((k) => tester.getTopLeft(find.byKey(Key(k))).dy).toList();
    expect(y, orderedEquals([...y]..sort()));
  });

  testWidgets('comparaison à la précédente : « +0,6 % par rapport à … »', (tester) async {
    await pumpDetail(tester, FakeHomeBackend());
    await scrollThrough(tester);
    final text = find.descendant(
      of: find.byKey(const Key('bill.comparison')),
      matching: find.byType(Text),
    );
    expect(
      tester.widget<Text>(text).textSpan!.toPlainText(),
      '+0,6\u00A0% par rapport à juil.\u2013août 2026 (415,0\u00A0kWh · 31\u00A0281\u00A0FCFA).',
    );
  });

  testWidgets('période de la précédente : SES dates (contrat), aucune lecture de plus', (
    tester,
  ) async {
    final backend = FakeHomeBackend();
    await pumpDetail(tester, backend);
    await scrollThrough(tester);
    expect(backend.requestsTo('/bills/90'), isEmpty);
    expect(find.textContaining('TEXTE API'), findsNothing);
  });

  testWidgets('première facture du compteur : pas de comparaison', (tester) async {
    final backend = FakeHomeBackend()
      ..billDetails[101] = FakeHomeBackend.billDetail(101, withPrevious: false);
    await pumpDetail(tester, backend);
    await scrollThrough(tester);
    expect(
      find.text('Première facture de ce compteur : pas encore de comparaison.'),
      findsOneWidget,
    );
  });

  testWidgets('tarif confirmé : pas de « Tarif à confirmer »', (tester) async {
    final backend = FakeHomeBackend()
      ..billDetails[101] = FakeHomeBackend.billDetail(101, tariffAssumption: false);
    await pumpDetail(tester, backend);
    await scrollThrough(tester);
    expect(find.textContaining('Tarif à confirmer'), findsNothing);
  });

  testWidgets('Payer collé en bas → feuille de paiement de cette facture (F6)', (tester) async {
    await pumpDetail(tester, FakeHomeBackend());
    expect(find.text('Payer 31\u00A0420\u00A0FCFA'), findsOneWidget);
    await tester.tap(find.text('Payer 31\u00A0420\u00A0FCFA'));
    await settle(tester);
    expect(find.byType(PaymentSheetContent), findsOneWidget);
    expect(find.text('FACTURE DE SEPT.\u2013OCT. 2026 · MAISON MPITA'), findsOneWidget);
  });

  testWidgets('hors ligne (cache) : bannière, Payer désactivé avec la mention', (tester) async {
    final backend = FakeHomeBackend();
    await pumpDetail(tester, backend);
    await tester.pumpWidget(const SizedBox());
    backend.down.add('/bills');
    await pumpDetail(tester, backend);
    expect(find.textContaining('Hors connexion. Les données affichées datent du'), findsOneWidget);
    expect(find.text(PayButton.offlineHint), findsOneWidget);
    final button = tester.widget<PayButton>(find.byType(PayButton));
    expect(button.online, isFalse);
  });

  testWidgets('simple lecteur (can_pay faux) : pas de Payer, le PDF seul', (tester) async {
    final backend = FakeHomeBackend()
      ..billDetails[101] = FakeHomeBackend.billDetail(101, canPay: false);
    await pumpDetail(tester, backend);
    expect(find.byType(PayButton), findsNothing);
    // F5.4 : le PDF reste proposé à tout membre du foyer (maquette : PDF collé en bas).
    expect(find.byKey(const Key('bill.pdf')), findsOneWidget);
  });

  testWidgets('paiement en cours : « Paiement en cours », pas de deuxième paiement', (
    tester,
  ) async {
    final backend = FakeHomeBackend()
      ..billDetails[101] = FakeHomeBackend.billDetail(
        101,
        status: BillStatuses.pendingPayment,
        canPay: false,
      );
    await pumpDetail(tester, backend);
    expect(find.byType(PayButton), findsNothing);
    expect(find.text('Paiement en cours'), findsWidgets);
  });

  testWidgets('payée : date de paiement, pas d’échéance ni de Payer', (tester) async {
    final backend = FakeHomeBackend()
      ..billDetails[101] = FakeHomeBackend.billDetail(
        101,
        status: BillStatuses.paid,
        canPay: false,
      );
    await pumpDetail(tester, backend);
    expect(find.text('Payée le 10 nov. 2026'), findsOneWidget);
    expect(find.byKey(const Key('bill.due')), findsNothing);
    expect(find.byType(PayButton), findsNothing);
  });

  testWidgets('annulée : bandeau avec le motif, pas de Payer', (tester) async {
    final backend = FakeHomeBackend()
      ..billDetails[101] = FakeHomeBackend.billDetail(
        101,
        status: BillStatuses.cancelled,
        canPay: false,
        cancelledReason: 'Relevé erroné, facture réémise.',
      );
    await pumpDetail(tester, backend);
    expect(find.text('Facture annulée'), findsOneWidget);
    expect(find.text('Motif : Relevé erroné, facture réémise.'), findsOneWidget);
    expect(find.byType(PayButton), findsNothing);
  });

  testWidgets('facture introuvable ou d’un autre foyer (404) : « Accès impossible »', (
    tester,
  ) async {
    await pumpDetail(tester, FakeHomeBackend(), billId: 999);
    expect(find.text('Accès impossible'), findsOneWidget);
    expect(find.text('Facture introuvable.'), findsOneWidget);
  });

  testWidgets('hors ligne sans cache : bloc « Hors connexion »', (tester) async {
    await pumpDetail(tester, FakeHomeBackend()..down.add('/bills'));
    expect(find.text('Hors connexion'), findsOneWidget);
  });

  group('règle 2 : écran de l’itel, texte à 100, 130 et 200 %', () {
    for (final scale in textScales) {
      testWidgets('rien ne déborde à ${(scale * 100).round()} %', (tester) async {
        await pumpDetail(tester, FakeHomeBackend(), textScale: scale);
        await scrollThrough(tester);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('thème Jour, annulée, 200 % : rien ne déborde', (tester) async {
      final backend = FakeHomeBackend()
        ..billDetails[101] = FakeHomeBackend.billDetail(
          101,
          status: BillStatuses.cancelled,
          canPay: false,
          cancelledReason: 'Relevé erroné.',
        );
      await pumpDetail(tester, backend, textScale: 2, theme: AppTheme.light);
      await scrollThrough(tester);
      expect(tester.takeException(), isNull);
    });
  });
}
