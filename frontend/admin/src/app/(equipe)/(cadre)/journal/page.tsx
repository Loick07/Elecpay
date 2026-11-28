import type { Metadata } from "next";

import { ComingSoon } from "@/features/shell/coming-soon";

// Écran construit à l'étape A8 (PLAN.md) ; d'ici là, une page d'attente dans le cadre.
export const metadata: Metadata = { title: "Journal d’activité" };

export default function JournalPage() {
  // Réservé aux admins (`view_audit_log`) : le support voit « Accès refusé ».
  return <ComingSoon title="Journal d’activité" step="A8" capability="view_audit_log" />;
}
