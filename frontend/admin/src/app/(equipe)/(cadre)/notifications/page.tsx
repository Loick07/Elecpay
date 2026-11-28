import type { Metadata } from "next";

import { ComingSoon } from "@/features/shell/coming-soon";

// Écran construit à l'étape A7 (PLAN.md) ; d'ici là, une page d'attente dans le cadre.
export const metadata: Metadata = { title: "Notifications" };

export default function NotificationsPage() {
  return <ComingSoon title="Notifications" step="A7" />;
}
