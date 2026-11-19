// Parcours des factures (F5) rejoués sur le téléphone, contre l'API de démo du PC.
//
// Aux jalons seulement, jamais en CI :
//   .\tool\integration.ps1 -Device <téléphone> -Target integration_test/bills_test.dart
// Base DÉDIÉE `elecpay_e2e` remise à zéro et remplie par le script (jamais la base de démo `elecpay`).
// Compte de démo du seed : Arnaud Mavoungou (Maison Mpita + Boutique Tié-Tié). L'ouverture du PDF
// lance une autre application (lecteur PDF) : elle se vérifie à l'œil, pas ici.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/itel_app.dart';

/// Compte de démo du seed (backend/app/simulators/demo_dataset.py), saisi « 06… ».
const demoOwnerPhone = '060000101';
const demoPassword = 'Demo2026!';

Future<void> login(WidgetTester tester) async {
  await startApp(tester);
  await typeInto(tester, 0, demoOwnerPhone);
  await typeInto(tester, 1, demoPassword);
  await tapOn(tester, find.text('Se connecter'));
  await waitFor(tester, find.byKey(const Key('home.list')));
}

void main() {
  binding; // initialise le binding des tests d'intégration

  testWidgets('Mes factures : reste à payer, onglets, groupes par période', (tester) async {
    await login(tester);
    await tapOn(tester, find.text('Factures').last);
    await waitFor(tester, find.byKey(const Key('bills.outstanding')));
    expect(find.text('RESTE À PAYER · 2 FOYERS'), findsOneWidget);
    await shot(tester, 'f5-1-mes-factures');

    for (final filter in ['toPay', 'paid', 'overdue', 'all']) {
      await tapOn(tester, find.byKey(Key('bills.filter.$filter')));
      await waitFor(tester, find.byKey(const Key('bills.list')));
      await shot(tester, 'f5-2-onglet-$filter');
    }

    // Défilement : la deuxième page arrive (le seed a 12 à 24 mois d'historique).
    for (var i = 0; i < 6; i++) {
      await tester.drag(find.byKey(const Key('bills.list')), const Offset(0, -700));
      await tester.pump(const Duration(milliseconds: 600));
    }
    await shot(tester, 'f5-3-bas-de-liste');
  });

  testWidgets('détail d’une facture : lignes E²C, comparaison, PDF et Payer en bas', (
    tester,
  ) async {
    await login(tester);
    await tapOn(tester, find.text('Détail'));
    await waitFor(tester, find.byKey(const Key('bill.detail')));
    expect(find.byKey(const Key('bill.pdf')), findsOneWidget);
    await shot(tester, 'f5-4-detail-haut');
    for (var i = 0; i < 3; i++) {
      await tester.drag(find.byKey(const Key('bill.detail')), const Offset(0, -500));
      await tester.pump(const Duration(milliseconds: 400));
    }
    await waitFor(tester, find.byKey(const Key('bill.total')));
    await shot(tester, 'f5-5-detail-lignes');
    await androidBack(tester);
    await waitFor(tester, find.byKey(const Key('home.list')));
  });
}
