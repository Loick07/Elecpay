import type { Metadata } from "next";

import { ComingSoon } from "@/features/shell/coming-soon";

// Écran construit à l'étape A5 (PLAN.md) ; d'ici là, une page d'attente dans le cadre.
export const metadata: Metadata = { title: "Transactions" };

export default function TransactionsPage() {
  return <ComingSoon title="Transactions" step="A5" />;
}
