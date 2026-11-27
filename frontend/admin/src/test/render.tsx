// Rendu d'un composant avec les mêmes fournisseurs que l'application (lectures TanStack Query),
// un client de lectures NEUF par test (aucune donnée partagée entre deux tests).
import { QueryClientProvider } from "@tanstack/react-query";
import { render } from "@testing-library/react";
import type { ReactElement } from "react";

import { createQueryClient } from "@/lib/api/query-client";

export function renderWithProviders(ui: ReactElement) {
  const queryClient = createQueryClient();
  return render(<QueryClientProvider client={queryClient}>{ui}</QueryClientProvider>);
}
