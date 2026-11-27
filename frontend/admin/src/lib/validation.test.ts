import { describe, expect, it } from "vitest";

import {
  loginSchema,
  newPasswordField,
  passwordError,
  phoneField,
  smsCodeField,
  twoFactorCodeField,
} from "./validation";

const message = (result: { success: boolean; error?: { issues: { message: string }[] } }) =>
  result.success ? null : (result.error?.issues[0]?.message ?? null);

describe("mot de passe : règles et messages du backend", () => {
  it.each([
    ["court1", "Mot de passe trop court : 8 caractères minimum"],
    ["a1".repeat(65), "Mot de passe trop long : 128 caractères maximum"],
    ["sanschiffre", "Le mot de passe doit contenir au moins un chiffre"],
    ["12345678", "Le mot de passe doit contenir au moins une lettre"],
    [" espace123", "Le mot de passe ne doit pas commencer ni finir par un espace"],
    ["Électricité2026", null],
    ["Demo2026!", null],
  ])("« %s » → %s", (password, expected) => {
    expect(passwordError(password)).toBe(expected);
    expect(message(newPasswordField.safeParse(password))).toBe(expected);
  });
});

describe("téléphone : normalisé comme l’API", () => {
  it("« 06 123 45 67 » → +242061234567", () => {
    expect(phoneField.parse(" 06 123 45 67 ")).toBe("+242061234567");
  });

  it("vide, puis invalide : messages clairs", () => {
    expect(message(phoneField.safeParse("  "))).toBe("Saisissez votre numéro de téléphone.");
    expect(message(phoneField.safeParse("071234567"))).toBe(
      "Numéro invalide : il doit commencer par 04, 05, 06 ou 22",
    );
  });
});

describe("code de double authentification", () => {
  it.each([
    ["123456", "123456"],
    [" 123 456 ", "123456"],
    ["abcd-efgh", "ABCD-EFGH"],
    ["ABCDEFGH", "ABCD-EFGH"],
    ["ab12 cd34", "AB12-CD34"],
  ])("« %s » → « %s »", (raw, expected) => {
    expect(twoFactorCodeField.parse(raw)).toBe(expected);
  });

  it.each([
    ["", "Saisissez le code à 6 chiffres de votre application d’authentification."],
    ["12345", "Code invalide : 6 chiffres, ou un code de secours du type ABCD-EFGH."],
    ["ABC-DEFGH", "Code invalide : 6 chiffres, ou un code de secours du type ABCD-EFGH."],
  ])("« %s » refusé", (raw, expected) => {
    expect(message(twoFactorCodeField.safeParse(raw))).toBe(expected);
  });
});

it("code SMS : 6 chiffres", () => {
  expect(smsCodeField.parse("12 34 56")).toBe("123456");
  expect(message(smsCodeField.safeParse("12345"))).toBe("Le code reçu par SMS a 6 chiffres.");
});

it("connexion : numéro et mot de passe requis", () => {
  const result = loginSchema.safeParse({ phone: "", password: "" });
  expect(result.success).toBe(false);
  expect(result.error?.issues.map((issue) => issue.message)).toEqual([
    "Saisissez votre numéro de téléphone.",
    "Saisissez votre mot de passe.",
  ]);
  expect(loginSchema.parse({ phone: "060000002", password: "x" })).toEqual({
    phone: "+242060000002",
    password: "x",
  });
});
