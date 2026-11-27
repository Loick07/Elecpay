import { screen } from "@testing-library/react";
import { http, HttpResponse } from "msw";
import { describe, expect, it, vi } from "vitest";

import { SessionGate } from "@/features/session/session-gate";
import { apiUrl, healthHandler, teamMember } from "@/test/api";
import { server } from "@/test/msw-server";
import { renderWithProviders } from "@/test/render";

import HomePage from "./page";

vi.mock("next/navigation", () => ({
  useRouter: () => ({ replace: vi.fn(), push: vi.fn() }),
  usePathname: () => "/",
  useSearchParams: () => new URLSearchParams(),
}));

describe("accueil provisoire de l’équipe", () => {
  it("salue le membre connecté, avec le badge « Mode démo » lu dans /health", async () => {
    server.use(
      healthHandler(),
      http.get(apiUrl("/me"), () => HttpResponse.json(teamMember({ full_name: "Grâce Ngoma" }))),
      http.get(apiUrl("/me/2fa"), () =>
        HttpResponse.json({
          enabled: true,
          pending_setup: false,
          required: true,
          backup_codes_left: 10,
          enabled_at: "2026-11-20T10:00:00Z",
        }),
      ),
    );
    renderWithProviders(
      <SessionGate>
        <HomePage />
      </SessionGate>,
    );
    expect(await screen.findByText("Bonjour Grâce.")).toBeVisible();
    expect(screen.getByRole("heading", { level: 1, name: "Tableau de bord" })).toBeVisible();
    expect((await screen.findAllByText("Mode démo"))[0]).toBeVisible();
  });
});
