"use client";

// « Mis à jour à 10:42 » + « Actualiser » (décision DA2.3) : aucune interrogation périodique (quotas
// de ngrok), l'équipe relit quand elle le veut. L'heure est celle de Brazzaville.
import { RefreshCw } from "lucide-react";

import { Button } from "@/components/ui/button";
import { formatTime } from "@/lib/format";
import { cn } from "@/lib/utils";

export function RefreshControl({
  updatedAt,
  refreshing,
  onRefresh,
}: {
  /** `dataUpdatedAt` de TanStack Query (millisecondes) ; 0 : jamais lu. */
  updatedAt: number;
  refreshing: boolean;
  onRefresh: () => void;
}) {
  return (
    <div className="flex flex-wrap items-center gap-3">
      {updatedAt > 0 ? (
        <span className="text-ink-muted text-[13px] leading-5">
          Mis à jour à {formatTime(new Date(updatedAt))}
        </span>
      ) : null}
      <Button
        size="sm"
        onClick={onRefresh}
        disabled={refreshing}
        icon={
          <RefreshCw
            aria-hidden="true"
            className={cn("size-4", refreshing && "animate-spin motion-reduce:animate-none")}
          />
        }
      >
        {refreshing ? "Actualisation…" : "Actualiser"}
      </Button>
    </div>
  );
}
