"use client";

import { DemoBadge } from "@/components/demo-badge";
import { describeError } from "@/lib/api/errors";
import { useHealth } from "@/lib/api/health";

/**
 * État de l'API vu à travers le relais (page provisoire de A0) : badge « Mode démo » si l'API le
 * confirme, sinon rien ; API injoignable : le message du relais, sa référence et « Réessayer ».
 */
export function ApiStatus() {
  const health = useHealth();

  if (health.isPending) {
    return (
      <p role="status" className="text-ink-muted">
        Connexion à l’API ElecPay…
      </p>
    );
  }

  if (health.isError) {
    const { message, reference } = describeError(health.error);
    return (
      <div role="alert" className="bg-error-soft rounded-md p-4">
        <p className="text-error-text">{message}</p>
        {reference ? (
          <p className="text-reference text-ink-muted font-mono">Référence : {reference}</p>
        ) : null}
        <button
          type="button"
          onClick={() => void health.refetch()}
          className="text-admin-label text-ink mt-3 rounded-sm underline"
        >
          Réessayer
        </button>
      </div>
    );
  }

  return (
    <div className="flex items-center gap-3">
      {health.data.demo_mode ? <DemoBadge /> : null}
      <p>API ElecPay : {health.data.status === "ok" ? "disponible" : "dégradée"}</p>
    </div>
  );
}
