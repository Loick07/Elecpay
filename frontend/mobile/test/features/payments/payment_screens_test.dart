import 'package:elecpay/app/riverpod_config.dart';
import 'package:elecpay/app/routes.dart';
import 'package:elecpay/core/demo/demo_mode.dart';
import 'package:elecpay/core/models/bills.dart';
import 'package:elecpay/core/models/payments.dart';
import 'package:elecpay/core/network/api_failure.dart';
import 'package:elecpay/core/network/models/api_error.dart';
import 'package:elecpay/core/theme/app_theme.dart';
import 'package:elecpay/core/widgets/bottom_nav.dart';
import 'package:elecpay/core/widgets/payment_sheet.dart';
import 'package:elecpay/features/bills/bill_detail_screen.dart';
import 'package:elecpay/features/home/home_screen.dart';
import 'package:elecpay/features/payments/payment_entry.dart';
import 'package:elecpay/features/payments/payment_flow.dart';
import 'package:elecpay/features/payments/payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/app_harness.dart';
import '../../support/fake_health.dart';
import '../../support/fake_home_backend.dart';
import '../../support/fake_payments.dart';
import '../../support/itel_screen.dart';

/// Écrans 8 et 9 branchés sur la FAUSSE passerelle (aucun paiement réel : arrêt avant F6.3).
class PayHarness {
  final backend = FakeHomeBackend()..user = {...FakeHomeBackend().user, 'phone': '+242061234567'};
  final gateway = FakeGateway();
  final timing = FakeTiming();
  var _keys = 0;

