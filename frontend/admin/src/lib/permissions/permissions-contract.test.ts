// @vitest-environment node
// Garde-fou contre le backend (`backend/app/modules/admin/permissions.py`, lecture seule) :
// - les capacités connues du back-office sont EXACTEMENT celles du backend, dans le même ordre ;
// - la matrice des tests (`permissionsFor`, src/test/api.ts) est celle du backend, rôle par rôle.
// Si le backend change sa matrice, ce test échoue tant que le back-office n'est pas mis à jour
// (la CI Admin se relance quand ce fichier change).
import { readFileSync } from "node:fs";

import { describe, expect, it } from "vitest";

import { permissionsFor } from "@/test/api";

import { CAPABILITIES } from "./permissions";

const SOURCE = readFileSync(
  new URL("../../../../../backend/app/modules/admin/permissions.py", import.meta.url),
  "utf8",
);

type Role = "support" | "admin" | "super_admin";
const TEAM: readonly Role[] = ["support", "admin", "super_admin"];

/** `ROLES` du backend : niveau → rôles. */
function backendLevels(): Map<string, Role[]> {
  const levels = new Map<string, Role[]>();
  for (const [, level, roles] of SOURCE.matchAll(/Permission\.(\w+): frozenset\(\{([^}]*)\}\)/g)) {
    const names = [...(roles ?? "").matchAll(/UserRole\.(\w+)/g)].map(
      ([, role]) => (role ?? "").toLowerCase() as Role,
    );
    levels.set(level ?? "", names);
  }
  return levels;
}

/** `CAPABILITIES` du backend : clé → niveau (ou `None` : jamais). */
function backendCapabilities(): [string, string][] {
  return [
    ...SOURCE.matchAll(/Capability\(\s*"(\w+)",\s*"[^"]*",\s*(?:Permission\.(\w+)|(None))\s*\)/g),
  ].map(([, key, level, never]) => [key ?? "", level ?? never ?? ""]);
}

describe("droits du back-office contre le backend", () => {
  it("la lecture du backend a fonctionné (garde du garde-fou)", () => {
    expect(backendLevels().get("STAFF")).toEqual(["support", "admin", "super_admin"]);
    expect(backendCapabilities().length).toBeGreaterThanOrEqual(9);
  });

  it("mêmes capacités, même ordre", () => {
    expect(backendCapabilities().map(([key]) => key)).toEqual([...CAPABILITIES]);
  });

  it.each(TEAM)("matrice des tests identique à celle du backend : %s", (role) => {
    const levels = backendLevels();
    const expected = backendCapabilities().map(([key, level]) => [
      key,
      level !== "None" && (levels.get(level) ?? []).includes(role),
    ]);
    const fixture = permissionsFor(role).capabilities.map((entry) => [entry.key, entry.allowed]);
    expect(fixture).toEqual(expected);
    expect(permissionsFor(role).levels).toEqual(
      ["STAFF", "ADMIN", "SUPER_ADMIN"]
        .filter((level) => (levels.get(level) ?? []).includes(role))
        .map((level) => level.toLowerCase()),
    );
  });
});
