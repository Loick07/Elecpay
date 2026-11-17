/// Caractères typographiques des formats, choisis selon ce que les polices EMBARQUÉES dessinent
/// vraiment (sinon le téléphone afficherait un carré ou une police de secours).
/// `test/core/format/typography_test.dart` lit les fichiers de police et vérifie ces choix.
library;

/// Séparateur des milliers. La charte veut l'espace fine insécable (U+202F), mais Poppins ne la
/// contient pas (vérifié le 17/11/2026) : on utilise l'espace insécable normale (U+00A0).
const groupSpace = '\u00A0';

/// Espace avant une unité (FCFA, kWh, %) : insécable, le nombre ne se sépare jamais de son unité.
const unitSpace = '\u00A0';

/// Signe moins typographique (U+2212), présent dans Poppins.
const minusSign = '\u2212';

/// Tiret demi-cadratin des intervalles (« sept.–oct. »).
const enDash = '\u2013';
