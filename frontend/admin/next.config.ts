import type { NextConfig } from "next";
import { PHASE_DEVELOPMENT_SERVER, PHASE_PRODUCTION_SERVER } from "next/constants";

import { apiOrigin } from "./src/lib/relay/config";
import { SECURITY_HEADERS } from "./src/lib/security/headers";

// Back-office ElecPay. Toutes les données sont lues DANS LE NAVIGATEUR, à travers le relais
// `/api/v1/*` (aucune donnée rendue ni mise en cache côté serveur). « Cache Components » reste donc
// désactivé : la politique de sécurité (CSP) à nonce exige un rendu dynamique de chaque page, alors
// que Cache Components prérend une coque statique au moment de la construction. À revoir pour
// Next 17, où l'option deviendra obligatoire (voir JOURNAL.md).
const nextConfig: NextConfig = {
  reactStrictMode: true,
  poweredByHeader: false, // pas d'en-tête « X-Powered-By: Next.js »
  // En-têtes de sécurité fixes, sur toutes les réponses (la CSP, elle, est posée par src/proxy.ts).
  async headers() {
    return [{ source: "/:path*", headers: [...SECURITY_HEADERS] }];
  },
  turbopack: {
    rules: {
      "*.css": {
        loaders: ["@tailwindcss/turbopack"],
        as: "*.css",
      },
    },
  },
};

/**
 * Au DÉMARRAGE d'un serveur (`next dev`, `next start`), la cible du relais est vérifiée : manquante,
 * ou visant l'API publique (port 8000), le serveur refuse de démarrer (tests/startup-guard.test.ts).
 * La construction (`next build`) n'en a pas besoin : l'adresse est lue à l'exécution.
 */
export default function config(phase: string): NextConfig {
  if (phase === PHASE_DEVELOPMENT_SERVER || phase === PHASE_PRODUCTION_SERVER) {
    apiOrigin(
      process.env.ELECPAY_API_URL,
      phase === PHASE_DEVELOPMENT_SERVER ? "development" : "production",
    );
  }
  return nextConfig;
}
