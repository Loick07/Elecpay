import { describe, expect, it } from "vitest";

import { loginUrl, safeReturnPath } from "./return-path";

describe("retour après connexion : chemins internes seulement", () => {
  it.each([
    ["/utilisateurs", "/utilisateurs"],
    ["/factures/42?statut=unpaid#lignes", "/factures/42?statut=unpaid#lignes"],
    ["/mon-compte", "/mon-compte"],
  ])("« %s » gardé", (raw, expected) => {
    expect(safeReturnPath(raw)).toBe(expected);
  });

  it.each([
    null,
    undefined,
    "",
    "utilisateurs",
    "//pirate.example/vol",
    "https://pirate.example",
    "/\\pirate.example",
    "javascript:alert(1)",
    "/connexion",
    "/connexion?retour=/x",
    "/mot-de-passe-oublie",
  ])("« %s » → accueil", (raw) => {
    expect(safeReturnPath(raw)).toBe("/");
  });
});

it("adresse de la page de connexion", () => {
  expect(loginUrl("/mon-compte", "session")).toBe("/connexion?retour=%2Fmon-compte&raison=session");
  expect(loginUrl("https://pirate.example", "session")).toBe("/connexion?raison=session");
  expect(loginUrl(null)).toBe("/connexion");
});
