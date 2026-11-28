import { screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { http, HttpResponse } from "msw";
import { describe, expect, it } from "vitest";

import { apiUrl, permissionsFor } from "@/test/api";
import { axeViolations } from "@/test/axe";
import { server } from "@/test/msw-server";
import { renderWithProviders } from "@/test/render";

import { type Capability, rights } from "./permissions";
import { RequirePermission } from "./require-permission";

type Role = "support" | "admin" | "super_admin";

/** Ce que chaque rôle peut faire (matrice validée des maquettes, A11). */
const EXPECTED: Record<Capability, Role[]> = {
  view: ["support", "admin", "super_admin"],
  view_audit_log: ["admin", "super_admin"],
  toggle_account: ["admin", "super_admin"],
  cancel_bill: ["admin", "super_admin"],
  recheck_transaction: ["admin", "super_admin"],
  send_announcement: ["admin", "super_admin"],
  edit_tariffs: ["super_admin"],
  manage_team: ["super_admin"],
  force_payment_success: [],
};

describe("droits rôle par rôle", () => {
  it.each(["support", "admin", "super_admin"] as const)("%s", (role) => {
    const { can } = rights(permissionsFor(role));
    for (const [capability, roles] of Object.entries(EXPECTED)) {
      expect([capability, can(capability as Capability)]).toEqual([
        capability,
        roles.includes(role),
      ]);
    }
  });

  it("niveaux : support → staff ; admin → staff, admin ; super admin → les trois", () => {
    expect(rights(permissionsFor("support")).hasLevel("admin")).toBe(false);
    expect(rights(permissionsFor("admin")).hasLevel("admin")).toBe(true);
    expect(rights(permissionsFor("admin")).hasLevel("super_admin")).toBe(false);
    expect(rights(permissionsFor("super_admin")).hasLevel("super_admin")).toBe(true);
  });

  it("droits pas encore lus : rien n’est permis", () => {
    const { can, hasLevel } = rights(undefined);
    expect(can("view")).toBe(false);
    expect(hasLevel("staff")).toBe(false);
  });

  it("« Marquer une transaction comme réussie » : jamais, même si une réponse le prétendait", () => {
    const forged = permissionsFor("super_admin");
    forged.capabilities = forged.capabilities.map((entry) => ({ ...entry, allowed: true }));
    expect(rights(forged).can("force_payment_success")).toBe(false);
    expect(rights(forged).can("edit_tariffs")).toBe(true);
  });
});

describe("garde d’un écran réservé", () => {
  const permissions = (role: Role) =>
    http.get(apiUrl("/admin/permissions"), () => HttpResponse.json(permissionsFor(role)));

  function renderJournal() {
    return renderWithProviders(
      <RequirePermission capability="view_audit_log">
        <p>Journal réservé</p>
      </RequirePermission>,
    );
  }

  it("admin : le contenu", async () => {
    server.use(permissions("admin"));
    renderJournal();
    expect(screen.getByText("Vérification de vos droits…")).toBeVisible();
    expect(await screen.findByText("Journal réservé")).toBeVisible();
  });

  it("support : « Accès refusé », rien du contenu", async () => {
    server.use(permissions("support"));
    const { container } = renderJournal();
    expect(await screen.findByText("Accès refusé")).toBeVisible();
    expect(screen.queryByText("Journal réservé")).toBeNull();
    expect(await axeViolations(container)).toEqual([]);
  });

  it("niveau exigé : super admin seulement", async () => {
    server.use(permissions("admin"));
    renderWithProviders(
      <RequirePermission level="super_admin">
        <p>Tarifs</p>
      </RequirePermission>,
    );
    expect(await screen.findByText("Accès refusé")).toBeVisible();
  });

  it("droits illisibles : message, référence, « Réessayer » qui relit", async () => {
    let calls = 0;
    server.use(
      http.get(apiUrl("/admin/permissions"), () => {
        calls += 1;
        return calls === 1
          ? HttpResponse.json(
              { error: { code: "API_UNREACHABLE", message: "L'API ne répond pas.", details: {} } },
              { status: 502, headers: { "x-request-id": "ref-droits-1" } },
            )
          : HttpResponse.json(permissionsFor("admin"));
      }),
    );
    renderJournal();
    const alert = await screen.findByRole("alert");
    expect(alert).toHaveTextContent("L'API ne répond pas.");
    expect(alert).toHaveTextContent("Référence : ref-droits-1");
    await userEvent.setup().click(screen.getByRole("button", { name: "Réessayer" }));
    expect(await screen.findByText("Journal réservé")).toBeVisible();
  });
});
