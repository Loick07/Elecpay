// Mêmes cas que `frontend/mobile/test/core/format/numbers_test.dart` : « 12 500 FCFA » doit être
// identique dans l'application et dans le back-office (DA0.5).
import { describe, expect, it } from "vitest";

import {
  formatAboutFcfa,
  formatApproxFcfa,
  formatApproxKwh,
  formatDecimal,
  formatFcfa,
  formatFcfaValue,
  formatIndexKwh,
  formatIndexValue,
  formatKwh,
  formatKwhValue,
  formatPercent,
  formatReference,
  formatVariation,
  formatWhAsKwh,
  roundHalfAway,
} from "./numbers";
import { groupSpace } from "./typography";

/** Rend les espaces insécables visibles (« · ») dans les attentes et les messages d'échec. */
const visible = (s: string) => s.replaceAll(groupSpace, "·");

describe("montants FCFA (entiers, jamais de centimes)", () => {
  it.each([
    [0, "0·FCFA"],
    [7, "7·FCFA"],
    [999, "999·FCFA"],
    [1000, "1·000·FCFA"],
    [31420, "31·420·FCFA"],
    [40384, "40·384·FCFA"],
    [1250000, "1·250·000·FCFA"],
    [9007199254740991, "9·007·199·254·740·991·FCFA"],
    [-5000, "−5·000·FCFA"],
  ])("%d → %s", (amount, expected) => {
    expect(visible(formatFcfa(amount))).toBe(expected);
  });

  it("le nombre seul (montant mis en avant, « FCFA » à part)", () => {
    expect(visible(formatFcfaValue(31420))).toBe("31·420");
  });

  it("l’unité ne se sépare jamais du nombre (aucune espace ordinaire)", () => {
    expect(formatFcfa(31420)).not.toContain(" ");
  });

  it("refuse un montant non entier (jamais de float pour de l’argent)", () => {
    expect(() => formatFcfa(12.5)).toThrow(/non entier/);
    expect(() => formatFcfa(Number.NaN)).toThrow(/non entier/);
  });
});

describe("énergie (une décimale au plus, virgule)", () => {
  it.each([
    [417.4, "417,4·kWh"],
    [12.0, "12·kWh"],
    [0, "0·kWh"],
    [0.04, "0·kWh"],
    [0.05, "0,1·kWh"],
    [321.45, "321,5·kWh"],
    [18664.4, "18·664,4·kWh"],
    [1234567.89, "1·234·567,9·kWh"],
    [-0.4, "−0,4·kWh"],
    [-12.3, "−12,3·kWh"],
  ])("%d → %s", (kwh, expected) => {
    expect(visible(formatKwh(kwh))).toBe(expected);
  });

  it("valeur sans unité (axes de graphique)", () => {
    expect(visible(formatKwhValue(417.4))).toBe("417,4");
  });

  it("énergie de l’API en Wh entiers (back-office)", () => {
    expect(visible(formatWhAsKwh(417400))).toBe("417,4·kWh");
    expect(visible(formatWhAsKwh(571000))).toBe("571·kWh");
  });
});

describe("variations (signe, %, sens)", () => {
  it.each([
    [-12, "−12·%", "down"],
    [-12.4, "−12·%", "down"],
    [-12.5, "−13·%", "down"],
    [8, "+8·%", "up"],
    [7.6, "+8·%", "up"],
    [0, "0·%", "flat"],
    [0.4, "0·%", "flat"],
    [-0.4, "0·%", "flat"],
    [150, "+150·%", "up"],
  ])("%d → %s (%s)", (percent, text, trend) => {
    const variation = formatVariation(percent);
    expect(visible(variation.text)).toBe(text);
    expect(variation.trend).toBe(trend);
  });

  it("une décimale (comparaison de deux factures)", () => {
    expect(visible(formatVariation(0.58, 1).text)).toBe("+0,6·%");
    expect(formatVariation(0.58, 1).trend).toBe("up");
    expect(visible(formatVariation(-2.46, 1).text)).toBe("−2,5·%");
    expect(formatVariation(0.02, 1).trend).toBe("flat");
    expect(visible(formatVariation(0.58).text)).toBe("+1·%");
  });
});

it("références : majuscules, sans espaces autour", () => {
  expect(formatReference(" ep-2026-000123 ")).toBe("EP-2026-000123");
  expect(formatReference("20261103000127")).toBe("20261103000127");
});

it("estimations : « ≈ 206 kWh », « ≈ 10 100 FCFA » (arrondis honnêtes)", () => {
  expect(visible(formatApproxKwh(206.3))).toBe("≈·206·kWh");
  expect(visible(formatApproxKwh(1206.6))).toBe("≈·1·207·kWh");
  expect(visible(formatApproxFcfa(10112))).toBe("≈·10·100·FCFA");
  expect(visible(formatApproxFcfa(10150))).toBe("≈·10·200·FCFA");
  expect(visible(formatApproxFcfa(40))).toBe("≈·0·FCFA");
  expect(visible(formatAboutFcfa(441))).toBe("≈·441·FCFA");
  expect(visible(formatAboutFcfa(10112))).toBe("≈·10·112·FCFA");
});

it("nombres décimaux d’affichage, pourcentages et index", () => {
  expect(visible(formatDecimal(49.08))).toBe("49,08");
  expect(visible(formatDecimal(2550.0))).toBe("2·550");
  expect(visible(formatDecimal(417.4))).toBe("417,4");
  expect(visible(formatDecimal(0.005))).toBe("0,01");
  expect(visible(formatDecimal(12.3456, 3))).toBe("12,346");
  expect(visible(formatPercent(18.0))).toBe("18·%");
  expect(visible(formatPercent(5))).toBe("5·%");
  expect(visible(formatPercent(5.5))).toBe("5,5·%");
  expect(visible(formatIndexKwh(18247.0))).toBe("18·247,0·kWh");
  expect(visible(formatIndexKwh(18664.44))).toBe("18·664,4·kWh");
  expect(visible(formatIndexValue(18247))).toBe("18·247,0");
});

it("arrondi comme Dart : les demis s’éloignent de zéro", () => {
  expect(roundHalfAway(2.5)).toBe(3);
  expect(roundHalfAway(-2.5)).toBe(-3);
  expect(roundHalfAway(-2.4)).toBe(-2);
});
