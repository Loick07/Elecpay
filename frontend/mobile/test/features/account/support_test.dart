import 'package:elecpay/app/riverpod_config.dart';
import 'package:elecpay/app/routes.dart';
import 'package:elecpay/core/theme/app_theme.dart';
import 'package:elecpay/features/account/support_rules.dart';
import 'package:elecpay/features/account/support_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/itel_screen.dart';

Future<void> pumpSupport(WidgetTester tester, {double textScale = 1.0}) async {
  tester.view.physicalSize = itelPhysicalSize;
  tester.view.devicePixelRatio = itelPixelRatio;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final router = GoRouter(
    initialLocation: Routes.support,
    routes: [GoRoute(path: Routes.support, builder: (context, state) => const SupportScreen())],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      retry: noAutomaticRetry,
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('règles', () {
    test('5 questions fréquentes de la maquette, dans l’ordre', () {
      expect(faqs, hasLength(5));
      expect(faqs.first.question, 'Mon paiement est en attente depuis longtemps');
      expect(faqs.last.question, 'Où trouver la référence de mon compteur ?');
    });

    test('recherche sans accents ni majuscules, tous les mots', () {
      expect(simplify('Reçu ÉCHÉANCE d’un cœur'), "recu echeance d'un coeur");
      expect(searchFaqs('').length, 5);
      expect(searchFaqs('estimee').single.question, contains('estimée'));
      expect(searchFaqs('PROCHE').single.question, 'Comment payer la facture d’un proche ?');
      expect(searchFaqs('compteur facture').single.question, contains('référence de mon compteur'));
      expect(searchFaqs('bitcoin'), isEmpty);
    });
  });

  testWidgets('écran : première question ouverte, ouvrir / fermer, contacts « bientôt »', (
    tester,
  ) async {
    await pumpSupport(tester);
    expect(find.text('Assistance'), findsOneWidget);
    expect(find.textContaining('l’opérateur attend votre code PIN'), findsOneWidget);
    await tester.tap(find.byKey(const Key('support.faq.2')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Demandez au titulaire du foyer'), findsOneWidget);
    expect(find.textContaining('l’opérateur attend votre code PIN'), findsNothing);
    expect(
      tester
          .getSemantics(find.byKey(const Key('support.faq.2')))
          .getSemanticsData()
          .flagsCollection
          .isExpanded,
      isNot(false),
    );
    await tester.dragUntilVisible(
      find.byKey(const Key('support.e2c')),
      find.byKey(const Key('support.list')),
      const Offset(0, -200),
    );
    expect(find.text('Contacts du support : bientôt disponibles'), findsOneWidget);
    expect(find.textContaining('contactez directement E²C'), findsOneWidget);
    // Aucun faux contact : ni numéro, ni adresse e-mail.
    final texts = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? '').join(' ');
    expect(RegExp(r'@|\+242|0[456] ?\d{3}').hasMatch(texts), isFalse);
  });

  testWidgets('recherche : filtre les questions ; rien trouvé : un message', (tester) async {
    await pumpSupport(tester);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('support.search')),
        matching: find.byType(EditableText),
      ),
      'reçu',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('support.faq.1')), findsNothing);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('support.search')),
        matching: find.byType(EditableText),
      ),
      'bitcoin',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('support.noResult')), findsOneWidget);
  });

  for (final scale in [1.3, 2.0]) {
    testWidgets('texte à ${(scale * 100).round()} % : rien ne déborde', (tester) async {
      await pumpSupport(tester, textScale: scale);
      await tester.dragUntilVisible(
        find.byKey(const Key('support.e2c')),
        find.byKey(const Key('support.list')),
        const Offset(0, -200),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
