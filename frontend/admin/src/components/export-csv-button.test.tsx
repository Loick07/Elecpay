import { screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { http, HttpResponse } from "msw";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { apiError, apiUrl, permissionsFor } from "@/test/api";
import { server } from "@/test/msw-server";
import { renderWithProviders } from "@/test/render";

import { ExportCsvButton } from "./export-csv-button";
import { ToastProvider } from "./ui/toaster";

const saved: { name: string; text: string }[] = [];

beforeEach(() => {
  saved.length = 0;
  // jsdom n'enregistre pas de fichier : on capture ce que le navigateur recevrait.
  let pending: Blob | null = null;
  URL.createObjectURL = vi.fn((blob: Blob) => {
    pending = blob;
    return "blob:essai";
  });
  URL.revokeObjectURL = vi.fn();
  vi.spyOn(HTMLAnchorElement.prototype, "click").mockImplementation(function (
    this: HTMLAnchorElement,
  ) {
    const blob = pending;
    if (blob) void blob.text().then((text) => saved.push({ name: this.download, text }));
  });
});
afterEach(() => {
  saved.length = 0;
});

function renderExport(role: "support" | "admin") {
  server.use(http.get(apiUrl("/admin/permissions"), () => HttpResponse.json(permissionsFor(role))));
  return renderWithProviders(
    <ToastProvider>
      <ExportCsvButton
        path="/api/v1/admin/users/export.csv"
        query={{ q: "Ngoma", kind: "client", status: undefined }}
        fallbackName="utilisateurs.csv"
      />
    </ToastProvider>,
  );
}

describe("« Exporter (CSV) »", () => {
  it("support : pas de bouton (l’API refuserait)", async () => {
    renderExport("support");
    await waitFor(() => expect(screen.queryByText("Exporter (CSV)")).toBeNull());
    // Les droits sont lus : toujours rien.
    await new Promise((resolve) => setTimeout(resolve, 50));
    expect(screen.queryByRole("button", { name: "Exporter (CSV)" })).toBeNull();
  });

  it("admin : la liste filtrée, enregistrée sous le nom donné par l’API ; avis", async () => {
    let asked: URL | null = null;
    server.use(
      http.get(apiUrl("/admin/users/export.csv"), ({ request }) => {
        asked = new URL(request.url);
        return new HttpResponse("nom;téléphone\nGrâce Ngoma;+242 05 *** ** 10\n", {
          headers: {
            "content-type": "text/csv; charset=utf-8",
            "content-disposition": 'attachment; filename="utilisateurs-2026-11-28.csv"',
          },
        });
      }),
    );
    renderExport("admin");
    await userEvent.setup().click(await screen.findByRole("button", { name: "Exporter (CSV)" }));
    expect(await screen.findByText("Export prêt : utilisateurs-2026-11-28.csv.")).toBeVisible();
    await waitFor(() => expect(saved).toHaveLength(1));
    expect(saved[0]).toEqual({
      name: "utilisateurs-2026-11-28.csv",
      text: "nom;téléphone\nGrâce Ngoma;+242 05 *** ** 10\n",
    });
    expect(asked!.searchParams.get("q")).toBe("Ngoma");
    expect(asked!.searchParams.get("kind")).toBe("client");
    expect(asked!.searchParams.has("status")).toBe(false);
  });

  it("refus de l’API : avis d’erreur avec la référence, aucun fichier", async () => {
    server.use(
      http.get(apiUrl("/admin/users/export.csv"), () =>
        apiError(403, "FORBIDDEN", "Vous n'avez pas les droits nécessaires pour cette action.", {
          requestId: "ref-export-1",
        }),
      ),
    );
    renderExport("admin");
    await userEvent.setup().click(await screen.findByRole("button", { name: "Exporter (CSV)" }));
    expect(
      await screen.findByText(
        "Export impossible. Vous n'avez pas les droits nécessaires pour cette action. (référence : ref-export-1)",
      ),
    ).toBeVisible();
    expect(saved).toEqual([]);
  });
});
