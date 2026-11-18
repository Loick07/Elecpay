import 'package:dio/dio.dart';
import 'package:elecpay/app/router.dart';
import 'package:elecpay/app/routes.dart';
import 'package:elecpay/core/format/phone.dart';
import 'package:elecpay/core/format/typography.dart';
import 'package:elecpay/core/session/session_manager.dart';
import 'package:elecpay/core/session/session_providers.dart';
import 'package:elecpay/core/widgets/app_button.dart';
import 'package:elecpay/features/auth/forgot_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import '../../support/fake_auth_backend.dart';
import '../../support/fake_server.dart';
import '../../support/itel_screen.dart';

const accountPhone = '06 000 01 01'; // a un compte (FakeAuthBackend.resetAccountPhone)
const otherPhone = '06 777 88 99'; // sans compte

String location(WidgetTester tester) =>
    AppHarness.containerOf(tester)
        .read(routerProvider)
        .routerDelegate
        .currentConfiguration
        .last
        .matchedLocation;

Future<AppHarness> openForgot(WidgetTester tester, {double textScale = 1.0}) async {
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final h = AppHarness();
  await h.start(tester);
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Mot de passe oublié ?'));
  await tester.tap(find.text('Mot de passe oublié ?'));
  await tester.pumpAndSettle();
  expect(find.byType(ForgotPasswordScreen), findsOneWidget);
  return h;
}

Finder button(String label) => find.byWidgetPredicate(
  (w) =>
      w is AppButton &&
      (w.label == label ||
          w.label.startsWith('Réessayer') ||
          w.label.startsWith('Nouveau code dans')),
);

Future<void> tapButton(WidgetTester tester, String label) async {
  await tester.ensureVisible(button(label));
  await tester.tap(button(label));
  await tester.pumpAndSettle();
}

/// Étape 1 → étape 2 avec ce numéro.
Future<void> sendCode(WidgetTester tester, {String phone = accountPhone}) async {
  await tester.enterText(find.byType(TextField), phone);
  await tapButton(tester, 'Envoyer le code');
}

/// Étape 2 : code et nouveau mot de passe, puis « Changer le mot de passe ».
Future<void> reset(
  WidgetTester tester, {
  String code = '482913',
  String password = 'Mpita2026',
}) async {
  await tester.enterText(find.byType(TextField).at(0), code);
  await tester.enterText(find.byType(TextField).at(1), password);
  await tester.pump();
  await tapButton(tester, 'Changer le mot de passe');
}

String demoCodeText(String code) =>
    'Mode démo : aucun SMS n’est envoyé. Votre code est '
    '${code.substring(0, 3)}$groupSpace${code.substring(3)}.';

String sentText(String phone) =>
    'Si ce numéro correspond à un compte, un code vient d’être envoyé par SMS au '
    '${formatPhone(normalizeCongoPhone(phone))}.';

Finder rich(String text) => find.text(text, findRichText: true);

