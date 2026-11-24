// Compteurs et foyers (F8) rejoués sur le téléphone, contre l'API de démo du PC.
//
// Aux jalons seulement, jamais en CI :
//   .\tool\integration.ps1 -Device <téléphone> -Target integration_test/households_test.dart
// Base DÉDIÉE `elecpay_e2e`, supprimée et recréée par le script avant le passage. Les tests se suivent
// (même base) : Arnaud ajoute, renomme, invite Christelle et retire Grâce ; Christelle accepte ;
// Davy quitte le foyer de sa mère. E²C SIMULÉ : un branchement qui finit par 0000 est introuvable.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/itel_app.dart';

const demoPassword = 'Demo2026!';

/// Comptes du seed (backend/app/simulators/demo_dataset.py), saisis « 06… ».
const arnaud = '060000101'; // Maison Mpita (seul) + Boutique Tié-Tié (avec Grâce, payeuse)
const christelle = '060000103'; // Maison de maman (avec Davy)
const davy = '060000104'; // payeur délégué de Maison de maman

Future<void> loginAs(WidgetTester tester, String phone) async {
  await startApp(tester);
  await typeInto(tester, 0, phone);
  await typeInto(tester, 1, demoPassword);
  await tapOn(tester, find.text('Se connecter'));
  await waitFor(tester, find.byKey(const Key('home.list')));
}

Future<void> openHouseholds(WidgetTester tester) async {
  await openAccountRow(tester, 'Compteurs et foyers');
  await waitFor(tester, find.byKey(const Key('households.list')));
}

/// Saisit `text` dans le champ de la clé `key`.
Future<void> typeIn(WidgetTester tester, String key, String text) async {
  final field = find.descendant(of: find.byKey(Key(key)), matching: find.byType(EditableText));
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pump(const Duration(milliseconds: 200));
}

bool _keyStarts(Widget w, String prefix) =>
    w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith(prefix);

/// Bouton « Gérer » / « Inviter un proche » de la carte du foyer `name`.
Finder manageButton(String name) => find.descendant(
  of: find.ancestor(
    of: find.text(name).first,
    matching: find.byWidgetPredicate((w) => _keyStarts(w, 'households.card.')),
  ),
  matching: find.byWidgetPredicate((w) => _keyStarts(w, 'households.manage.')),
);

Future<void> openManage(WidgetTester tester, String name) async {
  await tester.dragUntilVisible(
    find.text(name).first,
    find.byKey(const Key('households.list')),
    const Offset(0, -300),
  );
  await tapOn(tester, manageButton(name));
}

/// Touche le bouton `button` dans la ligne dont la clé commence par `linePrefix` et qui contient
/// `text` (ex. le membre « Grâce Ngoma »).
Future<void> tapInLine(WidgetTester tester, String linePrefix, String text, String button) async {
  final line = find.ancestor(
    of: find.text(text),
    matching: find.byWidgetPredicate((w) => _keyStarts(w, linePrefix)),
  );
  await tapOn(tester, find.descendant(of: line.first, matching: find.text(button)));
}

