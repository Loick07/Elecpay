// Réponses simulées de l'API pour les tests (MSW) : adresses du relais, erreurs au format commun,
// profils et santé de l'API.
import { http, HttpResponse } from "msw";

import type { components } from "@/lib/api/schema";

import { TEST_ORIGIN } from "./msw-server";

/** Adresse d'une route de l'API vue par le navigateur des tests (relais du même domaine). */
export const apiUrl = (path: string) => `${TEST_ORIGIN}/api/v1${path}`;

/** Erreur au format commun de l'API. */
export function apiError(
  status: number,
  code: string,
  message: string,
  options: { requestId?: string; details?: Record<string, unknown> } = {},
) {
  return HttpResponse.json(
    { error: { code, message, details: options.details ?? {} } },
    { status, headers: options.requestId ? { "x-request-id": options.requestId } : {} },
  );
}

export const healthHandler = (demoMode = true) =>
  http.get(apiUrl("/health"), () =>
    HttpResponse.json({ status: "ok", database: "ok", demo_mode: demoMode }),
  );

type UserPublic = components["schemas"]["UserPublic"];

export function teamMember(overrides: Partial<UserPublic> = {}): UserPublic {
  return {
    id: 2,
    full_name: "Admin Démo",
    phone: "+242060000002",
    email: null,
    email_verified_at: null,
    is_active: true,
    last_login_at: "2026-11-27T08:00:00Z",
    created_at: "2026-11-01T08:00:00Z",
    role: "admin",
    ...overrides,
  };
}

/** Réponse de connexion réussie (session ouverte par cookies). */
export function webSession(overrides: Partial<UserPublic> = {}) {
  return {
    access_expires_at: "2026-11-27T09:15:00Z",
    refresh_expires_at: "2026-12-27T09:00:00Z",
    user: teamMember(overrides),
  };
}
