// Parcours de l'accueil et des notifications (F4) rejoués sur le téléphone, contre l'API de démo du PC.
//
// Aux jalons seulement, jamais en CI :
//   .\tool\integration.ps1 -Device <téléphone> -Target integration_test/home_notifications_test.dart
// Base DÉDIÉE `elecpay_e2e` remise à zéro et remplie par le script (jamais la base de démo `elecpay`).
// Compte de démo du seed : Arnaud Mavoungou (Maison Mpita + Boutique Tié-Tié), mot de passe public de
// démonstration. Captures dans build/integration/. Ils complètent le regard de Loick, ne le remplacent pas.
import 'package:elecpay/features/home/home_data.dart';
import 'package:elecpay/features/notifications/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/itel_app.dart';

/// Compte de démo du seed (backend/app/simulators/demo_dataset.py), saisi « 06… ».
const demoOwnerPhone = '060000101';
const demoPassword = 'Demo2026!';

void main() {
  binding; // initialise le binding des tests d'intégration

  testWidgets('accueil du compte de démo : cartes, foyers, actualiser', (tester) async {
    final container = await startApp(tester);
    await typeInto(tester, 0, demoOwnerPhone);
    await typeInto(tester, 1, demoPassword);
    await tapOn(tester, find.text('Se connecter'));

    await waitFor(tester, find.text('Bonjour Arnaud'));
    expect(find.text('MODE DÉMO'), findsOneWidget);
    await waitFor(tester, find.textContaining('· 2 foyers'));
    await shot(tester, 'f4-1-accueil');

    // Deux foyers : la feuille du choix, puis l'autre foyer.
    await tapOn(tester, find.byKey(const Key('home.household')));
    await waitFor(tester, find.text('Choisir un foyer'));
    await shot(tester, 'f4-2-choix-foyer');
    final other = container
        .read(householdsProvider)
        .value!
        .data
        .firstWhere((h) => h.id != container.read(shownHouseholdIdProvider).value);
    await tapOn(tester, find.byKey(Key('home.household.${other.id}')));
    await waitFor(tester, find.text('${other.name} · 2 foyers'));
    await shot(tester, 'f4-3-autre-foyer');

    // Tirer vers le bas : tout est relu, l'écran reste rempli.
    await tester.fling(find.byKey(const Key('home.list')), const Offset(0, 500), 1200);
    await waitFor(tester, find.text('${other.name} · 2 foyers'));

    // Bas de l'écran : activité récente.
    await tester.drag(find.byKey(const Key('home.list')), const Offset(0, -900));
    await waitFor(tester, find.text('Activité récente'));
    await shot(tester, 'f4-4-activite');
  });

  testWidgets('cloche → notifications → tout lu → retour : plus de point rouge', (tester) async {
    await startApp(tester);
    await typeInto(tester, 0, demoOwnerPhone);
    await typeInto(tester, 1, demoPassword);
    await tapOn(tester, find.text('Se connecter'));
    await waitFor(tester, find.byKey(const Key('home.list')));

    await tapOn(tester, find.byKey(const Key('home.bell')));
    await waitFor(tester, find.byType(NotificationsScreen));
    await waitFor(tester, find.byKey(const Key('notifications.list')));
    await shot(tester, 'f4-5-notifications');

    final markAll = tester.widget<TextButton>(find.byKey(const Key('notifications.markAll')));
    if (markAll.onPressed != null) {
      await tapOn(tester, find.byKey(const Key('notifications.markAll')));
      await waitFor(tester, find.text('Tout est lu'));
      await shot(tester, 'f4-6-tout-lu');
    }
    expect(find.byKey(const Key('notification.unreadDot')), findsNothing);

    await androidBack(tester);
    await waitFor(tester, find.byKey(const Key('home.list')));
    expect(find.byKey(const Key('home.bell.dot')), findsNothing);
  });
}
