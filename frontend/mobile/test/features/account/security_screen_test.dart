import 'package:dio/dio.dart';
import 'package:elecpay/app/router.dart';
import 'package:elecpay/app/routes.dart';
import 'package:elecpay/core/widgets/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import '../../support/fake_auth_backend.dart';
import '../../support/fake_server.dart';

/// L'application complète (vraie session), ouverte sur « Mot de passe et sécurité ».
Future<AppHarness> openSecurity(WidgetTester tester) async {
  final h = AppHarness(stored: SessionHarness.tokens(1));
  h.backend.validAccess.add('at-1');
  await h.start(tester);
  await tester.pumpAndSettle();
  AppHarness.containerOf(tester).read(routerProvider).go(Routes.security);
  await tester.pumpAndSettle();
  return h;
}

String location(WidgetTester tester) =>
    AppHarness.containerOf(tester).read(routerProvider).state.matchedLocation;

Future<void> fill(WidgetTester tester, String key, String text) async {
  await tester.enterText(
    find.descendant(of: find.byKey(Key(key)), matching: find.byType(EditableText)),
    text,
  );
  await tester.pump();
}

Future<void> tapKey(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

void main() {
  // F10.1 : état « hors connexion » d'une action (aucune relance automatique).
  testWidgets('hors connexion : message clair, rien de changé, toujours connecté', (tester) async {
    final h = await openSecurity(tester);
    h.backend.forced['/me/password'] = const FailReply(DioExceptionType.connectionError);
    await fill(tester, 'security.current', 'Demo2026!');
    await fill(tester, 'security.next', 'Nouveau2026!');
    await tapKey(tester, 'security.change');
    expect(
      find.text('Pas de connexion à ElecPay. Vérifiez votre connexion internet puis réessayez.'),
      findsOneWidget,
    );
    expect(h.tokens.tokens!.accessToken, 'at-1', reason: 'jetons inchangés');
    expect(location(tester), Routes.security);
    expect(
      h.backend.server.requests.where((r) => r.path == '/me/password'),
      hasLength(1),
      reason: 'aucune relance automatique',
    );
  });

  testWidgets('changer de mot de passe : nouveaux jetons enregistrés, toujours connecté', (
    tester,
  ) async {
    final h = await openSecurity(tester);
    expect(find.byKey(const Key('security.form')), findsOneWidget);
    await fill(tester, 'security.current', 'Demo2026!');
    await fill(tester, 'security.next', 'Nouveau2026!');
    await tapKey(tester, 'security.change');
    expect(h.tokens.tokens!.accessToken, 'at-2', reason: 'les jetons renvoyés sont gardés');
    expect(h.tokens.tokens!.refreshToken, 'rt-2');
    expect(location(tester), Routes.security, reason: 'cet appareil reste connecté');
    expect(
      find.text('Mot de passe changé. Vos autres appareils sont déconnectés.'),
      findsOneWidget,
    );
  });

  testWidgets('mot de passe actuel faux / identique / trop faible : messages sous le bon champ', (
    tester,
  ) async {
    final h = await openSecurity(tester);
    await fill(tester, 'security.current', 'Faux2026!');
    await fill(tester, 'security.next', 'Nouveau2026!');
    await tapKey(tester, 'security.change');
    expect(
      find.descendant(
        of: find.byKey(const Key('security.current')),
        matching: find.text('Mot de passe actuel incorrect.'),
      ),
      findsOneWidget,
    );
    await fill(tester, 'security.current', 'Demo2026!');
    await fill(tester, 'security.next', 'Demo2026!');
    await tapKey(tester, 'security.change');
    expect(
      find.descendant(
        of: find.byKey(const Key('security.next')),
        matching: find.text("Le nouveau mot de passe doit être différent de l'actuel."),
      ),
      findsOneWidget,
    );
    final before = h.backend.requestsTo('/me/password').length;
    await fill(tester, 'security.next', 'court');
    await tapKey(tester, 'security.change');
    expect(h.backend.requestsTo('/me/password'), hasLength(before), reason: 'refusé avant l’envoi');
    expect(h.tokens.tokens!.accessToken, 'at-1');
  });

  testWidgets('déconnecter tous les appareils : confirmation, puis cet appareil aussi', (
    tester,
  ) async {
    final h = await openSecurity(tester);
    await tapKey(tester, 'security.logoutAll');
    expect(find.text('Déconnecter tous vos appareils ?'), findsOneWidget);
    expect(find.textContaining('y compris celui-ci'), findsOneWidget);
    await tapKey(tester, 'manage.confirm.no');
    expect(h.backend.loggedOutEverywhere, isFalse);
    await tapKey(tester, 'security.logoutAll');
    await tapKey(tester, 'manage.confirm.yes');
    expect(h.backend.loggedOutEverywhere, isTrue);
    expect(location(tester), Routes.login);
    expect(h.tokens.tokens, isNull);
  });

  testWidgets('depuis l’écran Compte : « Mot de passe et sécurité »', (tester) async {
    final h = AppHarness(stored: SessionHarness.tokens(1));
    h.backend.validAccess.add('at-1');
    await h.start(tester);
    await tester.pumpAndSettle();
    AppHarness.containerOf(tester).read(routerProvider).go(AppTab.account.path);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account.security')));
    await tester.pumpAndSettle();
    expect(location(tester), Routes.security);
  });
}
