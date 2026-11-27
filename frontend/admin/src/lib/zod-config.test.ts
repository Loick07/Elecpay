// @vitest-environment node
import { expect, it, vi } from "vitest";
import { globalConfig } from "zod/v4/core";

import { loginSchema } from "@/lib/validation";

// La CSP stricte refuse `Function(…)` : Zod ne doit jamais compiler de code à la volée.
it("les règles de saisie chargent Zod sans compilation à la volée (aucun appel à Function)", () => {
  expect(globalConfig.jitless).toBe(true);
  const compile = vi.spyOn(globalThis, "Function");
  expect(loginSchema.safeParse({ phone: "06 123 45 67", password: "secret" }).success).toBe(true);
  expect(compile).not.toHaveBeenCalled();
});
