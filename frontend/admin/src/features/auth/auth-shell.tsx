// Cadre des écrans de connexion (sans maquette : construits selon la charte, décision DA1.1) :
// carte centrée sur le fond de la charte, logo ElecPay, badge « Mode démo » (si l'API le confirme),
// titre de l'étape, et la mention « Réservé à l'équipe ElecPay ».
import { Zap } from "lucide-react";
import type { ReactNode } from "react";

import { HealthDemoBadge } from "@/components/demo-badge";

export function AuthShell({
  title,
  description,
  children,
}: {
  title: string;
  description?: ReactNode;
  children: ReactNode;
}) {
  return (
    <main className="flex min-h-screen items-center justify-center p-6">
      <div className="w-full max-w-md">
        <div className="mb-6 flex items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <div className="bg-volt grid size-11 place-items-center rounded-md">
              <Zap aria-hidden="true" className="text-on-volt size-6" />
            </div>
            <p className="flex flex-col">
              <span className="text-admin-body text-ink font-semibold">ElecPay</span>
              <span className="text-admin-label text-ink-muted">Back-office</span>
            </p>
          </div>
          <HealthDemoBadge />
        </div>
        <section
          aria-labelledby="titre-etape"
          className="bg-surface-1 shadow-card flex flex-col gap-6 rounded-lg p-8"
        >
          <header className="flex flex-col gap-1">
            <h1 id="titre-etape" className="text-admin-h1 text-ink">
              {title}
            </h1>
            {description ? <p className="text-ink-muted">{description}</p> : null}
          </header>
          {children}
        </section>
        <p className="text-admin-label text-ink-muted mt-4 text-center">
          Réservé à l’équipe ElecPay.
        </p>
      </div>
    </main>
  );
}
