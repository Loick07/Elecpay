// Compte et assistance (F9) rejoués sur le téléphone, contre l'API de démo du PC, avec l'arbre
// d'accessibilité (ce que lit TalkBack) des interrupteurs et du choix du thème.
//
// Aux jalons seulement, jamais en CI :
//   .\tool\integration.ps1 -Device <téléphone> -Target integration_test/account_test.dart
// Base DÉDIÉE `elecpay_e2e`, supprimée et recréée par le script avant le passage. Comptes du seed :
// Arnaud (profil, réglages, assistance), Patrick (mot de passe), Rodrigue (tout déconnecter).
// Les réglages de l'appareil (thème, effet verre) sont remis par défaut à la fin de chaque test.
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsData;
import 'package:flutter_test/flutter_test.dart';

import 'support/itel_app.dart';

const demoPassword = 'Demo2026!';
const arnaud = '060000101';
const patrick = '060000105';
const rodrigue = '060000107';

Future<void> loginAs(WidgetTester tester, String phone, {String password = demoPassword}) async {
  await startApp(tester);
  await typeInto(tester, 0, phone);
  await typeInto(tester, 1, password);
  await tapOn(tester, find.text('Se connecter'));
  await waitFor(tester, find.byKey(const Key('home.list')));
}

Future<void> openAccount(WidgetTester tester) async {
  await tapOn(tester, find.text('Compte'));
  await waitFor(tester, find.byKey(const Key('account.list')));
}

