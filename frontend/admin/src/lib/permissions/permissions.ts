"use client";

// Droits du membre connecté (`GET /admin/permissions`) : le back-office MASQUE ce que le membre ne
// peut pas faire (entrées du menu, boutons) ; le serveur refuse de toute façon (403 FORBIDDEN).
// - niveaux : `staff` (support, admin, super admin), `admin` (admin, super admin), `super_admin` ;
// - capacités : la matrice validée (maquettes, A11), mêmes clés que le backend
//   (`backend/app/modules/admin/permissions.py`, vérifiées par `permissions-contract.test.ts`).
//   « Marquer une transaction comme réussie » : JAMAIS, pour personne.
// Tant que les droits ne sont pas lus (ou si la lecture échoue), RIEN n'est permis.
import { useQuery } from "@tanstack/react-query";

import { api, unwrap } from "@/lib/api/client";
import type { components } from "@/lib/api/schema";

export type Level = components["schemas"]["Permission"];
export type MyPermissions = components["schemas"]["MyPermissions"];

export const CAPABILITIES = [
  "view",
  "view_audit_log",
  "toggle_account",
  "cancel_bill",
  "recheck_transaction",
  "send_announcement",
  "edit_tariffs",
  "manage_team",
  "force_payment_success",
] as const;
export type Capability = (typeof CAPABILITIES)[number];

export const permissionsQueryKey = ["admin", "permissions"] as const;

/** Jamais permis, quoi que dise une réponse : aucun bouton « Marquer comme payée » n'existe. */
const NEVER: ReadonlySet<Capability> = new Set(["force_payment_success"]);

/** Ce que permettent des droits lus (fonctions pures, testées rôle par rôle). */
export function rights(permissions: MyPermissions | undefined) {
  return {
    hasLevel: (level: Level) => permissions?.levels.includes(level) ?? false,
    can: (capability: Capability) =>
      !NEVER.has(capability) &&
      (permissions?.capabilities.some((entry) => entry.key === capability && entry.allowed) ??
        false),
  };
}

export function usePermissions() {
  const query = useQuery({
    queryKey: permissionsQueryKey,
    queryFn: () => unwrap(api.GET("/api/v1/admin/permissions")),
  });
  return { query, ready: query.isSuccess, ...rights(query.data) };
}
