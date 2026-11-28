"use client";

// Garde d'un écran ou d'une partie d'écran selon les droits du membre (`GET /admin/permissions`) :
// - droits en cours de lecture → « Vérification de vos droits… » (rien n'est montré avant) ;
// - lecture impossible → message, référence, « Réessayer » ;
// - droit absent → « Accès refusé » (le serveur refuserait de toute façon, 403).
import type { ReactNode } from "react";

import { AccessDenied, ErrorState } from "@/components/ui/state-block";
import { describeError } from "@/lib/api/errors";

import { type Capability, type Level, usePermissions } from "./permissions";

export function RequirePermission({
  level,
  capability,
  children,
}: {
  level?: Level;
  capability?: Capability;
  children: ReactNode;
}) {
  const permissions = usePermissions();
  if (permissions.query.isPending) {
    return (
      <p role="status" className="text-ink-muted">
        Vérification de vos droits…
      </p>
    );
  }
  if (permissions.query.isError) {
    const { message, reference } = describeError(permissions.query.error);
    return (
      <ErrorState
        message={message}
        reference={reference}
        retrying={permissions.query.isFetching}
        onRetry={() => void permissions.query.refetch()}
      />
    );
  }
  const allowed =
    (level === undefined || permissions.hasLevel(level)) &&
    (capability === undefined || permissions.can(capability));
  return allowed ? children : <AccessDenied />;
}
