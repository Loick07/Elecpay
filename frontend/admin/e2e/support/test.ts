// `test` de Playwright avec deux contrôles AUTOMATIQUES sur chaque page de chaque test :
// - aucune violation de la CSP (le serveur de production l'applique, nonce compris) ;
// - aucune erreur JavaScript (`pageerror`).
// Et `expectAccessible(page)` : axe (WCAG 2.1 A et AA), aucune violation acceptée.
import AxeBuilder from "@axe-core/playwright";
import { test as base, expect, type Page } from "@playwright/test";

type Guards = { pageGuards: void };

export const test = base.extend<Guards>({
  pageGuards: [
    async ({ context }, use) => {
      const problems: string[] = [];
      await context.addInitScript(() => {
        document.addEventListener("securitypolicyviolation", (event) => {
          console.error(
            `CSP-VIOLATION ${event.violatedDirective} ${location.pathname} ${event.sourceFile}:${event.lineNumber}`,
          );
        });
      });
      context.on("page", (page) => watch(page, problems));
      for (const page of context.pages()) watch(page, problems);
      await use();
      expect(problems, "violations de la CSP ou erreurs JavaScript").toEqual([]);
    },
    { auto: true },
  ],
});

function watch(page: Page, problems: string[]): void {
  page.on("console", (message) => {
    if (message.type() === "error" && message.text().startsWith("CSP-VIOLATION")) {
      problems.push(message.text());
    }
  });
  page.on("pageerror", (error) => problems.push(`pageerror : ${error.message}`));
}

/** Accessibilité de la page affichée (axe, WCAG 2.1 A et AA). */
export async function expectAccessible(page: Page): Promise<void> {
  const results = await new AxeBuilder({ page })
    .withTags(["wcag2a", "wcag2aa", "wcag21a", "wcag21aa"])
    .analyze();
  const violations = results.violations.map(
    (violation) =>
      `${violation.id} (${violation.impact}) : ${violation.help} — ${violation.nodes
        .map((node) => node.target.join(" "))
        .join(", ")}`,
  );
  expect(violations, `accessibilité de ${new URL(page.url()).pathname}`).toEqual([]);
}

export { expect };
