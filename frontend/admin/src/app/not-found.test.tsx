import { render, screen } from "@testing-library/react";
import { expect, it } from "vitest";

import NotFound from "./not-found";

it("page introuvable : titre, lien vers l'accueil, aucune balise <style> (CSP)", () => {
  const { container } = render(<NotFound />);
  expect(screen.getByRole("heading", { level: 1, name: "Page introuvable" })).toBeVisible();
  expect(screen.getByRole("link", { name: "Retour à l’accueil" })).toHaveAttribute("href", "/");
  expect(container.querySelector("style")).toBeNull();
});
