// Montants, énergie et variations au format de la charte (`frontend/design/CHARTE.md`) : portage
// exact de `frontend/mobile/lib/core/format/numbers.dart` (mêmes cas de test).
import { groupSpace, minusSign, unitSpace } from "./typography";

/**
 * Arrondi « au plus proche, les demis s'éloignent de zéro », comme `round()` de Dart :
 * −12,5 → −13 (alors que `Math.round(−12.5)` donne −12).
 */
export function roundHalfAway(value: number): number {
  return value < 0 ? -Math.round(-value) : Math.round(value);
}

/** Chiffres groupés par milliers : 1234567 → « 1 234 567 » (espace insécable). */
function group(value: number): string {
  const digits = Math.abs(value).toString();
  let out = "";
  for (let i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 === 0) out += groupSpace;
    out += digits[i];
  }
  return `${value < 0 ? minusSign : ""}${out}`;
}

function integer(amount: number): number {
  if (!Number.isSafeInteger(amount)) {
    throw new Error(`Montant FCFA non entier : ${amount} (les montants sont toujours entiers)`);
  }
  return amount;
}

/** Montant en FCFA, toujours entier : 31420 → « 31 420 FCFA ». Jamais de centimes. */
export function formatFcfa(amount: number): string {
  return `${formatFcfaValue(amount)}${unitSpace}FCFA`;
}

/** Le nombre seul, quand « FCFA » est écrit à part en plus petit : « 31 420 ». */
export function formatFcfaValue(amount: number): string {
  return group(integer(amount));
}

/**
 * Nombre de kWh (sans l'unité), une décimale au plus, virgule : 417.4 → « 417,4 » ; 12 → « 12 » ;
 * 18664.4 → « 18 664,4 ». Arrondi au dixième le plus proche.
 */
export function formatKwhValue(kwh: number): string {
  const tenths = roundHalfAway(kwh * 10);
  const whole = Math.trunc(tenths / 10);
  const decimal = Math.abs(tenths % 10);
  const sign = tenths < 0 && whole === 0 ? minusSign : "";
  return `${sign}${group(whole)}${decimal === 0 ? "" : `,${decimal}`}`;
}

/** Énergie : « 417,4 kWh ». */
export function formatKwh(kwh: number): string {
  return `${formatKwhValue(kwh)}${unitSpace}kWh`;
}

/** Énergie reçue de l'API en Wh entiers (back-office) : 417400 → « 417,4 kWh ». */
export function formatWhAsKwh(wh: number): string {
  return formatKwh(integer(wh) / 1000);
}

/** Signe d'une valeur approchée (estimation). */
const approx = "≈";

/** Énergie ESTIMÉE, arrondie au kWh : 206.3 → « ≈ 206 kWh ». */
export function formatApproxKwh(kwh: number): string {
  return `${approx}${unitSpace}${group(roundHalfAway(kwh))}${unitSpace}kWh`;
}

/** Montant ESTIMÉ, arrondi à la centaine : 10112 → « ≈ 10 100 FCFA ». */
export function formatApproxFcfa(amount: number): string {
  return `${approx}${unitSpace}${formatFcfa(roundHalfAway(integer(amount) / 100) * 100)}`;
}

/** Coût d'énergie calculé (kWh × tarif, sans taxes) : « ≈ 441 FCFA ». */
export function formatAboutFcfa(amount: number): string {
  return `${approx}${unitSpace}${formatFcfa(amount)}`;
}

/**
 * Nombre décimal d'AFFICHAGE (prix unitaire, quantité), au plus `maxDecimals` décimales utiles,
 * virgule : 49.08 → « 49,08 » ; 2550 → « 2 550 ». Jamais pour un montant (`formatFcfa`).
 */
export function formatDecimal(value: number, maxDecimals = 2): string {
  const scale = 10 ** maxDecimals;
  const scaled = roundHalfAway(value * scale);
  const whole = Math.trunc(scaled / scale);
  const decimals = Math.abs(scaled % scale)
    .toString()
    .padStart(maxDecimals, "0")
    .replace(/0+$/, "");
  const sign = scaled < 0 && whole === 0 ? minusSign : "";
  return `${sign}${group(whole)}${decimals === "" ? "" : `,${decimals}`}`;
}

/** Taux : 18 → « 18 % » ; 5.5 → « 5,5 % ». */
export function formatPercent(percent: number): string {
  return `${formatDecimal(percent)}${unitSpace}%`;
}

/** Index de compteur, toujours au dixième : 18247 → « 18 247,0 kWh ». */
export function formatIndexKwh(kwh: number): string {
  return `${formatIndexValue(kwh)}${unitSpace}kWh`;
}

/** Index seul, au dixième : « 18 247,0 ». */
export function formatIndexValue(kwh: number): string {
  const tenths = roundHalfAway(kwh * 10);
  return `${group(Math.trunc(tenths / 10))},${Math.abs(tenths % 10)}`;
}

/** Sens d'une variation (la couleur en dépend : baisse = vert, hausse = orange). */
export type Trend = "down" | "flat" | "up";

/** Variation affichée : texte et sens. */
export type Variation = { text: string; trend: Trend };

/**
 * Variation en pourcentage, arrondie à l'entier : −12.4 → « −12 % » (baisse) ; 8 → « +8 % » ;
 * 0.3 → « 0 % » (stable). `decimals: 1` : 0.58 → « +0,6 % ».
 */
export function formatVariation(percent: number, decimals = 0): Variation {
  if (decimals > 0) {
    const text = formatDecimal(Math.abs(percent), decimals);
    if (text === "0") return { text: `0${unitSpace}%`, trend: "flat" };
    return percent < 0
      ? { text: `${minusSign}${text}${unitSpace}%`, trend: "down" }
      : { text: `+${text}${unitSpace}%`, trend: "up" };
  }
  const rounded = roundHalfAway(percent);
  if (rounded === 0) return { text: `0${unitSpace}%`, trend: "flat" };
  return rounded < 0
    ? { text: `${minusSign}${-rounded}${unitSpace}%`, trend: "down" }
    : { text: `+${rounded}${unitSpace}%`, trend: "up" };
}

/** Référence (facture, transaction, reçu, compteur) : majuscules, sans espaces autour. */
export function formatReference(reference: string): string {
  return reference.trim().toUpperCase();
}
