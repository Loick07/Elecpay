import 'package:dio/dio.dart';
import 'package:elecpay/app/router.dart';
import 'package:elecpay/app/routes.dart';
import 'package:elecpay/core/session/session_manager.dart';
import 'package:elecpay/core/session/session_providers.dart';
import 'package:elecpay/core/theme/app_icons.dart';
import 'package:elecpay/core/widgets/app_button.dart';
import 'package:elecpay/features/auth/register_screen.dart';
import 'package:elecpay/features/legal/legal_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import '../../support/fake_server.dart';
import '../../support/itel_screen.dart';

String location(WidgetTester tester) =>
    AppHarness.containerOf(tester)
        .read(routerProvider)
        .routerDelegate
        .currentConfiguration
        .last
        .matchedLocation;

/// L'application sans session, ouverte sur l'inscription (depuis la connexion).
Future<AppHarness> openRegister(WidgetTester tester, {double textScale = 1.0}) async {
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final h = AppHarness();
  await h.start(tester);
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Créer un compte'));
  await tester.tap(find.text('Créer un compte'));
  await tester.pumpAndSettle();
  expect(find.byType(RegisterScreen), findsOneWidget);
  return h;
}

Future<void> fill(
  WidgetTester tester, {
  String name = '  Loick   Makosso ',
  String phone = '06 555 44 33',
  String email = ' Loick@Example.CG ',
  String password = 'Elec2026',
  bool accept = true,
}) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), name);
  await tester.enterText(fields.at(1), phone);
  await tester.enterText(fields.at(2), email);
  await tester.enterText(fields.at(3), password);
  await tester.pump();
  if (accept) {
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
  }
}

