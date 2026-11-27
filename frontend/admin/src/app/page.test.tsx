import { screen } from "@testing-library/react";
import { http, HttpResponse } from "msw";
import { describe, expect, it } from "vitest";

import { server, TEST_ORIGIN } from "@/test/msw-server";
import { renderWithProviders } from "@/test/render";

import HomePage from "./page";

describe("page provisoire", () => {
  it("affiche le titre du back-office et le badge « Mode démo » lu dans /health", async () => {
    server.use(
      http.get(`${TEST_ORIGIN}/api/v1/health`, () =>
        HttpResponse.json({ status: "ok", database: "ok", demo_mode: true }),
      ),
    );
    renderWithProviders(<HomePage />);
    expect(screen.getByRole("heading", { level: 1, name: "Back-office ElecPay" })).toBeVisible();
    expect(await screen.findByText("Mode démo")).toBeVisible();
  });
});
