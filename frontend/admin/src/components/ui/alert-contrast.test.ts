// @vitest-environment node
// Contraste des alertes ET des badges de statut (WCAG AA : 4,5:1 pour le texte courant), calculé
// depuis les jetons générés de la charte : texte du ton et références (`ink-muted`) sur la teinte
// douce posée sur `surface-1` (base opaque de <Alert> et de <StatusBadge>), dans les deux thèmes.
import { readFileSync } from "node:fs";

import { describe, expect, it } from "vitest";

const css = readFileSync(new URL("../../styles/tokens.generated.css", import.meta.url), "utf8");

function theme(name: "light" | "dark"): Map<string, string> {
  const pattern = String.raw`\[data-theme="${name}"\][^{]*\{([^}]*)\}`;
  const block = new RegExp(pattern).exec(css)?.[1] ?? "";
  return new Map(
    [...block.matchAll(/--([\w-]+):\s*([^;]+);/g)].map(([, key, value]) => [
      key ?? "",
      (value ?? "").trim(),
    ]),
  );
}

type Rgb = [number, number, number];

function parse(color: string): { rgb: Rgb; alpha: number } {
  const hex = /^#([0-9a-f]{6})$/i.exec(color)?.[1];
  if (hex) {
    const n = Number.parseInt(hex, 16);
    return { rgb: [(n >> 16) & 255, (n >> 8) & 255, n & 255], alpha: 1 };
  }
  const rgba = /^rgba\((\d+),\s*(\d+),\s*(\d+),\s*([\d.]+)\)$/.exec(color);
  if (!rgba) throw new Error(`Couleur illisible : ${color}`);
  return { rgb: [Number(rgba[1]), Number(rgba[2]), Number(rgba[3])], alpha: Number(rgba[4]) };
}

function over(top: string, base: Rgb): Rgb {
  const { rgb, alpha } = parse(top);
  return rgb.map((channel, i) => alpha * channel + (1 - alpha) * (base[i] ?? 0)) as Rgb;
}

function luminance([r, g, b]: Rgb): number {
  const linear = (c: number) => {
    const v = c / 255;
    return v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4;
  };
  return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b);
}

function contrast(a: Rgb, b: Rgb): number {
  const [light, dark] = [luminance(a), luminance(b)].sort((x, y) => y - x);
  return ((light ?? 0) + 0.05) / ((dark ?? 0) + 0.05);
}

const TONES = [
  ["error", "error-soft", "error-text"],
  ["warning", "warning-soft", "warning-text"],
  ["success", "success-soft", "success-text"],
  ["info", "current-soft", "current-text"],
] as const;

describe.each(["light", "dark"] as const)("thème %s", (name) => {
  const tokens = theme(name);
  const value = (key: string) => {
    const found = tokens.get(key);
    if (!found) throw new Error(`Jeton --${key} absent du thème ${name}`);
    return found;
  };
  const surface = parse(value("surface-1")).rgb;

  it("le bon bloc de jetons est lu (fond de la charte)", () => {
    expect(value("bg")).toBe(name === "light" ? "#F3F6FA" : "#050D1A");
  });

  it.each(TONES)("%s : texte et référence lisibles (≥ 4,5:1)", (_tone, soft, text) => {
    const background = over(value(soft), surface);
    expect(contrast(parse(value(text)).rgb, background)).toBeGreaterThanOrEqual(4.5);
    expect(contrast(parse(value("ink-muted")).rgb, background)).toBeGreaterThanOrEqual(4.5);
  });

  it("badge de statut neutre (« Annulée », « Expirée ») : `ink-muted` sur `surface-3`", () => {
    const background = parse(value("surface-3")).rgb;
    expect(contrast(parse(value("ink-muted")).rgb, background)).toBeGreaterThanOrEqual(4.5);
  });
});

it("contre-épreuve : le bleu d'information directement sur le fond de page (avant) échouait", () => {
  const tokens = theme("light");
  const page = parse(tokens.get("bg") ?? "").rgb;
  const background = over(tokens.get("current-soft") ?? "", page);
  expect(contrast(parse(tokens.get("current-text") ?? "").rgb, background)).toBeLessThan(4.5);
});
