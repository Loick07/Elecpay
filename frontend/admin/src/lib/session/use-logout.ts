"use client";

// Déconnexion : `POST /auth/web/logout` (efface les cookies), mémoire des lectures vidée, AUTRES
// onglets prévenus (ils reviennent à la connexion), puis retour à la connexion avec la raison.
// Même si l'API ne répond pas, la page se déconnecte (rien ne reste affiché).
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { useRouter } from "next/navigation";

import { api, unwrap } from "@/lib/api/client";

import { announceSession } from "./events";

export type LogoutReason = "deconnexion" | "inactivite" | "mot-de-passe";

export function useLogout() {
  const router = useRouter();
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (reason: LogoutReason) => {
      await unwrap(api.POST("/api/v1/auth/web/logout")).catch(() => undefined);
      return reason;
    },
    onSettled: (_data, _error, reason) => {
      queryClient.clear();
      announceSession("deconnexion");
      router.replace(`/connexion?raison=${reason}`);
    },
  });
}
