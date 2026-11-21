import 'dart:io';

import 'package:elecpay/app/riverpod_config.dart';
import 'package:elecpay/app/routes.dart';
import 'package:elecpay/core/demo/demo_mode.dart';
import 'package:elecpay/core/format/formats.dart';
import 'package:elecpay/core/settings/app_settings.dart';
import 'package:elecpay/core/theme/app_theme.dart';
import 'package:elecpay/core/widgets/bottom_nav.dart';
import 'package:elecpay/core/widgets/offline_banner.dart';
import 'package:elecpay/features/account/account_data.dart';
import 'package:elecpay/features/account/account_screen.dart';
import 'package:elecpay/features/account/profile_screen.dart';
import 'package:elecpay/features/home/home_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/app_harness.dart';
import '../../support/fake_health.dart';
import '../../support/fake_home_backend.dart';
import '../../support/fake_server.dart';
import '../../support/itel_screen.dart';

/// Écran 14 (et « Mon profil »), sur l'itel ; les autres écrans sont de simples pages.
Future<void> pumpAccount(
  WidgetTester tester,
  FakeHomeBackend backend, {
  String location = '/compte',
  double textScale = 1.0,
  bool wait = true,
  SettingsStore? settings,
}) async {
  tester.view.physicalSize = itelPhysicalSize;
  tester.view.devicePixelRatio = itelPixelRatio;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  Widget page(String text) => Scaffold(body: Text(text));
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(path: AppTab.account.path, builder: (context, state) => const AccountScreen()),
      GoRoute(path: Routes.profile, builder: (context, state) => const ProfileScreen()),
      GoRoute(path: Routes.households, builder: (context, state) => page('Écran Foyers')),
      GoRoute(path: Routes.history, builder: (context, state) => page('Écran Historique')),
      GoRoute(path: Routes.security, builder: (context, state) => page('Écran Sécurité')),
      GoRoute(path: Routes.support, builder: (context, state) => page('Écran Assistance')),
      for (final extra in extraRoutes)
        GoRoute(path: extra, builder: (context, state) => page('Écran $extra')),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      retry: noAutomaticRetry,
      overrides: [
        ...backend.overrides(),
        ...healthOverrides(demoApi()),
        demoModeStoreProvider.overrideWithValue(MemoryDemoModeStore()),
        settingsStoreProvider.overrideWithValue(settings ?? MemorySettingsStore()),
      ],
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    ),
  );
  if (wait) await settle(tester);
}

/// Écrans ajoutés par les sous-étapes suivantes (sécurité, assistance) : de simples pages.
final extraRoutes = <String>[];

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> tapKey(WidgetTester tester, String key) async {
  final target = find.byKey(Key(key));
  if (key.startsWith('account.')) {
    // Ligne de l'écran Compte : la liste est construite au fil du défilement.
    await tester.dragUntilVisible(
      target.hitTestable(),
      find.byKey(const Key('account.list')),
      const Offset(0, -150),
    );
  } else {
    await tester.ensureVisible(target);
  }
  await settle(tester);
  await tester.tap(target);
  await settle(tester);
}

Future<void> fill(WidgetTester tester, String key, String text) async {
  await tester.enterText(
    find.descendant(of: find.byKey(Key(key)), matching: find.byType(EditableText)),
    text,
  );
  await tester.pump();
}

FakeHomeBackend withUser({String? email, bool verified = false}) {
  final backend = FakeHomeBackend();
  backend.user = {
    ...backend.user,
    'phone': '+242061234567',
    'email': email,
    'email_verified_at': verified ? '2026-11-01T10:00:00Z' : null,
  };
  return backend;
}

