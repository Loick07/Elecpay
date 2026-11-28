// @vitest-environment node
import { describe, expect, it } from "vitest";

import { filenameFrom } from "./api/download";
import { nextQuery, readListParams } from "./list-params";
import { REASON_LIMITS, reasonField } from "./validation";

describe("page et filtres dans l’adresse", () => {
  it("lecture : page ≥ 1 (1 si absente ou illisible), filtres vides par défaut", () => {
    expect(readListParams(new URLSearchParams("page=3&q=Ngoma"), ["q", "kind"])).toEqual({
      page: 3,
      filters: { q: "Ngoma", kind: "" },
    });
    for (const raw of ["", "page=0", "page=-2", "page=abc"]) {
      expect(readListParams(new URLSearchParams(raw), []).page).toBe(1);
    }
  });

  it("un filtre qui change ramène à la page 1 ; filtres vides et page 1 non écrits", () => {
    const current = new URLSearchParams("page=4&q=Ngoma&kind=client");
    expect(nextQuery(current, { kind: "team" })).toBe("q=Ngoma&kind=team");
    expect(nextQuery(current, { q: "" })).toBe("kind=client");
    expect(nextQuery(current, { page: 5 })).toBe("page=5&q=Ngoma&kind=client");
    expect(nextQuery(current, { page: 1 })).toBe("q=Ngoma&kind=client");
    expect(nextQuery(new URLSearchParams(), { kind: null })).toBe("");
  });
});

describe("nom du fichier exporté (Content-Disposition)", () => {
  it.each([
    ['attachment; filename="utilisateurs.csv"', "utilisateurs.csv"],
    ["attachment; filename=factures.csv", "factures.csv"],
    ["attachment; filename*=UTF-8''factures-d%C3%A9c.csv", "factures-déc.csv"],
    ["attachment", null],
    [null, null],
  ])("%s → %s", (header, expected) => {
    expect(filenameFrom(header)).toBe(expected);
  });
});

describe("motif d’une action sensible", () => {
  const long = reasonField(REASON_LIMITS.long.min, REASON_LIMITS.long.max);
  const message = (raw: string) => long.safeParse(raw).error?.issues[0]?.message ?? null;

  it("espaces superflus retirés, longueur en caractères", () => {
    expect(long.parse("  Index   de fin  erroné ")).toBe("Index de fin erroné");
    expect(message("éééééééééé")).toBeNull();
  });

  it.each([
    ["   ", "Indiquez le motif."],
    ["Erreur", "Motif trop court : 10 caractères minimum."],
    ["x".repeat(256), "Motif trop long : 255 caractères maximum."],
  ])("« %s » → %s", (raw, expected) => {
    expect(message(raw)).toBe(expected);
  });

  it("motifs courts (désactiver un compte…) : 5 caractères", () => {
    const short = reasonField(REASON_LIMITS.short.min, REASON_LIMITS.short.max);
    expect(short.safeParse("Fraude").success).toBe(true);
    expect(short.safeParse("Abus").success).toBe(false);
  });
});
