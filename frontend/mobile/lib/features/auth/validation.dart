/// Règles de saisie de l'inscription et du mot de passe : les MÊMES que le backend
/// (`backend/app/core/validation.py`), avec les mêmes messages, pour refuser une saisie avant
/// l'envoi. Le backend reste seul juge : il revérifie tout.
library;

const passwordMinLength = 8;
const passwordMaxLength = 128;
const fullNameMinLength = 2;
const fullNameMaxLength = 120;
const emailMaxLength = 254;

final _letter = RegExp(r'\p{L}', unicode: true);
final _digit = RegExp(r'\p{Nd}', unicode: true);
final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s.]{2,}$');

/// Une règle du mot de passe, affichée sous le champ et cochée pendant la saisie.
typedef PasswordRule = ({String label, bool Function(String password) ok});

/// Les règles VISIBLES (maquette + « au moins une lettre », validé le 18/11/2026).
final passwordRules = <PasswordRule>[
  (label: '8 caractères minimum', ok: (p) => p.length >= passwordMinLength),
  (label: 'Au moins un chiffre', ok: _digit.hasMatch),
  (label: 'Au moins une lettre', ok: _letter.hasMatch),
];

/// Message d'erreur du mot de passe (celui du backend), ou `null` s'il est accepté.
String? passwordError(String password) {
  if (password.length < passwordMinLength) {
    return 'Mot de passe trop court : $passwordMinLength caractères minimum';
  }
  if (password.length > passwordMaxLength) {
    return 'Mot de passe trop long : $passwordMaxLength caractères maximum';
  }
  if (!_digit.hasMatch(password)) return 'Le mot de passe doit contenir au moins un chiffre';
  if (!_letter.hasMatch(password)) return 'Le mot de passe doit contenir au moins une lettre';
  if (password != password.trim()) {
    return 'Le mot de passe ne doit pas commencer ni finir par un espace';
  }
  return null;
}

/// Nom normalisé comme le backend : espaces superflus retirés (« Grâce   Ngoma » → « Grâce Ngoma »).
String normalizeFullName(String raw) => raw.trim().split(RegExp(r'\s+')).join(' ');

/// Message d'erreur du nom (celui du backend), ou `null`.
String? fullNameError(String raw) {
  final name = normalizeFullName(raw);
  if (name.length < fullNameMinLength) return 'Nom trop court';
  if (name.length > fullNameMaxLength) {
    return 'Nom trop long : $fullNameMaxLength caractères maximum';
  }
  if (!_letter.hasMatch(name)) return 'Le nom doit contenir des lettres';
  return null;
}

/// E-mail normalisé (espaces retirés, minuscules) ; `null` si le champ est vide (facultatif).
String? normalizeEmail(String raw) {
  final email = raw.trim().toLowerCase();
  return email.isEmpty ? null : email;
}

/// Message d'erreur de l'e-mail (celui du backend), ou `null` (vide : accepté, il est facultatif).
String? emailError(String raw) {
  final email = normalizeEmail(raw);
  if (email == null) return null;
  if (email.length > emailMaxLength || !_email.hasMatch(email)) return 'Adresse e-mail invalide';
  return null;
}
