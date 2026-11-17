/// Numéros de téléphone du Congo-Brazzaville : mêmes règles que le backend
/// (`backend/app/core/validation.py`, `normalize_congo_phone`), pour refuser une saisie AVANT l'envoi
/// avec le même message que l'API.
library;

import 'typography.dart';

const _countryCode = '242';
const _nationalLength = 9;

/// Mobiles : 04, 05, 06 ; fixes : 22.
const _validPrefixes = ['04', '05', '06', '22'];
final _separators = RegExp(r'[\s.\-()/]');

/// Saisie refusée, avec le message à afficher sous le champ.
class PhoneFormatException implements Exception {
  const PhoneFormatException(this.message);

  final String message;

  @override
  String toString() => 'PhoneFormatException: $message';
}

/// « 06 123 45 67 », « 061234567 », « 00242… », « 242… », « +242… » → « +242061234567 ».
/// Lève [PhoneFormatException] (message du backend) si le numéro est invalide.
String normalizeCongoPhone(String raw) {
  var digits = raw.trim().replaceAll(_separators, '');
  if (digits.startsWith('+')) {
    digits = digits.substring(1);
  } else if (digits.startsWith('00')) {
    digits = digits.substring(2);
  }
  const wrongLength = 'Numéro invalide : 9 chiffres attendus (ex. 06 123 45 67)';
  if (digits.isEmpty) throw const PhoneFormatException(wrongLength);
  if (!RegExp(r'^[0-9]+$').hasMatch(digits)) {
    throw const PhoneFormatException(
      'Numéro invalide : seuls les chiffres, espaces et « + » sont acceptés',
    );
  }
  final String national;
  if (digits.length == _countryCode.length + _nationalLength && digits.startsWith(_countryCode)) {
    national = digits.substring(_countryCode.length);
  } else if (digits.length == _nationalLength) {
    national = digits;
  } else {
    throw const PhoneFormatException(wrongLength);
  }
  if (!_validPrefixes.any(national.startsWith)) {
    throw const PhoneFormatException('Numéro invalide : il doit commencer par 04, 05, 06 ou 22');
  }
  return '+$_countryCode$national';
}

/// Message d'erreur pour une saisie, ou `null` si elle est valide (champs de formulaire).
String? phoneError(String raw) {
  try {
    normalizeCongoPhone(raw);
    return null;
  } on PhoneFormatException catch (error) {
    return error.message;
  }
}

/// Affichage : « +242061234567 » → « +242 06 123 45 67 » (espaces insécables : jamais coupé).
/// Une valeur qui n'a pas cette forme (ex. numéro déjà masqué par l'API) est rendue telle quelle.
String formatPhone(String normalized) {
  final match = RegExp(r'^\+242(\d{2})(\d{3})(\d{2})(\d{2})$').firstMatch(normalized);
  if (match == null) return normalized;
  return ['+242', match[1], match[2], match[3], match[4]].join(unitSpace);
}
