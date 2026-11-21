import 'package:elecpay/core/models/households.dart';
import 'package:elecpay/features/households/households_rules.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_home_backend.dart';
import '../../support/fake_server.dart';
import 'add_meter_sheet_test.dart' show fill, pumpScreen;
import 'households_screen_test.dart' show mockupBackend, settle;

Future<void> tapKey(WidgetTester tester, String key) async {
  final target = find.byKey(Key(key));
  if (key.startsWith('households.')) {
    // Bouton d'une carte : la liste est construite au fil du défilement, et « Ajouter un
    // compteur » (fixé en bas) peut le cacher. On fait défiler jusqu'à pouvoir le toucher.
    await tester.dragUntilVisible(
      target.hitTestable(),
      find.byKey(const Key('households.list')),
      const Offset(0, -100),
    );
  } else {
    await tester.ensureVisible(target);
  }
  await settle(tester);
  await tester.tap(target);
  await settle(tester);
}

/// Touche un bouton d'une ligne (« Retirer », « Renommer ») de la feuille « Gérer ».
Future<void> tapInLine(WidgetTester tester, String line, String button) async {
  final target = find.descendant(of: find.byKey(Key(line)), matching: find.text(button));
  await tester.ensureVisible(target);
  await settle(tester);
  await tester.tap(target);
  await settle(tester);
}

