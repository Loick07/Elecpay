import type { NextConfig } from "next";

// Back-office ElecPay. Toutes les données sont lues DANS LE NAVIGATEUR, à travers le relais
// `/api/v1/*` (aucune donnée rendue ni mise en cache côté serveur). « Cache Components » reste donc
// désactivé : la politique de sécurité (CSP) à nonce exige un rendu dynamique de chaque page, alors
// que Cache Components prérend une coque statique au moment de la construction. À revoir pour
// Next 17, où l'option deviendra obligatoire (voir JOURNAL.md).
const nextConfig: NextConfig = {
  reactStrictMode: true,
  poweredByHeader: false, // pas d'en-tête « X-Powered-By: Next.js »
  turbopack: {
    rules: {
      "*.css": {
        loaders: ["@tailwindcss/turbopack"],
        as: "*.css",
      },
    },
  },
};

export default nextConfig;
