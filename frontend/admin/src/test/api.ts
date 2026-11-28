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

type Role = UserPublic["role"];
type MyPermissions = components["schemas"]["MyPermissions"];

/** Matrice du backend (`backend/app/modules/admin/permissions.py`) : niveau exigé par capacité. */
const CAPABILITY_LEVELS: [string, string, Role[]][] = [
  ["view", "Consulter clients, factures, transactions", ["support", "admin", "super_admin"]],
  ["view_audit_log", "Consulter le journal", ["admin", "super_admin"]],
  ["toggle_account", "Désactiver / réactiver un compte", ["admin", "super_admin"]],
  ["cancel_bill", "Annuler une facture (motif)", ["admin", "super_admin"]],
  ["recheck_transaction", "Relancer la vérification d'une transaction", ["admin", "super_admin"]],
  ["send_announcement", "Envoyer une annonce", ["admin", "super_admin"]],
  ["edit_tariffs", "Modifier les tarifs", ["super_admin"]],
  ["manage_team", "Attribuer des rôles, inviter un membre", ["super_admin"]],
  ["force_payment_success", "Marquer une transaction comme réussie", []],
];

const LEVELS: Record<Role, MyPermissions["levels"]> = {
  client: [],
  support: ["staff"],
  admin: ["staff", "admin"],
  super_admin: ["staff", "admin", "super_admin"],
};

/** Réponse de `GET /admin/permissions` pour un rôle (comme le backend). */
export function permissionsFor(role: Role): MyPermissions {
  return {
    role,
    levels: LEVELS[role],
    capabilities: CAPABILITY_LEVELS.map(([key, label, roles]) => ({
      key,
      label,
      roles,
      allowed: roles.includes(role),
    })),
  };
}

/** Ce que lit le cadre (menu) : droits du rôle et pastilles (anomalies, transactions en attente). */
export function shellHandlers(role: Role, counts: { anomalies?: number; pending?: number } = {}) {
  return [
    http.get(apiUrl("/admin/permissions"), () => HttpResponse.json(permissionsFor(role))),
    http.get(apiUrl("/admin/meters"), () =>
      HttpResponse.json({
        items: [],
        total: 0,
        page: 1,
        size: 1,
        counters: { open_anomalies: counts.anomalies ?? 0 },
      }),
    ),
    http.get(apiUrl("/admin/transactions"), () =>
      HttpResponse.json({ items: [], total: counts.pending ?? 0, page: 1, size: 1 }),
    ),
  ];
}
