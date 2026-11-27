"use client";

// Page de l'équipe avec un en-tête PROVISOIRE (A1) : logo, badge « Mode démo », membre connecté et
// son rôle, « Mon compte », « Se déconnecter ». Le cadre complet (menu latéral bleu nuit, maquette
// Menu.dc.html) le remplace en A2.
import { LogOut, Zap } from "lucide-react";
import Link from "next/link";
import type { ReactNode } from "react";

import { HealthDemoBadge } from "@/components/demo-badge";
import { Button } from "@/components/ui/button";
import { ROLE_LABELS, useTeamMember } from "@/lib/session/session-context";
import { useLogout } from "@/lib/session/use-logout";

export function TeamPage({ title, children }: { title: string; children: ReactNode }) {
  const member = useTeamMember();
  const logout = useLogout();
  return (
    <div className="flex min-h-screen flex-col">
      <header className="border-line bg-surface-1 flex flex-wrap items-center justify-between gap-4 border-b px-6 py-3">
        <Link href="/" className="flex items-center gap-3 rounded-md">
          <span className="bg-volt grid size-9 place-items-center rounded-md">
            <Zap aria-hidden="true" className="text-on-volt size-5" />
          </span>
          <span className="text-admin-body text-ink font-semibold">ElecPay · Back-office</span>
        </Link>
        <div className="flex flex-wrap items-center gap-4">
          <HealthDemoBadge />
          <p className="text-admin-body text-ink">
            {member.full_name}{" "}
            <span className="text-ink-muted">· {ROLE_LABELS[member.role] ?? member.role}</span>
          </p>
          <Link
            href="/mon-compte"
            className="text-admin-body text-volt-text underline-offset-4 hover:underline"
          >
            Mon compte
          </Link>
          <Button
            icon={<LogOut aria-hidden="true" className="size-4" />}
            loading={logout.isPending}
            loadingLabel="Déconnexion…"
            onClick={() => logout.mutate("deconnexion")}
          >
            Se déconnecter
          </Button>
        </div>
      </header>
      <main className="mx-auto flex w-full max-w-5xl flex-col gap-6 p-8">
        <h1 className="text-admin-h1 text-ink">{title}</h1>
        {children}
      </main>
    </div>
  );
}
