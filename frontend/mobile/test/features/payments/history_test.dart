import 'package:elecpay/app/riverpod_config.dart';
import 'package:elecpay/app/routes.dart';
import 'package:elecpay/core/cache/cache_policy.dart';
import 'package:elecpay/core/models/payments.dart';
import 'package:elecpay/core/theme/app_theme.dart';
import 'package:elecpay/features/home/home_screen.dart';
import 'package:elecpay/features/payments/history_data.dart';
import 'package:elecpay/features/payments/history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/fake_home_backend.dart';
import '../../support/itel_screen.dart';

/// Historique de la maquette : réussi, échoué (motif), payé par un délégué, expiré.
List<Map<String, Object?>> mockupPayments() => [
  {
    ...FakeHomeBackend.paymentJson(11, TransactionStatuses.succeeded),
    'initiated_at': '2026-11-12T13:32:00Z',
    'receipt_id': 3,
    'is_mine': true,
    'household_name': 'Maison Mpita',
  },
  {
    ...FakeHomeBackend.paymentJson(
      10,
      TransactionStatuses.failed,
      reason: 'Solde Mobile Money insuffisant',
    ),
    'initiated_at': '2026-11-12T13:20:00Z',
    'operator_label': 'Airtel Money',
    'is_mine': true,
    'household_name': 'Maison Mpita',
    'receipt_id': null,
  },
  {
    ...FakeHomeBackend.paymentJson(9, TransactionStatuses.succeeded),
    'initiated_at': '2026-09-12T08:14:00Z',
    'bill_period_start': '2026-07-01',
    'bill_period_end': '2026-08-31',
    'is_mine': false,
    'payer_name': 'Grâce Ngoma',
    'household_name': 'Boutique Tié-Tié',
    'receipt_id': 2,
  },
  {
    ...FakeHomeBackend.paymentJson(8, TransactionStatuses.expired),
    'initiated_at': '2026-09-09T20:02:00Z',
    'bill_period_start': '2026-07-01',
    'bill_period_end': '2026-08-31',
    'is_mine': true,
    'household_name': 'Maison Mpita',
    'receipt_id': null,
  },
];

FakeHomeBackend mockupBackend() => FakeHomeBackend()..payments = mockupPayments();

