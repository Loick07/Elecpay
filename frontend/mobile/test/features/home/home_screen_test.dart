import 'package:elecpay/app/riverpod_config.dart';
import 'package:elecpay/app/routes.dart';
import 'package:elecpay/core/demo/demo_mode.dart';
import 'package:elecpay/core/models/bills.dart';
import 'package:elecpay/core/theme/app_theme.dart';
import 'package:elecpay/core/widgets/bottom_nav.dart';
import 'package:elecpay/core/widgets/pay_button.dart';
import 'package:elecpay/core/widgets/payment_sheet.dart';
import 'package:elecpay/core/widgets/skeleton.dart';
import 'package:elecpay/features/home/home_screen.dart';
import 'package:elecpay/features/notifications/notifications_screen.dart';
import 'package:elecpay/features/pending/pending_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/app_harness.dart';
import '../../support/fake_health.dart';
import '../../support/fake_home_backend.dart';
import '../../support/fake_server.dart';
import '../../support/itel_screen.dart';

/// Jeudi 12 novembre 2026, 10:00 à Brazzaville.
final _now = DateTime.utc(2026, 11, 12, 9);

/// L'accueil seul, sur l'écran de l'itel, avec un petit routeur (accueil, Conso, page d'attente).
Future<void> pumpHome(
  WidgetTester tester,
  FakeHomeBackend backend, {
  MemoryHouseholdChoiceStore? choices,
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
    initialLocation: AppTab.home.path,
    routes: [
      GoRoute(path: AppTab.home.path, builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: AppTab.consumption.path,
        builder: (context, state) => const Scaffold(body: Text('Écran Conso')),
      ),
      GoRoute(
        path: Routes.history,
        builder: (context, state) => const Scaffold(body: Text('Écran Historique')),
      ),
      GoRoute(
        path: Routes.billPath,
        builder: (context, state) =>
            Scaffold(body: Text('Facture ${state.pathParameters['billId']}')),
      ),
      GoRoute(path: Routes.notifications, builder: (context, state) => const NotificationsScreen()),
      GoRoute(
        path: Routes.pendingPath,
        builder: (context, state) => PendingScreen(
          screen: state.uri.queryParameters['ecran']!,
          step: state.uri.queryParameters['etape']!,
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      retry: noAutomaticRetry,
      overrides: [
        ...backend.overrides(choices: choices),
        ...healthOverrides(demoApi()),
        demoModeStoreProvider.overrideWithValue(MemoryDemoModeStore()),
        homeClockProvider.overrideWithValue(() => _now),
      ],
      child: MaterialApp.router(theme: theme ?? AppTheme.dark, routerConfig: router),
    ),
  );
  if (wait) await settle(tester);
}

/// Laisse les lectures (faux serveur) se terminer, sans `pumpAndSettle` (squelettes animés).
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Fait défiler tout l'accueil (chaque carte est construite, donc mise en page).
Future<void> scrollThrough(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.drag(find.byKey(const Key('home.list')), const Offset(0, -300));
    await tester.pump();
  }
}

void main() {
  group('tout répond', () {
    testWidgets('en-tête, foyer, facture urgente, mois, activité (maquette)', (tester) async {
      await pumpHome(tester, FakeHomeBackend());
      expect(find.text('Jeudi 12 novembre'), findsOneWidget);
      expect(find.text('Bonjour Loick'), findsOneWidget);
      expect(find.text('MODE DÉMO'), findsOneWidget);
      expect(find.byKey(const Key('home.bell.dot')), findsOneWidget, reason: '3 non lues');
      expect(
        tester.getSemantics(find.byKey(const Key('home.bell'))).label,
        'Notifications, 3 non lues',
      );
      // Foyer par défaut : celui de la facture en retard.
      expect(find.text('Boutique Tié-Tié · 2 foyers'), findsOneWidget);
      expect(find.byKey(const Key('home.hero')), findsOneWidget);
      expect(find.text('Payer 31\u00A0420\u00A0FCFA'), findsOneWidget);
      expect(find.byKey(const Key('home.month')), findsOneWidget);
      await scrollThrough(tester);
      expect(find.text('Activité récente'), findsOneWidget);
      expect(find.text('Tout voir'), findsOneWidget);
      expect(find.text('Facture de juil.\u2013août 2026 payée'), findsOneWidget);
      expect(find.textContaining('TEXTE API'), findsNothing);
      expect(find.textContaining('Nouvelle facture de'), findsOneWidget);
    });

    testWidgets('aucune non lue : pas de point rouge', (tester) async {
      await pumpHome(tester, FakeHomeBackend()..unread = 0);
      expect(find.byKey(const Key('home.bell.dot')), findsNothing);
      expect(tester.getSemantics(find.byKey(const Key('home.bell'))).label, 'Notifications');
    });

    testWidgets('paiement en cours : « Paiement en cours » au lieu de Payer', (tester) async {
      final backend = FakeHomeBackend()
        ..toPay = [
          FakeHomeBackend.bill(101, household: 1, meter: 11, status: BillStatuses.pendingPayment),
        ];
      await pumpHome(tester, backend);
      expect(find.widgetWithText(InkWell, 'Paiement en cours').hitTestable(), findsOneWidget);
      expect(find.byType(PayButton), findsNothing);
    });

    testWidgets('tout payé : « Tout est payé »', (tester) async {
      await pumpHome(tester, FakeHomeBackend()..toPay = []);
      expect(find.text('Tout est payé'), findsOneWidget);
      expect(find.byType(PayButton), findsNothing);
    });

    testWidgets('compte neuf : « Ajoutez votre premier compteur », sans « Tout est payé »', (
      tester,
    ) async {
      final backend = FakeHomeBackend()
        ..households = []
        ..toPay = [];
      await pumpHome(tester, backend);
      expect(find.text('Ajoutez votre premier compteur'), findsOneWidget);
      expect(find.text('Tout est payé'), findsNothing);
      await tester.tap(find.text('Ajouter un compteur'));
      await settle(tester);
      expect(find.text('Compteurs et foyers : bientôt'), findsOneWidget);
    });
  });

  group('foyer', () {
    testWidgets('choisir un foyer : sa facture, le rappel du retard ailleurs, choix gardé', (
      tester,
    ) async {
      final choices = MemoryHouseholdChoiceStore();
      await pumpHome(tester, FakeHomeBackend(), choices: choices);
      await tester.tap(find.byKey(const Key('home.household')));
      await settle(tester);
      expect(find.text('Choisir un foyer'), findsOneWidget);
      await tester.tap(find.byKey(const Key('home.household.1')));
      await settle(tester);
      expect(choices.saved, 1);
      expect(find.text('Maison Mpita · 2 foyers'), findsOneWidget);
      expect(find.text('1 facture en retard dans Boutique Tié-Tié'), findsOneWidget);
      // Le rappel ramène au foyer en retard.
      await tester.tap(find.byKey(const Key('home.elsewhere.2')));
      await settle(tester);
      expect(choices.saved, 2);
      expect(find.text('Boutique Tié-Tié · 2 foyers'), findsOneWidget);
    });

    testWidgets('un seul foyer : son nom, sans menu', (tester) async {
      final backend = FakeHomeBackend();
      backend.households = [backend.households.first];
      await pumpHome(tester, backend);
      expect(find.text('Maison Mpita'), findsWidgets);
      await tester.tap(find.byKey(const Key('home.household')));
      await settle(tester);
      expect(find.text('Choisir un foyer'), findsNothing);
    });
  });

  group('liens', () {
    testWidgets('« Payer » → feuille de paiement de la facture urgente (F6)', (tester) async {
      await pumpHome(tester, FakeHomeBackend());
      await tester.tap(find.text('Payer 31\u00A0420\u00A0FCFA'));
      await settle(tester);
      expect(find.byType(PaymentSheetContent), findsOneWidget);
    });

    testWidgets('« Détail » → détail de la facture urgente (F5.3)', (tester) async {
      await pumpHome(tester, FakeHomeBackend());
      await tester.tap(find.text('Détail'));
      await settle(tester);
      expect(find.text('Facture 201'), findsOneWidget);
    });

    testWidgets('cloche → écran Notifications ; au retour, le point rouge est relu', (
      tester,
    ) async {
      final backend = FakeHomeBackend();
      await pumpHome(tester, backend);
      await tester.tap(find.byKey(const Key('home.bell')));
      await settle(tester);
      expect(find.byType(NotificationsScreen), findsOneWidget);
      backend.unread = 0;
      await tester.pageBack();
      await settle(tester);
      expect(find.byKey(const Key('home.bell.dot')), findsNothing);
    });

    testWidgets('« Tout voir » → historique des paiements (F6.5)', (tester) async {
      await pumpHome(tester, FakeHomeBackend());
      await scrollThrough(tester);
      await tester.tap(find.byKey(const Key('home.activity.all')));
      await settle(tester);
      expect(find.text('Écran Historique'), findsOneWidget);
    });

    testWidgets('carte du mois → onglet Conso', (tester) async {
      await pumpHome(tester, FakeHomeBackend());
      await tester.tap(find.byKey(const Key('home.month')));
      await settle(tester);
      expect(find.text('Écran Conso'), findsOneWidget);
    });
  });

  group('états', () {
    testWidgets('une carte en échec : elle seule, avec « Réessayer » ; les autres s’affichent', (
      tester,
    ) async {
      final backend = FakeHomeBackend()..down.add('/payments');
      await pumpHome(tester, backend);
      expect(find.byKey(const Key('home.hero')), findsOneWidget);
      await scrollThrough(tester);
      expect(
        find.text('Hors connexion : impossible de charger votre activité récente.'),
        findsOneWidget,
      );
      backend.down.clear();
      await tester.tap(find.text('Réessayer'));
      await settle(tester);
      expect(find.text('Activité récente'), findsOneWidget);
    });

    testWidgets('erreur du serveur : la référence de la requête est affichée', (tester) async {
      final backend = FakeHomeBackend()
        ..forced['/payments'] = JsonReply(500, apiError('INTERNAL', 'Erreur'), requestId: 'r-42');
      await pumpHome(tester, backend);
      await scrollThrough(tester);
      expect(find.text('Référence : r-42'), findsOneWidget);
    });

    testWidgets('hors ligne avec le cache : bannière datée, Payer désactivé', (tester) async {
      final backend = FakeHomeBackend();
      await pumpHome(tester, backend);
      await tester.pumpWidget(const SizedBox());
      backend.down.addAll(['/me', '/households', '/bills', '/meters', '/payments']);
      await pumpHome(tester, backend);
      expect(
        find.textContaining('Hors connexion. Les données affichées datent du'),
        findsOneWidget,
      );
      expect(find.text(PayButton.offlineHint), findsOneWidget);
    });

    testWidgets('rien de lisible (hors ligne, pas de cache) : un seul bloc « Hors connexion »', (
      tester,
    ) async {
      final backend = FakeHomeBackend()..down.addAll(['/me', '/households', '/bills']);
      await pumpHome(tester, backend);
      expect(find.text('Hors connexion'), findsOneWidget);
      expect(find.byKey(const Key('home.hero')), findsNothing);
    });

    testWidgets('chargement : squelettes, puis le contenu', (tester) async {
      await pumpHome(tester, FakeHomeBackend(), wait: false);
      expect(tester.getSemantics(find.byType(AppSkeleton).first).label, contains('Chargement'));
      expect(find.text('Bonjour'), findsOneWidget, reason: 'prénom pas encore lu');
      await settle(tester);
      expect(find.byType(AppSkeleton), findsNothing);
      expect(find.text('Bonjour Loick'), findsOneWidget);
    });
  });

  group('actualiser', () {
    testWidgets('tirer vers le bas relit toutes les cartes', (tester) async {
      final backend = FakeHomeBackend();
      await pumpHome(tester, backend);
      final before = backend.server.requests.length;
      backend.unread = 0;
      await tester.fling(find.byKey(const Key('home.list')), const Offset(0, 400), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await settle(tester);
      for (final path in ['/me', '/households', '/bills', '/payments']) {
        expect(
          backend.server.requests.skip(before).where((r) => r.path == path),
          isNotEmpty,
          reason: path,
        );
      }
      expect(find.byKey(const Key('home.bell.dot')), findsNothing);
    });

    testWidgets('retour sur l’application : la cloche est relue (et seulement elle)', (
      tester,
    ) async {
      final backend = FakeHomeBackend();
      await pumpHome(tester, backend);
      backend.unread = 0;
      final before = backend.server.requests.length;
      tester.binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester);
      final paths = backend.server.requests.skip(before).map((r) => r.path).toSet();
      expect(paths, {'/notifications/unread-count'});
      expect(find.byKey(const Key('home.bell.dot')), findsNothing);
    });
  });

  group('règle 2 : écran de l’itel, texte à 100, 130 et 200 %', () {
    for (final scale in textScales) {
      testWidgets('rien ne déborde à ${(scale * 100).round()} %', (tester) async {
        await pumpHome(tester, FakeHomeBackend(), textScale: scale);
        await scrollThrough(tester);
        expect(tester.takeException(), isNull);
      });

      testWidgets('compte neuf, rien ne déborde à ${(scale * 100).round()} %', (tester) async {
        final backend = FakeHomeBackend()
          ..households = []
          ..toPay = [];
        await pumpHome(tester, backend, textScale: scale);
        await scrollThrough(tester);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('thème Jour : rien ne déborde', (tester) async {
      await pumpHome(tester, FakeHomeBackend(), textScale: 1.3, theme: AppTheme.light);
      await scrollThrough(tester);
      expect(tester.takeException(), isNull);
    });
  });
}
