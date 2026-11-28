// Accessibilité des composants (axe, mêmes règles WCAG 2.1 A et AA que les parcours de bout en
// bout). Le contraste des couleurs n'est pas calculable dans jsdom (aucun rendu) : il est vérifié
// par les parcours (vrai navigateur) et par les tests de contraste depuis les jetons.
import axe from "axe-core";

export async function axeViolations(container: Element): Promise<string[]> {
  const results = await axe.run(container, {
    runOnly: { type: "tag", values: ["wcag2a", "wcag2aa", "wcag21a", "wcag21aa"] },
    rules: { "color-contrast": { enabled: false } },
  });
  return results.violations.map(
    (violation) =>
      `${violation.id} : ${violation.help} (${violation.nodes
        .map((node) => node.target.join(" "))
        .join(", ")})`,
  );
}
