import type { Metadata } from "next";

import { ComingSoon } from "@/features/shell/coming-soon";

// Écran construit à l'étape A8 (PLAN.md) ; d'ici là, une page d'attente dans le cadre.
export const metadata: Metadata = { title: "Paramètres et rôles" };

export default function ParametresPage() {
  return <ComingSoon title="Paramètres et rôles" step="A8" />;
}
