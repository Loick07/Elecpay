import { describe, expect, it } from "vitest";

import {
  ApiError,
  apiErrorFrom,
  describeError,
  fieldErrors,
  NETWORK_ERROR,
  networkError,
} from "./errors";

const response = (status: number, requestId?: string) =>
  new Response(null, { status, headers: requestId ? { "x-request-id": requestId } : {} });

describe("erreur au format commun de l’API", () => {
  it("code, message de l’API, détails et référence", () => {
    const error = apiErrorFrom(response(403, "ref-12345678"), {
      error: {
        code: "FORBIDDEN",
        message: "Action réservée aux administrateurs.",
        details: { x: 1 },
      },
    });
    expect(error).toBeInstanceOf(ApiError);
    expect(error).toMatchObject({
      status: 403,
      code: "FORBIDDEN",
      message: "Action réservée aux administrateurs.",
      details: { x: 1 },
      requestId: "ref-12345678",
    });
  });

  it("détails absents : objet vide", () => {
    const error = apiErrorFrom(response(401), {
      error: { code: "NOT_AUTHENTICATED", message: "Authentification requise." },
    });
    expect(error.details).toEqual({});
    expect(error.requestId).toBeNull();
  });

  it.each([
    [500, "Le serveur ElecPay a rencontré un problème. Réessayez dans un instant."],
    [502, "Le serveur ElecPay a rencontré un problème. Réessayez dans un instant."],
    [404, "Élément introuvable."],
    [400, "La demande n'a pas abouti."],
  ])("corps illisible (%i) : message clair, jamais le corps brut", (status, message) => {
    const error = apiErrorFrom(response(status), "<html>Erreur</html>");
    expect(error.code).toBe(`HTTP_${status}`);
    expect(error.message).toBe(message);
  });
});

it("réseau coupé : message clair, code NETWORK", () => {
  expect(networkError()).toMatchObject({ status: 0, code: NETWORK_ERROR });
  expect(networkError().message).toMatch(/Connexion impossible/);
});

it("erreurs par champ (422) : rangées par nom de champ, premier message gardé", () => {
  const error = new ApiError({
    status: 422,
    code: "VALIDATION_ERROR",
    message: "Données invalides.",
    details: {
      fields: [
        { field: "body.reason", message: "Au moins 10 caractères.", type: "string_too_short" },
        { field: "body.reason", message: "Second message.", type: "x" },
        { field: "query.page", message: "Doit être positif.", type: "x" },
        { field: 3, message: "ignoré" },
        "ignoré",
      ],
    },
  });
  expect(fieldErrors(error)).toEqual({
    reason: "Au moins 10 caractères.",
    page: "Doit être positif.",
  });
  expect(fieldErrors(new ApiError({ status: 400, code: "X", message: "x" }))).toEqual({});
});

it("ce qu’un écran affiche : message et référence ; erreur inconnue : message générique", () => {
  expect(
    describeError(
      new ApiError({ status: 409, code: "X", message: "Conflit.", requestId: "ref-1" }),
    ),
  ).toEqual({ message: "Conflit.", reference: "ref-1" });
  expect(describeError(new Error("détail technique"))).toEqual({
    message: "Une erreur inattendue est survenue. Réessayez.",
    reference: null,
  });
});

it.each(["NOT_AUTHENTICATED", "TOKEN_EXPIRED", "TOKEN_INVALID", "REFRESH_TOKEN_REUSED"])(
  "session terminée (401 %s) : le texte de la fenêtre « Session expirée », sans référence",
  (code) => {
    expect(
      describeError(
        new ApiError({ status: 401, code, message: "Authentification requise.", requestId: "r" }),
      ),
    ).toEqual({
      message: "Votre session a expiré. Reconnectez-vous pour continuer.",
      reference: null,
    });
  },
);

it("autres 401 (mauvais identifiants, code faux) : leur propre message", () => {
  for (const code of ["INVALID_CREDENTIALS", "TWO_FACTOR_CODE_INVALID"]) {
    expect(
      describeError(new ApiError({ status: 401, code, message: "Refusé.", requestId: "r" })),
    ).toEqual({ message: "Refusé.", reference: "r" });
  }
});
