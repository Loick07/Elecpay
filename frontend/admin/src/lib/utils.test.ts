import { expect, it } from "vitest";

import { cn } from "./utils";

it("une taille de la charte et une couleur coexistent (aucune n’efface l’autre)", () => {
  expect(cn("text-admin-body text-ink")).toBe("text-admin-body text-ink");
  expect(cn("text-reference text-error-text")).toBe("text-reference text-error-text");
});

it("deux tailles, deux couleurs, deux ombres : la dernière l’emporte", () => {
  expect(cn("text-admin-body", "text-admin-h1")).toBe("text-admin-h1");
  expect(cn("text-ink", "text-ink-muted")).toBe("text-ink-muted");
  expect(cn("shadow-card", "shadow-float")).toBe("shadow-float");
});

it("classes conditionnelles", () => {
  const disabled = false;
  expect(cn("rounded-md", disabled && "opacity-45", { "bg-volt": true })).toBe(
    "rounded-md bg-volt",
  );
});
