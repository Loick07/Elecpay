import 'package:elecpay/app/riverpod_config.dart';
import 'package:elecpay/app/routes.dart';
import 'package:elecpay/core/demo/demo_mode.dart';
import 'package:elecpay/core/theme/app_theme.dart';
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

/// Écran 15 seul, sur l'itel.
Future<void> pumpHouseholds(
  WidgetTester tester,
  FakeHomeBackend backend, {
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = itelPhysicalSize;
  tester.view.devicePixelRatio = itelPixelRatio;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final router = GoRouter(
    initialLocation: Routes.households,
    routes: [
      GoRoute(path: Routes.households, builder: (context, state) => const HouseholdsScreen()),
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

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Faux backend de la maquette : compteurs avec leur référence et leur puissance.
FakeHomeBackend mockupBackend() {
  final backend = FakeHomeBackend();
  Map<String, Object?> meter(Map<String, Object?> m, String reference, int va, [String? label]) => {
    ...m,
    'reference': reference,
    'subscribed_power_va': va,
    'label': label,
  };
  backend
    ..households = [
      {...backend.households[0], 'district': 'Mpita', 'city': 'Pointe-Noire'},
      {...backend.households[1], 'district': 'Tié-Tié', 'city': 'Pointe-Noire'},
    ]
    ..meters = {
      1: [meter(backend.meters[1]![0], '0412-8833', 6000)],
      2: [meter(backend.meters[2]![0], '0377-1209', 9000)],
    };
  return backend;
}

void main() {
  testWidgets('une carte par foyer (maquette) : compteur, puissance, rôle, membres, « À payer »', (
    tester,
  ) async {
    await pumpHouseholds(tester, mockupBackend());
    expect(find.text('Compteurs et foyers'), findsOneWidget);
    expect(find.text('MODE DÉMO'), findsOneWidget);
    expect(find.text('Maison Mpita'), findsOneWidget);
    expect(find.text('Mpita, Pointe-Noire · Propriétaire'), findsOneWidget);
    expect(find.text('0412-8833'), findsOneWidget);
    expect(find.text('6\u00A0kVA'), findsOneWidget);
    expect(find.text('Vous seul'), findsOneWidget);
    expect(find.byKey(const Key('households.toPay.1')), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const Key('households.members.2')), 200);
    expect(find.text('Grâce Ngoma · payeur délégué'), findsOneWidget);
    expect(find.text('9\u00A0kVA'), findsOneWidget);
    await tester.scrollUntilVisible(find.textContaining('Un payeur délégué voit et paie'), 200);
    expect(find.textContaining('Un payeur délégué voit et paie'), findsOneWidget);
  });

  testWidgets('TalkBack : la puissance dit « kilovoltampères »', (tester) async {
    await pumpHouseholds(tester, mockupBackend());
    expect(find.bySemanticsLabel('Puissance souscrite : 6 kilovoltampères'), findsOneWidget);
  });

  testWidgets('invitation reçue en haut : Accepter → le foyer rejoint apparaît', (tester) async {
    final backend = mockupBackend()..invitations = [FakeHomeBackend.invitation(1, 'Chez Mamie')];
    await pumpHouseholds(tester, backend);
    expect(find.text('Marie Loemba vous invite comme payeur délégué'), findsOneWidget);
    expect(find.text('Chez Mamie, Pointe-Noire'), findsOneWidget);
    await tester.tap(find.byKey(const Key('households.accept.1')));
    await settle(tester);
    expect(find.text('Vous avez rejoint Chez Mamie.'), findsOneWidget);
    expect(find.byKey(const Key('households.invitation.1')), findsNothing);
    await tester.scrollUntilVisible(find.byKey(const Key('households.card.31')), 200);
    expect(find.text('Propriétaire : Loick Makosso'), findsOneWidget);
  });

  testWidgets('Refuser : l’invitation disparaît ; une erreur de l’API s’affiche', (tester) async {
    final backend = mockupBackend()
      ..invitations = [
        FakeHomeBackend.invitation(1, 'Chez Mamie'),
        FakeHomeBackend.invitation(2, 'Atelier'),
      ];
    backend.forced['/invitations/2/decline'] = JsonReply(
      404,
      apiError('INVITATION_NOT_FOUND', 'Invitation introuvable ou déjà traitée.'),
    );
    await pumpHouseholds(tester, backend);
    await tester.tap(find.byKey(const Key('households.decline.1')));
    await settle(tester);
    expect(find.byKey(const Key('households.invitation.1')), findsNothing);
    expect(find.text('Invitation refusée.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('households.decline.2')));
    await settle(tester);
    expect(find.text('Invitation introuvable ou déjà traitée.'), findsOneWidget);
  });

  testWidgets('aucun foyer : état vide', (tester) async {
    await pumpHouseholds(
      tester,
      FakeHomeBackend()
        ..households = []
        ..toPay = [],
    );
    expect(find.byKey(const Key('households.empty')), findsOneWidget);
    expect(find.text('Aucun foyer'), findsOneWidget);
  });

  testWidgets('un foyer illisible échoue seul ; Réessayer', (tester) async {
    final backend = mockupBackend();
    backend.forced['/households/2'] = JsonReply(500, apiError('INTERNAL_ERROR', 'Erreur.'));
    await pumpHouseholds(tester, backend);
    expect(find.byKey(const Key('households.card.1')), findsOneWidget);
    expect(find.byKey(const Key('households.card.2.error')), findsOneWidget);
    backend.forced.clear();
    await tester.tap(find.text('Réessayer'));
    await settle(tester);
    expect(find.byKey(const Key('households.card.2')), findsOneWidget);
  });

  testWidgets('hors connexion : les foyers du cache, avec la bannière', (tester) async {
    final backend = mockupBackend();
    await pumpHouseholds(tester, backend);
    backend.down.add('/households');
    backend.down.add('/invitations');
    await tester.fling(find.byKey(const Key('households.list')), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(find.textContaining('Hors connexion'), findsOneWidget);
    expect(find.text('Maison Mpita'), findsOneWidget);
  });

  testWidgets('liste illisible : message et Réessayer', (tester) async {
    final backend = mockupBackend();
    backend.forced['/households'] = JsonReply(500, apiError('INTERNAL_ERROR', 'Erreur.'));
    await pumpHouseholds(tester, backend);
    expect(find.text('Chargement impossible'), findsOneWidget);
  });

  // Vu sur une capture à 200 % : « Pointe-Noire · Pr / opriétair », le badge écrasait la colonne.
  testWidgets('texte à 200 % : « À payer » passe sous le lieu ; à 100 % il est à droite', (
    tester,
  ) async {
    for (final (scale, below) in [(2.0, true), (1.0, false)]) {
      await pumpHouseholds(tester, mockupBackend(), textScale: scale);
      final badge = tester.getRect(find.byKey(const Key('households.toPay.1')));
      final place = tester.getRect(find.text('Mpita, Pointe-Noire · Propriétaire'));
      if (below) {
        expect(badge.top, greaterThanOrEqualTo(place.bottom), reason: 'à $scale');
      } else {
        expect(badge.left, greaterThan(place.right), reason: 'à $scale');
      }
    }
  });

  for (final scale in [1.3, 2.0]) {
    testWidgets('texte à ${(scale * 100).round()} % : rien ne déborde', (tester) async {
      final backend = mockupBackend()..invitations = [FakeHomeBackend.invitation(1, 'Chez Mamie')];
      await pumpHouseholds(tester, backend, textScale: scale);
      for (var i = 0; i < 8; i++) {
        await tester.drag(find.byKey(const Key('households.list')), const Offset(0, -400));
        await settle(tester);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
