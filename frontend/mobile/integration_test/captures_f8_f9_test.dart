// Captures des écrans F8 et F9 SUR LE TÉLÉPHONE (vraies polices), avec la taille de texte réglée
// dans Android (adb shell settings put system font_scale 1.3 ou 2.0). Aucune vérification de
// contenu ici, seulement : rien ne déborde (aucune erreur de mise en page), et les captures.
//
// Aux jalons seulement, jamais en CI :
//   .\tool\integration.ps1 -Device <téléphone> -Target integration_test/captures_f8_f9_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/itel_app.dart';

void main() {
  binding; // initialise le binding des tests d'intégration

  testWidgets('tournée F8 + F9 : Compte, foyers, Gérer, Ajouter, Profil, Sécurité, Assistance', (
    tester,
  ) async {
    final scale = (tester.platformDispatcher.textScaleFactor * 100).round();
    String name(String screen) => 'texte$scale-$screen';
    final overflows = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      overflows.add(details.exceptionAsString());
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);

    await startApp(tester);
    await typeInto(tester, 0, '060000101');
    await typeInto(tester, 1, 'Demo2026!');
    await tapOn(tester, find.text('Se connecter'));
    await waitFor(tester, find.byKey(const Key('home.list')));

    await tapOn(tester, find.text('Compte'));
    await waitFor(tester, find.byKey(const Key('account.list')));
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, name('compte-1-haut'));
    for (var i = 2; i <= 4; i++) {
      await tester.drag(find.byKey(const Key('account.list')), const Offset(0, -500));
      await tester.pump(const Duration(milliseconds: 800));
      await shot(tester, name('compte-$i'));
    }

    // Retour en haut de Compte (la ligne est au-dessus après la tournée vers le bas).
    for (var i = 0; i < 4; i++) {
      await tester.drag(find.byKey(const Key('account.list')), const Offset(0, 600));
      await tester.pump(const Duration(milliseconds: 400));
    }
    await openAccountRow(tester, 'Compteurs et foyers');
    await waitFor(tester, find.byKey(const Key('households.list')));
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, name('foyers'));
    final manage = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('households.manage.'),
    );
    await tester.dragUntilVisible(
      manage.last,
      find.byKey(const Key('households.list')),
      const Offset(0, -300),
    );
    await tapOn(tester, manage.last);
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, name('gerer'));
    await androidBack(tester);
    await tapOn(tester, find.byKey(const Key('households.add')));
    await waitFor(tester, find.byKey(const Key('addMeter.form')));
    await tester.pump(const Duration(milliseconds: 600));
    await shot(tester, name('ajouter-compteur'));
    await androidBack(tester);
    await androidBack(tester); // retour à Compte

    for (final (key, screen) in [
      ('account.edit', 'profil'),
      ('account.security', 'securite'),
      ('account.support', 'assistance'),
    ]) {
      await waitFor(tester, find.byKey(const Key('account.list')));
      await tester.dragUntilVisible(
        find.byKey(Key(key)),
        find.byKey(const Key('account.list')),
        key == 'account.edit' ? const Offset(0, 300) : const Offset(0, -300),
      );
      await tapOn(tester, find.byKey(Key(key)));
      await tester.pump(const Duration(seconds: 1));
      await shot(tester, name(screen));
      await androidBack(tester);
    }

    expect(overflows, isEmpty, reason: overflows.join('\n'));
  });
}
