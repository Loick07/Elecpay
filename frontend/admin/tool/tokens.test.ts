// @vitest-environment node
import { readFileSync } from "node:fs";

import { describe, expect, it } from "vitest";

import { generateTokensCss, generateTokensTs } from "./tokens-generator.ts";
import { DESIGN_TOKENS_CSS, GENERATED_CSS, GENERATED_TS, TOKENS_JSON } from "./tokens-paths.ts";

const tokensJson = readFileSync(TOKENS_JSON, "utf8");
const generated = generateTokensCss(tokensJson);

/** Variables `--nom: valeur;` d'un bloc CSS dont le sélecteur commence par `selector`. */
function variables(css: string, selector: string): Map<string, string> {
  const start = css.indexOf(selector);
  const block = css.slice(css.indexOf("{", start) + 1, css.indexOf("}", start));
  return new Map(
    [...block.matchAll(/--([\w-]+):\s*([^;]+);/g)].map((m) => [m[1] ?? "", (m[2] ?? "").trim()]),
  );
}

describe("thème généré depuis la charte (tokens.json)", () => {
  it("les fichiers générés sont à jour (sinon : npm run generate:tokens)", () => {
    expect(readFileSync(GENERATED_CSS, "utf8")).toBe(generated);
    expect(readFileSync(GENERATED_TS, "utf8")).toBe(generateTokensTs(tokensJson));
  });

  it("noms du thème pour tailwind-merge : styles de texte, ombres, flous de la charte", () => {
    const ts = generateTokensTs(tokensJson);
    expect(ts).toContain('"admin-body",');
    expect(ts).toContain('"reference",');
    expect(ts).toContain('"card",');
    expect(ts).toContain('"glass",');
  });

  it("mêmes couleurs que frontend/design/tokens.css, dans les deux thèmes", () => {
    const design = readFileSync(DESIGN_TOKENS_CSS, "utf8");
    for (const [ours, theirs] of [
      [':root,\n[data-theme="light"]', '[data-theme="light"]'],
      ['[data-theme="dark"]', ':root, [data-theme="dark"]'],
    ] as const) {
      const mine = variables(generated, ours);
      const reference = variables(design, theirs);
      const colors = [...reference].filter(([name]) => !name.startsWith("shadow-"));
      expect(colors.length).toBeGreaterThan(25);
      for (const [name, value] of colors) {
        expect(mine.get(name), `--${name}`).toBe(value);
      }
      for (const [name, value] of reference) {
        if (name.startsWith("shadow-")) expect(mine.get(`ep-${name}`), `--${name}`).toBe(value);
      }
    }
  });

  it("le thème Jour est celui par défaut (:root)", () => {
    expect(generated).toContain(':root,\n[data-theme="light"] {\n  color-scheme: light;');
  });

  it("Tailwind ne garde que les valeurs de la charte", () => {
    for (const namespace of ["color", "text", "radius", "shadow", "font"]) {
      expect(generated).toContain(`--${namespace}-*: initial;`);
    }
    expect(generated).toContain("--color-volt: var(--volt);");
    expect(generated).toContain("--color-current-base: var(--current);");
    expect(generated).not.toContain("--color-current:");
    expect(generated).toContain("--text-admin-table: 13px;");
    expect(generated).toContain("--text-admin-kpi--letter-spacing: -0.01em;");
    expect(generated).toContain("--font-sans: var(--font-inter), ");
    expect(generated).toContain("--font-mono: var(--font-jetbrains-mono), ");
  });

  it("refuse une charte dont les espacements ne suivent plus 4 px × n", () => {
    const broken = JSON.parse(tokensJson) as { spacing: { tokens: { value: string }[] } };
    const first = broken.spacing.tokens[0];
    if (first) first.value = "5px";
    expect(() => generateTokensCss(JSON.stringify(broken))).toThrow(/échelle de 4 px/);
  });
});
