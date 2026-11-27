import { screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { http, HttpResponse } from "msw";
import { beforeEach, describe, expect, it, vi } from "vitest";

import { apiError, apiUrl, healthHandler } from "@/test/api";
import { server } from "@/test/msw-server";
import { renderWithProviders } from "@/test/render";

import { ForgotPasswordScreen } from "./forgot-password-screen";

const navigation = vi.hoisted(() => ({ replace: vi.fn() }));
vi.mock("next/navigation", () => ({
  useRouter: () => ({ replace: navigation.replace, push: navigation.replace }),
  useSearchParams: () => new URLSearchParams(),
}));

function forgotHandler(demoCode: string | null = "482913") {
  return http.post(apiUrl("/auth/password/forgot"), () =>
    HttpResponse.json({
      message: "Si ce numéro a un compte, un code vient d'être envoyé par SMS.",
      expires_in: 600,
      demo_code: demoCode,
    }),
  );
}

beforeEach(() => {
  navigation.replace.mockReset();
  server.use(healthHandler(), forgotHandler());
});

async function requestCode() {
  const user = userEvent.setup();
  renderWithProviders(<ForgotPasswordScreen />);
  await user.type(screen.getByLabelText("Numéro de téléphone"), "06 999 00 01");
  await user.click(screen.getByRole("button", { name: "Recevoir un code" }));
  await screen.findByLabelText("Code reçu par SMS");
  return user;
}

async function fillReset(
  user: ReturnType<typeof userEvent.setup>,
  { code = "482913", password = "Nouveau2026", confirmation = "Nouveau2026" } = {},
) {
  await user.type(screen.getByLabelText("Code reçu par SMS"), code);
  await user.type(screen.getByLabelText("Nouveau mot de passe"), password);
  await user.type(screen.getByLabelText("Confirmer le mot de passe"), confirmation);
  await user.click(screen.getByRole("button", { name: "Enregistrer le mot de passe" }));
}

it("parcours complet : code de démo affiché, mot de passe enregistré, retour à la connexion", async () => {
  let reset: unknown = null;
  server.use(
    http.post(apiUrl("/auth/password/reset"), async ({ request }) => {
      reset = await request.json();
      return new HttpResponse(null, { status: 204 });
    }),
  );
  const user = await requestCode();
  expect(screen.getByText(/Si ce numéro a un compte/)).toBeVisible();
  expect(screen.getByText(/Mode démo \(aucun SMS envoyé\)/)).toHaveTextContent("482913");
  await fillReset(user);
  await waitFor(() =>
    expect(navigation.replace).toHaveBeenCalledWith("/connexion?raison=reinitialise"),
  );
  expect(reset).toEqual({ phone: "+242069990001", code: "482913", new_password: "Nouveau2026" });
});

it("hors mode démo : aucun code affiché", async () => {
  server.use(forgotHandler(null));
  await requestCode();
  expect(screen.queryByText(/aucun SMS envoyé/)).toBeNull();
});

describe("erreurs de saisie (rien n’est envoyé)", () => {
  it("mots de passe différents", async () => {
    const user = await requestCode();
    await fillReset(user, { confirmation: "Autre2026x" });
    expect(await screen.findByText("Les deux mots de passe ne sont pas identiques.")).toBeVisible();
  });

  it("mot de passe trop faible : message du backend", async () => {
    const user = await requestCode();
    await fillReset(user, { password: "court1", confirmation: "court1" });
    expect(await screen.findByText("Mot de passe trop court : 8 caractères minimum")).toBeVisible();
  });

  it("code de 5 chiffres", async () => {
    const user = await requestCode();
    await fillReset(user, { code: "12345" });
    expect(await screen.findByText("Le code reçu par SMS a 6 chiffres.")).toBeVisible();
  });
});

it("code faux ou expiré : message de l’API, puis « Demander un nouveau code »", async () => {
  server.use(
    http.post(apiUrl("/auth/password/reset"), () =>
      apiError(400, "RESET_CODE_INVALID", "Code invalide ou expiré.", { requestId: "ref-code" }),
    ),
  );
  const user = await requestCode();
  await fillReset(user);
  const alert = await screen.findByRole("alert");
  expect(alert).toHaveTextContent("Code invalide ou expiré.");
  expect(alert).toHaveTextContent("Référence : ref-code");
  await user.click(screen.getByRole("button", { name: "Demander un nouveau code" }));
  expect(await screen.findByRole("button", { name: "Recevoir un code" })).toBeVisible();
});

it("trop de demandes (429) : bouton bloqué avec un compte à rebours", async () => {
  server.use(
    http.post(apiUrl("/auth/password/forgot"), () =>
      apiError(429, "TOO_MANY_ATTEMPTS", "Trop de demandes.", {
        details: { retry_after_seconds: 30 },
      }),
    ),
  );
  const user = userEvent.setup();
  renderWithProviders(<ForgotPasswordScreen />);
  await user.type(screen.getByLabelText("Numéro de téléphone"), "06 999 00 01");
  await user.click(screen.getByRole("button", { name: "Recevoir un code" }));
  expect(await screen.findByRole("button", { name: "Réessayer dans 0:30" })).toBeDisabled();
});
