import type { Metadata } from "next";
import { Suspense } from "react";

import { LoginScreen } from "@/features/auth/login-screen";

export const metadata: Metadata = { title: "Connexion" };

export default function ConnexionPage() {
  return (
    <Suspense>
      <LoginScreen />
    </Suspense>
  );
}