void main() {
  test('version affichée = version de pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(r'^version:\s*([0-9.]+)', multiLine: true).firstMatch(pubspec)!.group(1);
    expect(appVersion, version);
  });

  group('écran Compte (maquette)', () {
    testWidgets('en-tête, « Mon compte », déconnexion, version · Mode démo', (tester) async {
      await pumpAccount(tester, withUser());
      expect(find.text('Loick Makosso'), findsOneWidget);
      expect(find.text('LM'), findsOneWidget);
      expect(find.text(formatPhone('+242061234567')), findsOneWidget);
      expect(find.text('MON COMPTE'), findsOneWidget);
      expect(find.text('2 foyers'), findsOneWidget);
      expect(find.text('Paiements et reçus'), findsOneWidget);
      await tester.scrollUntilVisible(find.byKey(const Key('account.version')), 200);
      expect(find.text('Se déconnecter'), findsOneWidget);
      expect(find.text('ElecPay $appVersion · Mode démo'), findsOneWidget);
    });

    testWidgets('liens : Modifier → profil, foyers, paiements et reçus', (tester) async {
      for (final (key, page) in [
        ('account.households', 'Écran Foyers'),
        ('account.history', 'Écran Historique'),
        ('account.security', 'Écran Sécurité'),
        ('account.support', 'Écran Assistance'),
      ]) {
        await pumpAccount(tester, withUser());
        await tapKey(tester, key);
        expect(find.text(page), findsOneWidget);
      }
      await pumpAccount(tester, withUser());
      await tapKey(tester, 'account.edit');
      expect(find.byKey(const Key('profile.form')), findsOneWidget);
    });

    // Vu sur une capture à 200 % : « Compte / urs et / foyers » (la valeur prenait la place).
    testWidgets('texte à 200 % : « 2 foyers » passe sous le libellé', (tester) async {
      await pumpAccount(tester, withUser(), textScale: 2);
      final label = tester.getRect(find.text('Compteurs et foyers'));
      final value = tester.getRect(find.text('2 foyers'));
      expect(value.top, greaterThanOrEqualTo(label.bottom));
      expect(value.left, label.left);
    });

    for (final scale in [1.3, 2.0]) {
      testWidgets('texte à ${(scale * 100).round()} % : rien ne déborde', (tester) async {
        await pumpAccount(tester, withUser(), textScale: scale);
        await tester.scrollUntilVisible(find.byKey(const Key('account.version')), 200);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Mon profil', () {
    testWidgets('seuls les champs changés partent ; rien de changé : rien n’est envoyé', (
      tester,
    ) async {
      final backend = withUser();
      await pumpAccount(tester, backend, location: Routes.profile);
      await tapKey(tester, 'profile.save');
      expect(find.text('Aucune modification.'), findsOneWidget);
      expect(backend.sent['/me'], isNull);
      await fill(tester, 'profile.name', '  Loick   Makosso-Mbemba ');
      await tapKey(tester, 'profile.save');
      expect(backend.sent['/me']!.single, {'full_name': 'Loick Makosso-Mbemba'});
      expect(find.text('Profil enregistré.'), findsOneWidget);
    });

    testWidgets('nom trop court et e-mail invalide : refusés avant l’envoi', (tester) async {
      final backend = withUser();
      await pumpAccount(tester, backend, location: Routes.profile);
      await fill(tester, 'profile.name', 'L');
      await fill(tester, 'profile.email', 'pas-un-email');
      await tapKey(tester, 'profile.save');
      expect(backend.sent['/me'], isNull);
      expect(
        find.descendant(of: find.byKey(const Key('profile.email')), matching: find.byType(Text)),
        findsWidgets,
      );
    });

    testWidgets('e-mail déjà utilisé : le message de l’API sous le champ', (tester) async {
      final backend = withUser();
      await pumpAccount(tester, backend, location: Routes.profile);
      // Après la lecture du profil : seul l'enregistrement est refusé.
      backend.forced['/me'] = JsonReply(
        409,
        apiError('EMAIL_ALREADY_USED', 'Cette adresse est déjà utilisée par un autre compte.'),
      );
      await fill(tester, 'profile.email', 'loick@exemple.cg');
      await tapKey(tester, 'profile.save');
      expect(
        find.descendant(
          of: find.byKey(const Key('profile.email')),
          matching: find.text('Cette adresse est déjà utilisée par un autre compte.'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('vérifier l’adresse : code envoyé (démo : affiché), code faux puis bon', (
      tester,
    ) async {
      final backend = withUser(email: 'loick@exemple.cg');
      await pumpAccount(tester, backend, location: Routes.profile);
      expect(find.text('Adresse pas encore vérifiée'), findsOneWidget);
      await tapKey(tester, 'profile.sendCode');
      expect(find.textContaining('Code envoyé à l***@exemple.cg'), findsOneWidget);
      expect(
        find.textContaining('Mode démo : aucun e-mail n’est envoyé. Code : 482913'),
        findsOneWidget,
      );
      await fill(tester, 'profile.code', '000000');
      await tapKey(tester, 'profile.confirm');
      expect(find.text('Code invalide ou expiré. Demandez un nouveau code.'), findsOneWidget);
      await fill(tester, 'profile.code', '482913');
      await tapKey(tester, 'profile.confirm');
      expect(find.text('Adresse e-mail vérifiée.'), findsOneWidget);
      expect(find.text('Adresse vérifiée'), findsOneWidget);
      expect(find.byKey(const Key('profile.sendCode')), findsNothing);
    });

    testWidgets('adresse déjà vérifiée : aucune vérification proposée', (tester) async {
      await pumpAccount(
        tester,
        withUser(email: 'loick@exemple.cg', verified: true),
        location: Routes.profile,
      );
      expect(find.text('Adresse vérifiée'), findsOneWidget);
      expect(find.byKey(const Key('profile.sendCode')), findsNothing);
    });
  });

  // F10.1 : états de l'écran Compte et de « Mon profil ».
  group('états (F10.1)', () {
    testWidgets('compte illisible hors connexion (sans cache) : on le dit, « Réessayer » relit', (
      tester,
    ) async {
      final backend = withUser()..down.add('/me');
      await pumpAccount(tester, backend);
      expect(find.text('Hors connexion : profil non chargé. Réessayer'), findsOneWidget);
      expect(find.text('Mon compte'), findsOneWidget);
      backend.down.clear();
      // Ligne visible en haut de l'écran : toucher sans faire défiler (le nom resterait caché).
      await tester.tap(find.byKey(const Key('account.user.retry')));
      await settle(tester);
      expect(find.text('Loick Makosso'), findsOneWidget);
      expect(find.byKey(const Key('account.user.retry')), findsNothing);
    });

    testWidgets('erreur du serveur : « Profil illisible : réessayer »', (tester) async {
      final backend = withUser()..forced['/me'] = JsonReply(500, apiError('INTERNAL', 'Erreur'));
      await pumpAccount(tester, backend);
      expect(find.text('Profil illisible : réessayer'), findsOneWidget);
    });

    testWidgets('hors ligne avec le cache : bannière datée, le compte reste lisible', (
      tester,
    ) async {
      final backend = withUser();
      await pumpAccount(tester, backend);
      backend.down.add('/me');
      ProviderScope.containerOf(tester.element(find.byKey(const Key('account.list'))))
          .invalidate(homeUserProvider);
      await settle(tester);
      expect(find.byType(OfflineBanner), findsOneWidget);
      expect(find.text('Loick Makosso'), findsOneWidget);
      expect(find.byKey(const Key('account.user.retry')), findsNothing);
    });

    testWidgets('Mon profil : chargement, puis le formulaire', (tester) async {
      await pumpAccount(tester, withUser(), location: Routes.profile, wait: false);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await settle(tester);
      expect(find.byKey(const Key('profile.form')), findsOneWidget);
    });

    testWidgets('Mon profil hors connexion, sans cache : bloc « Hors connexion »', (tester) async {
      await pumpAccount(tester, withUser()..down.add('/me'), location: Routes.profile);
      expect(find.text('Hors connexion'), findsOneWidget);
      expect(find.byKey(const Key('profile.form')), findsNothing);
    });
  });
}
