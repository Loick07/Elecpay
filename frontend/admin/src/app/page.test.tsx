import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import HomePage from "./page";

describe("page provisoire", () => {
  it("affiche le titre du back-office", () => {
    render(<HomePage />);
    expect(screen.getByRole("heading", { level: 1, name: "Back-office ElecPay" })).toBeVisible();
  });
});
