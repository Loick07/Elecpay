import type { Metadata } from "next";

import { ComingSoon } from "@/features/shell/coming-soon";

// Écran construit à l'étape A3 (PLAN.md) ; d'ici là, une page d'attente dans le cadre.
export const metadata: Metadata = { title: "Utilisateurs" };

export default function UtilisateursPage() {
  return <ComingSoon title="Utilisateurs" step="A3" />;
}
