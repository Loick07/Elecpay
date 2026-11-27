import { screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { http, HttpResponse } from "msw";
import { beforeEach, describe, expect, it, vi } from "vitest";

import { apiError, apiUrl, healthHandler, webSession } from "@/test/api";
import { server } from "@/test/msw-server";
import { renderWithProviders } from "@/test/render";

import { LoginScreen } from "./login-screen";

const navigation = vi.hoisted(() => ({ replace: vi.fn(), search: "" }));
vi.mock("next/navigation", () => ({
  useRouter: () => ({ replace: navigation.replace, push: navigation.replace }),
  useSearchParams: () => new URLSearchParams(navigation.search),
}));

const CHALLENGE = {
  two_factor_required: true,
  challenge_token: "defi-123",
  expires_at: "2026-11-27T09:05:00Z",
  methods: ["totp", "backup_code"],
};

beforeEach(() => {
  navigation.replace.mockReset();
  navigation.search = "";
  server.use(healthHandler());
});

async function fillLogin(phone = "06 000 00 02", password = "Demo2026!") {
  const user = userEvent.setup();
  await user.type(screen.getByLabelText("Numéro de téléphone"), phone);
  await user.type(screen.getByLabelText("Mot de passe"), password);
  await user.click(screen.getByRole("button", { name: "Se connecter" }));
  return user;
}

describe("connexion : numéro et mot de passe", () => {
  it("champs vides : un message par champ, rien n’est envoyé", async () => {
    let sent = false;
    server.use(
      http.post(apiUrl("/auth/web/login"), () => {
        sent = true;
        return HttpResponse.json(webSession());
      }),
    );
    renderWithProviders(<LoginScreen />);
    await userEvent.setup().click(screen.getByRole("button", { name: "Se connecter" }));
    expect(await screen.findByText("Saisissez votre numéro de téléphone.")).toBeVisible();
    expect(screen.getByText("Saisissez votre mot de passe.")).toBeVisible();
    expect(screen.getByLabelText("Numéro de téléphone")).toHaveAttribute("aria-invalid", "true");
    expect(sent).toBe(false);
  });

  it("sans double authentification : numéro normalisé, retour à la page demandée", async () => {
    navigation.search = "retour=%2Fmon-compte";
    let body: unknown = null;
    server.use(
      http.post(apiUrl("/auth/web/login"), async ({ request }) => {
        body = await request.json();
        return HttpResponse.json(webSession({ role: "support" }));
      }),
    );
    renderWithProviders(<LoginScreen />);
    await fillLogin();
    await waitFor(() => expect(navigation.replace).toHaveBeenCalledWith("/mon-compte"));
    expect(body).toEqual({ phone: "+242060000002", password: "Demo2026!" });
  });

  it("retour vers un autre site : ignoré, accueil", async () => {
    navigation.search = "retour=https%3A%2F%2Fpirate.example";
    server.use(http.post(apiUrl("/auth/web/login"), () => HttpResponse.json(webSession())));
    renderWithProviders(<LoginScreen />);
    await fillLogin();
    await waitFor(() => expect(navigation.replace).toHaveBeenCalledWith("/"));
  });

  it("client (403) : message de l’API et référence", async () => {
    server.use(
      http.post(apiUrl("/auth/web/login"), () =>
        apiError(403, "FORBIDDEN", "Cet espace est réservé à l'équipe ElecPay.", {
          requestId: "ref-client-01",
        }),
      ),
    );
    renderWithProviders(<LoginScreen />);
    await fillLogin("06 000 01 01");
    const alert = await screen.findByRole("alert");
    expect(alert).toHaveTextContent("Cet espace est réservé à l'équipe ElecPay.");
    expect(alert).toHaveTextContent("Référence : ref-client-01");
    expect(navigation.replace).not.toHaveBeenCalled();
  });

  it("trop de tentatives (429) : bouton bloqué avec un compte à rebours", async () => {
    server.use(
      http.post(apiUrl("/auth/web/login"), () =>
        apiError(429, "TOO_MANY_ATTEMPTS", "Trop de tentatives. Réessayez plus tard.", {
          details: { retry_after_seconds: 125 },
        }),
      ),
    );
    renderWithProviders(<LoginScreen />);
    await fillLogin();
    expect(await screen.findByRole("alert")).toHaveTextContent("Trop de tentatives.");
    const button = await screen.findByRole("button", { name: "Réessayer dans 2:05" });
    expect(button).toBeDisabled();
  });

  it("réseau coupé : message clair", async () => {
    server.use(http.post(apiUrl("/auth/web/login"), () => HttpResponse.error()));
    renderWithProviders(<LoginScreen />);
    await fillLogin();
    expect(await screen.findByRole("alert")).toHaveTextContent("Connexion impossible");
  });

  it("raison d’arrivée affichée (session expirée)", async () => {
    navigation.search = "raison=session";
    renderWithProviders(<LoginScreen />);
    expect(await screen.findByRole("status")).toHaveTextContent(
      "Votre session a expiré. Reconnectez-vous pour continuer.",
    );
  });

  it("lien vers « Mot de passe oublié ou première connexion »", () => {
    renderWithProviders(<LoginScreen />);
    expect(
      screen.getByRole("link", { name: "Mot de passe oublié ou première connexion ?" }),
    ).toHaveAttribute("href", "/mot-de-passe-oublie");
  });
});

describe("double authentification", () => {
  function withChallenge(answer: (body: { challenge_token: string; code: string }) => Response) {
    server.use(
      http.post(apiUrl("/auth/web/login"), () => HttpResponse.json(CHALLENGE)),
      http.post(apiUrl("/auth/web/login/2fa"), async ({ request }) =>
        answer((await request.json()) as { challenge_token: string; code: string }),
      ),
    );
  }

  it("le code est demandé, puis la session s’ouvre", async () => {
    let received: unknown = null;
    withChallenge((body) => {
      received = body;
      return HttpResponse.json(webSession());
    });
    renderWithProviders(<LoginScreen />);
    const user = await fillLogin();
    expect(
      await screen.findByRole("heading", { level: 1, name: "Double authentification" }),
    ).toBeVisible();
    await waitFor(() => expect(screen.getByLabelText("Code de vérification")).toHaveFocus());
    await user.type(screen.getByLabelText("Code de vérification"), "123 456");
    await user.click(screen.getByRole("button", { name: "Valider le code" }));
    await waitFor(() => expect(navigation.replace).toHaveBeenCalledWith("/"));
    expect(received).toEqual({ challenge_token: "defi-123", code: "123456" });
  });

  it("code de secours accepté (mis en forme ABCD-EFGH)", async () => {
    let code = "";
    withChallenge((body) => {
      code = body.code;
      return HttpResponse.json(webSession());
    });
    renderWithProviders(<LoginScreen />);
    const user = await fillLogin();
    await user.type(await screen.findByLabelText("Code de vérification"), "abcdefgh");
    await user.click(screen.getByRole("button", { name: "Valider le code" }));
    await waitFor(() => expect(code).toBe("ABCD-EFGH"));
  });

  it("code faux : message de l’API, on reste sur l’étape du code", async () => {
    withChallenge(() =>
      apiError(401, "TWO_FACTOR_CODE_INVALID", "Code incorrect ou déjà utilisé."),
    );
    renderWithProviders(<LoginScreen />);
    const user = await fillLogin();
    await user.type(await screen.findByLabelText("Code de vérification"), "000000");
    await user.click(screen.getByRole("button", { name: "Valider le code" }));
    expect(await screen.findByRole("alert")).toHaveTextContent("Code incorrect ou déjà utilisé.");
    expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent("Double authentification");
  });

  it("défi expiré : retour au mot de passe, avec le message de l’API", async () => {
    withChallenge(() =>
      apiError(401, "TWO_FACTOR_CHALLENGE_INVALID", "Délai dépassé : reconnectez-vous."),
    );
    renderWithProviders(<LoginScreen />);
    const user = await fillLogin();
    await user.type(await screen.findByLabelText("Code de vérification"), "123456");
    await user.click(screen.getByRole("button", { name: "Valider le code" }));
    expect(await screen.findByRole("heading", { level: 1, name: "Connexion" })).toBeVisible();
    expect(screen.getByRole("status")).toHaveTextContent("Délai dépassé : reconnectez-vous.");
  });

  it("« Recommencer la connexion » revient au mot de passe", async () => {
    withChallenge(() => HttpResponse.json(webSession()));
    renderWithProviders(<LoginScreen />);
    const user = await fillLogin();
    await user.click(await screen.findByRole("button", { name: "Recommencer la connexion" }));
    expect(await screen.findByRole("heading", { level: 1, name: "Connexion" })).toBeVisible();
  });
});
