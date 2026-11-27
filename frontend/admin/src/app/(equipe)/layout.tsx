import type { ReactNode } from "react";

import { SessionGate } from "@/features/session/session-gate";

// Toutes les pages de l'équipe : session obligatoire (SessionGate), double authentification exigée
// là où il faut. Les pages publiques (connexion, mot de passe oublié) sont hors de ce groupe.
export default function EquipeLayout({ children }: { children: ReactNode }) {
  return <SessionGate>{children}</SessionGate>;
}
