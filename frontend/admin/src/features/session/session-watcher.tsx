"use client";

// Veilleur de la session (sous SessionGate) :
// - « session expirée » (rafraîchissement refusé) → fenêtre « Se reconnecter » (texte de la charte) ;
// - déconnexion dans un AUTRE onglet → retour à la connexion ; connexion dans un autre onglet →
//   la fenêtre se ferme et les données sont relues ;
// - double authentification requise → page Sécurité ;
// - 30 min sans activité → avertissement 1 min avant, puis déconnexion (DA1.2).
import { useQueryClient } from "@tanstack/react-query";
import { usePathname, useRouter } from "next/navigation";
import { useEffect, useState } from "react";

import { AlertDialog } from "@/components/ui/alert-dialog";
import { Button } from "@/components/ui/button";
import { formatCountdown } from "@/lib/format";
import { onSessionEvent } from "@/lib/session/events";
import { useInactivity } from "@/lib/session/inactivity";
import { loginUrl } from "@/lib/session/return-path";
import { useLogout } from "@/lib/session/use-logout";

export function SessionWatcher() {
  const router = useRouter();
  const pathname = usePathname();
  const queryClient = useQueryClient();
  const logout = useLogout();
  const [expired, setExpired] = useState(false);

  useEffect(
    () =>
      onSessionEvent((event, fromOtherTab) => {
        if (event === "expiree") setExpired(true);
        if (event === "deconnexion" && fromOtherTab) {
          queryClient.clear();
          router.replace("/connexion?raison=deconnexion");
        }
        if (event === "connexion" && fromOtherTab) {
          setExpired(false);
          void queryClient.invalidateQueries();
        }
        if (event === "double-authentification-requise" && pathname !== "/securite") {
          router.replace(`/securite?retour=${encodeURIComponent(pathname)}`);
        }
      }),
    [pathname, queryClient, router],
  );

  const inactivity = useInactivity({ onTimeout: () => logout.mutate("inactivite") });

  return (
    <>
      <AlertDialog
        open={expired}
        title="Session expirée"
        description="Votre session a expiré. Reconnectez-vous pour continuer."
        actions={
          <Button variant="primary" onClick={() => router.replace(loginUrl(pathname, "session"))}>
            Se reconnecter
          </Button>
        }
      />
      <AlertDialog
        open={inactivity.warning && !expired}
        title="Toujours là ?"
        description={`Sans activité, vous serez déconnecté dans ${formatCountdown(inactivity.remainingMs)}.`}
        actions={
          <>
            <Button onClick={() => logout.mutate("deconnexion")}>Se déconnecter</Button>
            <Button variant="primary" onClick={inactivity.stayActive}>
              Rester connecté
            </Button>
          </>
        }
      />
    </>
  );
}
