import { screen, waitFor, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { http, HttpResponse } from "msw";
import { beforeEach, describe, expect, it, vi } from "vitest";

import { formatDate, formatPhone } from "@/lib/format";
import { onSessionEvent, type SessionEvent } from "@/lib/session/events";
import { apiError, apiUrl, healthHandler, shellHandlers, teamMember } from "@/test/api";
import { server } from "@/test/msw-server";
import { renderWithProviders } from "@/test/render";

import { SessionGate } from "../session/session-gate";
import { AppShell } from "../shell/app-shell";
import { AccountScreen } from "./account-screen";

const navigation = vi.hoisted(() => ({ replace: vi.fn() }));
vi.mock("next/navigation", () => ({
  useRouter: () => ({ replace: navigation.replace, push: navigation.replace }),
  usePathname: () => "/mon-compte",
  useSearchParams: () => new URLSearchParams(),
}));

const BACKUP_CODES = Array.from({ length: 10 }, (_, i) => `NV${i}A-BC${i}D`);

function twoFactor(overrides: Record<string, unknown> = {}) {
  return http.get(apiUrl("/me/2fa"), () =>
    HttpResponse.json({
      enabled: true,
      pending_setup: false,
      required: true,
      backup_codes_left: 8,
      enabled_at: "2026-11-20T10:00:00Z",
      ...overrides,
    }),
  );
}

function signedIn(overrides: Parameters<typeof teamMember>[0] = {}) {
  return http.get(apiUrl("/me"), () => HttpResponse.json(teamMember(overrides)));
}

/** Mon compte derrière la vraie garde des pages de l'équipe (/me, /me/2fa), dans le cadre. */
function renderAccount() {
  return renderWithProviders(
    <SessionGate>
      <AppShell>
        <AccountScreen />
      </AppShell>
    </SessionGate>,
  );
}

const section = (name: string) => screen.findByRole("region", { name });

beforeEach(() => {
  navigation.replace.mockReset();
  server.use(healthHandler(), ...shellHandlers("admin"));
});

describe("profil", () => {
  it("nom, téléphone, rôle, e-mail et date d’arrivée", async () => {
    server.use(signedIn(), twoFactor());
    renderAccount();
    const profile = within(await section("Profil"));
    expect(profile.getByText("Admin Démo")).toBeVisible();
    // Comparaison exacte : le numéro garde ses espaces insécables (Testing Library les remplacerait).
    expect(
      profile.getByText(formatPhone("+242060000002"), { normalizer: (text) => text }),
    ).toBeVisible();
    expect(profile.getByText("Admin")).toBeVisible();
    expect(profile.getByText("Non renseigné")).toBeVisible();
    expect(profile.getByText(`le ${formatDate("2026-11-01T08:00:00Z")}`)).toBeVisible();
  });

  it("modifier le nom : normalisé, enregistré, l’en-tête suit", async () => {
    const sent: unknown[] = [];
    server.use(
      signedIn(),
      twoFactor(),
      http.patch(apiUrl("/me"), async ({ request }) => {
        const body = (await request.json()) as { full_name: string };
        sent.push(body);
        return HttpResponse.json(teamMember({ full_name: body.full_name }));
      }),
    );
    renderAccount();
    const user = userEvent.setup();
    await user.click(await screen.findByRole("button", { name: "Modifier le nom" }));
    const field = screen.getByLabelText("Nom complet");

    await user.clear(field);
    await user.type(field, "A");
    await user.click(screen.getByRole("button", { name: "Enregistrer" }));
    expect(await screen.findByText("Nom trop court")).toBeVisible();
    expect(sent).toEqual([]);

    await user.clear(field);
    await user.type(field, "  Grâce   Ngoma ");
    await user.click(screen.getByRole("button", { name: "Enregistrer" }));
    expect(await screen.findByText("Nom enregistré.")).toBeVisible();
    expect(sent).toEqual([{ full_name: "Grâce Ngoma" }]);
    // Dans le menu ET dans le profil : la lecture de /me partagée a été mise à jour.
    expect(screen.getAllByText("Grâce Ngoma")).toHaveLength(2);
    expect(screen.queryByText("Admin Démo")).toBeNull();
  });
});

describe("mot de passe", () => {
  function passwordForm() {
    return {
      current: screen.getByLabelText("Mot de passe actuel"),
      next: screen.getByLabelText("Nouveau mot de passe"),
      confirmation: screen.getByLabelText("Confirmer le nouveau mot de passe"),
      submit: screen.getByRole("button", { name: "Changer le mot de passe" }),
    };
  }

  it("confirmation différente : refusée avant l’envoi", async () => {
    const sent: unknown[] = [];
    server.use(
      signedIn(),
      twoFactor(),
      http.post(apiUrl("/me/password"), ({ request }) => {
        sent.push(request.url);
        return HttpResponse.json({});
      }),
    );
    renderAccount();
    await section("Mot de passe");
    const user = userEvent.setup();
    const form = passwordForm();
    await user.type(form.current, "Demo2026!");
    await user.type(form.next, "Nouveau2026");
    await user.type(form.confirmation, "Nouveau2027");
    await user.click(form.submit);
    expect(await screen.findByText("Les deux mots de passe ne sont pas identiques.")).toBeVisible();
    expect(sent).toEqual([]);
  });

  it("mot de passe actuel incorrect : message sous le champ, la session continue", async () => {
    server.use(
      signedIn(),
      twoFactor(),
      http.post(apiUrl("/me/password"), () =>
        apiError(400, "WRONG_CURRENT_PASSWORD", "Mot de passe actuel incorrect."),
      ),
    );
    renderAccount();
    await section("Mot de passe");
    const user = userEvent.setup();
    const form = passwordForm();
    await user.type(form.current, "Faux2026!");
    await user.type(form.next, "Nouveau2026");
    await user.type(form.confirmation, "Nouveau2026");
    await user.click(form.submit);
    expect(await screen.findByText("Mot de passe actuel incorrect.")).toBeVisible();
    expect(form.current).toHaveAttribute("aria-invalid", "true");
    expect(navigation.replace).not.toHaveBeenCalled();
  });

  it("réussite : déconnexion (toutes les sessions sont fermées), connexion avec la raison", async () => {
    const calls: string[] = [];
    server.use(
      signedIn(),
      twoFactor(),
      http.post(apiUrl("/me/password"), async ({ request }) => {
        calls.push(`password ${JSON.stringify(await request.json())}`);
        return HttpResponse.json({
          token_type: "bearer",
          expires_in: 900,
          access_expires_at: "2026-11-27T10:15:00Z",
          refresh_expires_at: "2026-12-27T10:00:00Z",
          user: teamMember(),
        });
      }),
      http.post(apiUrl("/auth/web/logout"), () => {
        calls.push("logout");
        return new HttpResponse(null, { status: 204 });
      }),
    );
    renderAccount();
    await section("Mot de passe");
    const user = userEvent.setup();
    const form = passwordForm();
    await user.type(form.current, "Demo2026!");
    await user.type(form.next, "Nouveau2026");
    await user.type(form.confirmation, "Nouveau2026");
    await user.click(form.submit);
    await waitFor(() =>
      expect(navigation.replace).toHaveBeenCalledWith("/connexion?raison=mot-de-passe"),
    );
    expect(calls).toEqual([
      'password {"current_password":"Demo2026!","new_password":"Nouveau2026"}',
      "logout",
    ]);
  });
});

describe("double authentification", () => {
  it("active : depuis quand, codes restants ; peu de codes → avertissement", async () => {
    server.use(signedIn(), twoFactor({ backup_codes_left: 2 }));
    renderAccount();
    const box = within(await section("Double authentification"));
    expect(
      await box.findByText(
        `Active depuis le ${formatDate("2026-11-20T10:00:00Z")} ; 2 code(s) de secours restant(s).`,
      ),
    ).toBeVisible();
    expect(box.getByText(/Il vous reste peu de codes de secours/)).toBeVisible();
  });

  it("nouveaux codes : code faux refusé SANS fermer la session, puis 10 codes montrés une fois", async () => {
    let left = 8;
    const sentCodes: string[] = [];
    server.use(
      signedIn(),
      http.get(apiUrl("/me/2fa"), () =>
        HttpResponse.json({
          enabled: true,
          pending_setup: false,
          required: true,
          backup_codes_left: left,
          enabled_at: "2026-11-20T10:00:00Z",
        }),
      ),
      http.post(apiUrl("/me/2fa/backup-codes"), async ({ request }) => {
        const { code } = (await request.json()) as { code: string };
        sentCodes.push(code);
        if (code !== "654321") {
          return apiError(401, "TWO_FACTOR_CODE_INVALID", "Code de vérification incorrect.", {
            requestId: "ref-codes-1",
          });
        }
        left = 10;
        return HttpResponse.json({ backup_codes: BACKUP_CODES });
      }),
    );
    const events: SessionEvent[] = [];
    const stop = onSessionEvent((event) => events.push(event));
    renderAccount();
    const user = userEvent.setup();
    await user.click(await screen.findByRole("button", { name: "Nouveaux codes de secours" }));

    await user.type(screen.getByLabelText("Code à 6 chiffres"), "ABCD-EFGH");
    await user.click(screen.getByRole("button", { name: "Générer de nouveaux codes" }));
    expect(
      await screen.findByText("Saisissez les 6 chiffres affichés par l’application."),
    ).toBeVisible();
    expect(sentCodes).toEqual([]);

    await user.clear(screen.getByLabelText("Code à 6 chiffres"));
    await user.type(screen.getByLabelText("Code à 6 chiffres"), "000000");
    await user.click(screen.getByRole("button", { name: "Générer de nouveaux codes" }));
    const alert = await screen.findByRole("alert");
    expect(alert).toHaveTextContent("Code de vérification incorrect.");
    expect(alert).toHaveTextContent("Référence : ref-codes-1");
    expect(events).toEqual([]); // un code faux n'est pas une session expirée

    await user.clear(screen.getByLabelText("Code à 6 chiffres"));
    await user.type(screen.getByLabelText("Code à 6 chiffres"), "654 321");
    await user.click(screen.getByRole("button", { name: "Générer de nouveaux codes" }));
    const list = await screen.findByRole("list", { name: "Codes de secours" });
    expect(list.querySelectorAll("li")).toHaveLength(10);
    expect(sentCodes).toEqual(["000000", "654321"]);
    const done = screen.getByRole("button", { name: "Terminé" });
    expect(done).toBeDisabled();
    await user.click(screen.getByLabelText("J’ai mis ces codes en lieu sûr."));
    await user.click(done);

    expect(screen.queryByRole("list", { name: "Codes de secours" })).toBeNull();
    expect(await screen.findByText(/10 code\(s\) de secours restant\(s\)/)).toBeVisible();
    stop();
    expect(events).toEqual([]);
  });

  it("inactive (support) : bandeau « recommandée » vers la page Sécurité (DA1.5)", async () => {
    server.use(
      signedIn({ role: "support", full_name: "Support Démo" }),
      twoFactor({ enabled: false, required: false, backup_codes_left: 0, enabled_at: null }),
    );
    renderAccount();
    const box = within(await section("Double authentification"));
    expect(await box.findByText("Double authentification recommandée.")).toBeVisible();
    expect(
      box.getByRole("link", { name: "Configurer la double authentification" }),
    ).toHaveAttribute("href", "/securite?retour=%2Fmon-compte");
    expect(box.queryByRole("button", { name: "Nouveaux codes de secours" })).toBeNull();
  });
});
