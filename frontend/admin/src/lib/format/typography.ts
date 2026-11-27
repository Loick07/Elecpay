// Caractères typographiques des formats : les MÊMES que l'application mobile
// (`frontend/mobile/lib/core/format/typography.dart`), pour que « 12 500 FCFA » soit identique partout
// (décision DA0.5). Construits par leur code : jamais un caractère invisible écrit en dur dans le code
// (contrôlé par `tests/source-characters.test.ts`).

/** Séparateur des milliers : espace insécable (U+00A0), comme l'application. */
export const groupSpace = String.fromCharCode(0x00a0);

/** Espace avant une unité (FCFA, kWh, %) : insécable, le nombre ne se sépare jamais de son unité. */
export const unitSpace = String.fromCharCode(0x00a0);

/** Signe moins typographique (U+2212). */
export const minusSign = String.fromCharCode(0x2212);

/** Tiret demi-cadratin des intervalles (« sept.–oct. »), U+2013. */
export const enDash = String.fromCharCode(0x2013);
