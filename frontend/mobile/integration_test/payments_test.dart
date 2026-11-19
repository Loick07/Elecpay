// Parcours de paiement (F6) rejoués sur le téléphone, contre l'API de démo du PC (prestataire
// SIMULÉ : aucun débit réel).
//
// Aux jalons seulement, jamais en CI :
//   .\tool\integration.ps1 -Device <téléphone> -Target integration_test/payments_test.dart
// Base DÉDIÉE `elecpay_e2e` remise à zéro et remplie par le script (jamais la base de démo `elecpay`).
// Numéros de test du simulateur (backend/docs/PAIEMENTS.md) : `06 000 00 02` solde insuffisant,
// `06 000 00 06` prestataire injoignable ; tout autre numéro réussit (PIN ~5 s, succès ~10 s).
// Pas joués ici : `… 04` (expire au bout de 10 min) et `… 05` (jamais confirmé : bloque la facture).
import 'package:elecpay/features/payments/payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/itel_app.dart';

/// Compte de démo du seed (backend/app/simulators/demo_dataset.py), saisi « 06… ».
const demoOwnerPhone = '060000101';
const demoPassword = 'Demo2026!';

Future<void> loginAndOpenSheet(WidgetTester tester) async {
  await startApp(tester);
  await typeInto(tester, 0, demoOwnerPhone);
  await typeInto(tester, 1, demoPassword);
  await tapOn(tester, find.text('Se connecter'));
  await waitFor(tester, find.byKey(const Key('home.list')));
  await tapOn(tester, find.text('Payer').last); // bouton central de la barre du bas
  // Plusieurs factures : on prend la première proposée (la plus urgente).
  final choose = find.textContaining('Quelle facture payer');
  if (choose.evaluate().isNotEmpty) {
    await tapOn(tester, find.byWidgetPredicate((w) => '${w.key}'.contains('pay.choose.')).first);
  }
  await waitFor(tester, find.text('MOYEN DE PAIEMENT'));
}

/// Remplace le numéro de la feuille (premier champ) puis touche Payer.
Future<void> payFrom(WidgetTester tester, String digits) async {
  await typeInto(tester, 0, digits);
  await tapOn(tester, find.textContaining('Payer ').last);
  await waitFor(tester, find.byType(PaymentScreen));
}

void main() {
  binding; // initialise le binding des tests d'intégration

  testWidgets('solde insuffisant (06 000 00 02) : Échoué avec le motif, Réessayer', (tester) async {
    await loginAndOpenSheet(tester);
    await shot(tester, 'f6-1-feuille');
    await payFrom(tester, '060000002');
    await shot(tester, 'f6-2-attente');
    await waitFor(tester, find.text('Paiement échoué'), timeout: const Duration(seconds: 40));
    await shot(tester, 'f6-3-echoue');
    expect(find.text('Réessayer'), findsOneWidget);
  });

  testWidgets('prestataire injoignable (06 000 00 06) : Échoué tout de suite, rien débité', (
    tester,
  ) async {
    await loginAndOpenSheet(tester);
    await payFrom(tester, '060000006');
    await waitFor(tester, find.text('Paiement échoué'), timeout: const Duration(seconds: 20));
    await shot(tester, 'f6-4-injoignable');
  });

  testWidgets('paiement réussi (numéro du compte) : étapes, puis « Paiement réussi »', (
    tester,
  ) async {
    await loginAndOpenSheet(tester);
    await tapOn(tester, find.textContaining('Payer ').last);
    await waitFor(tester, find.byType(PaymentScreen));
    await waitFor(tester, find.text('Paiement réussi'), timeout: const Duration(seconds: 60));
    await shot(tester, 'f6-5-reussi');
    expect(find.text('Voir le reçu'), findsOneWidget);
  });
}