  Future<void> pump(WidgetTester tester, {String? location, double textScale = 1.0}) async {
    tester.view.physicalSize = itelPhysicalSize;
    tester.view.devicePixelRatio = itelPixelRatio;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final router = GoRouter(
      initialLocation: location ?? Routes.bill(101),
      routes: [
        GoRoute(
          path: AppTab.home.path,
          builder: (context, state) => Scaffold(
            body: Consumer(
              builder: (context, ref, _) => Center(
                child: TextButton(
                  key: const Key('host.pay'),
                  onPressed: () => payFromBottomBar(context, ref),
                  child: const Text('Payer (barre du bas)'),
                ),
              ),
            ),
          ),
        ),
        GoRoute(
          path: Routes.receiptPath,
          builder: (context, state) =>
              Scaffold(body: Text('Reçu ${state.pathParameters['receiptId']}')),
        ),
        GoRoute(
          path: Routes.paymentPath,
          builder: (context, state) =>
              PaymentScreen(billId: int.parse(state.pathParameters['billId']!)),
        ),
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
        overrides: [
          ...backend.overrides(),
          ...healthOverrides(demoApi()),
          demoModeStoreProvider.overrideWithValue(MemoryDemoModeStore()),
          homeClockProvider.overrideWithValue(() => DateTime.utc(2026, 11, 12, 9)),
          paymentGatewayProvider.overrideWithValue(gateway),
          paymentTimingProvider.overrideWithValue(timing.timing),
          idempotencyKeyProvider.overrideWithValue(() => 'cle-${++_keys}-0000000'),
        ],
        child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
      ),
    );
    await settle(tester);
  }
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Fin de test : l'écran d'attente est retiré (son minuteur de vérification s'arrête).
Future<void> unmount(WidgetTester tester) => tester.pumpWidget(const SizedBox());

const payLabel = 'Payer 31\u00A0420\u00A0FCFA';

/// Depuis le détail : ouvrir la feuille, puis toucher Payer dans la feuille.
Future<void> openSheet(WidgetTester tester) async {
  await tester.tap(find.text(payLabel).first);
  await settle(tester);
  expect(find.byType(PaymentSheetContent), findsOneWidget);
}

Finder sheetPay() =>
    find.descendant(of: find.byType(PaymentSheetContent), matching: find.text(payLabel));

/// Touche Payer dans la feuille, après l'avoir fait défiler jusqu'à lui (texte agrandi).
Future<void> tapSheetPay(WidgetTester tester) async {
  await tester.ensureVisible(sheetPay());
  await tester.pump();
  await tester.tap(sheetPay());
  await settle(tester);
}

Future<void> typePhone(WidgetTester tester, String digits) async {
  await tester.enterText(
    find.descendant(of: find.byType(PaymentSheetContent), matching: find.byType(TextField)),
    digits,
  );
  await tester.pump();
}

void main() {
  group('feuille de paiement (écran 8)', () {
    testWidgets('numéro du compte et son opérateur ; Payer → écran d’attente, UNE demande', (
      tester,
    ) async {
      final h = PayHarness();
      await h.pump(tester);
      await openSheet(tester);
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('^MTN MoMo,'))).flagsCollection.isChecked,
        isNotNull,
      );
      await tapSheetPay(tester);
      expect(h.gateway.creates, hasLength(1));
      final (request, _) = h.gateway.creates.single;
      expect(request.billId, 101);
      expect(request.operator, PaymentOperator.mtn);
      expect(request.phone, '+242061234567');
      expect(find.byType(PaymentScreen), findsOneWidget);
      expect(find.text('Confirmez sur votre téléphone'), findsOneWidget);
      expect(find.text('TX-00000001'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('compte Airtel (05) : Airtel Money proposé d’office', (tester) async {
      final h = PayHarness();
      h.backend.user = {...h.backend.user, 'phone': '+242051234567'};
      await h.pump(tester);
      await openSheet(tester);
      expect(find.text('Numéro Airtel Money'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('numéro d’un autre opérateur : message sous le champ, aucune demande', (
      tester,
    ) async {
      final h = PayHarness();
      await h.pump(tester);
      await openSheet(tester);
      await typePhone(tester, '05 123 45 67');
      await tapSheetPay(tester);
      expect(find.text('Ce numéro n’est pas un numéro MTN MoMo (numéros en 06).'), findsOneWidget);
      expect(h.gateway.creates, isEmpty);
      await unmount(tester);
    });

    testWidgets('payer pour un proche : la mention du titulaire du numéro', (tester) async {
      final h = PayHarness();
      await h.pump(tester);
      await openSheet(tester);
      expect(find.text(PaymentSheetContent.someoneElseNote), findsNothing);
      await typePhone(tester, '06 999 88 77');
      expect(find.text(PaymentSheetContent.someoneElseNote), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('refus de l’API : message dans la feuille, rien n’est suivi', (tester) async {
      final h = PayHarness();
      h.gateway.createReplies.add(
        const ApiRejected(
          statusCode: 409,
          body: ErrorBody(code: 'BILL_ALREADY_PAID', message: 'Cette facture est déjà payée.'),
        ),
      );
      await h.pump(tester);
      await openSheet(tester);
      await tapSheetPay(tester);
      expect(find.byType(PaymentSheetContent), findsOneWidget);
      expect(find.text('Cette facture est déjà payée.'), findsOneWidget);
      expect(find.byType(PaymentScreen), findsNothing);
      await unmount(tester);
    });

    testWidgets('de bout en bout par l’API (faux serveur) : une demande, puis l’attente', (
      tester,
    ) async {
      // La VRAIE passerelle (non remplacée) : seul le réseau est simulé.
      final backend = FakeHomeBackend()
        ..user = {...FakeHomeBackend().user, 'phone': '+242061234567'};
      tester.view.physicalSize = itelPhysicalSize;
      tester.view.devicePixelRatio = itelPixelRatio;
      addTearDown(tester.view.reset);
      final timing = FakeTiming();
      final router = GoRouter(
        initialLocation: Routes.bill(101),
        routes: [
          GoRoute(
            path: Routes.billPath,
            builder: (context, state) => const BillDetailScreen(billId: 101),
          ),
          GoRoute(
            path: Routes.paymentPath,
            builder: (context, state) => const PaymentScreen(billId: 101),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          retry: noAutomaticRetry,
          overrides: [
            ...backend.overrides(),
            homeClockProvider.overrideWithValue(() => DateTime.utc(2026, 11, 12, 9)),
            paymentTimingProvider.overrideWithValue(timing.timing),
          ],
          child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
        ),
      );
      await settle(tester);
      await openSheet(tester);
      await tapSheetPay(tester);
      final posts = backend.server.requests.where(
        (r) => r.path == '/payments' && r.method == 'POST',
      );
      expect(posts, hasLength(1));
      expect(posts.single.headers['Idempotency-Key'], isNotEmpty);
      expect(find.byType(PaymentScreen), findsOneWidget);
      expect(find.text('Confirmez sur votre téléphone'), findsOneWidget);
      await unmount(tester);
    });
  });

  group('écran d’attente (écran 9)', () {
    testWidgets('en attente : 3 étapes, référence, « Ne relancez pas », jamais Payer', (
      tester,
    ) async {
      final h = PayHarness();
      await h.pump(tester);
      await openSheet(tester);
      await tapSheetPay(tester);
      expect(find.text('Demande envoyée à MTN MoMo'), findsOneWidget);
      expect(find.text('Validation avec votre code PIN'), findsOneWidget);
      expect(find.text('Reçu disponible'), findsOneWidget);
      expect(find.text('En attente'), findsOneWidget);
      expect(find.text('14:31'), findsOneWidget, reason: 'heure de Brazzaville');
      expect(find.textContaining('Ne relancez pas le paiement'), findsOneWidget);
      expect(find.textContaining('Payer'), findsNothing);
      expect(find.text('MODE DÉMO'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('réussi : bascule seule sur le reçu (D6.4), factures relues', (tester) async {
      final h = PayHarness();
      await h.pump(tester);
      await openSheet(tester);
      await tapSheetPay(tester);
      int billReads() => h.backend.server.requests.where((r) => r.path.startsWith('/bills')).length;
      final before = billReads();
      h.gateway.onFetch = (id) => fakePayment(id, TransactionStatuses.succeeded);
      h.timing.release();
      await settle(tester);
      // F6.4 : le reçu s'ouvre de lui-même (D6.4) au lieu de rester sur « Paiement réussi ».
      expect(
        find.text('Reçu ${fakePayment(1, TransactionStatuses.succeeded).receiptId}'),
        findsOneWidget,
      );
      expect(find.byType(PaymentScreen), findsNothing);
      expect(billReads(), greaterThan(before), reason: 'facture et listes relues (D6.4)');
      await unmount(tester);
    });

    testWidgets('échoué : motif, « Réessayer » = nouvelle demande, NOUVELLE clé', (tester) async {
      final h = PayHarness();
      h.gateway.createReplies.add(
        fakePayment(1, TransactionStatuses.failed, reason: 'Solde Mobile Money insuffisant.'),
      );
      await h.pump(tester);
      await openSheet(tester);
      await tapSheetPay(tester);
      expect(find.text('Paiement échoué'), findsOneWidget);
      expect(find.text('Solde Mobile Money insuffisant.'), findsOneWidget);
      await tester.tap(find.text('Réessayer'));
      await settle(tester);
      expect(h.gateway.creates, hasLength(2));
      expect(h.gateway.keys[0], isNot(h.gateway.keys[1]));
      await unmount(tester);
    });

    testWidgets('réponse inconnue : « Vérification en cours », vérifier = MÊME clé', (
      tester,
    ) async {
      final h = PayHarness();
      h.gateway.createReplies.add(const ApiTimeout(mayHaveReachedServer: true));
      await h.pump(tester);
      await openSheet(tester);
      await tapSheetPay(tester);
      expect(find.text('Vérification en cours'), findsOneWidget);
      expect(find.text('Paiement échoué'), findsNothing, reason: 'jamais « échoué » sur un délai');
      expect(find.text('Retour à l’accueil'), findsOneWidget);
      await tester.tap(find.byKey(const Key('payment.check')));
      await settle(tester);
      expect(h.gateway.creates, hasLength(2));
      expect(h.gateway.keys[1], h.gateway.keys[0]);
      await unmount(tester);
    });

    testWidgets('« Retour à l’accueil » ne paie rien', (tester) async {
      final h = PayHarness();
      h.gateway.createReplies.add(const NoConnection());
      await h.pump(tester);
      await openSheet(tester);
      await tapSheetPay(tester);
      await tester.tap(find.text('Retour à l’accueil'));
      await settle(tester);
      expect(find.byKey(const Key('host.pay')), findsOneWidget);
      expect(h.gateway.creates, hasLength(1));
      await unmount(tester);
    });

    testWidgets('écran quitté : plus aucune interrogation', (tester) async {
      final h = PayHarness();
      await h.pump(tester);
      await openSheet(tester);
      await tapSheetPay(tester);
      await tester.tap(find.text('Retour à l’accueil'));
      await settle(tester);
      final before = h.gateway.fetches.length;
      h.timing.release();
      await settle(tester);
      expect(h.gateway.fetches.length, before);
      await unmount(tester);
    });
  });

  group('bouton Payer central (D6.1)', () {
    testWidgets('aucune facture à payer : un message', (tester) async {
      final h = PayHarness();
      h.backend.toPay = [];
      await h.pump(tester, location: AppTab.home.path);
      await tester.tap(find.byKey(const Key('host.pay')));
      await settle(tester);
      expect(find.text('Aucune facture à payer.'), findsOneWidget);
    });

    testWidgets('une seule facture : sa feuille directement', (tester) async {
      final h = PayHarness();
      h.backend.toPay = [FakeHomeBackend.bill(101, household: 1, meter: 11)];
      await h.pump(tester, location: AppTab.home.path);
      await tester.tap(find.byKey(const Key('host.pay')));
      await settle(tester);
      expect(find.byType(PaymentSheetContent), findsOneWidget);
    });

    testWidgets('plusieurs : « Quelle facture payer ? », la plus urgente d’abord', (tester) async {
      final h = PayHarness();
      await h.pump(tester, location: AppTab.home.path);
      await tester.tap(find.byKey(const Key('host.pay')));
      await settle(tester);
      expect(find.text('Quelle facture payer ?'), findsOneWidget);
      final overdue = tester.getTopLeft(find.byKey(const Key('pay.choose.201'))).dy;
      final unpaid = tester.getTopLeft(find.byKey(const Key('pay.choose.101'))).dy;
      expect(overdue, lessThan(unpaid), reason: 'la facture en retard en premier');
      await tester.tap(find.byKey(const Key('pay.choose.101')));
      await settle(tester);
      expect(find.byType(PaymentSheetContent), findsOneWidget);
    });

    testWidgets('paiement en cours : son suivi, jamais une nouvelle demande', (tester) async {
      final h = PayHarness();
      h.backend
        ..toPay = [
          FakeHomeBackend.bill(101, household: 1, meter: 11, status: BillStatuses.pendingPayment),
        ]
        ..payments = [
          {
            ...h.backend.payments.first,
            'id': 55,
            'bill_id': 101,
            'status': TransactionStatuses.pending,
          },
        ];
      await h.pump(tester, location: AppTab.home.path);
      await tester.tap(find.byKey(const Key('host.pay')));
      await settle(tester);
      expect(find.byType(PaymentScreen), findsOneWidget);
      expect(h.gateway.fetches, contains(55));
      expect(h.gateway.creates, isEmpty);
      await unmount(tester);
    });
  });

  group('règle 2 : feuille et attente sur l’itel, texte à 100, 130 et 200 %', () {
    for (final scale in textScales) {
      testWidgets('rien ne déborde à ${(scale * 100).round()} %', (tester) async {
        final h = PayHarness();
        await h.pump(tester, textScale: scale);
        await openSheet(tester);
        expect(tester.takeException(), isNull);
        await tapSheetPay(tester);
        for (var i = 0; i < 4; i++) {
          await tester.drag(find.byKey(const Key('payment.screen')), const Offset(0, -300));
          await tester.pump();
        }
        expect(tester.takeException(), isNull);
        await unmount(tester);
      });
    }
  });
}
