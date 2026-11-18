import 'package:dio/dio.dart';
import 'package:elecpay/app/router.dart';
import 'package:elecpay/app/routes.dart';
import 'package:elecpay/core/session/session_manager.dart';
import 'package:elecpay/core/session/session_providers.dart';
import 'package:elecpay/core/widgets/app_button.dart';
import 'package:elecpay/features/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import '../../support/fake_server.dart';
import '../../support/itel_screen.dart';

/// L'écran affiché (le dernier de la pile : `push` y ajoute un écran par-dessus).
String location(WidgetTester tester) =>
    AppHarness.containerOf(tester)
        .read(routerProvider)
        .routerDelegate
        .currentConfiguration
        .last
        .matchedLocation;

/// L'application sans session : le splash mène à l'écran de connexion.
Future<AppHarness> openLogin(WidgetTester tester, {double textScale = 1.0}) async {
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final h = AppHarness();
  await h.start(tester);
  await tester.pumpAndSettle();
  expect(find.byType(LoginScreen), findsOneWidget);
  return h;
}

Future<void> fill(WidgetTester tester, {String phone = '06 000 01 01', String? password}) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), phone);
  await tester.enterText(fields.at(1), password ?? 'Demo2026!');
}

Future<void> submit(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Se connecter'));
  await tester.tap(find.text('Se connecter'));
  await tester.pumpAndSettle();
}

/// Le bouton principal (« Se connecter », ou « Réessayer dans 2:05 » pendant l'attente).
AppButton loginButton(WidgetTester tester) => tester.widget<AppButton>(
  find.byWidgetPredicate(
    (w) => w is AppButton && (w.label == 'Se connecter' || w.label.startsWith('Réessayer dans')),
  ),
);

