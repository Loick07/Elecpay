import 'dart:ui' show Tristate;

import 'package:elecpay/app/riverpod_config.dart';
import 'package:elecpay/app/routes.dart';
import 'package:elecpay/core/demo/demo_mode.dart';
import 'package:elecpay/core/theme/app_theme.dart';
import 'package:elecpay/core/widgets/bottom_nav.dart';
import 'package:elecpay/core/widgets/demo_badge.dart';
import 'package:elecpay/features/consumption/consumption_screen.dart';
import 'package:elecpay/features/home/home_screen.dart' show homeClockProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/app_harness.dart';
import '../../support/fake_health.dart';
import '../../support/fake_home_backend.dart';
import '../../support/fake_server.dart';
import '../../support/itel_screen.dart';

/// Jeudi 12 novembre 2026, 10 h à Brazzaville (dernier relevé du faux backend : le 11).
final _now = DateTime.utc(2026, 11, 12, 9);

/// Écran 11 seul, sur l'itel ; la page d'attente F8 est une simple page.
Future<void> pumpConso(
  WidgetTester tester,
  FakeHomeBackend backend, {
  double textScale = 1.0,
  bool wait = true,
}) async {
  tester.view.physicalSize = itelPhysicalSize;
  tester.view.devicePixelRatio = itelPixelRatio;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final router = GoRouter(
    initialLocation: AppTab.consumption.path,
    routes: [
      GoRoute(
        path: AppTab.consumption.path,
        builder: (context, state) => const ConsumptionScreen(),
      ),
      GoRoute(
        path: Routes.billPath,
        builder: (context, state) =>
            Scaffold(body: Text('Facture ${state.pathParameters['billId']}')),
      ),
      GoRoute(
        path: Routes.pendingPath,
        builder: (context, state) =>
            Scaffold(body: Text('Attente ${state.uri.queryParameters['etape']}')),
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
        homeClockProvider.overrideWithValue(() => _now),
      ],
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    ),
  );
  if (wait) await settle(tester);
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Toucher un élément de l'écran, en faisant défiler la liste vers le bas s'il le faut.
Future<void> tapKey(WidgetTester tester, String key) async {
  final target = find.byKey(Key(key));
  await tester.dragUntilVisible(
    target.hitTestable(),
    find.byKey(const Key('conso.list')),
    const Offset(0, -150),
  );
  await tester.tap(target);
  await settle(tester);
}

String period(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('conso.period'))).data!;

/// Requêtes de série d'un compteur (plage demandée).
List<Map<String, dynamic>> seriesRequests(FakeHomeBackend backend, int meterId) => [
  for (final r in backend.requestsTo('/meters/$meterId/consumption')) r.queryParameters,
];

/// Faux backend avec des compteurs nommés : 2 dans Maison Mpita, 1 dans la Boutique.
FakeHomeBackend namedMeters() {
  final backend = FakeHomeBackend();
  Map<String, Object?> named(Map<String, Object?> m, String? label, String reference) => {
    ...m,
    'label': label,
    'reference': reference,
    'installed_at': '2025-01-10',
  };
  backend.meters = {
    1: [
      named(backend.meters[1]![0], 'Maison', '0412-778'),
      named(backend.meters[1]![1], null, '0412-990'),
    ],
    2: [named(backend.meters[2]![0], null, '0518-102')],
  };
  return backend;
}

