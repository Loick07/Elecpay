import 'package:elecpay/core/theme/app_theme.dart';
import 'package:elecpay/core/theme/tokens.g.dart';
import 'package:elecpay/core/widgets/bottom_sheet.dart';
import 'package:elecpay/core/widgets/glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsNode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/itel_screen.dart';

/// Donnée affichée par l'écran du dessous (comme une facture lue dans le cache).
const cachedData = 'Maison Mpita · 31 420 FCFA';

/// Un écran avec une donnée et un bouton qui ouvre la feuille.
Widget opener(void Function(BuildContext context) open) => ProviderScope(
  child: MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: Builder(
        builder: (context) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(cachedData),
            TextButton(onPressed: () => open(context), child: const Text('Ouvrir')),
          ],
        ),
      ),
    ),
  ),
);

/// Tous les textes que le lecteur d'écran peut lire, en parcourant l'arbre RÉEL depuis sa racine.
List<String> readableTexts(WidgetTester tester) {
  final texts = <String>[];
  void visit(SemanticsNode node) {
    final data = node.getSemanticsData();
    if (data.label.isNotEmpty) texts.add(data.label);
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(tester.binding.renderViews.single.owner!.semanticsOwner!.rootSemanticsNode!);
  return texts;
}

/// Le voile posé entre l'écran du dessous et la feuille.
ModalBarrier barrier(WidgetTester tester) =>
    tester.widgetList<ModalBarrier>(find.byType(ModalBarrier)).lastWhere((b) => b.color != null);

Future<void> openSheet(WidgetTester tester, void Function(BuildContext context) open) async {
  tester.view.physicalSize = itelPhysicalSize;
  tester.view.devicePixelRatio = itelPixelRatio;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(opener(open));
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('feuille du bas : en verre, avec poignée, se ferme d’un toucher à côté', (
    tester,
  ) async {
    await openSheet(tester, (context) => showAppSheet<void>(context, child: const Text('Filtres')));
    expect(find.text('Filtres'), findsOneWidget);
    expect(find.byType(GlassSurface), findsOneWidget);
    await tester.tapAt(const Offset(180, 40)); // au-dessus de la feuille
    await tester.pumpAndSettle();
    expect(find.text('Filtres'), findsNothing);
  });

  group('session expirée', () {
    testWidgets('texte de la charte, une seule action « Se reconnecter »', (tester) async {
      var reconnect = 0;
      await openSheet(
        tester,
        (context) => showSessionExpiredSheet(context, onReconnect: () => reconnect++),
      );
      expect(find.text('Votre session a expiré. Reconnectez-vous pour continuer.'), findsOneWidget);
      await tester.tap(find.text('Se reconnecter'));
      expect(reconnect, 1);
    });

    testWidgets('l’écran du dessous est entièrement masqué : fond opaque, données illisibles', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await openSheet(tester, (context) => showSessionExpiredSheet(context, onReconnect: () {}));

      // 1. Fond OPAQUE à la couleur du fond de l'application, sur tout l'écran.
      final veil = barrier(tester);
      expect(veil.color, ElecPayColors.dark.bg);
      expect(veil.color!.a, 1.0, reason: 'opaque : rien ne transparaît à travers le verre');
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      final covered = tester.getRect(
        find.byWidgetPredicate((w) => w is ModalBarrier && w.color == ElecPayColors.dark.bg),
      );
      expect(covered, Offset.zero & screen);

      // 2. La donnée du dessous n'est plus accessible : ni au toucher, ni au lecteur d'écran.
      expect(find.text(cachedData).hitTestable(), findsNothing);
      final readable = readableTexts(tester);
      expect(readable, contains('Votre session a expiré. Reconnectez-vous pour continuer.'));
      expect(readable.where((t) => t.contains('Maison Mpita')), isEmpty, reason: '$readable');
      semantics.dispose();
    });

    testWidgets('contre-épreuve : AVANT la feuille, la donnée est bien lisible', (tester) async {
      final semantics = tester.ensureSemantics();
      tester.view.physicalSize = itelPhysicalSize;
      tester.view.devicePixelRatio = itelPixelRatio;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        opener((context) => showSessionExpiredSheet(context, onReconnect: () {})),
      );
      expect(readableTexts(tester).where((t) => t.contains('Maison Mpita')), isNotEmpty);
      expect(find.text(cachedData).hitTestable(), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('contre-épreuve : une feuille ordinaire garde le voile translucide', (
      tester,
    ) async {
      await openSheet(
        tester,
        (context) => showAppSheet<void>(context, child: const Text('Filtres')),
      );
      expect(barrier(tester).color!.a, lessThan(1.0));
    });

    testWidgets('ne se ferme ni en touchant à côté, ni par le bouton retour', (tester) async {
      await openSheet(tester, (context) => showSessionExpiredSheet(context, onReconnect: () {}));
      await tester.tapAt(const Offset(180, 40));
      await tester.pumpAndSettle();
      expect(find.text('Se reconnecter'), findsOneWidget);
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      await navigator.maybePop();
      await tester.pumpAndSettle();
      expect(find.text('Se reconnecter'), findsOneWidget);
    });

    for (final scale in textScales) {
      testWidgets('texte × $scale : tient sur l’itel sans débordement', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await openSheet(tester, (context) => showSessionExpiredSheet(context, onReconnect: () {}));
        expect(tester.takeException(), isNull);
        expect(find.text('Se reconnecter'), findsOneWidget);
      });
    }
  });
}
