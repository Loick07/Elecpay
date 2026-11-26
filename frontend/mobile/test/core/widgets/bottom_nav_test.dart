import 'package:elecpay/core/theme/app_icons.dart';
import 'package:elecpay/core/theme/tokens.g.dart';
import 'package:elecpay/core/widgets/bottom_nav.dart';
import 'package:elecpay/core/widgets/glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/itel_screen.dart';

const c = ElecPayColors.dark;

void main() {
  final tabs = <AppTab>[];
  var pays = 0;

  Widget nav({AppTab current = AppTab.home, bool online = true, bool overdue = false}) =>
      AppBottomNav(
        current: current,
        onTab: tabs.add,
        onPay: () => pays++,
        online: online,
        billsOverdue: overdue,
      );

  setUp(() {
    tabs.clear();
    pays = 0;
  });

  testWidgets('5 entrées de la maquette, dans l’ordre ; Payer au centre', (tester) async {
    await pumpOnItel(tester, nav());
    final labels = ['Accueil', 'Factures', 'Payer', 'Conso', 'Compte'];
    final xs = [for (final label in labels) tester.getCenter(find.text(label)).dx];
    expect(xs, orderedEquals([...xs]..sort()));
    final screenCenter = tester.view.physicalSize.width / tester.view.devicePixelRatio / 2;
    expect((xs[2] - screenCenter).abs(), lessThan(20), reason: 'Payer au centre');
  });

  // Vu sur l'itel pendant M1 : « Payer » plus haut que les autres libellés (décalage d'affichage),
  // barre trop haute, disque qui dépassait à peine, contenu visible sous la barre.
  for (final scale in [1.0, 1.3]) {
    testWidgets('texte × $scale : les 5 libellés sur la même ligne', (tester) async {
      await pumpOnItel(tester, nav(), textScale: scale);
      final ys = [
        for (final label in ['Accueil', 'Factures', 'Payer', 'Conso', 'Compte'])
          tester.getRect(find.text(label)).bottom,
      ];
      for (final y in ys) {
        expect(y, closeTo(ys.first, 0.5));
      }
    });

    testWidgets('texte × $scale : disque Payer au-dessus du bord, sans toucher « Payer »', (
      tester,
    ) async {
      await pumpOnItel(tester, nav(), textScale: scale);
      final bar = tester.getRect(find.byType(GlassSurface));
      final disc = tester.getRect(
        find.ancestor(of: find.byIcon(AppIcons.navPay), matching: find.byType(Container)).first,
      );
      final label = tester.getRect(find.text('Payer'));
      expect(bar.height, AppBottomNav.barHeight);
      expect(disc.top, lessThan(bar.top - 20), reason: 'dépasse franchement du bord');
      expect(disc.bottom, lessThanOrEqualTo(label.top), reason: 'ne recouvre pas « Payer »');
      expect((disc.center.dx - label.center.dx).abs(), lessThan(0.5), reason: 'centré');
    });
  }

  // Demande de Loick (validation de la barre, M1) : zone tactile de Payer d'au moins 48 points.
  for (final scale in [1.0, 1.3]) {
    testWidgets('texte × $scale : zones tactiles de Payer ≥ 48 points (disque et libellé)', (
      tester,
    ) async {
      await pumpOnItel(tester, nav(), textScale: scale);
      final disc = tester.getSize(
        find.ancestor(of: find.byIcon(AppIcons.navPay), matching: find.byType(GestureDetector)),
      );
      final label = tester.getSize(
        find.ancestor(of: find.text('Payer'), matching: find.byType(GestureDetector)).first,
      );
      for (final size in [disc, label]) {
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
      // Toucher le bord du disque (pas seulement son centre) ouvre bien le paiement.
      final rect = tester.getRect(
        find.ancestor(of: find.byIcon(AppIcons.navPay), matching: find.byType(GestureDetector)),
      );
      await tester.tapAt(rect.topCenter + const Offset(0, 6));
      expect(pays, 1);
    });
  }

  testWidgets('fondu vers le fond derrière la barre (le contenu ne se voit plus dessous)', (
    tester,
  ) async {
    await pumpOnItel(tester, nav());
    final fade = tester.widget<DecoratedBox>(find.byKey(const Key('bottomNav.fade')));
    final gradient = (fade.decoration as BoxDecoration).gradient! as LinearGradient;
    expect(gradient.colors.first.a, 0, reason: 'transparent en haut');
    expect(gradient.colors.last, c.bg, reason: 'couleur du fond en bas');
  });

  testWidgets('verre (un des deux usages permis), coins arrondis xl', (tester) async {
    await pumpOnItel(tester, nav());
    final glass = tester.widget<GlassSurface>(find.byType(GlassSurface));
    expect(glass.borderRadius, const BorderRadius.all(Radius.circular(Radii.xl)));
  });

  testWidgets('onglet actif : ink + point volt ; inactifs : ink-muted', (tester) async {
    await pumpOnItel(tester, nav(current: AppTab.bills));
    expect(tester.widget<Text>(find.text('Factures')).style!.color, c.ink);
    expect(tester.widget<Text>(find.text('Accueil')).style!.color, c.inkMuted);
    final dots = tester
        .widgetList<Container>(find.byType(Container))
        .where((box) => (box.decoration as BoxDecoration?)?.color == c.volt)
        .where((box) => box.constraints?.maxWidth == 4);
    expect(dots, hasLength(1));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Factures')).flagsCollection.isSelected,
      isNotNull,
    );
  });

  testWidgets('toucher un onglet le signale', (tester) async {
    await pumpOnItel(tester, nav());
    await tester.tap(find.text('Conso'));
    await tester.tap(find.byIcon(AppIcons.navAccount));
    expect(tabs, [AppTab.consumption, AppTab.account]);
  });

  testWidgets('Payer : disque volt de 56, ouvre le paiement', (tester) async {
    await pumpOnItel(tester, nav());
    final disc = find.ancestor(of: find.byIcon(AppIcons.navPay), matching: find.byType(Container));
    expect(tester.getSize(disc.first), const Size(56, 56));
    expect((tester.widget<Container>(disc.first).decoration! as BoxDecoration).color, c.volt);
    await tester.tap(find.text('Payer'));
    expect(pays, 1);
  });

  testWidgets('HORS LIGNE : Payer ne lance rien et dit pourquoi', (tester) async {
    await pumpOnItel(tester, nav(online: false));
    await tester.tap(find.byIcon(AppIcons.navPay));
    await tester.pump();
    expect(pays, 0);
    expect(find.text('Connexion nécessaire pour payer'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel(RegExp('^Payer, connexion'))).label,
      'Payer, connexion nécessaire pour payer',
    );
  });

  testWidgets('facture en retard : pastille error sur Factures, lue par le lecteur d’écran', (
    tester,
  ) async {
    await pumpOnItel(tester, nav(overdue: true));
    expect(find.bySemanticsLabel('Factures, une facture est en retard'), findsOneWidget);
    final pastilles = tester
        .widgetList<Container>(find.byType(Container))
        .where((box) => (box.decoration as BoxDecoration?)?.color == c.error);
    expect(pastilles, hasLength(1));
  });

  testWidgets('sans retard : aucune pastille', (tester) async {
    await pumpOnItel(tester, nav());
    final pastilles = tester
        .widgetList<Container>(find.byType(Container))
        .where((box) => (box.decoration as BoxDecoration?)?.color == c.error);
    expect(pastilles, isEmpty);
  });

  for (final scale in textScales) {
    testWidgets('texte × $scale : tient sur l’itel, zones tactiles ≥ 48', (tester) async {
      await pumpOnItel(tester, nav(overdue: true), textScale: scale);
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });
  }

  testWidgets('libellés plafonnés à 130 % (5 entrées sur 360 points)', (tester) async {
    await pumpOnItel(tester, nav(), textScale: 2);
    final style = tester.widget<Text>(find.text('Accueil'));
    final scaler = MediaQuery.textScalerOf(tester.element(find.text('Accueil')));
    expect(scaler.scale(style.style!.fontSize!), closeTo(style.style!.fontSize! * 1.3, 0.01));
  });
}
