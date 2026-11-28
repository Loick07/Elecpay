import { screen, waitFor, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { http, HttpResponse } from "msw";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import EssaiComposantsPage from "@/app/(equipe)/(cadre)/essai-composants/page";
import { formatFcfa } from "@/lib/format";
import { apiUrl, healthHandler, shellHandlers, teamMember } from "@/test/api";
import { axeViolations } from "@/test/axe";
import { server } from "@/test/msw-server";
import { renderWithProviders } from "@/test/render";

import { SessionGate } from "../session/session-gate";
import { AppShell } from "../shell/app-shell";
import { ComponentLab } from "./component-lab";

const navigation = vi.hoisted(() => ({ replace: vi.fn(), search: "" }));
vi.mock("next/navigation", () => ({
  useRouter: () => ({ replace: navigation.replace, push: navigation.replace }),
  usePathname: () => "/essai-composants",
  useSearchParams: () => new URLSearchParams(navigation.search),
  notFound: () => {
    throw new Error("NEXT_NOT_FOUND");
  },
}));

function user(id: number, overrides: Record<string, unknown> = {}) {
  return {
    id,
    full_name: `Client ${id}`,
    phone: "+242060000101",
    email: null,
    role: "client",
    is_delegated_payer: false,
    households: 1,
    unpaid: {
      count: 0,
      amount: 0,
      overdue_count: 0,
      pending_payment_count: 0,
      oldest_overdue_days: null,
    },
    last_login_at: null,
    is_active: true,
    created_at: "2026-11-01T08:00:00Z",
    ...overrides,
  };
}

const asked: URL[] = [];

beforeEach(() => {
  asked.length = 0;
  navigation.replace.mockReset();
  navigation.search = "";
  server.use(
    healthHandler(),
    http.get(apiUrl("/me"), () => HttpResponse.json(teamMember())),
    http.get(apiUrl("/me/2fa"), () =>
      HttpResponse.json({
        enabled: true,
        pending_setup: false,
        required: true,
        backup_codes_left: 10,
        enabled_at: null,
      }),
    ),
    ...shellHandlers("admin"),
    http.get(apiUrl("/admin/users"), ({ request }) => {
      asked.push(new URL(request.url));
      return HttpResponse.json({
        items: [
          user(1, {
            full_name: "Grâce Ngoma",
            unpaid: { ...user(1).unpaid, count: 1, amount: 25818 },
          }),
          user(2, { full_name: "Agent Support Démo", role: "support", is_active: false }),
        ],
        total: 45,
        page: 1,
        size: 20,
        accounts: 1284,
        active_accounts: 1271,
      });
    }),
  );
});
afterEach(() => {
  delete process.env.ELECPAY_ESSAI;
});

function renderLab() {
  return renderWithProviders(
    <SessionGate>
      <AppShell>
        <ComponentLab />
      </AppShell>
    </SessionGate>,
  );
}

describe("écran d’essai des composants (A2.3)", () => {
  it("absent sans ELECPAY_ESSAI=1 (donc en ligne)", () => {
    expect(() => EssaiComposantsPage()).toThrow("NEXT_NOT_FOUND");
    process.env.ELECPAY_ESSAI = "1";
    expect(() => EssaiComposantsPage()).not.toThrow();
  });

  it("indicateurs, tableau de GET /admin/users, page 1 de 20 lignes", async () => {
    renderLab();
    const table = await screen.findByRole("table", { name: "Utilisateurs" });
    expect(await within(table).findByText("Grâce Ngoma")).toBeVisible();
    expect(within(table).getByText("Désactivé")).toBeVisible();
    expect(screen.getByRole("navigation", { name: "Pages" })).toHaveTextContent(
      "2 affichés · page 1 sur 3",
    );
    expect(asked[0]?.searchParams.get("size")).toBe("20");
    expect(asked[0]?.searchParams.get("page")).toBe("1");
    expect(await screen.findByRole("button", { name: "Exporter (CSV)" })).toBeVisible();
  });

  it("filtres dans l’adresse ; la page lue dans l’adresse est demandée à l’API", async () => {
    navigation.search = "page=2&kind=team";
    renderLab();
    await screen.findByRole("table", { name: "Utilisateurs" });
    expect(asked[0]?.searchParams.get("page")).toBe("2");
    expect(asked[0]?.searchParams.get("kind")).toBe("team");
    expect(screen.getByRole("button", { name: "Équipe ElecPay" })).toHaveAttribute(
      "aria-pressed",
      "true",
    );
    await userEvent.setup().click(screen.getByRole("button", { name: "Clients" }));
    expect(navigation.replace).toHaveBeenCalledWith("/essai-composants?kind=client", {
      scroll: false,
    });
  });

  it("ligne → panneau ; confirmation avec motif → avis, rien envoyé à l’API", async () => {
    const posts: string[] = [];
    server.use(
      http.post(apiUrl("/admin/*"), ({ request }) => {
        posts.push(request.url);
        return HttpResponse.json({});
      }),
    );
    const { container } = renderLab();
    const userEvents = userEvent.setup();
    await userEvents.click(await screen.findByRole("button", { name: /Grâce Ngoma/ }));
    const panel = screen.getByRole("region", { name: "Grâce Ngoma" });
    // Comparaison exacte : le montant garde ses espaces insécables.
    expect(
      within(panel).getByText(`1 · ${formatFcfa(25818)}`, { normalizer: (text) => text }),
    ).toBeVisible();
    expect(await axeViolations(container)).toEqual([]);

    await userEvents.click(
      within(panel).getByRole("button", { name: "Essayer la confirmation avec motif" }),
    );
    await screen.findByRole("alertdialog");
    await userEvents.type(screen.getByLabelText("Motif"), "Essai du motif obligatoire");
    await userEvents.click(screen.getByRole("button", { name: "Confirmer l’essai" }));
    expect(
      await screen.findByText(
        "Essai réussi : motif « Essai du motif obligatoire » accepté, aucune action envoyée.",
      ),
    ).toBeVisible();
    await waitFor(() => expect(screen.queryByRole("alertdialog")).toBeNull());
    expect(posts).toEqual([]);
  });
});

it("panneau fermé (Échap) : le focus revient à LA ligne du tableau, toujours la même", async () => {
  renderLab();
  const user = userEvent.setup();
  const row = await screen.findByRole("button", { name: /Grâce Ngoma/ });
  await user.click(row);
  expect(screen.getByRole("heading", { level: 2, name: "Grâce Ngoma" })).toHaveFocus();
  // Le bouton de la ligne n'a pas été recréé par le rendu de la page (même élément).
  expect(screen.getByRole("button", { name: /Grâce Ngoma/ })).toBe(row);
  await user.keyboard("{Escape}");
  expect(screen.queryByRole("region", { name: "Grâce Ngoma" })).toBeNull();
  await waitFor(() => expect(row).toHaveFocus());
});
