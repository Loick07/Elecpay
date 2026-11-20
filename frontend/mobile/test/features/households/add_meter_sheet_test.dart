import 'package:elecpay/app/riverpod_config.dart';
import 'package:elecpay/app/routes.dart';
import 'package:elecpay/core/demo/demo_mode.dart';
import 'package:elecpay/core/models/households.dart';
import 'package:elecpay/core/theme/app_theme.dart';
import 'package:elecpay/features/households/households_rules.dart';
import 'package:elecpay/features/households/households_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/app_harness.dart';
import '../../support/fake_health.dart';
import '../../support/fake_home_backend.dart';
import '../../support/fake_server.dart';
import '../../support/itel_screen.dart';
import 'households_screen_test.dart' show mockupBackend, settle;

Future<void> pumpScreen(
  WidgetTester tester,
  FakeHomeBackend backend, {
  String location = '/compte/compteurs',
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = itelPhysicalSize;
  tester.view.devicePixelRatio = itelPixelRatio;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: Routes.households,
        builder: (context, state) =>
            HouseholdsScreen(openAddMeter: state.uri.queryParameters['ajouter'] == '1'),
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
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    ),
  );
  await settle(tester);
}

Future<void> openSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('households.add')));
  await settle(tester);
}

Future<void> fill(WidgetTester tester, String key, String text) async {
  await tester.enterText(
    find.descendant(of: find.byKey(Key(key)), matching: find.byType(EditableText)),
    text,
  );
  await tester.pump();
}

/// Fait défiler LA FEUILLE (pas l'écran dessous) jusqu'au bouton, puis le touche.
Future<void> submit(WidgetTester tester) async {
  final button = find.byKey(const Key('addMeter.submit'));
  await tester.scrollUntilVisible(
    button.hitTestable(),
    100,
    scrollable: find
        .ancestor(of: find.byKey(const Key('addMeter.form')), matching: find.byType(Scrollable))
        .first,
  );
  await tester.tap(button);
  await settle(tester);
}

