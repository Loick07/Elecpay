// Captures d'écran pour le rapport de l'étape (build/e2e/captures/, jamais commitées : /build/ est
// ignoré). Celles retenues sont copiées à la main dans rapports/captures/.
import type { Page } from "@playwright/test";

/** Page entière ; `screen` : l'écran seul (une fenêtre ouverte : son voile couvre l'écran, pas la page). */
export async function capture(
  page: Page,
  name: string,
  area: "page" | "screen" = "page",
): Promise<void> {
  await page.screenshot({ path: `build/e2e/captures/${name}.png`, fullPage: area === "page" });
}