void main() {
  binding; // initialise le binding des tests d'intégration

  testWidgets('ajouter un compteur : introuvable chez E²C (…0000), puis ajouté', (tester) async {
    await loginAs(tester, arnaud);
    await openHouseholds(tester);
    await shot(tester, 'f8-1-foyers');
    await tapOn(tester, find.byKey(const Key('households.add')));
    await waitFor(tester, find.byKey(const Key('addMeter.form')));

    await typeIn(tester, 'addMeter.reference', '0018 09 0000');
    await typeIn(tester, 'addMeter.customer', '0758340H');
    await tapOn(tester, find.byKey(const Key('addMeter.submit')));
    // Message de l'API sous le N° de branchement ; rien n'est ajouté.
    await waitFor(
      tester,
      find.descendant(
        of: find.byKey(const Key('addMeter.reference')),
        matching: find.textContaining('E²C'),
      ),
    );
    expect(find.byKey(const Key('addMeter.success')), findsNothing);
    await shot(tester, 'f8-2-introuvable');

    final reference = '0018${100000 + Random().nextInt(899999)}';
    await typeIn(tester, 'addMeter.reference', reference);
    await tapOn(tester, find.byKey(const Key('addMeter.submit')));
    await waitFor(
      tester,
      find.byKey(const Key('addMeter.success')),
      timeout: const Duration(seconds: 60),
    );
    await shot(tester, 'f8-3-compteur-ajoute');
    await tapOn(tester, find.byKey(const Key('addMeter.done')));
    await waitFor(tester, find.byKey(const Key('households.list')));
  });

  testWidgets('renommer Maison Mpita, puis inviter Christelle (payeuse déléguée)', (tester) async {
    await loginAs(tester, arnaud);
    await openHouseholds(tester);

    // Propriétaire seul : le bouton de la carte ouvre l'invitation. Le renommage passe par
    // Boutique Tié-Tié (avec membre : « Gérer »).
    await openManage(tester, 'Boutique Tié-Tié');
    await waitFor(tester, find.byKey(const Key('manage.sheet')));
    await tapOn(tester, find.byKey(const Key('manage.renameHousehold')));
    await waitFor(tester, find.byKey(const Key('rename.sheet')));
    await typeIn(tester, 'rename.value', 'Boutique centre');
    await tapOn(tester, find.byKey(const Key('rename.save')));
    await waitFor(tester, find.text('Nom enregistré.'));
    await androidBack(tester); // ferme la feuille « Gérer »
    await waitFor(tester, find.text('Boutique centre'));
    await shot(tester, 'f8-4-renomme');

    await openManage(tester, 'Maison Mpita');
    await waitFor(tester, find.byKey(const Key('invite.sheet')));
    await typeIn(tester, 'invite.phone', christelle);
    await tapOn(tester, find.byKey(const Key('invite.send')));
    await waitFor(tester, find.textContaining('Invitation envoyée au'));
    await waitFor(tester, find.textContaining('invitation en attente'));
    await shot(tester, 'f8-5-invitation-envoyee');
  });

  testWidgets('retirer Grâce de Boutique centre (avec confirmation)', (tester) async {
    await loginAs(tester, arnaud);
    await openHouseholds(tester);
    await openManage(tester, 'Boutique centre');
    await waitFor(tester, find.byKey(const Key('manage.sheet')));
    await tapInLine(tester, 'manage.member.', 'Grâce Ngoma', 'Retirer');
    await waitFor(tester, find.text('Retirer ce membre ?'));
    await shot(tester, 'f8-6-confirmation-retrait');
    await tapOn(tester, find.byKey(const Key('manage.confirm.yes')));
    await waitFor(tester, find.text('Grâce Ngoma a été retiré.'));
    await waitFor(tester, find.text('Vous seul.'));
  });

  testWidgets('Christelle accepte l’invitation : Maison Mpita apparaît', (tester) async {
    await loginAs(tester, christelle);
    await openHouseholds(tester);
    final accept = find.byWidgetPredicate((w) => _keyStarts(w, 'households.accept.'));
    await waitFor(tester, accept);
    await shot(tester, 'f8-7-invitation-recue');
    await tapOn(tester, accept);
    await waitFor(tester, find.text('Maison Mpita'));
    expect(accept, findsNothing);
  });

  testWidgets('Davy quitte Maison de maman (avec confirmation)', (tester) async {
    await loginAs(tester, davy);
    await openHouseholds(tester);
    await openManage(tester, 'Maison de maman');
    await waitFor(tester, find.byKey(const Key('manage.sheet')));
    expect(find.byKey(const Key('manage.renameHousehold')), findsNothing);
    await tapOn(tester, find.byKey(const Key('manage.leave')));
    await waitFor(tester, find.text('Quitter Maison de maman ?'));
    await tapOn(tester, find.byKey(const Key('manage.confirm.yes')));
    await waitFor(tester, find.text('Vous avez quitté Maison de maman.'));
    await shot(tester, 'f8-8-quitte');
  });
}
