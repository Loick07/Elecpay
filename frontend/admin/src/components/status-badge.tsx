// Badge de statut (`frontend/design/components/StatusBadge`) : couleur, icône ET mot, mêmes
// libellés que l'application (`src/lib/status/statuses.ts`). Hauteur 26 px, rayon `radius-sm`,
// fond doux, texte `*-text` (≥ 4,5:1). Le jaune n'est jamais une couleur de statut ; un paiement
// sans réponse est « Vérification en cours », jamais « Échouée ».
// Comme les alertes, la teinte douce est posée sur une base BLANCHE opaque : sur le fond de page,
// « À payer » tombait à 4,49:1 (vu par axe le 28/11/2026 sur l'écran d'essai).
import { type StatusStyle, toneClasses } from "@/lib/status/statuses";
import { cn } from "@/lib/utils";

export function StatusBadge({ status, className }: { status: StatusStyle; className?: string }) {
  const tone = toneClasses[status.tone];
  const Icon = status.icon;
  return (
    <span className={cn("bg-surface-1 inline-flex rounded-sm", className)}>
      <span
        className={cn(
          "inline-flex h-[26px] items-center gap-1.5 rounded-sm px-2.5 text-xs leading-4 font-semibold whitespace-nowrap",
          tone.background,
          tone.text,
        )}
      >
        <Icon
          aria-hidden="true"
          strokeWidth={2.25}
          className={cn("size-3.5 shrink-0", tone.icon)}
        />
        {status.label}
      </span>
    </span>
  );
}
