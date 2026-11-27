"use client";

// Le membre de l'équipe connecté, fourni par SessionGate à toutes les pages de l'équipe.
import { createContext, useContext } from "react";

import type { components } from "@/lib/api/schema";

export type TeamMember = components["schemas"]["UserPublic"];

export const meQueryKey = ["me"] as const;

export const ROLE_LABELS: Record<string, string> = {
  support: "Support",
  admin: "Admin",
  super_admin: "Super admin",
  client: "Client",
};

export const SessionContext = createContext<TeamMember | null>(null);

export function useTeamMember(): TeamMember {
  const member = useContext(SessionContext);
  if (!member) throw new Error("useTeamMember : à utiliser sous SessionGate.");
  return member;
}

/** Prénom pour « Bonjour … » : le premier mot du nom. */
export function firstName(fullName: string): string {
  return fullName.trim().split(/\s+/)[0] ?? fullName;
}