void main() {
  group('règles', () {
    test('champs vides : un message par champ', () {
      expect(addMeterFieldError('reference', ' '), 'Saisissez le N° de branchement.');
      expect(addMeterFieldError('customer_number', ''), 'Saisissez le N° client.');
      expect(addMeterFieldError('name', ''), 'Donnez un nom au foyer.');
      expect(addMeterFieldError('city', ''), 'Indiquez la ville.');
      expect(addMeterFieldError('reference', '0018 09 5408'), isNull);
    });

    test('compteur ajouté et historique importé (démo dite)', () {
      final meter = MeterDetail.fromJson({
        ...FakeHomeBackend().meters[1]![0],
        'reference': '0018095408',
        'e2c_center': 'POINTE-NOIRE',
        'subscribed_power_va': 6000,
      });
      expect(addedMeterLine(meter), 'Branchement 0018095408 · Centre POINTE-NOIRE · 6\u00A0kVA');
      expect(
        importedHistoryLine(
          const HistoryImportPublic(readings: 540, bills: 9, source: 'simulated'),
        ),
        'Historique importé : 9 factures et 540 relevés (données de démo).',
      );
      expect(
        importedHistoryLine(const HistoryImportPublic(readings: 1, bills: 1, source: 'e2c')),
        'Historique importé : 1 facture et 1 relevé.',
      );
      expect(
        importedHistoryLine(const HistoryImportPublic(readings: 0, bills: 0, source: 'e2c')),
        'Aucun historique importé.',
      );
    });
  });

  testWidgets('ajout dans un foyer existant : les numéros partent, l’historique est annoncé', (
    tester,
  ) async {
    final backend = mockupBackend();
    await pumpScreen(tester, backend);
    await openSheet(tester);
    expect(find.text('Ajouter un compteur'), findsWidgets);
    expect(find.text('Les deux numéros figurent en haut de votre facture E²C.'), findsOneWidget);
    expect(
      tester.getSemantics(find.byKey(const Key('addMeter.household.1'))).flagsCollection.isSelected,
      isNot(false),
    );
    await fill(tester, 'addMeter.reference', '0018 09 5408');
    await fill(tester, 'addMeter.customer', '0758340h');
    await submit(tester);
    expect(backend.sent['/households/1/meters']!.single, {
      'reference': '0018 09 5408',
      'customer_number': '0758340h',
      'label': null,
    });
    expect(find.byKey(const Key('addMeter.success')), findsOneWidget);
    expect(find.text('Compteur ajouté'), findsOneWidget);
    expect(
      find.text('Historique importé : 9 factures et 540 relevés (données de démo).'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('addMeter.done')));
    await settle(tester);
    expect(find.byKey(const Key('addMeter.form')), findsNothing);
    expect(find.text('0018 09 5408'), findsOneWidget, reason: 'la carte du foyer est relue');
  });

  testWidgets('champs vides : messages sous les champs, rien n’est envoyé', (tester) async {
    final backend = mockupBackend();
    await pumpScreen(tester, backend);
    await openSheet(tester);
    await submit(tester);
    expect(find.text('Saisissez le N° de branchement.'), findsOneWidget);
    expect(find.text('Saisissez le N° client.'), findsOneWidget);
    expect(backend.sent, isEmpty);
  });

  testWidgets('compteur inconnu d’E²C : le message de l’API sous le N° de branchement', (
    tester,
  ) async {
    await pumpScreen(tester, mockupBackend());
    await openSheet(tester);
    await fill(tester, 'addMeter.reference', '0018 09 0000');
    await fill(tester, 'addMeter.customer', '0758340H');
    await submit(tester);
    expect(
      find.descendant(
        of: find.byKey(const Key('addMeter.reference')),
        matching: find.text('Compteur introuvable chez E²C. Vérifiez les numéros.'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('addMeter.success')), findsNothing);
  });

  testWidgets('nouveau foyer : créé UNE fois, même si l’ajout du compteur échoue puis réussit', (
    tester,
  ) async {
    final backend = mockupBackend();
    await pumpScreen(tester, backend);
    await openSheet(tester);
    await tester.tap(find.byKey(const Key('addMeter.household.new')));
    await tester.pump();
    await fill(tester, 'addMeter.reference', '0018 09 0000');
    await fill(tester, 'addMeter.customer', '0758340H');
    await submit(tester);
    expect(find.text('Donnez un nom au foyer.'), findsOneWidget);
    await fill(tester, 'addMeter.name', 'Maison Mpaka');
    await fill(tester, 'addMeter.city', 'Pointe-Noire');
    await submit(tester);
    expect(backend.sent['/households'], hasLength(1));
    // Le compteur était introuvable : on corrige le numéro et on renvoie.
    await fill(tester, 'addMeter.reference', '0018 09 5408');
    await submit(tester);
    expect(backend.sent['/households'], hasLength(1), reason: 'jamais un deuxième foyer');
    // Deux envois sur le MÊME foyer : le refus d'E²C, puis le bon numéro.
    expect(backend.sent['/households/52/meters'], hasLength(2));
    expect(find.byKey(const Key('addMeter.success')), findsOneWidget);
  });

  testWidgets('aucun foyer : le nouveau foyer est demandé directement (pas de choix)', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      FakeHomeBackend()
        ..households = []
        ..toPay = [],
    );
    await openSheet(tester);
    expect(find.byKey(const Key('addMeter.household.new')), findsNothing);
    expect(find.byKey(const Key('addMeter.name')), findsOneWidget);
    expect(find.byKey(const Key('addMeter.city')), findsOneWidget);
  });

  testWidgets('venu de « Ajouter un compteur » (accueil, Conso) : la feuille s’ouvre seule', (
    tester,
  ) async {
    await pumpScreen(tester, mockupBackend(), location: Routes.addMeter);
    expect(find.byKey(const Key('addMeter.form')), findsOneWidget);
  });

  testWidgets('erreur inattendue : message et référence de la requête dans la feuille', (
    tester,
  ) async {
    final backend = mockupBackend();
    backend.forced['/households/1/meters'] = JsonReply(
      409,
      apiError('METER_LIMIT_REACHED', 'Ce foyer a déjà 5 compteurs.'),
    );
    await pumpScreen(tester, backend);
    await openSheet(tester);
    await fill(tester, 'addMeter.reference', '0018 09 5408');
    await fill(tester, 'addMeter.customer', '0758340H');
    await submit(tester);
    expect(find.text('Ce foyer a déjà 5 compteurs.'), findsOneWidget);
  });

  testWidgets(
    'clavier ouvert (300 points) et texte à 200 % : « Ajouter ce compteur » atteignable',
    (tester) async {
      await pumpScreen(tester, mockupBackend(), textScale: 2);
      await openSheet(tester);
      tester.view.viewInsets = const FakeViewPadding(bottom: 600);
      addTearDown(tester.view.resetViewInsets);
      await settle(tester);
      await tester.tap(find.byKey(const Key('addMeter.household.new')));
      await settle(tester);
      await tester.ensureVisible(find.byKey(const Key('addMeter.submit')));
      await settle(tester);
      expect(find.byKey(const Key('addMeter.submit')).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
