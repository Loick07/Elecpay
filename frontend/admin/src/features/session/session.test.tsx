import { act, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { http, HttpResponse } from "msw";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { announceSession } from "@/lib/session/events";
import { apiError, apiUrl, healthHandler, shellHandlers, teamMember } from "@/test/api";
import { server } from "@/test/msw-server";
import { renderWithProviders } from "@/test/render";

import { SessionGate } from "./session-gate";
import { AppShell } from "../shell/app-shell";
import { TeamPage } from "../shell/team-page";

const navigation = vi.hoisted(() => ({ replace: vi.fn(), pathname: "/utilisateurs" }));
vi.mock("next/navigation", () => ({
  useRouter: () => ({ replace: navigation.replace, push: navigation.replace }),
  usePathname: () => navigation.pathname,
  useSearchParams: () => new URLSearchParams(),
}));

function twoFactor(overrides: Record<string, unknown> = {}) {
  return http.get(apiUrl("/me/2fa"), () =>
    HttpResponse.json({
      enabled: true,
      pending_setup: false,
      required: true,
      backup_codes_left: 10,
      enabled_at: "2026-11-20T10:00:00Z",
      ...overrides,
    }),
  );
}

const signedIn = () => http.get(apiUrl("/me"), () => HttpResponse.json(teamMember()));
const signedOut = () => [
  http.get(apiUrl("/me"), () => apiError(401, "NOT_AUTHENTICATED", "Authentification requise.")),
  http.post(apiUrl("/auth/web/refresh"), () =>
    apiError(401, "NOT_AUTHENTICATED", "Authentification requise."),
  ),
];

function renderGate() {
  return renderWithProviders(
    <SessionGate>
      <AppShell>
        <TeamPage title="Utilisateurs">
          <p>Contenu protégé</p>
        </TeamPage>
      </AppShell>
    </SessionGate>,
  );
}

beforeEach(() => {
  navigation.replace.mockReset();
  navigation.pathname = "/utilisateurs";
  server.use(healthHandler(), ...shellHandlers("admin"));
});
afterEach(() => {
  document.cookie = "elecpay_csrf=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/";
});

describe("garde des pages de l’équipe", () => {
  it("session ouverte : contenu, membre et rôle dans l’en-tête", async () => {
    server.use(signedIn(), twoFactor());
    renderGate();
    expect(await screen.findByText("Contenu protégé")).toBeVisible();
    // Dans le menu (cadre) : nom et rôle du membre connecté.
    expect(screen.getByText("Admin Démo")).toBeVisible();
    expect(screen.getByText("Admin")).toBeVisible();
  });

  it("jamais connecté : retour à la connexion, sans parler de session expirée", async () => {
    server.use(...signedOut());
    renderGate();
    await waitFor(() =>
      expect(navigation.replace).toHaveBeenCalledWith("/connexion?retour=%2Futilisateurs"),
    );
    expect(screen.queryByText("Contenu protégé")).toBeNull();
  });

  it("session expirée (cookie anti-CSRF présent) : « session expirée » et page demandée", async () => {
    document.cookie = "elecpay_csrf=ancien; path=/";
    server.use(...signedOut());
    renderGate();
    await waitFor(() =>
      expect(navigation.replace).toHaveBeenCalledWith(
        "/connexion?retour=%2Futilisateurs&raison=session",
      ),
    );
  });

  it("double authentification obligatoire et pas activée : page Sécurité", async () => {
    server.use(signedIn(), twoFactor({ enabled: false }));
    renderGate();
    await waitFor(() =>
      expect(navigation.replace).toHaveBeenCalledWith("/securite?retour=%2Futilisateurs"),
    );
    expect(screen.queryByText("Contenu protégé")).toBeNull();
  });

  it("sur la page Sécurité elle-même : pas de renvoi", async () => {
    navigation.pathname = "/securite";
    server.use(signedIn(), twoFactor({ enabled: false }));
    renderGate();
    expect(await screen.findByText("Contenu protégé")).toBeVisible();
    expect(navigation.replace).not.toHaveBeenCalled();
  });

  it("support (double authentification facultative) : accès sans elle", async () => {
    server.use(
      http.get(apiUrl("/me"), () => HttpResponse.json(teamMember({ role: "support" }))),
      twoFactor({ enabled: false, required: false }),
    );
    renderGate();
    expect(await screen.findByText("Contenu protégé")).toBeVisible();
  });

  it("API injoignable : message, référence et « Réessayer »", async () => {
    server.use(
      http.get(apiUrl("/me"), () =>
        apiError(502, "API_UNREACHABLE", "L'API ElecPay ne répond pas.", { requestId: "ref-9" }),
      ),
    );
    renderGate();
    const alert = await screen.findByRole("alert");
    expect(alert).toHaveTextContent("L'API ElecPay ne répond pas.");
    expect(alert).toHaveTextContent("Référence : ref-9");
    expect(screen.getByRole("button", { name: "Réessayer" })).toBeVisible();
  });
});

describe("veilleur de la session", () => {
  beforeEach(() => server.use(signedIn(), twoFactor()));

  it("« session expirée » : fenêtre de la charte, « Se reconnecter » garde la page demandée", async () => {
    renderGate();
    await screen.findByText("Contenu protégé");
    act(() => announceSession("expiree", { otherTabs: false }));
    const dialog = await screen.findByRole("alertdialog", { name: "Session expirée" });
    expect(dialog).toHaveTextContent("Votre session a expiré. Reconnectez-vous pour continuer.");
    await userEvent.setup().click(screen.getByRole("button", { name: "Se reconnecter" }));
    expect(navigation.replace).toHaveBeenCalledWith(
      "/connexion?retour=%2Futilisateurs&raison=session",
    );
  });

  it("déconnexion dans un AUTRE onglet : retour à la connexion", async () => {
    renderGate();
    await screen.findByText("Contenu protégé");
    const otherTab = new BroadcastChannel("elecpay-session");
    otherTab.postMessage("deconnexion");
    await waitFor(() =>
      expect(navigation.replace).toHaveBeenCalledWith("/connexion?raison=deconnexion"),
    );
    otherTab.close();
  });

  it("« Se déconnecter » : appel à l’API, puis la connexion avec « Vous êtes déconnecté »", async () => {
    let loggedOut = false;
    server.use(
      http.post(apiUrl("/auth/web/logout"), () => {
        loggedOut = true;
        return new HttpResponse(null, { status: 204 });
      }),
    );
    renderGate();
    await userEvent.setup().click(await screen.findByRole("button", { name: "Se déconnecter" }));
    await waitFor(() =>
      expect(navigation.replace).toHaveBeenCalledWith("/connexion?raison=deconnexion"),
    );
    expect(loggedOut).toBe(true);
  });

  it("« Se déconnecter » même si l’API ne répond pas : la page se déconnecte quand même", async () => {
    server.use(http.post(apiUrl("/auth/web/logout"), () => HttpResponse.error()));
    renderGate();
    await userEvent.setup().click(await screen.findByRole("button", { name: "Se déconnecter" }));
    await waitFor(() =>
      expect(navigation.replace).toHaveBeenCalledWith("/connexion?raison=deconnexion"),
    );
  });
});
