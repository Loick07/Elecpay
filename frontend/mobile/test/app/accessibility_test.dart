// F10.2 : accessibilité de TOUS les écrans client, sur l'écran de l'itel (360 × 800).
// - zones tactiles d'au moins 48 points (Android) ;
// - toute zone tactile a un libellé lu par TalkBack ;
// - contraste du texte (règle WCAG appliquée par Flutter) ;
// - texte à 200 % : rien ne déborde, du haut au bas de l'écran.
// Chaque écran est ouvert par l'aide de son propre fichier de test (mêmes faux serveurs).
import 'package:elecpay/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/account/account_screen_test.dart' as account;
import '../features/account/security_screen_test.dart' as security;
import '../features/account/support_test.dart' as support;
import '../features/auth/forgot_password_screen_test.dart' as forgot;
import '../features/auth/login_screen_test.dart' as login;
import '../features/auth/register_screen_test.dart' as register;
import '../features/bills/bill_detail_screen_test.dart' as detail;
import '../features/bills/bills_screen_test.dart' as bills;
import '../features/consumption/consumption_screen_test.dart' as conso;
import '../features/home/home_screen_test.dart' as home;
import '../features/households/households_screen_test.dart' as households;
import '../features/notifications/notifications_test.dart' as notifications;
import '../features/payments/history_test.dart' as history;
import '../features/payments/payment_screens_test.dart' as pay;
import '../features/receipts/receipt_screen_test.dart' as receipt;
import '../support/fake_home_backend.dart';

typedef Opener = Future<void> Function(WidgetTester tester, double textScale);

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Les écrans client (maquettes), dans l'ordre de `frontend/design/maquettes/client/README.md`.
/// Le splash (2 s au plus, un logo) est couvert par `test/features/startup/`.
final screens = <String, Opener>{
  'connexion': (t, s) => login.openLogin(t, textScale: s),
  'inscription': (t, s) => register.openRegister(t, textScale: s),
  'mot de passe oublié': (t, s) => forgot.openForgot(t, textScale: s),
  'accueil': (t, s) => home.pumpHome(t, FakeHomeBackend(), textScale: s),
  'mes factures': (t, s) => bills.pumpBills(t, bills.mockupBackend(), textScale: s),
  'détail de facture': (t, s) => detail.pumpDetail(t, FakeHomeBackend(), textScale: s),
  'paiement (feuille)': (t, s) async {
    await pay.PayHarness().pump(t, textScale: s);
    await pay.openSheet(t);
  },
  'paiement en attente': (t, s) async {
    await pay.PayHarness().pump(t, textScale: s);
    await pay.openSheet(t);
    await pay.tapSheetPay(t);
  },
  'reçu': (t, s) => receipt.ReceiptHarness().pump(t, textScale: s),
  'historique': (t, s) => history.pumpHistory(t, history.mockupBackend(), textScale: s),
  'consommation': (t, s) => conso.pumpConso(t, FakeHomeBackend(), textScale: s),
  'compteurs et foyers': (t, s) =>
      households.pumpHouseholds(t, households.mockupBackend(), textScale: s),
  'notifications': (t, s) => notifications.pumpNotifications(t, FakeHomeBackend(), textScale: s),
  'compte': (t, s) => account.pumpAccount(t, account.withUser(), textScale: s),
  'mon profil': (t, s) =>
      account.pumpAccount(t, account.withUser(), location: '/compte/profil', textScale: s),
  'mot de passe et sécurité': (t, s) async {
    t.platformDispatcher.textScaleFactorTestValue = s;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    await security.openSecurity(t);
  },
  'assistance': (t, s) => support.pumpSupport(t, textScale: s),
};

/// Fait défiler toutes les listes de l'écran jusqu'en bas (rien ne doit déborder en route).
Future<void> scrollAll(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    final lists = find.byType(Scrollable).hitTestable();
    if (lists.evaluate().isEmpty) return;
    await tester.drag(lists.first, const Offset(0, -500), warnIfMissed: false);
    await settle(tester);
  }
}

void main() {
  for (final MapEntry(key: name, value: open) in screens.entries) {
    group(name, () {
      testWidgets('zones tactiles ≥ 48 points, toutes avec un libellé', (tester) async {
        final semantics = tester.ensureSemantics();
        await open(tester, 1.0);
        await settle(tester);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        semantics.dispose();
      });

      testWidgets('contraste du texte (thème Nuit)', (tester) async {
        await open(tester, 1.0);
        await settle(tester);
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      });

      testWidgets('texte à 200 % : rien ne déborde, du haut au bas', (tester) async {
        await open(tester, 2.0);
        await settle(tester);
        expect(tester.takeException(), isNull);
        await scrollAll(tester);
        expect(tester.takeException(), isNull);
      });
    });
  }
  // Thème Jour (F9.2) : contraste aussi, sur les écrans qui se prêtent au changement de thème.
  final light = <String, Future<void> Function(WidgetTester)>{
    'accueil': (t) => home.pumpHome(t, FakeHomeBackend(), theme: AppTheme.light),
    'mes factures': (t) => bills.pumpBills(t, bills.mockupBackend(), theme: AppTheme.light),
    'détail de facture': (t) => detail.pumpDetail(t, FakeHomeBackend(), theme: AppTheme.light),
    'reçu': (t) => receipt.ReceiptHarness().pump(t, theme: AppTheme.light),
    'historique': (t) => history.pumpHistory(t, history.mockupBackend(), theme: AppTheme.light),
  };
  for (final MapEntry(key: name, value: open) in light.entries) {
    testWidgets('$name : contraste du texte (thème Jour)', (tester) async {
      await open(tester);
      await settle(tester);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  }
}
