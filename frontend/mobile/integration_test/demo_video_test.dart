// Parcours « démo » pour la vidéo de démonstration (demande de Loick, 27/11/2026) : les 16 écrans
// client dans un ordre logique, environ 3 s sur chaque écran, défilements lents. Aucune vérification
// de fond ici (les autres tests d'intégration s'en chargent) : seulement que chaque écran s'affiche.
//
// Jamais en CI. Base DÉDIÉE `elecpay_e2e` recréée par le script (jamais `elecpay` ni
// `elecpay_public`), API de test sur le port 8000 (l'API publique doit être arrêtée) :
//   .\tool\integration.ps1 -Device <téléphone> -Target integration_test/demo_video_test.dart
//
// Le film se fait à côté, depuis le PC : tool/video/tournage.py (adb shell screenrecord), lancé
// AVANT le parcours, puis tool/video/montage.py (mode d'emploi et leçons : JOURNAL.md). Le test écrit
// dans le journal du téléphone (logcat, étiquette `flutter`) des repères lus par le PC :
//   DEMO_PRET            le test démarre : le PC lance l'enregistrement (le test attend 4 s) ;
//   DEMO_ECRAN|ms|Nom    un écran est affiché (ms : heure du téléphone) : nom écrit sous la vidéo ;
//   DEMO_PDF             le PDF va s'ouvrir dans le lecteur du téléphone : le PC le referme (retour) ;
//   DEMO_FIN|ms          fin du parcours : le PC arrête l'enregistrement.
// Données : comptes FICTIFS du seed, paiement par le prestataire SIMULÉ (aucun débit réel).
import 'package:elecpay/core/widgets/bill_row.dart';
import 'package:elecpay/core/widgets/pay_button.dart';
import 'package:elecpay/features/notifications/notifications_screen.dart';
import 'package:elecpay/features/payments/payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/itel_app.dart';

/// Compte de démo du seed (Arnaud Mavoungou, comptes fictifs), saisi « 06… ».
const demoOwnerPhone = '060000101';
const demoPassword = 'Demo2026!';

/// Temps passé sur chaque écran.
const pause = Duration(seconds: 3);

/// Repère lu par le PC dans le journal du téléphone (voir l'en-tête).
void marker(String text) => debugPrint(text);

/// Un écran est affiché : son nom pour la vidéo, à l'heure du téléphone.
void screen(String name) => marker('DEMO_ECRAN|${DateTime.now().millisecondsSinceEpoch}|$name');

Future<void> hold(WidgetTester tester, [Duration duration = pause]) => tester.pump(duration);

/// Défilement lent (un doigt qui glisse), puis un court arrêt.
Future<void> slowScroll(WidgetTester tester, Finder list, double dy) async {
  await tester.timedDrag(list.first, Offset(0, dy), const Duration(milliseconds: 1600));
  await tester.pump(const Duration(milliseconds: 900));
}

/// Saisie lettre par lettre (le texte apparaît comme tapé ; le clavier du téléphone n'est pas utilisé).
Future<void> slowType(WidgetTester tester, Finder field, String text) async {
  await tester.ensureVisible(field.first);
  for (var i = 1; i <= text.length; i++) {
    await tester.enterText(field.first, text.substring(0, i));
    await tester.pump(const Duration(milliseconds: 90));
  }
  await tester.pump(const Duration(milliseconds: 300));
}

Finder fieldAt(int index) => find.byType(TextField).at(index);

