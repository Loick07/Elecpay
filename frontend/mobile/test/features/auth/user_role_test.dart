import 'package:elecpay/features/auth/models/auth_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const known = [UserRole.client, UserRole.support, UserRole.admin, UserRole.superAdmin];

  test('rôle inconnu : aucun droit, en dessous de tous les rôles connus', () {
    for (final role in known) {
      expect(UserRole.unknown.hasAtLeast(role), isFalse, reason: 'unknown ≥ $role');
      expect(UserRole.unknown.level, lessThan(role.level));
    }
    expect(UserRole.unknown.hasAtLeast(UserRole.unknown), isFalse);
    expect(UserRole.unknown.isClient, isFalse);
    expect(UserRole.unknown.isTeam, isFalse);
  });

  test('ordre des rôles : client < support < admin < super admin', () {
    for (var i = 0; i < known.length; i++) {
      for (var j = 0; j < known.length; j++) {
        expect(known[i].hasAtLeast(known[j]), i >= j, reason: '${known[i]} ≥ ${known[j]}');
      }
    }
  });

  test('client : application client, pas l’équipe ; équipe : support, admin, super admin', () {
    expect(UserRole.client.isClient, isTrue);
    expect(UserRole.client.isTeam, isFalse);
    for (final role in [UserRole.support, UserRole.admin, UserRole.superAdmin]) {
      expect(role.isTeam, isTrue);
      expect(role.isClient, isFalse);
    }
  });
}
