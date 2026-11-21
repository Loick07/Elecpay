import 'dart:ui' show Tristate;

import 'package:elecpay/app/app.dart' show themeModeOf;
import 'package:elecpay/core/settings/app_settings.dart';
import 'package:elecpay/core/widgets/glass.dart';
import 'package:elecpay/features/account/preferences_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_home_backend.dart';
import '../../support/fake_server.dart';
import 'account_screen_test.dart' show pumpAccount, settle, withUser;

Future<void> scrollTo(WidgetTester tester, String key) async {
  await tester.dragUntilVisible(
    find.byKey(Key(key)).hitTestable(),
    find.byKey(const Key('account.list')),
    const Offset(0, -150),
  );
  await settle(tester);
}

/// État lu par TalkBack sur la ligne `key` (libellé, sous-titre et interrupteur fusionnés).
Tristate toggled(WidgetTester tester, String key) =>
    tester.getSemantics(find.byKey(Key(key))).getSemanticsData().flagsCollection.isToggled;

void main() {
  test('textes des interrupteurs (contrat et maquette)', () {
    expect(PreferenceSwitch.values.map((p) => p.label), [
      'Échéances',
      'Paiements',
      'Consommation inhabituelle',
      'Reçus par e-mail',
    ]);
    expect(PreferenceSwitch.highConsumption.detail, contains('30'));
  });

  test('thème : Nuit = sombre, Jour = clair, Auto = celui du téléphone', () {
    expect(themeModeOf(ThemeChoice.night), ThemeMode.dark);
    expect(themeModeOf(ThemeChoice.day), ThemeMode.light);
    expect(themeModeOf(ThemeChoice.auto), ThemeMode.system);
  });

  group('« Me prévenir »', () {
    testWidgets('état du serveur ; basculer envoie seulement cet interrupteur', (tester) async {
      final backend = withUser();
      await pumpAccount(tester, backend);
      await scrollTo(tester, 'account.pref.highConsumption');
      expect(toggled(tester, 'account.pref.dueSoon'), Tristate.isTrue);
      expect(toggled(tester, 'account.pref.highConsumption'), Tristate.isFalse);
      await tester.tap(find.byKey(const Key('account.pref.highConsumption')));
      await settle(tester);
      expect(backend.sent['/me/notification-preferences']!.single, {'high_consumption': true});
      expect(toggled(tester, 'account.pref.highConsumption'), Tristate.isTrue);
    });

    testWidgets('refus de l’API : l’interrupteur revient en arrière, message affiché', (
      tester,
    ) async {
      final backend = withUser();
      await pumpAccount(tester, backend);
      backend.forced['/me/notification-preferences'] = JsonReply(
        409,
        apiError('PREFERENCES_LOCKED', 'Réglage refusé pour le moment.'),
      );
      await scrollTo(tester, 'account.pref.payments');
      await tester.tap(find.byKey(const Key('account.pref.payments')));
      await settle(tester);
      expect(toggled(tester, 'account.pref.payments'), Tristate.isTrue);
      expect(find.text('Réglage refusé pour le moment.'), findsOneWidget);
    });

    testWidgets('hors connexion : réglages du cache, non modifiables', (tester) async {
      final backend = withUser();
      await pumpAccount(tester, backend);
      backend.down.add('/me');
      final container = ProviderScope.containerOf(
        tester.element(find.byKey(const Key('account.list'))),
      );
      container.invalidate(notificationPreferencesProvider);
      await settle(tester);
      await scrollTo(tester, 'account.pref.payments');
      expect(find.textContaining('Hors connexion : réglages modifiables'), findsOneWidget);
      await tester.tap(find.byKey(const Key('account.pref.payments')));
      await settle(tester);
      expect(backend.sent['/me/notification-preferences'], isNull);
    });
  });

  // Vu sur une capture à 200 % : « Consommatio / n inhabituelle » (l'interrupteur prenait la place).
  testWidgets('texte à 200 % : l’interrupteur passe sous son libellé', (tester) async {
    await pumpAccount(tester, withUser(), textScale: 2);
    await scrollTo(tester, 'account.pref.highConsumption');
    final row = find.byKey(const Key('account.pref.highConsumption'));
    final label = tester.getRect(
      find.descendant(of: row, matching: find.text('Consommation inhabituelle')),
    );
    final toggle = tester.getRect(find.descendant(of: row, matching: find.byType(Switch)));
    expect(toggle.top, greaterThanOrEqualTo(label.bottom));
    expect(tester.takeException(), isNull);
  });

  group('« Affichage »', () {
    testWidgets('thème Jour : enregistré sur l’appareil ; Nuit par défaut', (tester) async {
      final store = MemorySettingsStore();
      await pumpAccount(tester, withUser(), settings: store);
      await scrollTo(tester, 'account.theme.day');
      expect(
        tester
            .getSemantics(find.byKey(const Key('account.theme.night')))
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
      await tester.tap(find.byKey(const Key('account.theme.day')));
      await settle(tester);
      expect(store.saved, {'theme': 'day', 'glass': false});
    });

    testWidgets('« Effet verre » : désactivé par défaut ; activé, il floute et reste enregistré', (
      tester,
    ) async {
      final store = MemorySettingsStore();
      await pumpAccount(tester, withUser(), settings: store);
      await scrollTo(tester, 'account.glass');
      expect(toggled(tester, 'account.glass'), Tristate.isFalse);
      await tester.tap(find.byKey(const Key('account.glass')));
      await settle(tester);
      expect(store.saved, {'theme': 'night', 'glass': true});
      final container = ProviderScope.containerOf(
        tester.element(find.byKey(const Key('account.list'))),
      );
      expect(container.read(glassModeProvider), GlassMode.blur);
    });

    testWidgets('réglages relus au lancement (Jour et effet verre gardés)', (tester) async {
      final store = MemorySettingsStore({'theme': 'day', 'glass': true});
      await pumpAccount(tester, withUser(), settings: store);
      await scrollTo(tester, 'account.glass');
      expect(
        tester.getSemantics(find.byKey(const Key('account.theme.day'))).flagsCollection.isSelected,
        Tristate.isTrue,
      );
      expect(toggled(tester, 'account.glass'), Tristate.isTrue);
    });
  });

  test('faux backend : préférences de la maquette', () {
    expect(FakeHomeBackend().preferences['due_soon'], isTrue);
  });
}
