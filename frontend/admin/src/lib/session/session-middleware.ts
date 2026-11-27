// Intermédiaire du client de l'API : session expirée et double authentification requise.
// - 401 TOKEN_EXPIRED ou NOT_AUTHENTICATED (le cookie d'accès disparaît du navigateur au bout de
//   15 min) → un rafraîchissement (refresh.ts), puis la requête est REJOUÉE une fois, avec le
//   NOUVEAU jeton anti-CSRF ; refusé → événement « expiree » (la page propose de se reconnecter) ;
//   API injoignable → erreur réseau (jamais « session expirée » à tort) ;
// - 401 TOKEN_INVALID ou REFRESH_TOKEN_REUSED (jeton illisible, réutilisé) → « expiree » ;
// - tout autre 401 est une erreur ORDINAIRE, montrée par l'écran : un code de vérification faux
//   (TWO_FACTOR_CODE_INVALID sur /me/2fa/…) ne ferme pas la session (défaut vu le 27/11/2026) ;
// - 403 TWO_FACTOR_SETUP_REQUIRED → « double-authentification-requise » (page Sécurité) ;
// - les routes /auth/* ne sont jamais rejouées (un 401 y a un sens : mauvais mot de passe…).
import type { Middleware } from "openapi-fetch";

import type { SessionEvent } from "./events";
import type { Refresher } from "./refresh";

const SAFE_METHODS = new Set(["GET", "HEAD", "OPTIONS"]);
/** 401 de session (backend : `NotAuthenticatedError` et ses sous-classes), testés contre le backend. */
export const REFRESHABLE_CODES: ReadonlySet<string> = new Set([
  "TOKEN_EXPIRED",
  "NOT_AUTHENTICATED",
]);
export const SESSION_LOST_CODES: ReadonlySet<string> = new Set([
  "TOKEN_INVALID",
  "REFRESH_TOKEN_REUSED",
]);

async function errorCode(response: Response): Promise<string | null> {
  try {
    const body = (await response.clone().json()) as { error?: { code?: unknown } };
    return typeof body.error?.code === "string" ? body.error.code : null;
  } catch {
    return null;
  }
}

function isAuthRoute(url: string): boolean {
  return new URL(url).pathname.startsWith("/api/v1/auth/");
}

export function sessionMiddleware(deps: {
  refresher: Refresher;
  readCsrf: () => string | null;
  announce: (event: SessionEvent) => void;
}): Middleware {
  const saved = new Map<string, { request: Request; csrf: string | null }>();
  return {
    onRequest({ request, id }) {
      if (!isAuthRoute(request.url)) {
        saved.set(id, { request: request.clone(), csrf: deps.readCsrf() });
      }
      return undefined;
    },
    async onResponse({ response, id, options }) {
      const original = saved.get(id);
      saved.delete(id);
      if (!original) return undefined;
      if (response.status === 403) {
        if ((await errorCode(response)) === "TWO_FACTOR_SETUP_REQUIRED") {
          deps.announce("double-authentification-requise");
        }
        return undefined;
      }
      if (response.status !== 401) return undefined;
      const code = (await errorCode(response)) ?? "";
      if (SESSION_LOST_CODES.has(code)) {
        deps.announce("expiree");
        return undefined;
      }
      if (!REFRESHABLE_CODES.has(code)) return undefined;
      const outcome = await deps.refresher(original.csrf);
      if (outcome === "unreachable") {
        throw new TypeError("Session : l'API ne répond pas (rafraîchissement impossible).");
      }
      if (outcome === "expired") {
        deps.announce("expiree");
        return undefined;
      }
      const replay = original.request.clone();
      const csrf = deps.readCsrf();
      if (csrf && !SAFE_METHODS.has(replay.method)) replay.headers.set("X-CSRF-Token", csrf);
      return options.fetch(replay);
    },
    onError({ id }) {
      saved.delete(id);
      return undefined;
    },
  };
}
