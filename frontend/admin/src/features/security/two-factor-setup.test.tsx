import { screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { http, HttpResponse } from "msw";
import { beforeEach, describe, expect, it, vi } from "vitest";

import { apiError, apiUrl, healthHandler } from "@/test/api";
import { server } from "@/test/msw-server";
import { renderWithProviders } from "@/test/render";

import { groupKey, qrImageSource, TwoFactorSetup } from "./two-factor-setup";

const navigation = vi.hoisted(() => ({ replace: vi.fn(), search: "" }));
vi.mock("next/navigation", () => ({
  useRouter: () => ({ replace: navigation.replace, push: navigation.replace }),
  useSearchParams: () => new URLSearchParams(navigation.search),
}));

const BACKUP_CODES = Array.from({ length: 10 }, (_, i) => `AB${i}D-EF${i}H`);
const SVG = '<svg xmlns="http://www.w3.org/2000/svg"><rect width="1" height="1"/></svg>';

function status(overrides: Record<string, unknown> = {}) {
  return http.get(apiUrl("/me/2fa"), () =>
    HttpResponse.json({
      enabled: false,
      pending_setup: false,
      required: true,
      backup_codes_left: 0,
      enabled_at: null,
      ...overrides,
    }),
  );
}

beforeEach(() => {
  navigation.replace.mockReset();
  navigation.search = "";
  server.use(healthHandler());
});

it("clé lisible en groupes de 4, QR code en image data: (jamais injecté dans la page)", () => {
  expect(groupKey("ELECPAYDEMO2FA")).toBe("ELEC PAYD EMO2 FA");
  expect(qrImageSource(SVG)).toMatch(/^data:image\/svg\+xml;charset=utf-8,%3Csvg/);
});

it("SVG de l’API sans xmlns (segno.svg_inline) : xmlns ajouté, sinon l’image n’est pas dessinée", () => {
  const fromSegno = '<svg width="132" height="132" class="segno"><path d="M2 2.5h7"/></svg>';
  const decoded = decodeURIComponent(qrImageSource(fromSegno).split(",")[1] ?? "");
  expect(decoded).toBe(
    '<svg xmlns="http://www.w3.org/2000/svg" width="132" height="132" class="segno"><path d="M2 2.5h7"/></svg>',
  );
  // Déjà présent : rien n'est ajouté une seconde fois.
  expect(decodeURIComponent(qrImageSource(SVG).split(",")[1] ?? "")).toBe(SVG);
});

it("déjà active : date et nombre de codes de secours restants", async () => {
  server.use(status({ enabled: true, enabled_at: "2026-11-20T10:00:00Z", backup_codes_left: 7 }));
  renderWithProviders(<TwoFactorSetup />);
  expect(
    await screen.findByText(/Double authentification active depuis le 20 nov\. 2026/),
  ).toHaveTextContent("7 code(s) de secours restant(s)");
});

describe("configuration", () => {
  beforeEach(() => {
    server.use(
      status(),
      http.post(apiUrl("/me/2fa/setup"), () =>
        HttpResponse.json({
          secret: "ELECPAYDEMO2FASECRET",
          otpauth_uri: "otpauth://totp/x",
          qr_svg: SVG,
        }),
      ),
    );
  });

  it("obligatoire pour le rôle : le dit clairement", async () => {
    renderWithProviders(<TwoFactorSetup />);
    expect(await screen.findByText(/Obligatoire pour votre rôle/)).toBeVisible();
  });

  it("recommandée pour le support (DA1.5)", async () => {
    server.use(status({ required: false }));
    renderWithProviders(<TwoFactorSetup />);
    expect(await screen.findByText(/Recommandée/)).toBeVisible();
  });

  it("QR code et clé, code faux refusé, puis codes de secours montrés une seule fois", async () => {
    let attempts = 0;
    server.use(
      http.post(apiUrl("/me/2fa/enable"), async ({ request }) => {
        attempts += 1;
        const { code } = (await request.json()) as { code: string };
        if (code !== "123456") {
          return apiError(401, "TWO_FACTOR_CODE_INVALID", "Code incorrect.", {
            requestId: "ref-2fa-1",
          });
        }
        return HttpResponse.json({ backup_codes: BACKUP_CODES });
      }),
    );
    navigation.search = "retour=%2Futilisateurs";
    renderWithProviders(<TwoFactorSetup />);
    const user = userEvent.setup();
    await user.click(
      await screen.findByRole("button", { name: "Configurer la double authentification" }),
    );

    const qr = await screen.findByRole("img", {
      name: "QR code à scanner avec votre application d’authentification",
    });
    expect(qr.getAttribute("src")).toBe(qrImageSource(SVG));
    expect(screen.getByText("ELEC PAYD EMO2 FASE CRET")).toBeVisible();

    await user.click(screen.getByRole("button", { name: "Activer la double authentification" }));
    expect(
      await screen.findByText("Saisissez les 6 chiffres affichés par l’application."),
    ).toBeVisible();
    expect(attempts).toBe(0);

    await user.type(screen.getByLabelText("Code à 6 chiffres"), "000000");
    await user.click(screen.getByRole("button", { name: "Activer la double authentification" }));
    const alert = await screen.findByRole("alert");
    expect(alert).toHaveTextContent("Code incorrect.");
    expect(alert).toHaveTextContent("Référence : ref-2fa-1");

    await user.clear(screen.getByLabelText("Code à 6 chiffres"));
    await user.type(screen.getByLabelText("Code à 6 chiffres"), "123 456");
    await user.click(screen.getByRole("button", { name: "Activer la double authentification" }));

    const list = await screen.findByRole("list", { name: "Codes de secours" });
    expect(list.querySelectorAll("li")).toHaveLength(10);
    expect(list).toHaveTextContent("AB0D-EF0H");
    const proceed = screen.getByRole("button", { name: "Continuer" });
    expect(proceed).toBeDisabled();
    expect(screen.getByRole("button", { name: "Télécharger (.txt)" })).toBeVisible();
    await user.click(screen.getByLabelText("J’ai mis ces codes en lieu sûr."));
    await user.click(proceed);
    await waitFor(() => expect(navigation.replace).toHaveBeenCalledWith("/utilisateurs"));
  });
});

it("API injoignable : message et référence", async () => {
  server.use(
    http.get(apiUrl("/me/2fa"), () =>
      apiError(502, "API_UNREACHABLE", "L'API ElecPay ne répond pas.", { requestId: "ref-502" }),
    ),
  );
  renderWithProviders(<TwoFactorSetup />);
  const alert = await screen.findByRole("alert");
  expect(alert).toHaveTextContent("L'API ElecPay ne répond pas.");
  expect(alert).toHaveTextContent("Référence : ref-502");
});
