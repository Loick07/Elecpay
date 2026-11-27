// Réglages communs des lectures (décision DA2.3) : les quotas de l'offre gratuite de ngrok et le
// chemin jusqu'au PC comptent.
// - données gardées 30 s, relues au retour sur l'onglet ;
// - AUCUNE interrogation périodique par défaut (la seule exception, le détail d'une transaction en
//   attente, se déclare dans son écran, en A5) ;
// - aucune relance automatique : l'écran affiche l'erreur et un bouton « Réessayer ».
import { QueryClient } from "@tanstack/react-query";

export const STALE_TIME_MS = 30_000;

export function createQueryClient(): QueryClient {
  return new QueryClient({
    defaultOptions: {
      queries: {
        staleTime: STALE_TIME_MS,
        refetchOnWindowFocus: true,
        refetchInterval: false,
        retry: false,
      },
      mutations: { retry: false },
    },
  });
}