void main() {
  testWidgets('ouverture : onglet Mois, mois en cours, total des jours relevés (D7.1)', (
    tester,
  ) async {
    final backend = namedMeters();
    await pumpConso(tester, backend);
    expect(find.text('Consommation'), findsOneWidget);
    expect(find.byType(DemoBadge), findsOneWidget);
    expect(
      tester.getSemantics(find.byKey(const Key('conso.tab.month'))).flagsCollection.isSelected,
      Tristate.isTrue,
    );
    expect(period(tester), 'Novembre 2026');
    // Compteur de l'accueil (facture en retard de la Boutique), seul de son foyer : le foyer seul.
    expect(find.text('Boutique Tié-Tié'), findsOneWidget);
    expect(find.text('DU 1ER AU 11 NOVEMBRE'), findsOneWidget);
    expect(seriesRequests(backend, 20).last, {
      'granularity': 'day',
      'from': '2026-11-01',
      'to': '2026-11-30',
    });
    expect(find.textContaining("d'énergie"), findsOneWidget);
    expect(find.textContaining('Un relevé par jour · dernier : 11 nov.'), findsOneWidget);
  });

  testWidgets('flèches : mois précédent, et jamais de mois futur', (tester) async {
    final backend = namedMeters();
    await pumpConso(tester, backend);
    expect(
      tester.getSemantics(find.byKey(const Key('conso.next'))).flagsCollection.isEnabled,
      Tristate.isFalse,
    );
    await tapKey(tester, 'conso.previous');
    expect(period(tester), 'Octobre 2026');
    expect(seriesRequests(backend, 20).last['from'], '2026-10-01');
    expect(find.text('OCTOBRE 2026'), findsOneWidget);
    await tapKey(tester, 'conso.next');
    expect(period(tester), 'Novembre 2026');
  });

  testWidgets('pas avant la pose du compteur', (tester) async {
    final backend = namedMeters();
    backend.meters[2] = [
      {...backend.meters[2]![0], 'installed_at': '2026-10-20'},
    ];
    await pumpConso(tester, backend);
    await tapKey(tester, 'conso.previous');
    expect(period(tester), 'Octobre 2026');
    expect(
      tester.getSemantics(find.byKey(const Key('conso.previous'))).flagsCollection.isEnabled,
      Tristate.isFalse,
    );
  });

  testWidgets('onglets et fil d’Ariane : Année, Semaine, Jour, retour au mois', (tester) async {
    final backend = namedMeters();
    await pumpConso(tester, backend);
    await tapKey(tester, 'conso.tab.year');
    expect(period(tester), '2026');
    expect(seriesRequests(backend, 20).last, {
      'granularity': 'month',
      'from': '2026-01-01',
      'to': '2026-12-31',
    });
    expect(find.text('DU 1ER JANV. AU 11 NOV. 2026'), findsOneWidget);

    await tapKey(tester, 'conso.tab.week');
    expect(period(tester), 'Sem. du 9 nov.');
    expect(find.text('SEMAINE EN COURS · 3 JOURS'), findsOneWidget);

    await tapKey(tester, 'conso.tab.day');
    expect(period(tester), 'Jeu. 12 nov.');
    // Fil d'Ariane : 2026 › Novembre › Sem. du 9 nov. › Jeu. 12.
    expect(find.text('Jeu. 12'), findsOneWidget);
    await tapKey(tester, 'conso.previous');
    expect(period(tester), 'Mer. 11 nov.');
    expect(find.text('CONSOMMATION DU JOUR'), findsOneWidget);

    await tapKey(tester, 'conso.crumb.month');
    expect(period(tester), 'Novembre 2026');
    expect(
      tester.getSemantics(find.byKey(const Key('conso.tab.month'))).flagsCollection.isSelected,
      Tristate.isTrue,
    );
  });

  testWidgets('jour non encore relevé : « Pas encore de relevé », pas de faux zéro', (
    tester,
  ) async {
    await pumpConso(tester, namedMeters());
    await tapKey(tester, 'conso.tab.day');
    expect(find.byKey(const Key('conso.emptyPeriod')), findsOneWidget);
    expect(find.text('Pas encore de relevé'), findsOneWidget);
    expect(find.byKey(const Key('conso.totals')), findsNothing);
  });

  testWidgets('sélecteur : choisir un autre compteur, gardé ; « foyer · compteur »', (
    tester,
  ) async {
    final backend = namedMeters();
    await pumpConso(tester, backend);
    await tapKey(tester, 'conso.meter');
    expect(find.text('Choisir un compteur'), findsOneWidget);
    expect(find.text('Compteur 0412-990'), findsOneWidget);
    await tapKey(tester, 'conso.meter.10');
    expect(find.text('Maison Mpita · Maison'), findsOneWidget);
    expect(seriesRequests(backend, 10).last['from'], '2026-11-01');
  });

  testWidgets('un seul compteur : son nom, sans menu', (tester) async {
    final backend = namedMeters()
      ..households = [FakeHomeBackend().households[1]]
      ..toPay = [FakeHomeBackend().toPay[1]];
    await pumpConso(tester, backend);
    expect(
      tester.getSemantics(find.byKey(const Key('conso.meter'))).label,
      'Compteur : Boutique Tié-Tié',
    );
    await tester.tap(find.byKey(const Key('conso.meter')));
    await settle(tester);
    expect(find.text('Choisir un compteur'), findsNothing);
  });

  testWidgets('aucun compteur : l’état vide mène à l’ajout (F8)', (tester) async {
    final backend = FakeHomeBackend()
      ..households = []
      ..toPay = [];
    await pumpConso(tester, backend);
    expect(find.text('Aucun compteur'), findsOneWidget);
    expect(find.byKey(const Key('conso.tab.month')), findsOneWidget, reason: 'onglets visibles');
    await tester.tap(find.text('Ajouter un compteur'));
    await settle(tester);
    expect(find.text('Attente F8'), findsOneWidget);
  });

  testWidgets('erreur du serveur : message et Réessayer', (tester) async {
    final backend = namedMeters();
    backend.forced['/meters/20/consumption'] = JsonReply(
      500,
      apiError('INTERNAL_ERROR', 'Erreur.'),
    );
    await pumpConso(tester, backend);
    expect(find.text('Chargement impossible'), findsOneWidget);
    backend.forced.clear();
    await tester.dragUntilVisible(
      find.text('Réessayer').hitTestable(),
      find.byKey(const Key('conso.list')),
      const Offset(0, -150),
    );
    await tester.tap(find.text('Réessayer'));
    await settle(tester);
    expect(find.text('DU 1ER AU 11 NOVEMBRE'), findsOneWidget);
  });

  testWidgets('hors connexion : la série du cache, avec sa bannière', (tester) async {
    final backend = namedMeters();
    await pumpConso(tester, backend);
    await tapKey(tester, 'conso.previous');
    backend.down.add('/meters');
    await tapKey(tester, 'conso.next');
    // Novembre est déjà en mémoire ; on force une relecture depuis le cache par le rafraîchissement.
    await tester.fling(find.byKey(const Key('conso.list')), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(find.textContaining('Hors connexion'), findsOneWidget);
    expect(find.text('DU 1ER AU 11 NOVEMBRE'), findsOneWidget);
  });

  testWidgets('Direct sans simulation : phase 2, jamais « temps réel »', (tester) async {
    await pumpConso(tester, namedMeters());
    await tapKey(tester, 'conso.tab.direct');
    expect(find.text('Disponible avec un compteur communicant (phase 2)'), findsOneWidget);
    expect(find.byKey(const Key('conso.period')), findsNothing);
  });

  testWidgets('jamais « temps réel » sur aucun onglet', (tester) async {
    await pumpConso(tester, namedMeters());
    for (final tab in ['direct', 'day', 'week', 'month', 'year']) {
      await tapKey(tester, 'conso.tab.$tab');
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '');
      expect(texts.where((t) => t.toLowerCase().contains('temps réel')), isEmpty, reason: tab);
    }
  });

  for (final scale in [1.3, 2.0]) {
    testWidgets('texte à ${(scale * 100).round()} % : tout reste lisible, sans débordement', (
      tester,
    ) async {
      await pumpConso(tester, namedMeters(), textScale: scale);
      expect(tester.takeException(), isNull);
      for (final tab in ['year', 'week', 'day', 'direct', 'month']) {
        await tapKey(tester, 'conso.tab.$tab');
        expect(tester.takeException(), isNull, reason: tab);
      }
      expect(period(tester), 'Novembre 2026');
    });
  }

  group('vue Mois (F7.3)', () {
    testWidgets('pastilles, barres lues par TalkBack, toucher un jour', (tester) async {
      await pumpConso(tester, namedMeters());
      expect(find.byKey(const Key('conso.stat.Moyenne')), findsOneWidget);
      expect(find.byKey(const Key('conso.stat.Pic')), findsOneWidget);
      expect(find.byKey(const Key('conso.stat.Fin de mois estimée')), findsOneWidget);
      expect(find.byKey(const Key('conso.chart')), findsOneWidget);
      expect(find.bySemanticsLabel('1er novembre : 11\u00A0kWh'), findsOneWidget);
      expect(find.bySemanticsLabel('12 novembre : pas encore de données'), findsOneWidget);
      expect(
        find.text('Touchez un jour pour son détail, ou une semaine ci-dessous'),
        findsOneWidget,
      );
      await tapKey(tester, 'conso.bar.1');
      expect(period(tester), 'Lun. 2 nov.');
    });

    testWidgets('« Semaine par semaine » : toucher une semaine ouvre la semaine', (tester) async {
      await pumpConso(tester, namedMeters());
      expect(find.text('SEMAINE PAR SEMAINE'), findsOneWidget);
      expect(find.text('Du 2 au 8 nov.'), findsOneWidget);
      await tapKey(tester, 'conso.row.1');
      expect(period(tester), 'Sem. du 2 nov.');
    });

    testWidgets('mois passé : pas d’estimation ; lien vers la facture bimestrielle', (
      tester,
    ) async {
      final backend = namedMeters()
        ..latestBills = [
          {
            ...FakeHomeBackend.bill(201, household: 2, meter: 20),
            'period_start': '2026-09-01',
            'period_end': '2026-10-31',
          },
        ];
      await pumpConso(tester, backend);
      await tapKey(tester, 'conso.previous');
      expect(find.byKey(const Key('conso.stat.Fin de mois estimée')), findsNothing);
      await tester.dragUntilVisible(
        find.byKey(const Key('conso.bill')),
        find.byKey(const Key('conso.list')),
        const Offset(0, -150),
      );
      expect(find.text('Voir la facture de septembre–octobre 2026 (bimestrielle)'), findsOneWidget);
      await tapKey(tester, 'conso.bill');
      expect(find.text('Facture 201'), findsOneWidget);
    });

    testWidgets('mois sans facture : pas de lien', (tester) async {
      await pumpConso(tester, namedMeters()..latestBills = []);
      await tester.dragUntilVisible(
        find.byKey(const Key('conso.legend')),
        find.byKey(const Key('conso.list')),
        const Offset(0, -150),
      );
      expect(find.byKey(const Key('conso.bill')), findsNothing);
    });
  });

  group('vue Année (F7.3)', () {
    testWidgets('12 barres ; toucher un mois ouvre ce mois', (tester) async {
      await pumpConso(tester, namedMeters());
      await tapKey(tester, 'conso.tab.year');
      expect(find.text('Touchez un mois pour voir ses jours et ses semaines'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Octobre 2026 : ')), findsOneWidget);
      expect(find.bySemanticsLabel('Décembre 2026 : pas encore de données'), findsOneWidget);
      await tapKey(tester, 'conso.bar.9');
      expect(period(tester), 'Octobre 2026');
    });

    testWidgets('« Mois par mois » : du plus récent ; toucher ouvre le mois', (tester) async {
      await pumpConso(tester, namedMeters());
      await tapKey(tester, 'conso.tab.year');
      expect(find.text('MOIS PAR MOIS'), findsOneWidget);
      expect(find.text('Novembre 2026'), findsOneWidget);
      await tapKey(tester, 'conso.row.1');
      expect(period(tester), 'Octobre 2026');
    });
  });
}
