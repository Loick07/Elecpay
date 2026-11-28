import type { Metadata } from "next";

import { ComingSoon } from "@/features/shell/coming-soon";

// Écran construit à l'étape A6 (PLAN.md) ; d'ici là, une page d'attente dans le cadre.
export const metadata: Metadata = { title: "Compteurs" };

export default function CompteursPage() {
  return <ComingSoon title="Compteurs" step="A6" />;
}
