import { screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { http, HttpResponse } from "msw";
import { describe, expect, it } from "vitest";

import { server, TEST_ORIGIN } from "@/test/msw-server";
import { renderWithProviders } from "@/test/render";

import { ApiStatus } from "./api-status";

const HEALTH = `${TEST_ORIGIN}/api/v1/health`;

describe("état de l’API et badge « Mode démo »", () => {
  it("l’API confirme le mode démo : badge visible", async () => {
    server.use(
      http.get(HEALTH, () => HttpResponse.json({ status: "ok", database: "ok", demo_mode: true })),
    );
    renderWithProviders(<ApiStatus />);
    expect(await screen.findByText("Mode démo")).toBeVisible();
    expect(screen.getByText("API ElecPay : disponible")).toBeVisible();
  });

  it("données réelles (demo_mode faux) : AUCUN badge", async () => {
    server.use(
      http.get(HEALTH, () => HttpResponse.json({ status: "ok", database: "ok", demo_mode: false })),
    );
    renderWithProviders(<ApiStatus />);
    expect(await screen.findByText("API ElecPay : disponible")).toBeVisible();
    expect(screen.queryByText("Mode démo")).toBeNull();
  });

  it("API dégradée", async () => {
    server.use(
      http.get(HEALTH, () =>
        HttpResponse.json({ status: "degraded", database: "error", demo_mode: true }),
      ),
    );
    renderWithProviders(<ApiStatus />);
    expect(await screen.findByText("API ElecPay : dégradée")).toBeVisible();
  });

  it("API injoignable (relais 502) : message, référence, puis « Réessayer » qui relit", async () => {
    let calls = 0;
    server.use(
      http.get(HEALTH, () => {
        calls += 1;
        if (calls === 1) {
          return HttpResponse.json(
            {
              error: {
                code: "API_UNREACHABLE",
                message: "L'API ElecPay ne répond pas. Le PC qui l'héberge est peut-être éteint.",
                details: {},
              },
            },
            { status: 502, headers: { "x-request-id": "ref-relais-0001" } },
          );
        }
        return HttpResponse.json({ status: "ok", database: "ok", demo_mode: true });
      }),
    );
    renderWithProviders(<ApiStatus />);
    const alert = await screen.findByRole("alert");
    expect(alert).toHaveTextContent("Le PC qui l'héberge est peut-être éteint.");
    expect(alert).toHaveTextContent("Référence : ref-relais-0001");
    await userEvent.click(screen.getByRole("button", { name: "Réessayer" }));
    expect(await screen.findByText("Mode démo")).toBeVisible();
    expect(calls).toBe(2);
  });

  it("réseau coupé : message clair, sans référence", async () => {
    server.use(http.get(HEALTH, () => HttpResponse.error()));
    renderWithProviders(<ApiStatus />);
    const alert = await screen.findByRole("alert");
    expect(alert).toHaveTextContent("Connexion impossible au back-office.");
    expect(alert).not.toHaveTextContent("Référence");
  });
});
