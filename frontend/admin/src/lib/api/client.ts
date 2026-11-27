// Client typé de l'API (types générés depuis le contrat, `schema.d.ts`). Dans le navigateur, il
// appelle le RELAIS du même domaine (`/api/v1/…`) : jamais l'adresse de l'API directement.
//
// - Requête qui modifie : en-tête `X-CSRF-Token` = cookie `elecpay_csrf`, relu à CHAQUE requête
//   (il change à chaque connexion et à chaque rafraîchissement de session).
// - `unwrap` : les données, ou une `ApiError` (message de l'API + référence).
// - Aucune relance automatique ici (DA2.3) ; le rafraîchissement de session arrive en A1.4.
import createClient, { type Middleware } from "openapi-fetch";

import { ApiError, apiErrorFrom, networkError } from "./errors";
import type { paths } from "./schema";

export const CSRF_COOKIE = "elecpay_csrf";
export const CSRF_HEADER = "X-CSRF-Token";
const SAFE_METHODS = new Set(["GET", "HEAD", "OPTIONS"]);

/** Valeur d'un cookie lisible par la page (seul le jeton anti-CSRF l'est : la session est httpOnly). */
export function readCookie(name: string, cookies: string): string | null {
  for (const part of cookies.split(";")) {
    const [key, ...value] = part.trim().split("=");
    if (key === name) return decodeURIComponent(value.join("="));
  }
  return null;
}

export function csrfMiddleware(readCookies: () => string): Middleware {
  return {
    onRequest({ request }) {
      if (SAFE_METHODS.has(request.method)) return undefined;
      const token = readCookie(CSRF_COOKIE, readCookies());
      if (token) request.headers.set(CSRF_HEADER, token);
      return request;
    },
  };
}

export function createApiClient(
  options: { baseUrl?: string; fetch?: typeof fetch; readCookies?: () => string } = {},
) {
  const client = createClient<paths>({
    baseUrl: options.baseUrl ?? "",
    credentials: "same-origin",
    ...(options.fetch ? { fetch: options.fetch } : {}),
  });
  client.use(csrfMiddleware(options.readCookies ?? (() => document.cookie)));
  return client;
}

export type ApiClient = ReturnType<typeof createApiClient>;

/** Client du navigateur (relais du même domaine). */
export const api = createApiClient();

type FetchResult<T> = { data?: T; error?: unknown; response: Response };

/** Données d'une réponse réussie, sinon `ApiError` (réseau coupé compris). */
export async function unwrap<T>(call: Promise<FetchResult<T>>): Promise<T> {
  let result: FetchResult<T>;
  try {
    result = await call;
  } catch (error) {
    if (error instanceof ApiError) throw error;
    throw networkError();
  }
  if (!result.response.ok || result.error !== undefined) {
    throw apiErrorFrom(result.response, result.error);
  }
  return result.data as T;
}