void main() {
  testWidgets('textes et liens de la maquette', (tester) async {
    await openLogin(tester);
    expect(find.text('ElecPay'), findsOneWidget);
    expect(find.text('Connexion'), findsOneWidget);
    expect(find.text('Connectez-vous avec votre numéro de téléphone.'), findsOneWidget);
    expect(find.text('Numéro de téléphone'), findsOneWidget);
    expect(find.text('+242'), findsOneWidget);
    expect(find.text('Mot de passe'), findsOneWidget);
    expect(find.text('Mot de passe oublié ?'), findsOneWidget);
    expect(find.text('Pas encore de compte ?'), findsOneWidget);
    expect(find.text('Créer un compte'), findsOneWidget);
  });

  group('vérification avant l’envoi', () {
    testWidgets('champs vides : un message sous chaque champ, rien n’est envoyé', (tester) async {
      final h = await openLogin(tester);
      await submit(tester);
      expect(find.text('Numéro invalide : 9 chiffres attendus (ex. 06 123 45 67)'), findsOneWidget);
      expect(find.text('Saisissez votre mot de passe.'), findsOneWidget);
      expect(h.backend.requestsTo('/auth/login'), isEmpty);
    });

    testWidgets('mauvais préfixe : le message du backend, rien n’est envoyé', (tester) async {
      final h = await openLogin(tester);
      await fill(tester, phone: '07 123 45 67');
      await submit(tester);
      expect(find.text('Numéro invalide : il doit commencer par 04, 05, 06 ou 22'), findsOneWidget);
      expect(h.backend.requestsTo('/auth/login'), isEmpty);
    });

    testWidgets('le message d’un champ disparaît dès qu’on le corrige', (tester) async {
      await openLogin(tester);
      await submit(tester);
      await tester.enterText(find.byType(TextField).at(1), 'a');
      await tester.pump();
      expect(find.text('Saisissez votre mot de passe.'), findsNothing);
    });
  });

  testWidgets('réussite : numéro normalisé envoyé, session ouverte, accueil', (tester) async {
    final h = await openLogin(tester);
    await fill(tester);
    await submit(tester);
    expect(h.backend.requestsTo('/auth/login').single.data, {
      'phone': '+242060000101',
      'password': 'Demo2026!',
    });
    expect(location(tester), Routes.home);
    expect(AppHarness.containerOf(tester).read(sessionStateProvider), const SessionActive(42));
  });

  testWidgets('double toucher : UNE seule demande de connexion', (tester) async {
    final h = await openLogin(tester);
    await fill(tester);
    await tester.tap(find.text('Se connecter'));
    await tester.tap(find.text('Se connecter'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(h.backend.requestsTo('/auth/login'), hasLength(1));
  });

  testWidgets('mauvais mot de passe : « Numéro ou mot de passe incorrect. »', (tester) async {
    await openLogin(tester);
    await fill(tester, password: 'faux1234');
    await submit(tester);
    expect(find.text('Numéro ou mot de passe incorrect.'), findsOneWidget);
    expect(find.textContaining('Référence'), findsNothing);
    expect(location(tester), Routes.login);
    // Le numéro est gardé, le mot de passe est vidé (à ressaisir).
    final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields[0].controller!.text, '06 000 01 01');
    expect(fields[1].controller!.text, isEmpty);
  });

  testWidgets('autre échec (hors connexion) : le mot de passe est gardé', (tester) async {
    final h = await openLogin(tester);
    h.backend.forced['/auth/login'] = const FailReply(DioExceptionType.connectionError);
    await fill(tester);
    await submit(tester);
    final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields[1].controller!.text, 'Demo2026!');
  });

  testWidgets('clavier ouvert (300 points) et texte à 130 % : « Se connecter » reste atteignable', (
    tester,
  ) async {
    final h = await openLogin(tester, textScale: 1.3);
    // Clavier de 300 points : 600 pixels à 2 pixels par point.
    tester.view.viewInsets = const FakeViewPadding(bottom: 600);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(LoginScreen));
    expect(MediaQuery.viewInsetsOf(context).bottom, 300, reason: 'clavier bien simulé');
    // Le contenu n'a plus que 800 − 300 points, moins les barres du système.
    expect(tester.getSize(find.byType(Scrollable).first).height, lessThanOrEqualTo(500));
    await fill(tester);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('Se connecter'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Se connecter').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    expect(h.backend.requestsTo('/auth/login'), hasLength(1));
  });

  group('trop de tentatives (429)', () {
    testWidgets('bouton désactivé avec un compte à rebours, puis de nouveau actif', (tester) async {
      final h = await openLogin(tester);
      h.backend.forced['/auth/login'] = JsonReply(
        429,
        apiError('TOO_MANY_ATTEMPTS', 'Trop de tentatives.', {'retry_after_seconds': 125}),
      );
      await fill(tester);
      await submit(tester);
      // Message court : le bouton donne déjà le temps exact.
      expect(find.text('Trop de tentatives.'), findsOneWidget);
      expect(find.textContaining('Réessayez dans 3 min'), findsNothing);
      expect(find.text('Réessayer dans 2:05'), findsOneWidget);
      expect(loginButton(tester).onPressed, isNull);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Réessayer dans 2:04'), findsOneWidget);

      // Un toucher pendant l'attente n'envoie rien.
      await tester.tap(find.text('Réessayer dans 2:04'));
      await tester.pump();
      expect(h.backend.requestsTo('/auth/login'), hasLength(1));

      await tester.pump(const Duration(seconds: 124));
      expect(find.text('Se connecter'), findsOneWidget);
      expect(loginButton(tester).onPressed, isNotNull);
      expect(find.textContaining('Trop de tentatives'), findsNothing);
    });

    testWidgets('sans délai donné par l’API : 60 s', (tester) async {
      final h = await openLogin(tester);
      h.backend.forced['/auth/login'] = JsonReply(
        429,
        apiError('TOO_MANY_REQUESTS', 'Trop de requêtes.'),
      );
      await fill(tester);
      await submit(tester);
      expect(find.text('Réessayer dans 1:00'), findsOneWidget);
      await tester.pump(const Duration(seconds: 60));
    });
  });

  testWidgets('compte désactivé : message de l’API + assistance', (tester) async {
    final h = await openLogin(tester);
    h.backend.forced['/auth/login'] = JsonReply(
      403,
      apiError('ACCOUNT_DISABLED', 'Ce compte est désactivé.'),
    );
    await fill(tester);
    await submit(tester);
    expect(find.text('Ce compte est désactivé. Contactez l’assistance ElecPay.'), findsOneWidget);
  });

  testWidgets('compte de l’équipe (code 2FA demandé) : aucune session, back-office', (
    tester,
  ) async {
    final h = await openLogin(tester);
    h.backend.forced['/auth/login'] = const JsonReply(200, {
      'two_factor_required': true,
      'challenge_token': 'défi',
      'expires_at': '2026-11-18T12:30:00Z',
    });
    await fill(tester, phone: '06 000 00 02');
    await submit(tester);
    expect(find.textContaining('réservé à l’équipe ElecPay'), findsOneWidget);
    expect(h.tokens.tokens, isNull);
    expect(location(tester), Routes.login);
  });

  testWidgets('hors connexion : message clair et référence', (tester) async {
    final h = await openLogin(tester);
    h.backend.forced['/auth/login'] = const FailReply(DioExceptionType.connectionError);
    await fill(tester);
    await submit(tester);
    expect(find.textContaining('Pas de connexion à ElecPay'), findsOneWidget);
    expect(find.textContaining('Référence : app-'), findsOneWidget);
  });

  testWidgets('liens : mot de passe oublié et inscription', (tester) async {
    await openLogin(tester);
    await tester.tap(find.text('Mot de passe oublié ?'));
    await tester.pumpAndSettle();
    expect(location(tester), Routes.forgotPassword);
    AppHarness.containerOf(tester).read(routerProvider).go(Routes.login);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Créer un compte'));
    await tester.tap(find.text('Créer un compte'));
    await tester.pumpAndSettle();
    expect(location(tester), Routes.register);
  });

  for (final scale in textScales) {
    testWidgets('texte × $scale : tient sur l’itel avec une erreur, zones tactiles ≥ 48', (
      tester,
    ) async {
      await openLogin(tester, textScale: scale);
      await submit(tester);
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });
  }
}