void main() {
  group('étape 1 : le numéro', () {
    testWidgets('textes de la maquette', (tester) async {
      await openForgot(tester);
      for (final text in [
        'Étape 1 sur 3',
        'Mot de passe oublié',
        'Saisissez votre numéro. Nous vous envoyons un code à 6 chiffres par SMS.',
        'Numéro de téléphone',
        'Envoyer le code',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
    });

    testWidgets('numéro invalide : message du backend, rien n’est envoyé', (tester) async {
      final h = await openForgot(tester);
      await sendCode(tester, phone: '06 12');
      expect(find.text('Numéro invalide : 9 chiffres attendus (ex. 06 123 45 67)'), findsOneWidget);
      expect(h.backend.requestsTo('/auth/password/forgot'), isEmpty);
    });

    testWidgets('trop de tentatives : « Trop de tentatives. » et compte à rebours', (tester) async {
      final h = await openForgot(tester);
      h.backend.forced['/auth/password/forgot'] = JsonReply(
        429,
        apiError('TOO_MANY_ATTEMPTS', 'Trop de tentatives.', {'retry_after_seconds': 90}),
      );
      await sendCode(tester);
      expect(find.text('Trop de tentatives.'), findsOneWidget);
      expect(find.text('Réessayer dans 1:30'), findsOneWidget);
      expect(find.text('Étape 1 sur 3'), findsOneWidget);
      await tester.pump(const Duration(seconds: 90));
      expect(find.text('Envoyer le code'), findsOneWidget);
      expect(find.text('Trop de tentatives.'), findsNothing);
    });

    testWidgets('hors connexion : message et référence, on reste à l’étape 1', (tester) async {
      final h = await openForgot(tester);
      h.backend.forced['/auth/password/forgot'] = const FailReply(DioExceptionType.connectionError);
      await sendCode(tester);
      expect(find.textContaining('Pas de connexion à ElecPay'), findsOneWidget);
      expect(find.textContaining('Référence : app-'), findsOneWidget);
      expect(find.text('Étape 1 sur 3'), findsOneWidget);
    });

    testWidgets('retour : la connexion', (tester) async {
      await openForgot(tester);
      await tester.tap(find.byTooltip('Retour à la connexion'));
      await tester.pumpAndSettle();
      expect(location(tester), Routes.login);
    });
  });

  group('étape 2 : même parcours pour tous les numéros', () {
    testWidgets('numéro avec compte (mode démo) : code affiché, numéro normalisé envoyé', (
      tester,
    ) async {
      final h = await openForgot(tester);
      await sendCode(tester);
      expect(h.backend.requestsTo('/auth/password/forgot').single.data, {'phone': '+242060000101'});
      expect(find.text('Étape 2 sur 3'), findsOneWidget);
      expect(find.text('Nouveau mot de passe'), findsNWidgets(2)); // titre + champ
      expect(rich(sentText(accountPhone)), findsOneWidget);
      expect(rich(demoCodeText('482913')), findsOneWidget);
      expect(find.text('Code reçu'), findsOneWidget);
    });

    testWidgets('numéro SANS compte : la même étape 2, les mêmes textes (rien ne le révèle)', (
      tester,
    ) async {
      await openForgot(tester);
      await sendCode(tester, phone: otherPhone);
      expect(find.text('Étape 2 sur 3'), findsOneWidget);
      expect(rich(sentText(otherPhone)), findsOneWidget);
      expect(find.text('Code reçu'), findsOneWidget);
      expect(find.text('Changer le mot de passe'), findsOneWidget);
      // Pas de code de démo : l'API n'en donne pas (aucun compte). Voir docs/API.md.
      expect(find.textContaining('Mode démo', findRichText: true), findsNothing);
    });

    testWidgets('hors mode démo (production) : aucun code affiché', (tester) async {
      final h = await openForgot(tester);
      h.backend.demoMode = false;
      await sendCode(tester);
      expect(find.text('Étape 2 sur 3'), findsOneWidget);
      expect(find.textContaining('Mode démo', findRichText: true), findsNothing);
    });

    testWidgets('« Renvoyer le code » : 60 s d’attente, puis un nouveau code', (tester) async {
      final h = await openForgot(tester);
      await sendCode(tester);
      expect(find.text('Renvoyer le code dans 1:00'), findsOneWidget);
      await tester.pump(const Duration(seconds: 18));
      expect(find.text('Renvoyer le code dans 0:42'), findsOneWidget);
      await tester.tap(find.text('Renvoyer le code dans 0:42'));
      await tester.pumpAndSettle();
      expect(h.backend.requestsTo('/auth/password/forgot'), hasLength(1), reason: 'désactivé');

      await tester.pump(const Duration(seconds: 42));
      await tester.ensureVisible(find.text('Renvoyer le code'));
      await tester.tap(find.text('Renvoyer le code'));
      await tester.pumpAndSettle();
      expect(h.backend.requestsTo('/auth/password/forgot'), hasLength(2));
      expect(rich(demoCodeText('715204')), findsOneWidget);
      expect(find.text('Nouveau code demandé. L’ancien code ne fonctionne plus.'), findsOneWidget);
      expect(find.text('Renvoyer le code dans 1:00'), findsOneWidget);
    });

    testWidgets('« Renvoyer le code » refusé (429) : attente du délai de l’API', (tester) async {
      final h = await openForgot(tester);
      await sendCode(tester);
      await tester.pump(const Duration(seconds: 60));
      h.backend.forced['/auth/password/forgot'] = JsonReply(
        429,
        apiError('TOO_MANY_ATTEMPTS', 'Trop de tentatives.', {'retry_after_seconds': 300}),
      );
      await tester.ensureVisible(find.text('Renvoyer le code'));
      await tester.tap(find.text('Renvoyer le code'));
      await tester.pumpAndSettle();
      expect(find.text('Trop de tentatives.'), findsOneWidget);
      expect(find.text('Renvoyer le code dans 5:00'), findsOneWidget);
      // On peut toujours saisir le code déjà reçu.
      expect(find.text('Changer le mot de passe'), findsOneWidget);
    });

    testWidgets('code collé avec des lettres et des espaces : 6 chiffres gardés', (tester) async {
      await openForgot(tester);
      await sendCode(tester);
      await tester.enterText(find.byType(TextField).at(0), 'Code: 482 9134');
      await tester.pump();
      expect(tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text, '482913');
      for (final digit in ['4', '8', '2', '9', '1', '3']) {
        expect(find.text(digit), findsOneWidget);
      }
    });

    testWidgets('lecteur d’écran : « Code reçu, 6 chiffres » (un seul champ)', (tester) async {
      final semantics = tester.ensureSemantics();
      await openForgot(tester);
      await sendCode(tester);
      expect(find.bySemanticsLabel('Code reçu, 6 chiffres'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('code incomplet, mot de passe sans lettre : refusés avant l’envoi', (tester) async {
      final h = await openForgot(tester);
      await sendCode(tester);
      await reset(tester, code: '4829', password: '12345678');
      expect(find.text('Saisissez les 6 chiffres du code reçu.'), findsOneWidget);
      expect(find.text('Le mot de passe doit contenir au moins une lettre'), findsOneWidget);
      expect(h.backend.requestsTo('/auth/password/reset'), isEmpty);
    });

    testWidgets('code faux : message de l’API sous le code, code vidé, on reste à l’étape 2', (
      tester,
    ) async {
      await openForgot(tester);
      await sendCode(tester);
      await reset(tester, code: '000000');
      expect(find.text('Code invalide ou expiré. Demandez un nouveau code.'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text, isEmpty);
      expect(find.text('Étape 2 sur 3'), findsOneWidget);
      final message = tester.getRect(
        find.text('Code invalide ou expiré. Demandez un nouveau code.'),
      );
      expect(message.top, greaterThan(tester.getRect(find.text('Code reçu')).bottom));
    });

    testWidgets('numéro sans compte : le code échoue comme un code faux', (tester) async {
      await openForgot(tester);
      await sendCode(tester, phone: otherPhone);
      await reset(tester);
      expect(find.text('Code invalide ou expiré. Demandez un nouveau code.'), findsOneWidget);
    });

    testWidgets('trop d’essais (429) : « Trop de tentatives. » et compte à rebours', (
      tester,
    ) async {
      final h = await openForgot(tester);
      await sendCode(tester);
      h.backend.forced['/auth/password/reset'] = JsonReply(
        429,
        apiError('TOO_MANY_ATTEMPTS', 'Trop de tentatives.', {'retry_after_seconds': 125}),
      );
      await reset(tester);
      expect(find.text('Trop de tentatives.'), findsOneWidget);
      expect(find.text('Réessayer dans 2:05'), findsOneWidget);
    });

    testWidgets('retour (bouton ou retour système) : l’étape 1, numéro gardé, délai respecté', (
      tester,
    ) async {
      final h = await openForgot(tester);
      await sendCode(tester);
      await tester.tap(find.byTooltip('Retour : modifier le numéro'));
      await tester.pumpAndSettle();
      expect(find.text('Étape 1 sur 3'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, accountPhone);
      // Pas de nouveau code avant la fin des 60 s.
      final labels = tester.widgetList<AppButton>(find.byType(AppButton)).map((b) => b.label);
      expect(labels.single, startsWith('Nouveau code dans 0:5'));
      await tapButton(tester, labels.single);
      expect(h.backend.requestsTo('/auth/password/forgot'), hasLength(1));

      await tester.pump(const Duration(seconds: 60));
      await sendCode(tester);
      expect(find.text('Étape 2 sur 3'), findsOneWidget);
      // Retour système (bouton Android) : l'étape 1, pas la sortie de l'écran.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Étape 1 sur 3'), findsOneWidget);
      expect(location(tester), Routes.forgotPassword);
    });
  });

  group('étape 3 : mot de passe modifié', () {
    testWidgets('code + nouveau mot de passe envoyés ; aucune session ; « Se connecter »', (
      tester,
    ) async {
      final h = await openForgot(tester);
      await sendCode(tester);
      await reset(tester);
      expect(h.backend.requestsTo('/auth/password/reset').single.data, {
        'phone': FakeAuthBackend.resetAccountPhone,
        'code': '482913',
        'new_password': 'Mpita2026',
      });
      for (final text in [
        'Étape 3 sur 3',
        'Mot de passe modifié',
        'Par sécurité, vous avez été déconnecté de vos autres appareils.',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect(
        AppHarness.containerOf(tester).read(sessionStateProvider),
        isA<SessionEnded>(),
        reason: 'on se reconnecte avec le nouveau mot de passe',
      );
      await tapButton(tester, 'Se connecter');
      expect(location(tester), Routes.login);
    });
  });

  group('écran de l’itel', () {
    for (final step in ['numéro', 'code']) {
      testWidgets('clavier ouvert (300 points) et texte à 130 % : bouton atteignable ($step)', (
        tester,
      ) async {
        final h = await openForgot(tester, textScale: 1.3);
        if (step == 'code') await sendCode(tester);
        tester.view.viewInsets = const FakeViewPadding(bottom: 600);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        expect(
          MediaQuery.viewInsetsOf(tester.element(find.byType(ForgotPasswordScreen))).bottom,
          300,
        );
        final label = step == 'code' ? 'Changer le mot de passe' : 'Envoyer le code';
        if (step == 'code') {
          await tester.enterText(find.byType(TextField).at(0), '482913');
          await tester.enterText(find.byType(TextField).at(1), 'Mpita2026');
        } else {
          await tester.enterText(find.byType(TextField), accountPhone);
        }
        await tester.pump();
        await tester.scrollUntilVisible(
          find.text(label),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(label).hitTestable(), findsOneWidget);
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        final path = step == 'code' ? '/auth/password/reset' : '/auth/password/forgot';
        expect(h.backend.requestsTo(path), hasLength(1));
      });
    }

    for (final scale in textScales) {
      testWidgets('texte × $scale : les 3 étapes tiennent, avec erreurs, cibles ≥ 48', (
        tester,
      ) async {
        await openForgot(tester, textScale: scale);
        await sendCode(tester, phone: '06 12');
        expect(tester.takeException(), isNull);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await sendCode(tester);
        await reset(tester, code: '000000', password: 'court');
        expect(tester.takeException(), isNull);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await reset(tester);
        expect(find.text('Mot de passe modifié'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      });
    }
  });
}
