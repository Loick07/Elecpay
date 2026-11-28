import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { Suspense } from "react";

import { ComponentLab } from "@/features/lab/component-lab";

// Écran d'essai des composants communs (A2.3) : seulement si le serveur a ELECPAY_ESSAI=1 (posé
// par tool/e2e.ps1 et le job e2e de la CI). Ailleurs, et donc en ligne : page introuvable.
export const metadata: Metadata = { title: "Essai des composants", robots: { index: false } };

export default function EssaiComposantsPage() {
  if (process.env.ELECPAY_ESSAI !== "1") notFound();
  return (
    <Suspense>
      <ComponentLab />
    </Suspense>
  );
}
