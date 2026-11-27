// @vitest-environment node
import { describe, expect, it } from "vitest";

import {
  forbiddenInBundle,
  FORBIDDEN_IN_BROWSER,
  publicVariables,
  secretValues,
} from "./bundle-rules.ts";

describe("rien de sensible dans le code du navigateur", () => {
  it("trouve un secret de démo ou une adresse du serveur dans un fichier envoyé", () => {
    const findings = forbiddenInBundle(
      [
        { path: "a.js", content: 'login({password:"Demo2026!"})' },
        { path: "b.js", content: 'fetch("https://omnivore-pardon-sixth.ngrok-free.dev/api/v1")' },
        { path: "c.js", content: "rien à signaler" },
      ],
      FORBIDDEN_IN_BROWSER,
    );
    expect(findings).toEqual([
      { path: "a.js", problem: "contient « Demo2026! »" },
      { path: "b.js", problem: "contient « ngrok-free.dev »" },
    ]);
  });

  it("cherche aussi la VALEUR des variables secrètes du serveur, sans le protocole", () => {
    expect(
      secretValues({
        ELECPAY_API_URL: "https://api-sentinelle.invalid",
        ELECPAY_PROXY_SECRET: "s3cr3t-tres-long",
        AUTRE: "x",
      }),
    ).toEqual(["api-sentinelle.invalid", "s3cr3t-tres-long"]);
    expect(secretValues({ ELECPAY_PROXY_SECRET: "court" })).toEqual([]);
    expect(secretValues({})).toEqual([]);
  });

  it("refuse toute variable NEXT_PUBLIC_ non autorisée (aucune ne l’est)", () => {
    expect(
      publicVariables([
        { path: "src/x.ts", content: "process.env.NEXT_PUBLIC_API_URL" },
        { path: "src/y.ts", content: "process.env.ELECPAY_API_URL" },
      ]),
    ).toEqual([
      { path: "src/x.ts", problem: "variable publique « NEXT_PUBLIC_API_URL » non autorisée" },
    ]);
    expect(
      publicVariables([{ path: "src/x.ts", content: "NEXT_PUBLIC_OK" }], ["NEXT_PUBLIC_OK"]),
    ).toEqual([]);
    // Le préfixe seul, dans un commentaire (« jamais `NEXT_PUBLIC_` »), n'est pas une variable.
    expect(
      publicVariables([{ path: "src/z.ts", content: "// jamais `NEXT_PUBLIC_` ici" }]),
    ).toEqual([]);
  });
});
