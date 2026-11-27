// @vitest-environment node
// Garde-fou de playwright.config.ts : sans ELECPAY_E2E_DATABASE=elecpay_admin_e2e (posé par
// tool/e2e.ps1 et le job e2e de la CI), aucun test de bout en bout ne démarre.
import { afterEach, expect, it, vi } from "vitest";

const saved = process.env.ELECPAY_E2E_DATABASE;

afterEach(() => {
  if (saved === undefined) delete process.env.ELECPAY_E2E_DATABASE;
  else process.env.ELECPAY_E2E_DATABASE = saved;
  vi.resetModules();
});

it.each([undefined, "", "elecpay_admin_dev", "elecpay", "elecpay_public", "elecpay_e2e"])(
  "base « %s » : refusée",
  async (database) => {
    if (database === undefined) delete process.env.ELECPAY_E2E_DATABASE;
    else process.env.ELECPAY_E2E_DATABASE = database;
    await expect(import("../playwright.config")).rejects.toThrow(
      "Tests de bout en bout refusés : ils tournent uniquement sur la base elecpay_admin_e2e",
    );
  },
);

it("base elecpay_admin_e2e : back-office construit sur le port 3010, un seul navigateur", async () => {
  process.env.ELECPAY_E2E_DATABASE = "elecpay_admin_e2e";
  const { default: config } = await import("../playwright.config");
  expect(config.use?.baseURL).toBe("http://127.0.0.1:3010");
  expect(config.workers).toBe(1);
});
