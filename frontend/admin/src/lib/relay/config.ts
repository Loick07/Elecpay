// Adresse de l'API ElecPay vue par le RELAIS (côté serveur uniquement : jamais `NEXT_PUBLIC_`, le
// navigateur ne la connaît pas). Variable `ELECPAY_API_URL` : l'origine seule, sans chemin
// (ex. `https://omnivore-pardon-sixth.ngrok-free.dev`) ; le relais ajoute `/api/v1`.

/** API locale de démonstration, en développement seulement (`npm run dev`). */
export const DEV_API_URL = "http://127.0.0.1:8000";

const LOCAL_HOSTS = new Set(["127.0.0.1", "localhost", "[::1]"]);

/** Configuration refusée : le relais ne démarre pas (message lisible dans les journaux). */
export class RelayConfigError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "RelayConfigError";
  }
}

/**
 * Origine de l'API à partir de `ELECPAY_API_URL`. HTTPS obligatoire, sauf vers ce PC (API locale de
 * démonstration ou de test) ; ni chemin, ni paramètres, ni identifiants dans l'adresse.
 */
export function apiOrigin(value: string | undefined, nodeEnv: string | undefined): string {
  if (!value) {
    if (nodeEnv === "production") {
      throw new RelayConfigError("ELECPAY_API_URL manquante : adresse de l'API ElecPay requise.");
    }
    return DEV_API_URL;
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
  if (url.protocol !== "https:" && !(url.protocol === "http:" && local)) {
    throw new RelayConfigError("ELECPAY_API_URL : HTTPS obligatoire (HTTP seulement vers ce PC).");
  }
  return url.origin;
}
