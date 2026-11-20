import 'package:elecpay/core/models/households.dart';
import 'package:elecpay/features/households/households_rules.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_home_backend.dart';

HouseholdDetail detail({
  String role = HouseholdRoles.owner,
  List<Map<String, Object?>> members = const [],
}) => HouseholdDetail.fromJson({
  ...FakeHomeBackend().householdDetailJson(2)!,
  'my_role': role,
  'members': members,
});

void main() {
  test('rôles : « Propriétaire », « Payeur délégué », « Lecteur » ; inconnu : « Membre »', () {
    expect(householdRoleLabel('owner'), 'Propriétaire');
    expect(householdRoleLabel('payer'), 'Payeur délégué');
    expect(householdRoleLabel('viewer'), 'Lecteur');
    expect(householdRoleLabel('nouveau'), 'Membre');
    expect(memberRoleLabel('payer'), 'payeur délégué', reason: 'jamais de genre deviné');
  });

  test('ligne du lieu (maquette) : « Mpita, Pointe-Noire · Propriétaire »', () {
    expect(
      householdPlaceLine('Mpita', 'Pointe-Noire', 'owner'),
      'Mpita, Pointe-Noire · Propriétaire',
    );
    expect(householdPlaceLine(null, 'Pointe-Noire', 'payer'), 'Pointe-Noire · Payeur délégué');
  });

  test('initiales et puissance souscrite', () {
    expect(initials('Grâce Ngoma'), 'GN');
    expect(initials('Loick  Makosso '), 'LM');
    expect(initials('Arnaud'), 'A');
    expect(initials(' '), '?');
    expect(subscribedPowerLabel(6000), '6\u00A0kVA');
    expect(subscribedPowerLabel(4500), '4,5\u00A0kVA');
    expect(subscribedPowerLabel(null), '—');
  });

  group('ligne des membres (maquette)', () {
    test('propriétaire seul : « Vous seul »', () {
      expect(membersLine(detail()), 'Vous seul');
      expect(memberInitials(detail()), ['LM']);
    });

    test('un payeur délégué : « Grâce Ngoma · payeur délégué »', () {
      final h = detail(members: [FakeHomeBackend.member(7, 'Grâce Ngoma')]);
      expect(membersLine(h), 'Grâce Ngoma · payeur délégué');
      expect(memberInitials(h), ['LM', 'GN']);
    });

    test('plusieurs, et des invitations en attente', () {
      final h = detail(
        members: [
          FakeHomeBackend.member(7, 'Grâce Ngoma'),
          FakeHomeBackend.member(8, 'Paul Mabiala', role: 'viewer'),
          FakeHomeBackend.member(9, 'Jean Moukala'),
          FakeHomeBackend.member(10, 'Invité', status: 'invited'),
        ],
      );
      expect(membersLine(h), 'Grâce Ngoma et 2 autres · 1 invitation en attente');
      expect(memberInitials(h), hasLength(3), reason: '3 pastilles au plus');
    });

    test('je ne suis pas propriétaire : le nom du propriétaire', () {
      expect(membersLine(detail(role: 'payer')), 'Propriétaire : Loick Makosso');
    });
  });

  test('invitation reçue : « Marie Loemba vous invite comme payeur délégué »', () {
    final i = InvitationPublic.fromJson(FakeHomeBackend.invitation(1, 'Chez Mamie'));
    expect(invitationTitle(i), 'Marie Loemba vous invite comme payeur délégué');
  });
}
