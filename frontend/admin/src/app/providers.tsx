"use client";

import "@/lib/zod-config";

import { QueryClientProvider } from "@tanstack/react-query";
import { type ReactNode, useState } from "react";

import { createQueryClient } from "@/lib/api/query-client";
import { shareNonceWithStyleInjectors } from "@/lib/security/nonce";

// Dès le chargement du code de la page, avant toute fenêtre : le nonce pour les <style> injectés.
shareNonceWithStyleInjectors();

/** Fournisseurs communs côté navigateur (un seul client de lectures par onglet). */
export function Providers({ children }: { children: ReactNode }) {
  const [queryClient] = useState(createQueryClient);
  return <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>;
}
