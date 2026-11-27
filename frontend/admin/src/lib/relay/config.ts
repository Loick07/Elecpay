// Adresse de l'API ElecPay vue par le RELAIS (côté serveur uniquement : jamais `NEXT_PUBLIC_`, le
// navigateur ne la connaît pas). Variable `ELECPAY_API_URL` : l'origine seule, sans chemin ; le
// relais ajoute `/api/v1`.
//
// Règles (décision de Loick du 27/11/2026, avant A1) :
// - AUCUNE valeur par défaut : un oubli de réglage refuse de démarrer (next.config.ts) ;
// - jamais le port 8000 de ce PC : c'est l'API PUBLIQUE (base `elecpay_public`, exposée par ngrok) ;
// - en développement et en test : seulement une API de CE PC (API de développement, port 8001,
//   base `elecpay_admin_dev`, `tool/dev-api.ps1`) ; jamais l'API publique, même par son adresse ngrok ;
// - en production : HTTPS (l'API publique par ngrok), ou HTTP vers ce PC pour les tests de bout en
//   bout (`next start`, port 8010).

/** API de développement du back-office (`tool/dev-api.ps1`). */
export const DEV_API_URL = "http://127.0.0.1:8001";

/** Port de l'API PUBLIQUE sur ce PC (`backend/deploy/public.ps1`) : jamais visé par le back-office local. */
export const PUBLIC_API_PORT = "8000";

const LOCAL_HOSTS = new Set(["127.0.0.1", "localhost", "[::1]"]);

/** Configuration refusée : le serveur ne démarre pas, le relais répond 500 (message dans les journaux). */
export class RelayConfigError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "RelayConfigError";
  }
}

const HOW_TO =
  "En développement : lancer l'API de développement (.\\tool\\dev-api.ps1, port 8001, base " +
  "elecpay_admin_dev) et mettre ELECPAY_API_URL=http://127.0.0.1:8001 dans frontend/admin/.env.local " +
  "(modèle : env.local.example).";

/** Origine de l'API à partir de `ELECPAY_API_URL` ; lève `RelayConfigError` si elle est refusée. */
export function apiOrigin(value: string | undefined, nodeEnv: string | undefined): string {
  if (!value) {
    throw new RelayConfigError(`ELECPAY_API_URL manquante : aucune API par défaut. ${HOW_TO}`);
  }
  let url: URL;
  try {
    url = new URL(value);
  } catch {
    throw new RelayConfigError(`ELECPAY_API_URL invalide : « ${value} ».`);
  }
  if (url.username || url.password || url.search || url.hash || url.pathname !== "/") {
    throw new RelayConfigError(
      "ELECPAY_API_URL : l'origine seule est attendue (ex. https://api.exemple.cg), sans chemin.",
    );
  }
  const local = LOCAL_HOSTS.has(url.hostname);
  if (local && url.port === PUBLIC_API_PORT) {
    throw new RelayConfigError(
      `ELECPAY_API_URL vise le port ${PUBLIC_API_PORT} de ce PC : c'est l'API PUBLIQUE (base ` +
        `elecpay_public), jamais visée par le back-office local. ${HOW_TO}`,
    );
  }
  if (nodeEnv !== "production" && !local) {
    throw new RelayConfigError(
      `ELECPAY_API_URL : en développement et en test, seulement une API de ce PC (jamais l'API ` +
        `publique ni une API distante). ${HOW_TO}`,
    );
  }
  if (url.protocol !== "https:" && !(url.protocol === "http:" && local)) {
    throw new RelayConfigError("ELECPAY_API_URL : HTTPS obligatoire (HTTP seulement vers ce PC).");
  }
  return url.origin;
}
