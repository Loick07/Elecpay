// Parcours de connexion (F3) rejoués sur le téléphone, contre l'API de démo du PC.
//
// Aux jalons seulement, jamais en CI : .\tool\integration.ps1 -Device <téléphone>
// (base de démo remise à zéro, API en jetons d'une minute, captures dans build/integration/).
// Ils complètent le regard de Loick sur le téléphone, ils ne le remplacent pas.
import 'package:elecpay/core/session/session_manager.dart';
import 'package:elecpay/core/session/session_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/itel_app.dart';

void main() {
  binding; // initialise le binding des tests d'intégration

  testWidgets('inscription → accueil → déconnexion', (tester) async {
    final container = await startApp(tester);
    final phone = newTestPhone();

    await tapOn(tester, find.text('Créer un compte'));
    await waitFor(tester, find.text('Créer mon compte'));
    await typeInto(tester, 0, 'Parcours Inscription');
    await typeInto(tester, 1, phone);
    await typeInto(tester, 3, testPassword);
    await tapOn(tester, find.byType(Checkbox));
    await shot(tester, 'f3-1-inscription-remplie');
    await tapOn(tester, find.text('Créer mon compte'));

    await waitFor(tester, find.text('Accueil : bientôt'));
    expect(container.read(sessionStateProvider), isA<SessionActive>());
    await shot(tester, 'f3-1-accueil');

    await tapOn(tester, find.text('Compte'));
    await waitFor(tester, find.text('Se déconnecter'));
    await tapOn(tester, find.text('Se déconnecter'));
    await waitFor(tester, find.text('Connexion'));
    expect(container.read(sessionStateProvider), isA<SessionEnded>());
    expect(find.text('Session expirée'), findsNothing);
  });

  testWidgets('connexion ratée (numéro gardé, mot de passe vidé) puis réussie', (tester) async {
    final phone = newTestPhone();
    await DemoApi.register(phone);
    await startApp(tester);

    await typeInto(tester, 0, phone);
    await typeInto(tester, 1, 'Mauvais2026');
    await tapOn(tester, find.text('Se connecter'));
    await waitFor(tester, find.text('Numéro ou mot de passe incorrect.'));
    final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields[0].controller!.text.replaceAll(' ', ''), phone);
    expect(fields[1].controller!.text, isEmpty);
    await shot(tester, 'f3-2-connexion-refusee');

    await typeInto(tester, 1, testPassword);
    await tapOn(tester, find.text('Se connecter'));
    await waitFor(tester, find.text('Accueil : bientôt'));
  });

  testWidgets('mot de passe oublié complet : code de démo, code faux, « suivant », nouveau '
      'mot de passe', (tester) async {
    final phone = newTestPhone();
    await DemoApi.register(phone);
    await startApp(tester);

    await tapOn(tester, find.text('Mot de passe oublié ?'));
    await waitFor(tester, find.text('Étape 1 sur 3'));
    await typeInto(tester, 0, phone);
    await tapOn(tester, find.text('Envoyer le code'));
    await waitFor(tester, find.text('Étape 2 sur 3'));
    // Le code de démo, lu à l'écran (« 482 913 », espace insécable au milieu).
    final code = RegExp(r'\d{3}\D\d{3}')
        .firstMatch(shownText(tester, 'Votre code est'))!
        .group(0)!
        .replaceAll(RegExp(r'\D'), '');
    await shot(tester, 'f3-3-code-de-demo');

    await typeInto(tester, 0, '000000');
    await typeInto(tester, 1, 'Nouveau2026');
    await tapOn(tester, find.text('Changer le mot de passe'));
    await waitFor(tester, find.text('Code invalide ou expiré. Demandez un nouveau code.'));
    await shot(tester, 'f3-3-code-faux');

    // « suivant » depuis le code : le curseur va au mot de passe (défaut corrigé au jalon F3).
    await tester.showKeyboard(find.byType(TextField).at(0));
    await tester.enterText(find.byType(TextField).at(0), code);
    await keyboardAction(tester, TextInputAction.next);
    expect(tester.widget<TextField>(find.byType(TextField).at(1)).focusNode!.hasFocus, isTrue);
    await keyboardAction(tester, TextInputAction.done);
    await waitFor(tester, find.text('Mot de passe modifié'));
    await shot(tester, 'f3-3-mot-de-passe-modifie');

    await tapOn(tester, find.text('Se connecter'));
    await waitFor(tester, find.text('Connexion'));
    await typeInto(tester, 0, phone);
    await typeInto(tester, 1, 'Nouveau2026');
    await tapOn(tester, find.text('Se connecter'));
    await waitFor(tester, find.text('Accueil : bientôt'));
  });

  testWidgets('retour Android à l’étape 2 : l’étape 1, pas la sortie de l’écran', (tester) async {
    await startApp(tester);
    await tapOn(tester, find.text('Mot de passe oublié ?'));
    await waitFor(tester, find.text('Étape 1 sur 3'));
    await typeInto(tester, 0, newTestPhone()); // numéro sans compte : même parcours
    await tapOn(tester, find.text('Envoyer le code'));
    await waitFor(tester, find.text('Étape 2 sur 3'));
    expect(find.textContaining('Mode démo', findRichText: true), findsNothing);

    await androidBack(tester);
    await waitFor(tester, find.text('Étape 1 sur 3'));
    expect(find.textContaining('Nouveau code dans'), findsOneWidget);
    await shot(tester, 'f3-4-retour-etape-1');
  });

  testWidgets('vraie session expirée : sessions fermées ailleurs, jeton d’une minute', (
    tester,
  ) async {
    final phone = newTestPhone();
    final tokens = await DemoApi.register(phone);
    expect(
      tokens['expires_in'],
      60,
      reason: 'lancer par tool/integration.ps1 (API en jetons d’une minute)',
    );
    await startApp(tester);

    await typeInto(tester, 0, phone);
    await typeInto(tester, 1, testPassword);
    await tapOn(tester, find.text('Se connecter'));
    await waitFor(tester, find.text('Accueil : bientôt'));
    final signedInAt = DateTime.now();

    // « Déconnecter tous mes appareils », fait depuis un autre appareil.
    final other = await DemoApi.login(phone, testPassword);
    final (status, _) = await DemoApi.post(
      '/auth/logout-all',
      {},
      token: other['access_token'] as String,
    );
    expect(status, 200);

    await tapOn(tester, find.text('Compte'));
    await waitFor(tester, find.text('Diagnostic'));
    await tapOn(tester, find.text('Diagnostic'));
    await waitFor(tester, find.text('Lire mon profil'));
    // Attendre que le jeton d'accès du téléphone ait expiré (une minute, plus une marge).
    final wait = const Duration(seconds: 65) - DateTime.now().difference(signedInAt);
    if (!wait.isNegative) await tester.pump(wait);

    await tapOn(tester, find.text('Lire mon profil'));
    await waitFor(tester, find.text('Session expirée'));
    await shot(tester, 'f3-5-session-expiree');
    await tapOn(tester, find.text('Se reconnecter'));
    await waitFor(tester, find.text('Connexion'));
  }, timeout: const Timeout(Duration(minutes: 4)));
}
