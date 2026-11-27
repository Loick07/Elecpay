// Client typé de l'API (types générés depuis le contrat, `schema.d.ts`). Dans le navigateur, il
// appelle le RELAIS du même domaine (`/api/v1/…`) : jamais l'adresse de l'API directement.
//
// - Requête qui modifie : en-tête `X-CSRF-Token` = cookie `elecpay_csrf`, relu à CHAQUE requête
//   (il change à chaque connexion et à chaque rafraîchissement de session).
// - Session (A1.4, `src/lib/session/`) : 401 d'un jeton expiré → UN rafraîchissement puis la
//   requête est rejouée une fois ; sinon événement « session expirée ».
// - `unwrap` : les données, ou une `ApiError` (message de l'API + référence).
// - Aucune autre relance automatique (DA2.3).
import createClient, { type Middleware } from "openapi-fetch";

import { announceSession, type SessionEvent } from "@/lib/session/events";
import { createRefresher, refreshSession } from "@/lib/session/refresh";
import { sessionMiddleware } from "@/lib/session/session-middleware";

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

type LockRequester = Parameters<typeof createRefresher>[0]["locks"];

export function createApiClient(
  options: {
    baseUrl?: string;
    fetch?: typeof fetch;
    readCookies?: () => string;
    /** Événements de session (par défaut : ceux du back-office, dans cet onglet). */
    announce?: (event: SessionEvent) => void;
    /** Verrou entre onglets (par défaut : Web Locks du navigateur, s'il existe). */
    locks?: LockRequester;
  } = {},
) {
  const baseUrl = options.baseUrl ?? globalThis.location?.origin ?? "";
  // `fetch` pris AU MOMENT de l'appel (et non à la création) : l'API simulée des tests l'intercepte.
  const fetchFn = options.fetch ?? ((request: Request) => globalThis.fetch(request));
  // Hors navigateur (rendu côté serveur, tests Node), pas de `document` : aucun cookie lisible.
  const readCookies = options.readCookies ?? (() => globalThis.document?.cookie ?? "");
  const readCsrf = () => readCookie(CSRF_COOKIE, readCookies());
  const client = createClient<paths>({
    // Navigateur : le domaine de la page (le relais) ; rendu côté serveur : aucun appel.
    baseUrl,
    credentials: "same-origin",
    fetch: fetchFn,
  });
  client.use(csrfMiddleware(readCookies));
  client.use(
    sessionMiddleware({
      readCsrf,
      announce: options.announce ?? ((event) => announceSession(event, { otherTabs: false })),
      refresher: createRefresher({
        refresh: () => refreshSession(fetchFn, baseUrl, readCsrf()),
        readCsrf,
        locks: "locks" in options ? options.locks : globalThis.navigator?.locks,
      }),
    }),
  );
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
