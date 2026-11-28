import { screen, waitFor, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { http, HttpResponse } from "msw";
import { beforeEach, describe, expect, it, vi } from "vitest";

import { apiUrl, healthHandler, shellHandlers, teamMember } from "@/test/api";
import { axeViolations } from "@/test/axe";
import { server } from "@/test/msw-server";
import { renderWithProviders } from "@/test/render";

import { SessionGate } from "../session/session-gate";
import { AppShell } from "./app-shell";
import { ComingSoon } from "./coming-soon";
import { initials, isCurrent } from "./sidebar";
import { TeamPage } from "./team-page";

const navigation = vi.hoisted(() => ({ replace: vi.fn(), pathname: "/" }));
vi.mock("next/navigation", () => ({
  useRouter: () => ({ replace: navigation.replace, push: navigation.replace }),
  usePathname: () => navigation.pathname,
  useSearchParams: () => new URLSearchParams(),
}));

type Role = "support" | "admin" | "super_admin";

const NAMES: Record<Role, string> = {
  support: "Agent Support Démo",
  admin: "Administrateur Démo",
  super_admin: "Superviseur Démo",
};

function session(role: Role) {
  return [
    http.get(apiUrl("/me"), () => HttpResponse.json(teamMember({ role, full_name: NAMES[role] }))),
    http.get(apiUrl("/me/2fa"), () =>
      HttpResponse.json({
        enabled: role !== "support",
        pending_setup: false,
        required: role !== "support",
        backup_codes_left: 10,
        enabled_at: null,
      }),
    ),
  ];
}

function renderShell(role: Role, counts: { anomalies?: number; pending?: number } = {}) {
  server.use(...session(role), ...shellHandlers(role, counts));
  return renderWithProviders(
    <SessionGate>
      <AppShell>
        <TeamPage title="Essai" description="Sous-titre de la page">
          <p>Contenu de la page</p>
        </TeamPage>
      </AppShell>
    </SessionGate>,
  );
}

const menuEntries = async () => {
  const nav = await screen.findByRole("navigation", { name: "Menu principal" });
  return within(nav)
    .getAllByRole("link")
    .map((link) => link.textContent);
};

beforeEach(() => {
  navigation.replace.mockReset();
  navigation.pathname = "/";
  server.use(healthHandler());
});

describe("menu selon le rôle (droits lus dans GET /admin/permissions)", () => {
  it("support : tout sauf le journal d’activité", async () => {
    renderShell("support");
    await screen.findByText("Contenu de la page");
    await waitFor(async () =>
      expect(await menuEntries()).toEqual([
        "Tableau de bord",
        "Utilisateurs",
        "Compteurs",
        "Factures",
        "Transactions",
        "Notifications",
        "Paramètres et rôles",
      ]),
    );
  });

  it.each(["admin", "super_admin"] as const)(
    "%s : les huit entrées, journal compris",
    async (role) => {
      renderShell(role);
      await waitFor(async () => expect(await menuEntries()).toContain("Journal d’activité"));
      expect(await menuEntries()).toHaveLength(8);
    },
  );

  it("droits illisibles (API injoignable) : seules les entrées de toute l’équipe", async () => {
    // Dans un même `server.use`, le PREMIER gestionnaire qui correspond répond.
    server.use(
      http.get(apiUrl("/admin/permissions"), () => HttpResponse.error()),
      ...session("admin"),
      ...shellHandlers("admin"),
    );
    renderWithProviders(
      <SessionGate>
        <AppShell>
          <p>Contenu de la page</p>
        </AppShell>
      </SessionGate>,
    );
    await screen.findByText("Contenu de la page");
    expect(await menuEntries()).not.toContain("Journal d’activité");
  });
});

describe("cadre", () => {
  it("rubrique affichée marquée ; pastilles lues et dites en toutes lettres", async () => {
    navigation.pathname = "/transactions/42";
    renderShell("admin", { anomalies: 3, pending: 1 });
    const transactions = await screen.findByRole("link", {
      name: "Transactions, 1 transaction en attente",
    });
    expect(transactions).toHaveAttribute("aria-current", "page");
    expect(
      await screen.findByRole("link", { name: "Compteurs, 3 anomalies à traiter" }),
    ).not.toHaveAttribute("aria-current");
    expect(screen.getByRole("link", { name: "Tableau de bord" })).not.toHaveAttribute(
      "aria-current",
    );
  });

  it("aucune pastille quand il n’y a rien à traiter", async () => {
    renderShell("support");
    expect(await screen.findByRole("link", { name: "Compteurs" })).toBeVisible();
    expect(screen.getByRole("link", { name: "Transactions" })).toBeVisible();
  });

  it("membre connecté, « Mode démo », Mon compte et déconnexion", async () => {
    const calls: string[] = [];
    server.use(
      http.post(apiUrl("/auth/web/logout"), () => {
        calls.push("logout");
        return new HttpResponse(null, { status: 204 });
      }),
    );
    renderShell("support");
    const aside = (await screen.findByRole("navigation", { name: "Menu principal" })).closest(
      "aside",
    );
    expect(aside).toHaveAttribute("data-theme", "dark");
    const menu = within(aside as HTMLElement);
    expect(menu.getByText("Agent Support Démo")).toBeVisible();
    expect(menu.getByText("Support")).toBeVisible();
    expect(menu.getByText("AS")).toBeVisible();
    expect(await menu.findByText("Mode démo")).toBeVisible();
    expect(menu.getByRole("link", { name: "Mon compte" })).toHaveAttribute("href", "/mon-compte");

    await userEvent.setup().click(menu.getByRole("button", { name: "Se déconnecter" }));
    await waitFor(() =>
      expect(navigation.replace).toHaveBeenCalledWith("/connexion?raison=deconnexion"),
    );
    expect(calls).toEqual(["logout"]);
  });

  it("en-tête de page (titre, sous-titre) et lien d’évitement vers le contenu", async () => {
    renderShell("support");
    expect(await screen.findByRole("heading", { level: 1, name: "Essai" })).toBeVisible();
    expect(screen.getByText("Sous-titre de la page")).toBeVisible();
    expect(screen.getByRole("link", { name: "Aller au contenu" })).toHaveAttribute(
      "href",
      "#contenu",
    );
    expect(screen.getByRole("main")).toHaveAttribute("id", "contenu");
  });

  it("petit écran : le bouton « Menu » déplie et replie le menu", async () => {
    renderShell("support");
    const toggle = await screen.findByRole("button", { name: "Menu" });
    expect(toggle).toHaveAttribute("aria-expanded", "false");
    const user = userEvent.setup();
    await user.click(toggle);
    expect(toggle).toHaveAttribute("aria-expanded", "true");
    expect(document.getElementById(toggle.getAttribute("aria-controls") ?? "")).toContainElement(
      screen.getByRole("navigation", { name: "Menu principal" }),
    );
    await user.click(screen.getByRole("link", { name: "Utilisateurs" }));
    expect(toggle).toHaveAttribute("aria-expanded", "false");
  });

  it("accessibilité (axe) du cadre", async () => {
    const { container } = renderShell("admin", { anomalies: 2, pending: 4 });
    await screen.findByRole("link", { name: "Journal d’activité" });
    expect(await axeViolations(container)).toEqual([]);
  });
});

it("rubrique pas encore construite : bloc clair avec l’étape", () => {
  renderWithProviders(<ComingSoon title="Factures" step="A4" />);
  expect(screen.getByRole("heading", { level: 1, name: "Factures" })).toBeVisible();
  expect(screen.getByText("Écran en préparation")).toBeVisible();
  expect(screen.getByText("Cet écran arrive à l’étape A4 du back-office.")).toBeVisible();
});

describe("outils du menu", () => {
  it.each([
    ["/", "/", true],
    ["/", "/utilisateurs", false],
    ["/utilisateurs", "/utilisateurs", true],
    ["/utilisateurs", "/utilisateurs/12", true],
    ["/utilisateurs", "/utilisateurs-archives", false],
  ])("entrée %s, page %s → %s", (href, pathname, expected) => {
    expect(isCurrent(href, pathname)).toBe(expected);
  });

  it("initiales : deux premiers mots", () => {
    expect(initials("Agent Support Démo")).toBe("AS");
    expect(initials("  élodie ")).toBe("É");
  });
});
