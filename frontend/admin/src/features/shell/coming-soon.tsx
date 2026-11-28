// Rubrique du menu dont l'écran n'est pas encore construit (étapes A3 à A8 du back-office) : un
// bloc clair plutôt qu'une page introuvable. Chaque page est remplacée par son écran à son étape.
import { Construction } from "lucide-react";

import { StateBlock } from "@/components/ui/state-block";
import type { Capability } from "@/lib/permissions/permissions";
import { RequirePermission } from "@/lib/permissions/require-permission";

import { TeamPage } from "./team-page";

/** `capability` : écran réservé (ex. le journal) → « Accès refusé » pour les autres rôles. */
export function ComingSoon({
  title,
  step,
  capability,
}: {
  title: string;
  step: string;
  capability?: Capability;
}) {
  const block = (
    <StateBlock
      icon={Construction}
      title="Écran en préparation"
      description={`Cet écran arrive à l’étape ${step} du back-office.`}
    />
  );
  return (
    <TeamPage title={title}>
      {capability ? <RequirePermission capability={capability}>{block}</RequirePermission> : block}
    </TeamPage>
  );
}