/// Fait défiler l'écran Compte jusqu'à la ligne `key` (liste construite au fil du défilement).
Future<void> scrollToAccount(WidgetTester tester, String key) async {
  await tester.dragUntilVisible(
    find.byKey(Key(key)),
    find.byKey(const Key('account.list')),
    const Offset(0, -250),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> typeIn(WidgetTester tester, String key, String text) async {
  final field = find.descendant(of: find.byKey(Key(key)), matching: find.byType(EditableText));
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pump(const Duration(milliseconds: 200));
}

/// Ce que lit TalkBack sur une ligne (libellé, détail et état fusionnés).
SemanticsData talkBack(WidgetTester tester, String key) =>
    tester.getSemantics(find.byKey(Key(key))).getSemanticsData();

Brightness shownBrightness(WidgetTester tester) =>
    Theme.of(tester.element(find.byKey(const Key('account.list')))).brightness;

/// Remet thème Nuit et effet verre désactivé (réglages gardés sur l'appareil entre les tests).
Future<void> restoreDisplay(WidgetTester tester) async {
  await scrollToAccount(tester, 'account.theme.night');
  await tapOn(tester, find.byKey(const Key('account.theme.night')));
  await scrollToAccount(tester, 'account.glass');
  if (talkBack(tester, 'account.glass').flagsCollection.isToggled == Tristate.isTrue) {
    await tapOn(tester, find.byKey(const Key('account.glass')));
  }
}

void main() {
  binding; // initialise le binding des tests d'intégration

  testWidgets('profil : nom changé, puis nouvelle adresse vérifiée par le code (démo)', (
    tester,
  ) async {
    await loginAs(tester, arnaud);
    await openAccount(tester);
    await tapOn(tester, find.byKey(const Key('account.edit')));
    await waitFor(tester, find.byKey(const Key('profile.form')));
    await typeIn(tester, 'profile.name', 'Arnaud Mavoungou-Test');
    await tapOn(tester, find.byKey(const Key('profile.save')));
    await waitFor(tester, find.text('Profil enregistré.'));

    await typeIn(tester, 'profile.email', 'arnaud.jalon-f10@example.com');
    await tapOn(tester, find.byKey(const Key('profile.save')));
    await waitFor(tester, find.byKey(const Key('profile.sendCode')));
    await tapOn(tester, find.byKey(const Key('profile.sendCode')));
    await waitFor(tester, find.textContaining('Code : '));
    await shot(tester, 'f9-1-code-email');
    final shown = tester.widget<Text>(find.textContaining('Code : ')).data!;
    final code = RegExp(r'Code : (\d{6})').firstMatch(shown)!.group(1)!;
    await typeIn(tester, 'profile.code', code);
    await tapOn(tester, find.byKey(const Key('profile.confirm')));
    await waitFor(tester, find.text('Adresse e-mail vérifiée.'));
    await waitFor(tester, find.text('Adresse vérifiée'));
    await shot(tester, 'f9-2-adresse-verifiee');
  });

  testWidgets('interrupteurs « Me prévenir » : TalkBack (libellé, état), gardés par le serveur', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await loginAs(tester, arnaud);
    await openAccount(tester);
    await scrollToAccount(tester, 'account.pref.payments');
    final before = talkBack(tester, 'account.pref.payments');
    expect(before.label, contains('Paiements'));
    expect(before.label, contains('Réussis, échoués, reçus disponibles'));
    expect(before.flagsCollection.isToggled, isNot(Tristate.none), reason: 'lu comme interrupteur');
    final wasOn = before.flagsCollection.isToggled == Tristate.isTrue;

    await tapOn(tester, find.byKey(const Key('account.pref.payments')));
    await tester.pump(const Duration(seconds: 2));
    final expected = wasOn ? Tristate.isFalse : Tristate.isTrue;
    expect(talkBack(tester, 'account.pref.payments').flagsCollection.isToggled, expected);

    // Relance : l'état vient du serveur.
    await relaunchApp(tester);
    await waitFor(tester, find.byKey(const Key('home.list')));
    await openAccount(tester);
    await scrollToAccount(tester, 'account.pref.payments');
    await tester.pump(const Duration(seconds: 1));
    expect(talkBack(tester, 'account.pref.payments').flagsCollection.isToggled, expected);
    for (final key in ['dueSoon', 'highConsumption', 'emailReceipts']) {
      await scrollToAccount(tester, 'account.pref.$key');
      final data = talkBack(tester, 'account.pref.$key');
      expect(data.flagsCollection.isToggled, isNot(Tristate.none), reason: key);
      expect(data.label, isNotEmpty, reason: key);
    }
    // Remis comme avant.
    await tapOn(tester, find.byKey(const Key('account.pref.payments')));
    await tester.pump(const Duration(seconds: 2));
    semantics.dispose();
  });

  testWidgets('thème Jour puis Auto, gardés après relance ; TalkBack : choix sélectionné', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await loginAs(tester, arnaud);
    await openAccount(tester);
    await scrollToAccount(tester, 'account.theme.night');
    final night = talkBack(tester, 'account.theme.night');
    expect(night.label, 'Nuit');
    expect(night.flagsCollection.isSelected, Tristate.isTrue, reason: 'Nuit par défaut');
    expect(night.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
    expect(night.flagsCollection.isButton, isTrue);
    expect(shownBrightness(tester), Brightness.dark);

    await tapOn(tester, find.byKey(const Key('account.theme.day')));
    await tester.pump(const Duration(seconds: 1));
    expect(shownBrightness(tester), Brightness.light);
    expect(talkBack(tester, 'account.theme.day').flagsCollection.isSelected, Tristate.isTrue);
    expect(talkBack(tester, 'account.theme.night').flagsCollection.isSelected, Tristate.isFalse);
    await shot(tester, 'f9-3-theme-jour');

    await relaunchApp(tester);
    await waitFor(tester, find.byKey(const Key('home.list')));
    await shot(tester, 'f9-4-accueil-jour');
    await openAccount(tester);
    expect(shownBrightness(tester), Brightness.light, reason: 'Jour gardé après relance');
    await scrollToAccount(tester, 'account.theme.auto');
    expect(talkBack(tester, 'account.theme.day').flagsCollection.isSelected, Tristate.isTrue);

    await tapOn(tester, find.byKey(const Key('account.theme.auto')));
    await relaunchApp(tester);
    await waitFor(tester, find.byKey(const Key('home.list')));
    await openAccount(tester);
    await scrollToAccount(tester, 'account.theme.auto');
    expect(talkBack(tester, 'account.theme.auto').flagsCollection.isSelected, Tristate.isTrue);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.system, reason: 'Auto = thème du téléphone');

    await restoreDisplay(tester);
    semantics.dispose();
  });

  testWidgets('« Effet verre » : TalkBack, flou réel sur la feuille, gardé après relance', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await loginAs(tester, arnaud);
    await openAccount(tester);
    await scrollToAccount(tester, 'account.glass');
    final off = talkBack(tester, 'account.glass');
    expect(off.label, contains('Effet verre'));
    expect(off.flagsCollection.isToggled, Tristate.isFalse, reason: 'désactivé par défaut');
    await tapOn(tester, find.byKey(const Key('account.glass')));
    await tester.pump(const Duration(seconds: 1));
    expect(talkBack(tester, 'account.glass').flagsCollection.isToggled, Tristate.isTrue);

    await relaunchApp(tester);
    await waitFor(tester, find.byKey(const Key('home.list')));
    // Feuille de paiement (verre) au-dessus de l'accueil : le flou est bien là.
    await tapOn(tester, find.text('Payer').last);
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(BackdropFilter), findsWidgets);
    await shot(tester, 'f9-5-effet-verre');
    await androidBack(tester);
    await openAccount(tester);
    await scrollToAccount(tester, 'account.glass');
    expect(talkBack(tester, 'account.glass').flagsCollection.isToggled, Tristate.isTrue);

    await restoreDisplay(tester);
    semantics.dispose();
  });

  testWidgets('changer de mot de passe : connecté, puis l’ancien refusé et le nouveau accepté', (
    tester,
  ) async {
    await loginAs(tester, patrick);
    await openAccountRow(tester, 'Mot de passe et sécurité');
    await waitFor(tester, find.byKey(const Key('security.form')));
    await typeIn(tester, 'security.current', demoPassword);
    await typeIn(tester, 'security.next', 'Jalon2026F10');
    await tapOn(tester, find.byKey(const Key('security.change')));
    await waitFor(tester, find.text('Mot de passe changé. Vos autres appareils sont déconnectés.'));
    expect(find.byKey(const Key('security.form')), findsOneWidget, reason: 'toujours connecté');
    await shot(tester, 'f9-6-mot-de-passe-change');

    await startApp(tester); // autre session : l'ancien mot de passe ne marche plus
    await typeInto(tester, 0, patrick);
    await typeInto(tester, 1, demoPassword);
    await tapOn(tester, find.text('Se connecter'));
    await waitFor(tester, find.text('Numéro ou mot de passe incorrect.'));
    await loginAs(tester, patrick, password: 'Jalon2026F10');
  });

  testWidgets('« Déconnecter tous mes appareils » : confirmation, puis la connexion', (
    tester,
  ) async {
    await loginAs(tester, rodrigue);
    await openAccountRow(tester, 'Mot de passe et sécurité');
    await waitFor(tester, find.byKey(const Key('security.logoutAll')));
    await tapOn(tester, find.byKey(const Key('security.logoutAll')));
    await waitFor(tester, find.text('Déconnecter tous vos appareils ?'));
    await shot(tester, 'f9-7-tout-deconnecter');
    await tapOn(tester, find.byKey(const Key('manage.confirm.yes')));
    await waitFor(tester, find.text('Connexion'));
  });

  testWidgets('assistance : recherche « recu » puis « proche »', (tester) async {
    await loginAs(tester, arnaud);
    await openAccountRow(tester, 'Assistance');
    await waitFor(tester, find.byKey(const Key('support.list')));
    // Mots-clés cachés (décision de Loick, M1) : « recu » trouve « J’ai payé mais… ».
    await typeIn(tester, 'support.search', 'recu');
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('support.noResult')), findsNothing);
    expect(find.text('J’ai payé mais la facture reste « À payer »'), findsOneWidget);
    await shot(tester, 'f9-8-recherche-recu');
    await typeIn(tester, 'support.search', 'proche');
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Comment payer la facture d’un proche ?'), findsOneWidget);
    await shot(tester, 'f9-9-recherche-proche');
  });
}
