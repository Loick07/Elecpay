// @vitest-environment node
import { readFileSync } from "node:fs";

import { expect, it } from "vitest";

import { OPENAPI_JSON, SCHEMA_TS } from "./api-paths.ts";
import { generateApiTypes } from "./api-types-generator.ts";

it("les types de l’API sont à jour avec backend/openapi.json (sinon : npm run generate:api)", async () => {
  const generated = await generateApiTypes(readFileSync(OPENAPI_JSON, "utf8"));
  expect(readFileSync(SCHEMA_TS, "utf8")).toBe(generated);
});

it("le fichier contient les routes d’administration et les statuts du contrat", () => {
  const schema = readFileSync(SCHEMA_TS, "utf8");
  for (const route of ["/api/v1/admin/users", "/api/v1/auth/web/login", "/api/v1/health"]) {
    expect(schema).toContain(`"${route}"`);
  }
  expect(schema).toMatch(/BillStatus: "unpaid" \| "pending_payment"/);
});
