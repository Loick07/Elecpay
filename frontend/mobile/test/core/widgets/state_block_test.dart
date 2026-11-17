import 'package:elecpay/core/network/api_failure.dart';
import 'package:elecpay/core/network/models/api_error.dart';
import 'package:elecpay/core/theme/app_icons.dart';
import 'package:elecpay/core/theme/tokens.g.dart';
import 'package:elecpay/core/widgets/app_button.dart';
import 'package:elecpay/core/widgets/state_block.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/itel_screen.dart';

ApiRejected rejected(int status, String code, String message) => ApiRejected(
  statusCode: status,
  body: ErrorBody(code: code, message: message),
  reference: 'app-ref123456',
);

void main() {
  const c = ElecPayColors.dark;

  testWidgets('vide : pastille neutre, titre, phrase, une action primary', (tester) async {
    var taps = 0;
    await pumpOnItel(
      tester,
      StateBlock.empty(
        title: 'Aucune facture pour l’instant',
        message: 'Ajoutez un compteur pour les voir ici.',
        actionLabel: 'Ajouter un compteur',
        onAction: () => taps++,
      ),
    );
    expect(find.text('Aucune facture pour l’instant'), findsOneWidget);
    expect(find.text('Ajoutez un compteur pour les voir ici.'), findsOneWidget);
    expect(find.byIcon(AppIcons.empty), findsOneWidget);
    expect(tester.widget<AppButton>(find.byType(AppButton)).variant, ButtonVariant.primary);
    await tester.tap(find.text('Ajouter un compteur'));
    expect(taps, 1);
  });

  testWidgets('vide sans action : aucun bouton', (tester) async {
    await pumpOnItel(
      tester,
      const StateBlock.empty(
        title: 'Aucune facture en retard',
        message: 'Vos deux foyers sont à jour.',
        tone: StateTone.success,
      ),
    );
    expect(find.byType(AppButton), findsNothing);
  });

  testWidgets('erreur serveur : texte de la charte, « Réessayer » secondary, référence', (
    tester,
  ) async {
    var retries = 0;
    await pumpOnItel(
      tester,
      StateBlock.error(what: 'vos factures', onRetry: () => retries++, reference: 'app-ref123456'),
    );
    expect(
      find.text('Impossible de charger vos factures. Réessayez dans un instant.'),
      findsOneWidget,
    );
    expect(tester.widget<AppButton>(find.byType(AppButton)).variant, ButtonVariant.secondary);
    expect(find.text('Référence : app-ref123456'), findsOneWidget);
    final pastille = tester.widget<Container>(
      find.ancestor(of: find.byIcon(AppIcons.error), matching: find.byType(Container)).first,
    );
    expect((pastille.decoration! as BoxDecoration).color, c.errorSoft);
    await tester.tap(find.text('Réessayer'));
    expect(retries, 1);
  });

  testWidgets('accès refusé : le message donné, sans action', (tester) async {
    await pumpOnItel(tester, const StateBlock.accessDenied(message: 'Facture introuvable.'));
    expect(find.text('Facture introuvable.'), findsOneWidget);
    expect(find.byType(AppButton), findsNothing);
  });

  group('le bon bloc pour chaque échec (sans donnée en cache)', () {
    StateBlock blockFor(ApiFailure failure) =>
        stateForFailure(failure, what: 'vos factures', onRetry: () {});

    test('hors connexion → bloc « Hors connexion » avec Réessayer', () {
      final block = blockFor(const NoConnection(reference: 'r'));
      expect(block.title, 'Hors connexion');
      expect(block.actionLabel, 'Réessayer');
    });

    for (final failure in <ApiFailure>[
      const ApiTimeout(mayHaveReachedServer: false, reference: 'r1'),
      const ServerUnavailable(statusCode: 503, reference: 'r2'),
      const UnexpectedResponse(reference: 'r3'),
      rejected(409, 'CONFLICT', 'Conflit.'),
    ]) {
      test('${failure.runtimeType} → erreur avec la référence', () {
        final block = blockFor(failure);
        expect(block.message, 'Impossible de charger vos factures. Réessayez dans un instant.');
        expect(block.reference, failure.reference);
      });
    }

    for (final status in [403, 404]) {
      test('$status → accès refusé, message de l’API', () {
        final block = blockFor(
          rejected(status, 'FORBIDDEN', 'Ce compteur ne vous est plus partagé.'),
        );
        expect(block.title, 'Accès impossible');
        expect(block.message, 'Ce compteur ne vous est plus partagé.');
        expect(block.actionLabel, isNull);
      });
    }

    test('404 sur une facture : le message de l’API, JAMAIS le texte « foyer » par défaut', () {
      final block = blockFor(rejected(404, 'NOT_FOUND', 'Facture introuvable.'));
      expect(block.message, 'Facture introuvable.');
      expect(block.message, isNot(householdNotShared));
    });

    test('écran d’un foyer : « Ce foyer ne vous est plus partagé. » (charte)', () {
      final block = stateForFailure(
        rejected(404, 'NOT_FOUND', 'Ressource introuvable.'),
        what: 'votre foyer',
        onRetry: () {},
        accessDeniedMessage: householdNotShared,
      );
      expect(block.message, 'Ce foyer ne vous est plus partagé.');
      expect(block.reference, 'app-ref123456');
    });

    test('le message d’écran ne s’applique qu’à l’accès refusé, pas aux autres échecs', () {
      final block = stateForFailure(
        const ServerUnavailable(statusCode: 503),
        what: 'votre foyer',
        onRetry: () {},
        accessDeniedMessage: householdNotShared,
      );
      expect(block.message, 'Impossible de charger votre foyer. Réessayez dans un instant.');
    });
  });

  group('écran de l’itel (360 × 800), texte agrandi', () {
    for (final scale in textScales) {
      testWidgets('texte × $scale : sans débordement, zones tactiles ≥ 48', (tester) async {
        await pumpOnItel(
          tester,
          StateBlock.error(
            what: 'l’historique de vos paiements',
            onRetry: () {},
            reference: 'app-k3v9q2x7m1z8c4b6n0p5',
          ),
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      });
    }
  });
}
