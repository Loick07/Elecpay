import type { Metadata } from "next";

import { ForgotPasswordScreen } from "@/features/auth/forgot-password-screen";

export const metadata: Metadata = { title: "Mot de passe oublié ou première connexion" };

export default function MotDePasseOubliePage() {
  return <ForgotPasswordScreen />;
}
