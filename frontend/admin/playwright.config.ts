// Tests de bout en bout (Playwright) : le back-office CONSTRUIT (`next start`, port 3010) relié à
// l'API de TEST (port 8010, base `elecpay_admin_e2e` supprimée et recréée à chaque passage,
// jetons d'accès d'une minute). Toujours lancés par `tool/e2e.ps1` (en local) ou par le job `e2e`
// de la CI, qui préparent la base et les deux serveurs : jamais `npx playwright test` seul.
//
// Garde-fou : sans ELECPAY_E2E_DATABASE=elecpay_admin_e2e (posé par ces deux lanceurs), aucun test
// ne démarre. Les tests changent des mots de passe et calculent les codes de double
// authentification depuis le secret de démo PUBLIC : jamais sur une autre base.
import { defineConfig, devices } from "@playwright/test";

const E2E_DATABASE = "elecpay_admin_e2e";
if (process.env.ELECPAY_E2E_DATABASE !== E2E_DATABASE) {
  throw new Error(
    `Tests de bout en bout refusés : ils tournent uniquement sur la base ${E2E_DATABASE}, préparée ` +
      "par .\\tool\\e2e.ps1 (ou le job e2e de la CI).",
  );
}

export default defineConfig({
  testDir: "./e2e",
  // Un seul navigateur à la fois : les comptes de démo sont partagés (limites de tentatives,
  // codes de double authentification à usage unique).
  workers: 1,
  fullyParallel: false,
  retries: 0,
  forbidOnly: Boolean(process.env.CI),
  timeout: 120_000,
  expect: { timeout: 15_000 },
  outputDir: "build/e2e/resultats",
  reporter: [["list"], ["html", { outputFolder: "build/e2e/rapport", open: "never" }]],
  use: {
    baseURL: "http://127.0.0.1:3010",
    locale: "fr-FR",
    timezoneId: "Africa/Brazzaville",
    viewport: { width: 1440, height: 900 },
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
  },
  projects: [
    {
      name: "chromium",
      use: {
        ...devices["Desktop Chrome"],
        viewport: { width: 1440, height: 900 },
        // En local : Edge (Chromium) déjà installé sur le PC, aucun navigateur téléchargé hors du
        // dépôt. Dans la CI : le Chromium de Playwright.
        channel: process.env.CI ? undefined : "msedge",
      },
    },
  ],
});
