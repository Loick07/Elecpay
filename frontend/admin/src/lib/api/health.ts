// État de l'API et MODE DÉMO (`GET /health`, à travers le relais). Le badge « Mode démo » n'est
// affiché que si l'API le confirme (`demo_mode`) : jamais une donnée simulée présentée comme réelle.
import { useQuery } from "@tanstack/react-query";

import { api, unwrap } from "./client";

export const healthQueryKey = ["health"] as const;

export function useHealth() {
  return useQuery({
    queryKey: healthQueryKey,
    queryFn: () => unwrap(api.GET("/api/v1/health")),
  });
}
