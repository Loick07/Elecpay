import 'dart:ui' show Tristate;

import 'package:elecpay/app/riverpod_config.dart';
import 'package:elecpay/app/routes.dart';
import 'package:elecpay/core/demo/demo_mode.dart';
import 'package:elecpay/core/models/bills.dart';
import 'package:elecpay/core/theme/app_theme.dart';
import 'package:elecpay/core/widgets/bottom_nav.dart';
import 'package:elecpay/core/widgets/skeleton.dart';
import 'package:elecpay/features/bills/bills_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/app_harness.dart';
import '../../support/fake_health.dart';
import '../../support/fake_home_backend.dart';
import '../../support/fake_server.dart';
import '../../support/itel_screen.dart';

/// Écran 6 seul, sur l'itel ; le détail est une simple page qui affiche l'identifiant reçu.
Future<void> pumpBills(
  WidgetTester tester,
  FakeHomeBackend backend, {
  double textScale = 1.0,
  ThemeData? theme,
  bool wait = true,
}) async {
  tester.view.physicalSize = itelPhysicalSize;
  tester.view.devicePixelRatio = itelPixelRatio;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final router = GoRouter(
    initialLocation: AppTab.bills.path,
    routes: [
      GoRoute(path: AppTab.bills.path, builder: (context, state) => const BillsScreen()),
      GoRoute(
        path: Routes.billPath,
        builder: (context, state) =>
            Scaffold(body: Text('Détail ${state.pathParameters['billId']}')),
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
      ],
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

/// Fait défiler jusqu'en bas (la police carrée des tests rend les lignes bien plus hautes que
/// Poppins sur le téléphone : il faut beaucoup de défilement).
Future<void> scrollThrough(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.drag(find.byKey(const Key('bills.list')), const Offset(0, -400));
    await settle(tester);
  }
}

/// Faux backend de la maquette : 2 à payer (dont 1 en retard), 3 payées.
FakeHomeBackend mockupBackend() {
  final backend = FakeHomeBackend();
  backend
    ..paidBills = [
      for (final id in [91, 92, 93])
        {
          ...FakeHomeBackend.bill(id, household: 1, meter: 11, status: BillStatuses.paid),
          'period_start': '2026-07-01',
          'period_end': '2026-08-31',
          'paid_at': '2026-09-10T09:00:00Z',
        },
    ]
    ..latestBills = [
      for (final b in backend.toPay)
        {...b, 'period_start': '2026-09-01', 'period_end': '2026-10-31'},
      ...backend.paidBills,
    ];
  return backend;
}

Finder chip(String name) => find.byKey(Key('bills.filter.$name'));

/// Touche un onglet de filtre (rendu visible d'abord : à 200 %, il peut être sous l'écran).
Future<void> tapChip(WidgetTester tester, String name) async {
  await tester.ensureVisible(chip(name));
  await tester.pump();
  await tester.tap(chip(name));
  await settle(tester);
}

void main() {
  testWidgets('maquette : titre, reste à payer, onglets avec leur nombre, groupes par période', (
    tester,
  ) async {
    await pumpBills(tester, mockupBackend());
    expect(find.text('Mes factures'), findsOneWidget);
    expect(find.text('MODE DÉMO'), findsOneWidget);
    expect(find.text('RESTE À PAYER · 2 FOYERS'), findsOneWidget);
    expect(find.text('2 factures, dont 1 en retard'), findsOneWidget);
    expect(tester.getSemantics(chip('all')).label, 'Toutes, 5 factures');
    expect(tester.getSemantics(chip('toPay')).label, 'À payer, 2 factures');
    expect(tester.getSemantics(chip('paid')).label, 'Payées, 3 factures');
    expect(tester.getSemantics(chip('overdue')).label, 'En retard, 1 facture');
    expect(tester.getSemantics(chip('all')).flagsCollection.isSelected, Tristate.isTrue);
    expect(find.text('SEPTEMBRE – OCTOBRE 2026'), findsOneWidget);
    await scrollThrough(tester);
    expect(find.text('JUILLET – AOÛT 2026'), findsOneWidget);
    expect(find.text('Payée le 10 sept.'), findsNWidgets(3));
  });

  testWidgets('onglet « Payées » : seulement les payées ; l’onglet choisi est gardé', (
    tester,
  ) async {
    final backend = mockupBackend();
    await pumpBills(tester, backend);
    await tapChip(tester, 'paid');
    expect(find.byKey(const Key('bill.91')), findsOneWidget);
    expect(find.byKey(const Key('bill.101')), findsNothing);
    expect(backend.requestsTo('/bills').last.queryParameters['status'], 'paid');
    expect(tester.getSemantics(chip('paid')).flagsCollection.isSelected, Tristate.isTrue);
  });

  testWidgets('« En retard » vide : texte de la maquette, avec le nombre de foyers', (
    tester,
  ) async {
    final backend = mockupBackend()..toPay = [FakeHomeBackend.bill(101, household: 1, meter: 11)];
    await pumpBills(tester, backend);
    await tapChip(tester, 'overdue');
    expect(find.text('Aucune facture en retard'), findsOneWidget);
    expect(
      find.text('Vos deux foyers sont à jour. Nous vous prévenons 5 jours avant chaque échéance.'),
      findsOneWidget,
    );
  });

  testWidgets('reste à payer sans retard : « N factures avant le … »', (tester) async {
    final backend = mockupBackend()
      ..toPay = [
        FakeHomeBackend.bill(101, household: 1, meter: 11, due: '2026-11-18'),
        FakeHomeBackend.bill(102, household: 2, meter: 20, due: '2026-11-25'),
      ];
    await pumpBills(tester, backend);
    expect(find.text('2 factures avant le 18 nov.'), findsOneWidget);
  });

  testWidgets('toucher une facture : son détail s’ouvre', (tester) async {
    await pumpBills(tester, mockupBackend());
    await tester.tap(find.byKey(const Key('bill.201')));
    await settle(tester);
    expect(find.text('Détail 201'), findsOneWidget);
  });

  testWidgets('pages de 20 au défilement', (tester) async {
    final backend = mockupBackend()
      ..latestBills = [
        for (var i = 1; i <= 30; i++)
          FakeHomeBackend.bill(1000 + i, household: 1, meter: 11, status: BillStatuses.paid),
      ];
    await pumpBills(tester, backend);
    await scrollThrough(tester);
    expect(find.byKey(const Key('bill.1030')), findsOneWidget);
    final pages = backend
        .requestsTo('/bills')
        .where((r) => r.queryParameters['size'] == 20)
        .map((r) => r.queryParameters['page']);
    expect(pages, [1, 2]);
  });

  testWidgets('page suivante en échec : « Réessayer », puis la suite', (tester) async {
    final backend = mockupBackend()
      ..latestBills = [
        for (var i = 1; i <= 25; i++)
          FakeHomeBackend.bill(1000 + i, household: 1, meter: 11, status: BillStatuses.paid),
      ];
    await pumpBills(tester, backend);
    backend.down.add('/bills');
    await scrollThrough(tester);
    expect(find.byKey(const Key('loadMore.retry')), findsOneWidget);
    backend.down.clear();
    await tester.tap(find.byKey(const Key('loadMore.retry')));
    await settle(tester);
    await scrollThrough(tester);
    expect(find.byKey(const Key('bill.1025')), findsOneWidget);
  });

  testWidgets('hors ligne avec le cache : bannière datée, la liste reste lisible', (tester) async {
    final backend = mockupBackend();
    await pumpBills(tester, backend);
    await tester.pumpWidget(const SizedBox());
    backend.down.add('/bills');
    await pumpBills(tester, backend);
    expect(find.textContaining('Hors connexion. Les données affichées datent du'), findsOneWidget);
    expect(find.byKey(const Key('bill.101')), findsOneWidget);
  });

  testWidgets('hors ligne sans cache : bloc « Hors connexion »', (tester) async {
    await pumpBills(tester, mockupBackend()..down.add('/bills'));
    expect(find.text('Hors connexion'), findsOneWidget);
  });

  testWidgets('erreur du serveur : « Chargement impossible » avec la référence', (tester) async {
    final backend = mockupBackend()
      ..forced['/bills'] = JsonReply(500, apiError('INTERNAL', 'Erreur'), requestId: 'r-7');
    await pumpBills(tester, backend);
    expect(find.text('Chargement impossible'), findsOneWidget);
    expect(find.text('Référence : r-7'), findsOneWidget);
  });

  testWidgets('chargement : squelettes, puis la liste', (tester) async {
    await pumpBills(tester, mockupBackend(), wait: false);
    expect(find.byType(AppSkeleton), findsWidgets);
    await settle(tester);
    expect(find.byType(AppSkeleton), findsNothing);
  });

  testWidgets('tirer vers le bas : liste, pastilles et reste à payer relus', (tester) async {
    final backend = mockupBackend();
    await pumpBills(tester, backend);
    final before = backend.requestsTo('/bills').length;
    await tester.fling(find.byKey(const Key('bills.list')), const Offset(0, 400), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await settle(tester);
    expect(backend.requestsTo('/bills').length - before, greaterThanOrEqualTo(4));
  });

  group('règle 2 : écran de l’itel, texte à 100, 130 et 200 %', () {
    for (final scale in textScales) {
      testWidgets('rien ne déborde à ${(scale * 100).round()} %', (tester) async {
        await pumpBills(tester, mockupBackend(), textScale: scale);
        await scrollThrough(tester);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('thème Jour, état vide : rien ne déborde', (tester) async {
      await pumpBills(tester, mockupBackend()..paidBills = [], theme: AppTheme.light, textScale: 2);
      await tapChip(tester, 'paid');
      expect(find.text('Aucune facture payée'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
