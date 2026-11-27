"use client";

// Garde des pages de l'équipe (groupe `(equipe)`) : le profil (`GET /me`) est lu au chargement.
// La garde est côté navigateur (le cookie d'accès n'est envoyé qu'à /api/v1, pas aux pages) ; la
// vraie protection reste le serveur, qui refuse toute donnée sans session.
// - sans session → connexion, avec la page demandée (et « session expirée » s'il y en avait une) ;
// - double authentification obligatoire et pas encore activée → page Sécurité ;
// - API injoignable → message clair, référence, « Réessayer ».
import { useQuery } from "@tanstack/react-query";
import { usePathname, useRouter } from "next/navigation";
import { type ReactNode, useEffect } from "react";

import { Alert } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { twoFactorStatusKey } from "@/features/security/two-factor-setup";
import { api, CSRF_COOKIE, readCookie, unwrap } from "@/lib/api/client";
import { ApiError, describeError } from "@/lib/api/errors";
import { loginUrl } from "@/lib/session/return-path";
import { meQueryKey, SessionContext } from "@/lib/session/session-context";

import { SessionWatcher } from "./session-watcher";

export const SECURITY_PATH = "/securite";

export function SessionGate({ children }: { children: ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const me = useQuery({ queryKey: meQueryKey, queryFn: () => unwrap(api.GET("/api/v1/me")) });
  const twoFactor = useQuery({
    queryKey: twoFactorStatusKey,
    queryFn: () => unwrap(api.GET("/api/v1/me/2fa")),
    enabled: me.isSuccess,
  });
  const unauthenticated = me.error instanceof ApiError && me.error.status === 401;
  const mustSetUp =
    twoFactor.data?.required === true && !twoFactor.data.enabled && pathname !== SECURITY_PATH;

  useEffect(() => {
    if (!unauthenticated) return;
    // « Session expirée » seulement s'il y avait une session (cookie anti-CSRF présent).
    const hadSession = readCookie(CSRF_COOKIE, document.cookie) !== null;
    router.replace(loginUrl(pathname, hadSession ? "session" : undefined));
  }, [unauthenticated, pathname, router]);

  useEffect(() => {
    if (mustSetUp) router.replace(`${SECURITY_PATH}?retour=${encodeURIComponent(pathname)}`);
  }, [mustSetUp, pathname, router]);

  if (me.isError && !unauthenticated) {
    const { message, reference } = describeError(me.error);
    return (
      <main className="mx-auto flex min-h-screen max-w-md flex-col justify-center gap-4 p-6">
        <Alert tone="error" reference={reference}>
          {message}
        </Alert>
        <Button onClick={() => void me.refetch()}>Réessayer</Button>
      </main>
    );
  }
  if (!me.isSuccess || unauthenticated || mustSetUp || twoFactor.isPending) {
    return (
      <main className="flex min-h-screen items-center justify-center">
        <p role="status" className="text-ink-muted">
          Chargement de votre session…
        </p>
      </main>
    );
  }
  return (
    <SessionContext.Provider value={me.data}>
      <SessionWatcher />
      {children}
    </SessionContext.Provider>
  );
}