/// Attend un changement d'état de l'application (lecteur PDF au premier plan, puis retour), sans
/// demander d'image : l'application en arrière-plan n'en dessine plus.
Future<bool> waitLifecycle(bool Function(AppLifecycleState? state) done, Duration timeout) async {
  final end = DateTime.now().add(timeout);
  while (!done(WidgetsBinding.instance.lifecycleState)) {
    if (DateTime.now().isAfter(end)) return false;
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
  return true;
}

void main() {
  // Images réelles, au rythme de l'écran : les animations se voient comme à l'usage.
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('démo : les 16 écrans client', timeout: const Timeout(Duration(minutes: 15)), (
    tester,
  ) async {
    marker('DEMO_PRET');
    await Future<void>.delayed(const Duration(seconds: 4)); // le PC lance l'enregistrement

    // 1. Démarrage (splash), puis 2. Connexion.
    screen('Démarrage');
    await startApp(tester); // attend « Connexion » (le splash dure 2 s au plus)
    screen('Connexion');
    await hold(tester);

    // 3. Inscription (formulaire seulement : aucun compte créé).
    await tapOn(tester, find.text('Créer un compte'));
    await waitFor(tester, find.text('Créer mon compte'));
    screen('Inscription');
    await tester.pump(const Duration(milliseconds: 800));
    await slowType(tester, fieldAt(0), 'Grâce Loubaki');
    await hold(tester);
    await androidBack(tester);
    await waitFor(tester, find.text('Mot de passe oublié ?'));

    // 4. Mot de passe oublié (étape 1 seulement : aucun code demandé).
    await tapOn(tester, find.text('Mot de passe oublié ?'));
    await waitFor(tester, find.text('Étape 1 sur 3'));
    screen('Mot de passe oublié');
    await hold(tester);
    await androidBack(tester);
    await waitFor(tester, find.text('Se connecter'));

    // Connexion au compte de démo (mot de passe masqué à l'écran).
    screen('Connexion');
    await slowType(tester, fieldAt(0), demoOwnerPhone);
    await slowType(tester, fieldAt(1), demoPassword);
    await tester.pump(const Duration(milliseconds: 600));
    await tapOn(tester, find.text('Se connecter'));

    // 5. Accueil.
    await waitFor(tester, find.byKey(const Key('home.list')));
    await tester.pump(const Duration(seconds: 1)); // cartes chargées
    screen('Accueil');
    await hold(tester);
    final home = find.byKey(const Key('home.list'));
    await slowScroll(tester, home, -450);
    await slowScroll(tester, home, -450);
    await hold(tester, const Duration(seconds: 2));
    await slowScroll(tester, home, 900);
    await tester.pump(const Duration(milliseconds: 600));

    // 6. Notifications (cloche de l'accueil).
    await tapOn(tester, find.byKey(const Key('home.bell')));
    await waitFor(tester, find.byType(NotificationsScreen));
    await waitFor(tester, find.byKey(const Key('notifications.list')));
    screen('Notifications');
    await hold(tester);
    await slowScroll(tester, find.byKey(const Key('notifications.list')), -500);
    await hold(tester, const Duration(seconds: 2));
    await androidBack(tester);
    await waitFor(tester, find.byKey(const Key('home.list')));

    // 7. Mes factures : toutes, puis « À payer ».
    await tapOn(tester, find.text('Factures').last);
    await waitFor(tester, find.byKey(const Key('bills.list')));
    await tester.pump(const Duration(seconds: 1));
    screen('Mes factures');
    await hold(tester);
    await tapOn(tester, find.byKey(const Key('bills.filter.all')));
    await waitFor(tester, find.byType(BillRow));
    await tester.pump(const Duration(milliseconds: 800));
    final bills = find.byKey(const Key('bills.list'));
    await slowScroll(tester, bills, -500);
    await slowScroll(tester, bills, 500);
    await tapOn(tester, find.byKey(const Key('bills.filter.toPay')));
    await waitFor(tester, find.byType(BillRow).hitTestable());
    await hold(tester, const Duration(seconds: 2));

    // 8. Détail d'une facture à payer (la première VISIBLE : jamais sous la barre du bas).
    await tester.tap(find.byType(BillRow).hitTestable().first);
    await tester.pump(const Duration(milliseconds: 500));
    await waitFor(tester, find.byKey(const Key('bill.detail')));
    await tester.pump(const Duration(seconds: 1));
    screen('Détail d’une facture');
    await hold(tester);
    final detail = find.byKey(const Key('bill.detail'));
    await slowScroll(tester, detail, -450);
    await slowScroll(tester, detail, -450);
    await hold(tester, const Duration(seconds: 2));
    await slowScroll(tester, detail, 900);

    // 9. Son PDF, ouvert dans le lecteur du téléphone (le PC le referme par « retour »).
    screen('Facture PDF');
    marker('DEMO_PDF');
    await tester.tap(find.byKey(const Key('bill.pdf')));
    final opened = await waitLifecycle(
      (s) => s != AppLifecycleState.resumed,
      const Duration(seconds: 20),
    );
    if (opened) {
      await waitLifecycle((s) => s == AppLifecycleState.resumed, const Duration(seconds: 40));
    }
    await waitFor(tester, find.byKey(const Key('bill.detail')));
    await tester.pump(const Duration(seconds: 1));

    // 10. Paiement Mobile Money (numéro du compte : le prestataire simulé l'accepte).
    await tapOn(
      tester,
      find.descendant(of: find.byKey(const Key('bill.footer')), matching: find.byType(PayButton)),
    );
    await waitFor(tester, find.text('MOYEN DE PAIEMENT'));
    await tester.pump(const Duration(milliseconds: 600));
    screen('Paiement Mobile Money');
    await hold(tester);
    await tapOn(tester, find.textContaining('Payer ').last);

    // 11. État du paiement (en attente, validation, confirmation), puis 12. Reçu (bascule seule).
    await waitFor(tester, find.byType(PaymentScreen));
    screen('État du paiement');
    await waitFor(
      tester,
      find.byKey(const Key('receipt.screen')),
      timeout: const Duration(seconds: 60),
    );
    await tester.pump(const Duration(seconds: 1));
    screen('Reçu');
    await hold(tester);
    await slowScroll(tester, find.byKey(const Key('receipt.screen')), -500);
    await hold(tester, const Duration(seconds: 2));
    await tapOn(tester, find.byKey(const Key('receipt.done')));
    await tester.pump(const Duration(seconds: 2));

    // 13. Historique des paiements (onglet Compte).
    await tapOn(tester, find.text('Compte'));
    await waitFor(tester, find.byKey(const Key('account.history')));
    await tapOn(tester, find.byKey(const Key('account.history')));
    await waitFor(tester, find.byKey(const Key('history.list')));
    await tester.pump(const Duration(seconds: 1));
    screen('Historique des paiements');
    await hold(tester);
    final history = find.byKey(const Key('history.list'));
    await slowScroll(tester, history, -500);
    await slowScroll(tester, history, -500);
    await hold(tester, const Duration(seconds: 2));
    await androidBack(tester);
    await waitFor(tester, find.byKey(const Key('account.list')));

    // 14. Consommation : Jour, Semaine, Mois, Année, puis Direct (simulation du mode démo).
    await tapOn(tester, find.text('Conso').last);
    await waitFor(
      tester,
      find.byKey(const Key('conso.chart')),
      timeout: const Duration(seconds: 30),
    );
    for (final (tab, label) in [
      ('day', 'Jour'),
      ('week', 'Semaine'),
      ('month', 'Mois'),
      ('year', 'Année'),
    ]) {
      await tester.tap(find.byKey(Key('conso.tab.$tab')));
      await tester.pump(const Duration(milliseconds: 1200));
      screen('Consommation · $label');
      await hold(tester);
      if (tab == 'month') {
        final list = find.byKey(const Key('conso.list'));
        await slowScroll(tester, list, -500);
        await hold(tester, const Duration(seconds: 2));
        await slowScroll(tester, list, 500);
      }
    }
    await tester.tap(find.byKey(const Key('conso.tab.direct')));
    await waitFor(tester, find.byKey(const Key('conso.directChart')));
    screen('Consommation · Direct (simulation)');
    await hold(tester, const Duration(seconds: 6)); // la courbe avance toutes les 2 s
    await tester.tap(find.byKey(const Key('conso.tab.month')));
    await tester.pump(const Duration(seconds: 1));

    // 15. Compteurs et foyers (depuis Compte).
    await openAccountRow(tester, 'Compteurs et foyers');
    await waitFor(tester, find.byKey(const Key('households.list')));
    await tester.pump(const Duration(seconds: 1));
    screen('Compteurs et foyers');
    await hold(tester);
    final households = find.byKey(const Key('households.list'));
    await slowScroll(tester, households, -500);
    await hold(tester, const Duration(seconds: 2));
    await androidBack(tester);

    // 16. Compte : profil et paramètres.
    await waitFor(tester, find.byKey(const Key('account.list')));
    final account = find.byKey(const Key('account.list'));
    for (var i = 0; i < 4; i++) {
      await tester.drag(account, const Offset(0, 600)); // tout en haut, avant le film de l'écran
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.pump(const Duration(milliseconds: 600));
    screen('Compte et paramètres');
    await hold(tester);
    await slowScroll(tester, account, -450);
    await slowScroll(tester, account, -450);
    await hold(tester, const Duration(seconds: 2));

    // 17. Assistance : questions fréquentes, recherche.
    await tester.dragUntilVisible(
      find.byKey(const Key('account.support')),
      account,
      const Offset(0, -300),
    );
    await tapOn(tester, find.byKey(const Key('account.support')));
    await waitFor(tester, find.byKey(const Key('support.list')));
    await tester.pump(const Duration(seconds: 1));
    screen('Assistance');
    await hold(tester);
    await slowType(
      tester,
      find.descendant(
        of: find.byKey(const Key('support.search')),
        matching: find.byType(EditableText),
      ),
      'reçu',
    );
    await hold(tester);
    await slowScroll(tester, find.byKey(const Key('support.list')), -400);
    await hold(tester, const Duration(seconds: 2));

    marker('DEMO_FIN|${DateTime.now().millisecondsSinceEpoch}');
    await tester.pump(const Duration(seconds: 1));
  });
}