Future<void> pumpHistory(
  WidgetTester tester,
  FakeHomeBackend backend, {
  double textScale = 1.0,
  ThemeData? theme,
}) async {
  tester.view.physicalSize = itelPhysicalSize;
  tester.view.devicePixelRatio = itelPixelRatio;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final router = GoRouter(
    initialLocation: Routes.history,
    routes: [
      GoRoute(path: Routes.history, builder: (context, state) => const HistoryScreen()),
      GoRoute(
        path: Routes.receiptPath,
        builder: (context, state) =>
            Scaffold(body: Text('Reçu ${state.pathParameters['receiptId']}')),
      ),
      GoRoute(
        path: Routes.billPath,
        builder: (context, state) =>
            Scaffold(body: Text('Facture ${state.pathParameters['billId']}')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      retry: noAutomaticRetry,
      overrides: [
        ...backend.overrides(),
        homeClockProvider.overrideWithValue(() => DateTime.utc(2026, 11, 20, 9)),
      ],
      child: MaterialApp.router(theme: theme ?? AppTheme.dark, routerConfig: router),
    ),
  );
  await settle(tester);
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> scrollThrough(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.drag(find.byKey(const Key('history.list')), const Offset(0, -400));
    await settle(tester);
  }
}

PaymentPublic payment(Map<String, Object?> json) => PaymentPublic.fromJson(json);

void main() {
  group('règles', () {
    test('groupes par MOIS de la demande, à l’heure de Brazzaville', () {
      final groups = groupByMonth(mockupPayments().map(payment));
      expect(groups.map((g) => g.title), ['Novembre 2026', 'Septembre 2026']);
      expect(groups.first.payments.map((p) => p.id), [11, 10]);
      // 23:30 UTC le 31 octobre = 00:30 le 1er novembre à Brazzaville.
      final lateOctober = payment({
        ...FakeHomeBackend.paymentJson(1, TransactionStatuses.succeeded),
        'initiated_at': '2026-10-31T23:30:00Z',
      });
      expect(groupByMonth([lateOctober]).single.title, 'Novembre 2026');
    });

    test('note : motif de l’échec, PIN non saisi, payé par un autre membre', () {
      final [ok, failed, delegated, expired] = mockupPayments().map(payment).toList();
      expect(historyNote(ok), isNull);
      expect(historyNote(failed), 'Solde Mobile Money insuffisant');
      expect(historyNote(delegated), 'Payé par Grâce Ngoma');
      expect(historyNote(expired), 'Code PIN non saisi à temps');
    });

    test('titre : période à partir des DATES et foyer (jamais le libellé de l’API)', () {
      final delegated = payment(mockupPayments()[2]);
      expect(historyTitle(delegated), 'juil.–août 2026 · Boutique Tié-Tié');
    });

    test('statuts au masculin (maquette : « un paiement »)', () {
      final labels = mockupPayments().map(payment).map((p) => historyStatus(p).label);
      expect(labels, ['Réussi', 'Échoué', 'Réussi', 'Expiré']);
    });

    test('historique et reçus en cache ; état d’un paiement jamais', () {
      expect(isCacheable('/payments'), isTrue);
      expect(isCacheable('/receipts'), isTrue);
      expect(isCacheable('/payments/11'), isFalse);
    });
  });

  group('lectures', () {
    ProviderContainer containerFor(FakeHomeBackend backend) {
      final c = ProviderContainer(retry: noAutomaticRetry, overrides: backend.overrides());
      addTearDown(c.dispose);
      return c;
    }

    test('« Non aboutis » : échoués + expirés fusionnés, du plus récent', () async {
      final backend = mockupBackend();
      final c = containerFor(backend);
      final sub = c.listen(historyProvider(HistoryFilter.notCompleted), (_, _) {});
      addTearDown(sub.close);
      final view = await c.read(historyProvider(HistoryFilter.notCompleted).future);
      expect(view.items.map((p) => p.id), [10, 8]);
      final statuses = backend.requestsTo('/payments').map((r) => r.queryParameters['status']);
      expect(statuses.toSet(), {'echouee', 'expiree'});
    });

    test('« Réussis » : filtre de l’API ; pages de 20', () async {
      final backend = FakeHomeBackend()
        ..payments = [
          for (var i = 1; i <= 25; i++)
            {
              ...FakeHomeBackend.paymentJson(i, TransactionStatuses.succeeded),
              'initiated_at': '2026-11-${(i % 28 + 1).toString().padLeft(2, '0')}T08:00:00Z',
            },
        ];
      final c = containerFor(backend);
      final sub = c.listen(historyProvider(HistoryFilter.succeeded), (_, _) {});
      addTearDown(sub.close);
      await c.read(historyProvider(HistoryFilter.succeeded).future);
      await c.read(historyProvider(HistoryFilter.succeeded).notifier).loadMore();
      expect(c.read(historyProvider(HistoryFilter.succeeded)).value!.items, hasLength(25));
      expect(backend.requestsTo('/payments').map((r) => r.queryParameters['page']), [1, 2]);
      expect(backend.requestsTo('/payments').map((r) => r.queryParameters['status']).toSet(), {
        'reussie',
      });
    });

    test('payé dans l’année : somme et nombre des reçus de l’année', () async {
      final backend = FakeHomeBackend()
        ..receipts = {
          1: {...FakeHomeBackend.receiptJson(1), 'amount': 31420},
          2: {...FakeHomeBackend.receiptJson(2), 'amount': 24570},
          3: {...FakeHomeBackend.receiptJson(3), 'amount': 1, 'issued_at': '2025-12-01T08:00:00Z'},
        };
      final paid = await containerFor(backend).read(yearPaidProvider(2026).future);
      expect((paid.amount, paid.count, paid.atLeast), (55990, 2, false));
      expect(backend.requestsTo('/receipts').single.queryParameters['year'], 2026);
    });
  });

  group('écran', () {
    testWidgets('maquette : payé en 2026, onglets, groupes par mois, motifs', (tester) async {
      await pumpHistory(tester, mockupBackend());
      expect(find.text('Historique des paiements'), findsOneWidget);
      expect(find.text('PAYÉ EN 2026'), findsOneWidget);
      expect(find.text('NOVEMBRE 2026'), findsOneWidget);
      expect(find.text('Solde Mobile Money insuffisant'), findsOneWidget);
      await scrollThrough(tester);
      expect(find.text('SEPTEMBRE 2026'), findsOneWidget);
      expect(find.text('Payé par Grâce Ngoma'), findsOneWidget);
      expect(find.text('Code PIN non saisi à temps'), findsOneWidget);
    });

    testWidgets('montant barré quand le paiement n’a pas abouti', (tester) async {
      await pumpHistory(tester, mockupBackend());
      final failed = tester
          .widgetList<Text>(
            find.descendant(of: find.byKey(const Key('history.10')), matching: find.byType(Text)),
          )
          .firstWhere((t) => t.data == '31\u00A0420\u00A0FCFA');
      expect(failed.style!.decoration, TextDecoration.lineThrough);
    });

    testWidgets('toucher un paiement réussi : son reçu', (tester) async {
      await pumpHistory(tester, mockupBackend());
      await tester.tap(find.byKey(const Key('history.11')));
      await settle(tester);
      expect(find.text('Reçu 3'), findsOneWidget);
    });

    testWidgets('toucher un paiement échoué : la facture (pour la repayer)', (tester) async {
      await pumpHistory(tester, mockupBackend());
      await tester.tap(find.byKey(const Key('history.10')));
      await settle(tester);
      expect(find.text('Facture 101'), findsOneWidget);
    });

    testWidgets('« Non aboutis » vide : « Tous vos paiements ont abouti. »', (tester) async {
      final backend = mockupBackend()..payments = [mockupPayments().first];
      await pumpHistory(tester, backend);
      await tester.tap(find.byKey(const Key('history.filter.notCompleted')));
      await settle(tester);
      expect(find.text('Aucun paiement non abouti'), findsOneWidget);
      expect(find.text('Tous vos paiements ont abouti.'), findsOneWidget);
    });

    testWidgets('hors ligne avec le cache : bannière datée, liste lisible', (tester) async {
      final backend = mockupBackend();
      await pumpHistory(tester, backend);
      await tester.pumpWidget(const SizedBox());
      backend.down.addAll(['/payments', '/receipts']);
      await pumpHistory(tester, backend);
      expect(
        find.textContaining('Hors connexion. Les données affichées datent du'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('history.11')), findsOneWidget);
    });

    testWidgets('hors ligne sans cache : bloc « Hors connexion »', (tester) async {
      await pumpHistory(tester, mockupBackend()..down.add('/payments'));
      expect(find.text('Hors connexion'), findsOneWidget);
    });

    group('règle 2 : texte à 100, 130 et 200 %', () {
      for (final scale in textScales) {
        testWidgets('rien ne déborde à ${(scale * 100).round()} %', (tester) async {
          await pumpHistory(tester, mockupBackend(), textScale: scale);
          await scrollThrough(tester);
          expect(tester.takeException(), isNull);
        });
      }

      testWidgets('thème Jour à 200 % : rien ne déborde', (tester) async {
        await pumpHistory(tester, mockupBackend(), textScale: 2, theme: AppTheme.light);
        await scrollThrough(tester);
        expect(tester.takeException(), isNull);
      });
    });
  });
}