void main() {
  group('règles', () {
    test('bouton de la carte : « Inviter un proche » (propriétaire seul), sinon « Gérer »', () {
      final backend = FakeHomeBackend();
      expect(
        householdActionLabel(HouseholdDetail.fromJson(backend.householdDetailJson(1)!)),
        'Inviter un proche',
      );
      expect(
        householdActionLabel(HouseholdDetail.fromJson(backend.householdDetailJson(2)!)),
        'Gérer',
      );
      backend.households = [
        {...backend.households[0], 'my_role': 'payer'},
      ];
      expect(
        householdActionLabel(HouseholdDetail.fromJson(backend.householdDetailJson(1)!)),
        'Gérer',
      );
    });

    test('messages d’invitation (D8.2 : aucun SMS)', () {
      expect(inviteeWithoutAccount, contains('Demandez-lui de s’inscrire'.replaceAll('’', "'")));
      expect(inviteSentMessage('+242 06 000 02 02'), contains('doit l\'accepter'));
    });
  });

  group('inviter un proche', () {
    testWidgets('propriétaire seul : numéro vérifié, invitation envoyée, en attente sur la carte', (
      tester,
    ) async {
      final backend = mockupBackend();
      await pumpScreen(tester, backend);
      expect(
        find.descendant(
          of: find.byKey(const Key('households.manage.1')),
          matching: find.text('Inviter un proche'),
        ),
        findsOneWidget,
      );
      await tapKey(tester, 'households.manage.1');
      expect(find.byKey(const Key('invite.sheet')), findsOneWidget);
      await fill(tester, 'invite.phone', '12');
      await tapKey(tester, 'invite.send');
      expect(
        backend.sent['/households/1/members'],
        isNull,
        reason: 'numéro invalide : rien n’est envoyé',
      );
      await fill(tester, 'invite.phone', '060000202');
      await tapKey(tester, 'invite.role.viewer');
      await tapKey(tester, 'invite.send');
      expect(backend.sent['/households/1/members']!.single, {
        'phone': '+242060000202',
        'role': 'viewer',
      });
      expect(find.byKey(const Key('invite.sheet')), findsNothing);
      expect(find.textContaining('Invitation envoyée au'), findsOneWidget);
      expect(find.text('Vous seul · 1 invitation en attente'), findsOneWidget);
    });

    testWidgets('numéro sans compte ElecPay : message D8.2 sous le numéro', (tester) async {
      final backend = mockupBackend();
      backend.forced['/households/1/members'] = JsonReply(
        404,
        apiError('INVITEE_NOT_FOUND', 'Aucun compte ElecPay avec ce numéro.'),
      );
      await pumpScreen(tester, backend);
      await tapKey(tester, 'households.manage.1');
      await fill(tester, 'invite.phone', '060000909');
      await tapKey(tester, 'invite.send');
      expect(
        find.descendant(
          of: find.byKey(const Key('invite.phone')),
          matching: find.text(inviteeWithoutAccount),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('invite.sheet')),
        findsOneWidget,
        reason: 'la feuille reste ouverte',
      );
    });
  });

  group('gérer (propriétaire)', () {
    testWidgets('retirer un membre : confirmation, puis « Vous seul » ; Annuler : rien', (
      tester,
    ) async {
      final backend = mockupBackend();
      await pumpScreen(tester, backend);
      await tapKey(tester, 'households.manage.2');
      expect(find.byKey(const Key('manage.sheet')), findsOneWidget);
      expect(find.text('Grâce Ngoma'), findsOneWidget);
      await tapInLine(tester, 'manage.member.7', 'Retirer');
      expect(find.text('Retirer ce membre ?'), findsOneWidget);
      await tapKey(tester, 'manage.confirm.no');
      expect(backend.requestsTo('/households/2/members/7'), isEmpty);
      await tapInLine(tester, 'manage.member.7', 'Retirer');
      await tapKey(tester, 'manage.confirm.yes');
      expect(backend.requestsTo('/households/2/members/7').single.method, 'DELETE');
      expect(find.text('Grâce Ngoma a été retiré.'), findsOneWidget);
      expect(find.text('Vous seul.'), findsOneWidget, reason: 'la feuille suit le foyer relu');
    });

    testWidgets('renommer le foyer (nom obligatoire) et un compteur (nom facultatif)', (
      tester,
    ) async {
      final backend = mockupBackend();
      await pumpScreen(tester, backend);
      await tapKey(tester, 'households.manage.2');
      await tapKey(tester, 'manage.renameHousehold');
      await fill(tester, 'rename.value', '  ');
      await tapKey(tester, 'rename.save');
      expect(find.text('Saisissez un nom.'), findsOneWidget);
      expect(backend.sent['/households/2'], isNull);
      await fill(tester, 'rename.value', 'Boutique centre');
      await tapKey(tester, 'rename.save');
      expect(backend.sent['/households/2']!.single, {'name': 'Boutique centre'});
      expect(find.text('Nom enregistré.'), findsOneWidget);
      await tapInLine(tester, 'manage.meter.20', 'Renommer');
      await fill(tester, 'rename.value', 'Cuisine');
      await tapKey(tester, 'rename.save');
      expect(backend.sent['/meters/20']!.single, {'label': 'Cuisine'});
      await tapInLine(tester, 'manage.meter.20', 'Renommer');
      await fill(tester, 'rename.value', '');
      await tapKey(tester, 'rename.save');
      expect(backend.sent['/meters/20']!.last, {'label': null}, reason: 'vide : plus de nom');
    });

    testWidgets('refus de l’API : son message, l’écran reste juste', (tester) async {
      final backend = mockupBackend();
      backend.forced['/households/2/members/7'] = JsonReply(
        403,
        apiError('HOUSEHOLD_FORBIDDEN', 'Seul le propriétaire peut retirer un membre.'),
      );
      await pumpScreen(tester, backend);
      await tapKey(tester, 'households.manage.2');
      await tapInLine(tester, 'manage.member.7', 'Retirer');
      await tapKey(tester, 'manage.confirm.yes');
      expect(find.text('Seul le propriétaire peut retirer un membre.'), findsOneWidget);
      expect(find.text('Grâce Ngoma'), findsOneWidget);
    });
  });

  testWidgets(
    'membre (payeur délégué) : « Gérer » propose seulement de quitter, avec confirmation',
    (tester) async {
      final backend = mockupBackend();
      backend.households = [
        backend.households[0],
        {...backend.households[1], 'my_role': 'payer'},
      ];
      await pumpScreen(tester, backend);
      await tapKey(tester, 'households.manage.2');
      expect(find.byKey(const Key('manage.renameHousehold')), findsNothing);
      expect(find.byKey(const Key('manage.invite')), findsNothing);
      expect(find.textContaining('Seul le propriétaire (Loick Makosso)'), findsOneWidget);
      await tapKey(tester, 'manage.leave');
      expect(find.text('Quitter Boutique Tié-Tié ?'), findsOneWidget);
      await tapKey(tester, 'manage.confirm.yes');
      expect(backend.requestsTo('/households/2/leave').single.method, 'POST');
      expect(find.text('Vous avez quitté Boutique Tié-Tié.'), findsOneWidget);
      expect(find.byKey(const Key('manage.sheet')), findsNothing);
      expect(find.byKey(const Key('households.card.2')), findsNothing);
    },
  );

  testWidgets('texte à 200 % : feuille « Gérer » sans débordement', (tester) async {
    await pumpScreen(tester, mockupBackend(), textScale: 2);
    await tapKey(tester, 'households.manage.2');
    expect(find.byKey(const Key('manage.sheet')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