Future<void> submit(WidgetTester tester) async {
  final button = find.byWidgetPredicate(
    (w) => w is AppButton && (w.label == 'Créer mon compte' || w.label.startsWith('Réessayer')),
  );
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('textes de la maquette ; introduction qui annonce l’ajout du compteur', (
    tester,
  ) async {
    await openRegister(tester);
    for (final text in [
      'Créer un compte',
      'Vous ajouterez votre compteur E²C juste après, depuis l’accueil.',
      'Nom et prénom',
      'Numéro de téléphone',
      'Il servira à vous connecter et à recevoir vos alertes.',
      'E-mail (facultatif)',
      'Mot de passe',
      '8 caractères minimum',
      'Au moins un chiffre',
      'Au moins une lettre',
      'J’accepte les conditions d’utilisation et la politique de confidentialité.',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
  });

  testWidgets('tout vide : un message sous chaque champ et sous la case, rien n’est envoyé', (
    tester,
  ) async {
    final h = await openRegister(tester);
    await submit(tester);
    expect(find.text('Nom trop court'), findsOneWidget);
    expect(find.text('Numéro invalide : 9 chiffres attendus (ex. 06 123 45 67)'), findsOneWidget);
    expect(find.text('Mot de passe trop court : 8 caractères minimum'), findsOneWidget);
    expect(find.textContaining('Acceptez les conditions d’utilisation'), findsOneWidget);
    expect(h.backend.requestsTo('/auth/register'), isEmpty);
  });

  testWidgets('case non cochée : refus, rien n’est envoyé', (tester) async {
    final h = await openRegister(tester);
    await fill(tester, accept: false);
    await submit(tester);
    expect(find.textContaining('Acceptez les conditions d’utilisation'), findsOneWidget);
    expect(h.backend.requestsTo('/auth/register'), isEmpty);
  });

  testWidgets('règles du mot de passe cochées pendant la saisie', (tester) async {
    await openRegister(tester);
    int met() => find.byIcon(AppIcons.ruleMet).evaluate().length;
    expect(met(), 0);
    await tester.enterText(find.byType(TextField).at(3), 'abc');
    await tester.pump();
    expect(met(), 1, reason: 'une lettre');
    await tester.enterText(find.byType(TextField).at(3), 'abcdefg1');
    await tester.pump();
    expect(met(), 3);
  });

  testWidgets('mot de passe sans lettre : refusé avant l’envoi', (tester) async {
    final h = await openRegister(tester);
    await fill(tester, password: '12345678');
    await submit(tester);
    expect(find.text('Le mot de passe doit contenir au moins une lettre'), findsOneWidget);
    expect(h.backend.requestsTo('/auth/register'), isEmpty);
  });

  testWidgets('réussite : données normalisées comme le backend, session ouverte, accueil', (
    tester,
  ) async {
    final h = await openRegister(tester);
    await fill(tester);
    await submit(tester);
    expect(h.backend.requestsTo('/auth/register').single.data, {
      'full_name': 'Loick Makosso',
      'phone': '+242065554433',
      'email': 'loick@example.cg',
      'password': 'Elec2026',
    });
    expect(location(tester), Routes.home);
    expect(AppHarness.containerOf(tester).read(sessionStateProvider), isA<SessionActive>());
  });

  testWidgets('e-mail laissé vide : envoyé comme null (facultatif)', (tester) async {
    final h = await openRegister(tester);
    await fill(tester, email: '');
    await submit(tester);
    expect((h.backend.requestsTo('/auth/register').single.data as Map)['email'], isNull);
  });

  testWidgets('numéro déjà utilisé : message de l’API SOUS le champ téléphone', (tester) async {
    await openRegister(tester);
    await fill(tester, phone: '06 000 01 01');
    await submit(tester);
    final phoneField = tester.getRect(find.text('Numéro de téléphone'));
    final message = tester.getRect(find.text('Ce numéro est déjà utilisé par un compte.'));
    expect(message.top, greaterThan(phoneField.bottom));
    expect(message.top, lessThan(tester.getRect(find.text('E-mail (facultatif)')).top));
  });

  testWidgets('e-mail déjà utilisé : message de l’API SOUS le champ e-mail', (tester) async {
    await openRegister(tester);
    await fill(tester, email: 'pris@example.com');
    await submit(tester);
    final message = tester.getRect(find.text('Cette adresse e-mail est déjà utilisée.'));
    expect(message.top, greaterThan(tester.getRect(find.text('E-mail (facultatif)')).bottom));
    expect(message.top, lessThan(tester.getRect(find.text('Mot de passe')).top));
  });

  testWidgets('trop de tentatives : « Trop de tentatives. » et bouton à compte à rebours', (
    tester,
  ) async {
    final h = await openRegister(tester);
    h.backend.forced['/auth/register'] = JsonReply(
      429,
      apiError('TOO_MANY_ATTEMPTS', 'Trop de tentatives.', {'retry_after_seconds': 90}),
    );
    await fill(tester);
    await submit(tester);
    expect(find.text('Trop de tentatives.'), findsOneWidget);
    expect(find.text('Réessayer dans 1:30'), findsOneWidget);
    await tester.pump(const Duration(seconds: 90));
    expect(find.text('Créer mon compte'), findsOneWidget);
  });

  testWidgets('hors connexion : message et référence', (tester) async {
    final h = await openRegister(tester);
    h.backend.forced['/auth/register'] = const FailReply(DioExceptionType.connectionError);
    await fill(tester);
    await submit(tester);
    expect(find.textContaining('Pas de connexion à ElecPay'), findsOneWidget);
    expect(find.textContaining('Référence : app-'), findsOneWidget);
  });

  testWidgets('documents provisoires : bandeau « Document provisoire », lisibles sans compte', (
    tester,
  ) async {
    await openRegister(tester);
    for (final document in LegalDocument.values) {
      final link = find.text('Lire : ${document.title.toLowerCase()}');
      await tester.ensureVisible(link);
      await tester.tap(link);
      await tester.pumpAndSettle();
      expect(location(tester), document.path);
      expect(find.text(LegalScreen.provisional), findsOneWidget);
      expect(find.text(document.title), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(RegisterScreen), findsOneWidget);
    }
  });

  testWidgets('retour : la connexion', (tester) async {
    await openRegister(tester);
    await tester.tap(find.byTooltip('Retour à la connexion'));
    await tester.pumpAndSettle();
    expect(location(tester), Routes.login);
  });

  testWidgets('clavier ouvert (300 points) et texte à 130 % : « Créer mon compte » atteignable', (
    tester,
  ) async {
    final h = await openRegister(tester, textScale: 1.3);
    tester.view.viewInsets = const FakeViewPadding(bottom: 600);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(MediaQuery.viewInsetsOf(tester.element(find.byType(RegisterScreen))).bottom, 300);
    await fill(tester);
    await tester.scrollUntilVisible(
      find.text('Créer mon compte'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Créer mon compte').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Créer mon compte'));
    await tester.pumpAndSettle();
    expect(h.backend.requestsTo('/auth/register'), hasLength(1));
  });

  for (final scale in textScales) {
    testWidgets('texte × $scale : tient sur l’itel avec toutes les erreurs, cibles ≥ 48', (
      tester,
    ) async {
      await openRegister(tester, textScale: scale);
      await submit(tester);
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });
  }
}
