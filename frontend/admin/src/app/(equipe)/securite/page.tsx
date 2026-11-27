import type { Metadata } from "next";
import { Suspense } from "react";

import { TwoFactorSetup } from "@/features/security/two-factor-setup";

export const metadata: Metadata = { title: "Sécurité" };

export default function SecuritePage() {
  return (
    <Suspense>
      <TwoFactorSetup />
    </Suspense>
  );
}
