// Mêmes cas que `frontend/mobile/test/core/format/phone_test.dart` (messages du backend).
import { describe, expect, it } from "vitest";

import { formatPhone, normalizeCongoPhone, PhoneFormatError, phoneError } from "./phone";
import { unitSpace } from "./typography";

const WRONG_LENGTH = "Numéro invalide : 9 chiffres attendus (ex. 06 123 45 67)";

describe("saisie libre → +242XXXXXXXXX (comme l’API)", () => {
  it.each([
    "06 123 45 67",
    "061234567",
    "06.123.45.67",
    "06-123-45-67",
    "(06) 123 45 67",
    "06/123/45/67",
    "+242 06 123 45 67",
    "+242061234567",
    "00242061234567",
    "242061234567",
    "  06 123 45 67  ",
  ])("« %s »", (input) => {
    expect(normalizeCongoPhone(input)).toBe("+242061234567");
  });

  it("les 4 préfixes acceptés : 04, 05, 06, 22", () => {
    for (const prefix of ["04", "05", "06", "22"]) {
      expect(normalizeCongoPhone(`${prefix}1234567`)).toBe(`+242${prefix}1234567`);
    }
  });
});

describe("saisies refusées, avec le message du backend", () => {
  it.each([
    ["", WRONG_LENGTH],
    ["   ", WRONG_LENGTH],
    ["+", WRONG_LENGTH],
    ["06123456", WRONG_LENGTH],
    ["0612345678", WRONG_LENGTH],
    ["243061234567", WRONG_LENGTH],
    ["06 12a 45 67", "Numéro invalide : seuls les chiffres, espaces et « + » sont acceptés"],
    ["071234567", "Numéro invalide : il doit commencer par 04, 05, 06 ou 22"],
    ["+242 01 234 56 78", "Numéro invalide : il doit commencer par 04, 05, 06 ou 22"],
  ])("« %s »", (input, message) => {
    expect(() => normalizeCongoPhone(input)).toThrow(PhoneFormatError);
    expect(() => normalizeCongoPhone(input)).toThrow(message);
    expect(phoneError(input)).toBe(message);
  });

  it("saisie valide : aucun message", () => {
    expect(phoneError("06 123 45 67")).toBeNull();
  });
});

describe("affichage", () => {
  it("« +242 06 123 45 67 », avec des espaces insécables (jamais coupé)", () => {
    const shown = formatPhone("+242061234567");
    expect(shown.replaceAll(unitSpace, " ")).toBe("+242 06 123 45 67");
    expect(shown).not.toContain(" ");
  });

  it("numéro déjà masqué par l’API : rendu tel quel", () => {
    expect(formatPhone("+242 06 *** ** 67")).toBe("+242 06 *** ** 67");
  });
});
