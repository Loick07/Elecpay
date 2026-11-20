import 'package:elecpay/app/riverpod_config.dart';
import 'package:elecpay/core/cache/cache_policy.dart';
import 'package:elecpay/core/cache/cached_api.dart';
import 'package:elecpay/core/models/households.dart';
import 'package:elecpay/core/network/api_failure.dart';
import 'package:elecpay/features/home/home_data.dart';
import 'package:elecpay/features/households/households_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_home_backend.dart';
import '../../support/fake_server.dart';

ProviderContainer containerFor(FakeHomeBackend backend) {
  final c = ProviderContainer(retry: noAutomaticRetry, overrides: backend.overrides());
  addTearDown(c.dispose);
  return c;
}

Future<T> listenRead<T>(ProviderContainer c, ProviderListenable<Future<T>> p) async {
  final sub = c.listen(p, (_, _) {});
  try {
    return await sub.read();
  } finally {
    sub.close();
  }
}

void main() {
  test('cache : cartes et membres gardés hors ligne ; invitations JAMAIS', () {
    expect(isCacheable('/households/2'), isTrue);
    expect(isCacheable('/households/2/members'), isTrue);
    expect(isCacheable('/invitations'), isFalse);
  });

  test('carte d’un foyer : compteurs, membres, droits venus du serveur', () async {
    final detail = await listenRead(
      containerFor(FakeHomeBackend()),
      householdDetailProvider(2).future,
    );
    expect(detail, isA<FreshData<HouseholdDetail>>());
    expect(detail.data.name, 'Boutique Tié-Tié');
    expect(detail.data.canManage, isTrue);
    expect(detail.data.meters.single.id, 20);
    expect(detail.data.members.single.person.fullName, 'Grâce Ngoma');
  });

  test('carte d’un foyer hors ligne : depuis le cache, signalée', () async {
    final backend = FakeHomeBackend();
    await listenRead(containerFor(backend), householdDetailProvider(2).future);
    backend.down.add('/households');
    final offline = await listenRead(containerFor(backend), householdDetailProvider(2).future);
    expect(offline, isA<CachedData<HouseholdDetail>>());
  });

  test('invitations hors ligne : erreur (jamais une liste ancienne)', () async {
    final backend = FakeHomeBackend()..invitations = [FakeHomeBackend.invitation(1, 'Chez Mamie')];
    expect(await listenRead(containerFor(backend), invitationsProvider.future), hasLength(1));
    backend.down.add('/invitations');
    await expectLater(
      listenRead(containerFor(backend), invitationsProvider.future),
      throwsA(isA<ApiFailure>()),
    );
  });

  test('badge « À payer » : les foyers qui ont une facture à payer', () async {
    expect(await listenRead(containerFor(FakeHomeBackend()), householdsToPayProvider.future), {
      1,
      2,
    });
  });

  group('actions (envoyées une fois, puis relues)', () {
    test('accepter une invitation : le foyer rejoint apparaît', () async {
      final backend = FakeHomeBackend()
        ..invitations = [FakeHomeBackend.invitation(1, 'Chez Mamie')];
      final c = containerFor(backend);
      final sub = c.listen(householdsProvider.future, (_, _) {});
      addTearDown(sub.close);
      expect((await sub.read()).data, hasLength(2));
      final joined = await c.read(householdActionsProvider).accept(1);
      expect(joined.name, 'Chez Mamie');
      expect(joined.myRole, HouseholdRoles.payer);
      expect((await c.read(householdsProvider.future)).data, hasLength(3));
      expect(await c.read(invitationsProvider.future), isEmpty);
    });

    test('refuser : l’invitation disparaît, aucun foyer ajouté', () async {
      final backend = FakeHomeBackend()
        ..invitations = [FakeHomeBackend.invitation(1, 'Chez Mamie')];
      final c = containerFor(backend);
      await c.read(householdActionsProvider).decline(1);
      expect(backend.households, hasLength(2));
      expect(backend.requestsTo('/invitations/1/decline').single.method, 'POST');
    });

    test(
      'ajouter un compteur : les deux numéros partent, l’historique importé est renvoyé',
      () async {
        final backend = FakeHomeBackend();
        final added = await containerFor(backend)
            .read(householdActionsProvider)
            .addMeter(
              1,
              const MeterAddRequest(reference: '0018 09 5408', customerNumber: '0758340H'),
            );
        expect(added.history.bills, 9);
        expect(backend.sent['/households/1/meters']!.single, {
          'reference': '0018 09 5408',
          'customer_number': '0758340H',
          'label': null,
        });
      },
    );

    test('compteur inconnu d’E²C : l’erreur de l’API remonte telle quelle', () async {
      final failure = await containerFor(FakeHomeBackend())
          .read(householdActionsProvider)
          .addMeter(1, const MeterAddRequest(reference: '0018 09 0000', customerNumber: '0758340H'))
          .then<Object?>((_) => null, onError: (Object e) => e);
      expect((failure! as ApiRejected).code, 'E2C_METER_NOT_FOUND');
    });

    test('créer un foyer, inviter, retirer, quitter, renommer', () async {
      final backend = FakeHomeBackend();
      final actions = containerFor(backend).read(householdActionsProvider);
      final created = await actions.createHousehold(
        const HouseholdCreate(name: 'Maison Mpaka', city: 'Pointe-Noire'),
      );
      expect(created.name, 'Maison Mpaka');
      final invited = await actions.invite(
        2,
        const InviteRequest(phone: '+242060000202', role: 'payer'),
      );
      expect(invited.status, MemberStatuses.invited);
      await actions.removeMember(2, 7);
      expect(backend.requestsTo('/households/2/members/7').single.method, 'DELETE');
      await actions.renameHousehold(1, 'Maison familiale');
      expect(backend.sent['/households/1']!.single, {'name': 'Maison familiale'});
      await actions.renameMeter(1, 10, 'Cuisine');
      expect(backend.sent['/meters/10']!.single, {'label': 'Cuisine'});
      await actions.leave(2);
      expect(backend.requestsTo('/households/2/leave').single.method, 'POST');
    });

    test('une action en échec n’est JAMAIS relancée automatiquement', () async {
      final backend = FakeHomeBackend();
      backend.forced['/households/2/leave'] = JsonReply(
        400,
        apiError('OWNER_CANNOT_LEAVE', 'Le propriétaire ne peut pas quitter son foyer.'),
      );
      await expectLater(
        containerFor(backend).read(householdActionsProvider).leave(2),
        throwsA(isA<ApiRejected>()),
      );
      expect(backend.requestsTo('/households/2/leave'), hasLength(1));
    });
  });
}
