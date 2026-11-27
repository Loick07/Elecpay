"use client";

// Badge « Mode démo » de la charte (`frontend/design/components/DemoBadge`, classe `.ep-demo`) :
// pointillés `current-text`, point plein, texte en capitales ; il informe sans alarmer.
import { useHealth } from "@/lib/api/health";

/** Le badge, seulement si l'API confirme le mode démo (`GET /health`) ; rien sinon. */
export function HealthDemoBadge() {
  const health = useHealth();
  return health.data?.demo_mode ? <DemoBadge /> : null;
}

export function DemoBadge() {
  return (
    <span
      className="border-current-text text-overline text-current-text inline-flex h-6 items-center gap-1.5 rounded-full border border-dashed px-2.5 tracking-[0.06em] uppercase"
      title="Données simulées : aucune donnée réelle, aucun débit réel."
    >
      <span aria-hidden="true" className="bg-current-text size-1.5 rounded-full" />
      Mode démo
    </span>
  );
}
