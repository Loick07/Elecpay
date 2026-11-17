import 'package:elecpay/core/format/phone.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mêmes cas que le backend (`backend/app/core/validation.py`, `normalize_congo_phone`).
void main() {
  group('saisie libre → +242XXXXXXXXX (comme l’API)', () {
    for (final input in [
      '06 123 45 67',
      '061234567',
      '06.123.45.67',
      '06-123-45-67',
      '(06) 123 45 67',
      '06/123/45/67',
      '+242 06 123 45 67',
      '+242061234567',
      '00242061234567',
      '242061234567',
      '  06 123 45 67  ',
    ]) {
      test('« $input »', () => expect(normalizeCongoPhone(input), '+242061234567'));
    }

    test('les 4 préfixes acceptés : 04, 05, 06, 22', () {
      for (final prefix in ['04', '05', '06', '22']) {
        expect(normalizeCongoPhone('${prefix}1234567'), '+242${prefix}1234567');
      }
    });
  });

  group('saisies refusées, avec le message du backend', () {
    for (final (input, message) in [
      ('', 'Numéro invalide : 9 chiffres attendus (ex. 06 123 45 67)'),
      ('   ', 'Numéro invalide : 9 chiffres attendus (ex. 06 123 45 67)'),
      ('+', 'Numéro invalide : 9 chiffres attendus (ex. 06 123 45 67)'),
      ('06123456', 'Numéro invalide : 9 chiffres attendus (ex. 06 123 45 67)'),
      ('0612345678', 'Numéro invalide : 9 chiffres attendus (ex. 06 123 45 67)'),
      ('243061234567', 'Numéro invalide : 9 chiffres attendus (ex. 06 123 45 67)'),
      ('06 12a 45 67', 'Numéro invalide : seuls les chiffres, espaces et « + » sont acceptés'),
      ('071234567', 'Numéro invalide : il doit commencer par 04, 05, 06 ou 22'),
      ('+242 01 234 56 78', 'Numéro invalide : il doit commencer par 04, 05, 06 ou 22'),
    ]) {
      test('« $input »', () {
        expect(
          () => normalizeCongoPhone(input),
          throwsA(isA<PhoneFormatException>().having((e) => e.message, 'message', message)),
        );
        expect(phoneError(input), message);
      });
    }

    test('saisie valide : aucun message', () => expect(phoneError('06 123 45 67'), isNull));
  });

  group('affichage', () {
    test('« +242 06 123 45 67 », avec des espaces insécables (jamais coupé)', () {
      final shown = formatPhone('+242061234567');
      expect(shown.replaceAll('\u00A0', ' '), '+242 06 123 45 67');
      expect(shown, isNot(contains(' ')));
    });

    test('numéro déjà masqué par l’API : rendu tel quel', () {
      expect(formatPhone('+242 06 *** ** 67'), '+242 06 *** ** 67');
    });
  });
}
