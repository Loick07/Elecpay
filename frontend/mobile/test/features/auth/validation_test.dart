import 'package:elecpay/features/auth/validation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mêmes règles et messages que le backend (`backend/app/core/validation.py`).
void main() {
  group('mot de passe', () {
    for (final (password, message) in [
      ('court1', 'Mot de passe trop court : 8 caractères minimum'),
      ('${'a' * 128}1', 'Mot de passe trop long : 128 caractères maximum'),
      ('sanschiffre', 'Le mot de passe doit contenir au moins un chiffre'),
      ('12345678', 'Le mot de passe doit contenir au moins une lettre'),
      (' Demo2026!', 'Le mot de passe ne doit pas commencer ni finir par un espace'),
      ('Demo2026! ', 'Le mot de passe ne doit pas commencer ni finir par un espace'),
    ]) {
      test('« $password » refusé', () => expect(passwordError(password), message));
    }

    test('accepté : Demo2026!, lettres accentuées, 128 caractères', () {
      expect(passwordError('Demo2026!'), isNull);
      expect(passwordError('élecpay2026'), isNull);
      expect(passwordError('${'a' * 127}1'), isNull);
    });

    test('règles visibles cochées pendant la saisie (dont « Au moins une lettre »)', () {
      expect(passwordRules.map((r) => r.label), [
        '8 caractères minimum',
        'Au moins un chiffre',
        'Au moins une lettre',
      ]);
      bool met(String rule, String password) =>
          passwordRules.firstWhere((r) => r.label == rule).ok(password);
      expect(met('8 caractères minimum', 'abcdefg'), isFalse);
      expect(met('8 caractères minimum', 'abcdefgh'), isTrue);
      expect(met('Au moins un chiffre', 'abc'), isFalse);
      expect(met('Au moins un chiffre', 'abc1'), isTrue);
      expect(met('Au moins une lettre', '1234'), isFalse);
      expect(met('Au moins une lettre', '1234é'), isTrue);
    });
  });

  group('nom', () {
    test('espaces superflus retirés, comme le backend', () {
      expect(normalizeFullName('  Grâce   Ngoma '), 'Grâce Ngoma');
    });

    test('refusés : trop court, trop long, sans lettre', () {
      expect(fullNameError(' A '), 'Nom trop court');
      expect(fullNameError('a' * 121), 'Nom trop long : 120 caractères maximum');
      expect(fullNameError('12 34'), 'Le nom doit contenir des lettres');
      expect(fullNameError('Loick Makosso'), isNull);
    });
  });

  group('e-mail (facultatif)', () {
    test('vide : accepté et envoyé comme null', () {
      expect(emailError('  '), isNull);
      expect(normalizeEmail('  '), isNull);
    });

    test('normalisé en minuscules, sans espaces', () {
      expect(normalizeEmail(' Grace.Ngoma@Example.COM '), 'grace.ngoma@example.com');
    });

    test('forme invalide : refusé', () {
      for (final email in ['grace', 'grace@', 'grace@example', 'a b@c.cg', 'g@e.c']) {
        expect(emailError(email), 'Adresse e-mail invalide', reason: email);
      }
      expect(emailError('vous@exemple.cg'), isNull);
    });
  });
}
