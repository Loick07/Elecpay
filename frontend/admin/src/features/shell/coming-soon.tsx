// Rubrique du menu dont l'écran n'est pas encore construit (étapes A3 à A8 du back-office) : un
// bloc clair plutôt qu'une page introuvable. Chaque page est remplacée par son écran à son étape.
import { Construction } from "lucide-react";

import { StateBlock } from "@/components/ui/state-block";

import { TeamPage } from "./team-page";

export function ComingSoon({ title, step }: { title: string; step: string }) {
  return (
    <TeamPage title={title}>
      <StateBlock
        icon={Construction}
        title="Écran en préparation"
        description={`Cet écran arrive à l’étape ${step} du back-office.`}
      />
    </TeamPage>
  );
}
