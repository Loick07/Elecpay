"use client";

// Accueil PROVISOIRE de l'équipe (A1) : remplacé par le tableau de bord en A9 (DECOUPAGES.md, DA2.4).
import { ApiStatus } from "@/components/api-status";
import { Alert } from "@/components/ui/alert";
import { TeamPage } from "@/features/shell/team-page";
import { firstName, useTeamMember } from "@/lib/session/session-context";

export function HomePlaceholder() {
  const member = useTeamMember();
  return (
    <TeamPage title="Tableau de bord">
      <p className="text-ink">Bonjour {firstName(member.full_name)}.</p>
      <Alert tone="info">
        Le tableau de bord arrive à l’étape A9 ; les écrans de l’équipe arrivent de A3 à A8 (menu à
        gauche).
      </Alert>
      <ApiStatus />
    </TeamPage>
  );
}
