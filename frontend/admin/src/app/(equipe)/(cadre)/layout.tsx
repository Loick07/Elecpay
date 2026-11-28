import type { ReactNode } from "react";

import { AppShell } from "@/features/shell/app-shell";

// Pages de l'équipe DANS le cadre (menu latéral). La page Sécurité reste hors du cadre : un admin
// sans double authentification n'a encore accès à aucun écran.
export default function CadreLayout({ children }: { children: ReactNode }) {
  return <AppShell>{children}</AppShell>;
}
