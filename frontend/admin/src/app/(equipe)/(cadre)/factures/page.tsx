import type { Metadata } from "next";

import { ComingSoon } from "@/features/shell/coming-soon";

// Écran construit à l'étape A4 (PLAN.md) ; d'ici là, une page d'attente dans le cadre.
export const metadata: Metadata = { title: "Factures" };

export default function FacturesPage() {
  return <ComingSoon title="Factures" step="A4" />;
}
