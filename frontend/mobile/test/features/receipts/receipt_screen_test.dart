import 'package:elecpay/app/riverpod_config.dart';
import 'package:elecpay/app/routes.dart';
import 'package:elecpay/core/cache/cache_policy.dart';
import 'package:elecpay/core/documents/documents.dart';
import 'package:elecpay/core/theme/app_theme.dart';
import 'package:elecpay/core/widgets/app_button.dart';
import 'package:elecpay/core/widgets/bottom_nav.dart';
import 'package:elecpay/core/widgets/skeleton.dart';
import 'package:elecpay/features/home/home_screen.dart';
import 'package:elecpay/features/receipts/receipt_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/fake_documents.dart';
import '../../support/fake_home_backend.dart';
import '../../support/itel_screen.dart';

class ReceiptHarness {
  final backend = FakeHomeBackend();
  final actions = FakeDocumentActions();
  final downloader = FakeDownloader();

  Future<void> pump(
    WidgetTester tester, {
    int receiptId = 3,
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
      initialLocation: Routes.receipt(receiptId),
      routes: [
        GoRoute(
          path: AppTab.home.path,
          builder: (context, state) => const Scaffold(body: Text('Accueil')),
        ),
        GoRoute(
          path: Routes.receiptPath,
          builder: (context, state) =>
              ReceiptScreen(receiptId: int.parse(state.pathParameters['receiptId']!)),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        retry: noAutomaticRetry,
        overrides: [
          ...backend.overrides(),
          homeClockProvider.overrideWithValue(() => DateTime.utc(2026, 11, 12, 15)),
          documentActionsProvider.overrideWithValue(actions),
          documentDownloaderProvider.overrideWithValue(downloader),
        ],
        child: MaterialApp.router(theme: theme ?? AppTheme.dark, routerConfig: router),
      ),
    );
    if (wait) await settle(tester);
  }
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Fait défiler jusqu'à `finder` (la liste ne construit que ce qui est à l'écran).
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
  await tester.pump();
}

Future<void> tapVisible(WidgetTester tester, String key) async {
  await scrollTo(tester, find.byKey(Key(key)));
  await tester.tap(find.byKey(Key(key)));
  await settle(tester);
}

void main() {
  // F10.1 : état « chargement » de l'écran.
  testWidgets('chargement : squelettes, puis le contenu', (tester) async {
    await ReceiptHarness().pump(tester, wait: false);
    expect(find.byType(AppSkeleton), findsWidgets);
    await settle(tester);
    expect(find.byType(AppSkeleton), findsNothing);
    expect(find.text('MODE DÉMO'), findsOneWidget);
  });

  test('reçu en cache (il ne change jamais) ; son PDF jamais', () {
    expect(isCacheable('/receipts/3'), isTrue);
    expect(isCacheable('/receipts/3/pdf'), isFalse);
  });

  testWidgets('maquette : paiement réussi, numéro, montant, détail, Mode démo', (tester) async {
    await ReceiptHarness().pump(tester);
    expect(find.text('Paiement réussi'), findsOneWidget);
    expect(
      find.text('La facture de septembre–octobre 2026 est payée.'),
      findsOneWidget,
      reason: 'période construite à partir des dates',
    );
    expect(find.text('Reçu EP-2026-000123'), findsOneWidget);
    expect(find.text('MODE DÉMO'), findsOneWidget);
    for (final label in [
      'Facture : sept.–oct. 2026 · 20261103000127',
      'Foyer : Maison Mpita · 0412-8833',
      'Payé par : Loick Makosso',
      'Date : 12 nov. à 14:32',
      'Transaction : TX-00000500',
      'Vérification : 8F3K-2Q9M-7XHT',
    ]) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
    expect(find.textContaining('TEXTE API'), findsNothing);
  });

  testWidgets('numéro TOUJOURS masqué (tel que l’API le donne)', (tester) async {
    await ReceiptHarness().pump(tester);
    expect(
      find.bySemanticsLabel(RegExp(r'^Moyen : MTN MoMo · \+242 06 \*\*\* 45 67$')),
      findsOneWidget,
    );
  });

  testWidgets('données réelles (e2c) : pas de badge Mode démo', (tester) async {
    final h = ReceiptHarness();
    h.backend.receipts[3] = FakeHomeBackend.receiptJson(3, source: 'e2c');
    await h.pump(tester);
    expect(find.text('MODE DÉMO'), findsNothing);
  });

  testWidgets('« Télécharger » : PDF du reçu ouvert dans le lecteur', (tester) async {
    final h = ReceiptHarness();
    await h.pump(tester);
    await tapVisible(tester, 'receipt.download');
    expect(h.downloader.requests, [('/receipts/3/pdf', 'recu-EP-2026-000123.pdf')]);
    expect(h.actions.opened, hasLength(1));
  });

  testWidgets('« Partager » : PDF du reçu partagé', (tester) async {
    final h = ReceiptHarness();
    await h.pump(tester);
    await tapVisible(tester, 'receipt.share');
    expect(h.actions.shared.single.$2, 'Reçu ElecPay EP-2026-000123');
  });

  testWidgets('hors ligne (cache) : reçu lisible, PDF désactivé avec la mention', (tester) async {
    final h = ReceiptHarness();
    await h.pump(tester);
    await tester.pumpWidget(const SizedBox());
    h.backend.down.add('/receipts');
    await h.pump(tester);
    expect(find.textContaining('Hors connexion. Les données affichées datent du'), findsOneWidget);
    expect(find.text('Reçu EP-2026-000123'), findsOneWidget);
    await scrollTo(tester, find.text('Connexion nécessaire pour le PDF'));
    expect(find.text('Connexion nécessaire pour le PDF'), findsOneWidget);
    final download = tester.widget<AppButton>(find.byKey(const Key('receipt.download')));
    expect(download.onPressed, isNull);
  });

  testWidgets('reçu d’un autre foyer (404) : « Accès impossible »', (tester) async {
    await ReceiptHarness().pump(tester, receiptId: 999);
    expect(find.text('Accès impossible'), findsOneWidget);
    expect(find.text('Reçu introuvable.'), findsOneWidget);
  });

  testWidgets('« Terminé » : retour à l’accueil', (tester) async {
    await ReceiptHarness().pump(tester);
    await tapVisible(tester, 'receipt.done');
    expect(find.text('Accueil'), findsOneWidget);
  });

  group('règle 2 : écran de l’itel, texte à 100, 130 et 200 %', () {
    for (final scale in textScales) {
      testWidgets('rien ne déborde à ${(scale * 100).round()} %', (tester) async {
        await ReceiptHarness().pump(tester, textScale: scale);
        for (var i = 0; i < 6; i++) {
          await tester.drag(find.byKey(const Key('receipt.screen')), const Offset(0, -300));
          await tester.pump();
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('thème Jour à 200 % : rien ne déborde', (tester) async {
      await ReceiptHarness().pump(tester, textScale: 2, theme: AppTheme.light);
      expect(tester.takeException(), isNull);
    });
  });
}
