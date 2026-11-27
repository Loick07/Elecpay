// Contrôle dans un VRAI navigateur (Edge du PC, piloté par Playwright) : la page s'affiche, ses
// scripts tournent malgré la CSP stricte, le badge « Mode démo » arrive de /health à travers le
// relais ; aucune erreur dans la console ; capture à 1440 × 900 pour le rapport.
//   node tool/smoke-browser.ts <adresse> <capture.png>
// (Les vrais parcours de bout en bout arrivent en A1.5, avec la base elecpay_admin_e2e.)
import { chromium } from "@playwright/test";

const [url = "http://localhost:3010/", capture] = process.argv.slice(2);
const problems: string[] = [];

const browser = await chromium.launch({ channel: "msedge" });
try {
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  page.on("console", (message) => {
    if (message.type() === "error") problems.push(`console : ${message.text()}`);
  });
  page.on("pageerror", (error) => problems.push(`erreur de la page : ${error.message}`));
  await page.goto(url);
  await page.getByText("Mode démo").waitFor({ timeout: 20_000 });
  await page.getByText("API ElecPay : disponible").waitFor({ timeout: 5_000 });
  if (capture) await page.screenshot({ path: capture });
} catch (error) {
  problems.push(error instanceof Error ? error.message : String(error));
} finally {
  await browser.close();
}

if (problems.length > 0) {
  console.error(`Navigateur : ${problems.length} problème(s)\n- ${problems.join("\n- ")}`);
  process.exit(1);
}
console.warn("Navigateur : page affichée, badge « Mode démo » présent, console sans erreur.");
