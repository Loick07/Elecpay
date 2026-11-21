// F10.3 : parcours client COMPLET rejoué sur le téléphone, contre l'API de démo du PC :
// inscription → compteur → consommation → facture → paiement → reçu → historique.
//
// Aux jalons seulement, jamais en CI :
//   .\tool\integration.ps1 -Device <téléphone> -Target integration_test/full_journey_test.dart
// Base DÉDIÉE `elecpay_e2e` remise à zéro par le script (jamais la base de démo `elecpay`).
// Compteur : E²C SIMULÉ (tout branchement est trouvé, sauf ceux qui finissent par 0000 ;
// backend/docs/FOYERS_COMPTEURS.md) ; paiement : prestataire SIMULÉ, aucun débit réel.
import 'dart:math';

import 'package:elecpay/core/widgets/bill_row.dart';
import 'package:elecpay/core/widgets/pay_button.dart';
import 'package:elecpay/features/payments/payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/itel_app.dart';

/// Saisit `text` dans le champ de la clé `key` (champs de la feuille « Ajouter un compteur »).
Future<void> typeIn(WidgetTester tester, String key, String text) async {
  final field = find.descendant(of: find.byKey(Key(key)), matching: find.byType(EditableText));
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  binding; // initialise le binding des tests d'intégration

  testWidgets('inscription → compteur → conso → facture → paiement → reçu → historique', (
    tester,
  ) async {
    await startApp(tester);

    // 1. Inscription (compte neuf : aucun compteur).
    await tapOn(tester, find.text('Créer un compte'));
    await waitFor(tester, find.text('Créer mon compte'));
    await typeInto(tester, 0, 'Parcours Complet');
    await typeInto(tester, 1, newTestPhone());
    await typeInto(tester, 3, testPassword);
    await tapOn(tester, find.byType(Checkbox));
    await tapOn(tester, find.text('Créer mon compte'));
    await waitFor(tester, find.byKey(const Key('home.noMeter')));
    await shot(tester, 'f10-1-accueil-neuf');

    // 2. Compteur : N° de branchement neuf à chaque passage, nouveau foyer.
    await tapOn(tester, find.text('Ajouter un compteur'));
    await waitFor(tester, find.byKey(const Key('addMeter.form')));
    final reference = '0018${(100000 + Random().nextInt(899999)).toString()}';
    await typeIn(tester, 'addMeter.reference', reference);
    await typeIn(tester, 'addMeter.customer', '0758340H');
    await typeIn(tester, 'addMeter.name', 'Maison Parcours');
    await typeIn(tester, 'addMeter.city', 'Pointe-Noire');
    await shot(tester, 'f10-2-ajout-compteur');
    await tapOn(tester, find.byKey(const Key('addMeter.submit')));
    await waitFor(
      tester,
      find.byKey(const Key('addMeter.success')),
      timeout: const Duration(seconds: 60), // import de l'historique de démo
    );
    await shot(tester, 'f10-3-compteur-ajoute');
    await tapOn(tester, find.byKey(const Key('addMeter.done')));
    // L'écran Compteurs et foyers est posé sur l'accueil (sans barre du bas) : on y revient.
    await androidBack(tester);
    await waitFor(tester, find.byKey(const Key('home.list')));

    // 3. Consommation (historique importé).
    await tapOn(tester, find.text('Conso'));
    await waitFor(
      tester,
      find.byKey(const Key('conso.list')),
      timeout: const Duration(seconds: 30),
    );
    await shot(tester, 'f10-4-conso');

    // 4. Facture à payer → détail.
    await tapOn(tester, find.text('Factures'));
    await waitFor(tester, find.byKey(const Key('bills.list')));
    await tapOn(tester, find.byKey(const Key('bills.filter.toPay')));
    await waitFor(tester, find.byType(BillRow));
    await tapOn(tester, find.byType(BillRow));
    await waitFor(tester, find.byKey(const Key('bill.detail')));
    await shot(tester, 'f10-5-detail');

    // 5. Paiement (numéro du compte : réussit) → bascule seule sur le reçu.
    await tapOn(
      tester,
      find.descendant(of: find.byKey(const Key('bill.footer')), matching: find.byType(PayButton)),
    );
    await waitFor(tester, find.text('MOYEN DE PAIEMENT'));
    await tapOn(tester, find.textContaining('Payer ').last);
    await waitFor(tester, find.byType(PaymentScreen));
    await shot(tester, 'f10-6-attente');
    await waitFor(
      tester,
      find.byKey(const Key('receipt.screen')),
      timeout: const Duration(seconds: 60),
    );
    await shot(tester, 'f10-7-recu');
    await tapOn(tester, find.byKey(const Key('receipt.done')));
    await tester.pump(const Duration(seconds: 2));

    // 6. Historique : le paiement réussi y est.
    await tapOn(tester, find.text('Compte'));
    await waitFor(tester, find.byKey(const Key('account.history')));
    await tapOn(tester, find.byKey(const Key('account.history')));
    await waitFor(tester, find.byKey(const Key('history.list')));
    await waitFor(tester, find.text('Réussie'));
    await shot(tester, 'f10-8-historique');
  });
}
