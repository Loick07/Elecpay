// Relais `/api/v1/*` du back-office (PLAN.md, « Architecture ») : le navigateur ne parle qu'au
// domaine du back-office ; ce relais, côté serveur, transmet à l'API ElecPay. Les cookies de session
// de l'API (`SameSite=Strict`, `Secure`) sont ainsi posés sur le domaine du back-office : aucun
// cookie tiers, aucun CORS à ouvrir dans le backend.
//
// Règles (testées dans `relay.test.ts`) :
// - seuls quelques préfixes de l'API sont ouverts (`health`, `auth/web`, `auth/password`, `me`,
//   `admin`) ; un segment `.`, `..` ou contenant `/` est refusé : la requête ne peut pas viser
//   autre chose que l'API, ni une autre partie de l'API ;
// - une requête qui MODIFIE doit venir du back-office lui-même (`Origin`, `Sec-Fetch-Site`), en plus
//   du jeton anti-CSRF que vérifie l'API ;
// - en-têtes transmis sur liste blanche, cookies `elecpay_*` seulement ; aucun en-tête d'adresse IP
//   (l'IP réelle passera par un en-tête signé, décision DA11.1, étape A11) ;
// - `ngrok-skip-browser-warning` ajouté (sinon ngrok répond par sa page d'avertissement) ;
// - API injoignable, trop lente ou réponse inattendue : erreur au format commun de l'API
//   (`{"error": {"code", "message", "details"}}`) avec un `X-Request-ID` à citer ;
// - journal : méthode, chemin SANS paramètres, statut, durée, référence ; jamais un cookie, un jeton,
//   un corps de requête ni un numéro de téléphone ;
// - jetons dans le CORPS d'une réponse (`POST /me/password`, pensé pour le mobile) : retirés, le code
//   de la page ne les voit jamais (le back-office n'a que ses cookies httpOnly).

export type RelayLogEntry = {
  method: string;
  path: string;
  status: number;
  durationMs: number;
  requestId: string;
};

export type RelayOptions = {
  /** Origine de l'API (`apiOrigin()` de `config.ts`). */
  apiOrigin: string;
  fetch?: typeof fetch;
  log?: (entry: RelayLogEntry) => void;
  timeoutMs?: number;
  now?: () => number;
};

export const RELAY_TIMEOUT_MS = 25_000;
export const MAX_BODY_BYTES = 1_000_000;

const ALLOWED_METHODS = new Set(["GET", "HEAD", "POST", "PUT", "PATCH", "DELETE"]);
const MUTATING_METHODS = new Set(["POST", "PUT", "PATCH", "DELETE"]);
/** Même règle que le backend (`app/core/logs.py`, `SAFE_REQUEST_ID`). */
const SAFE_REQUEST_ID = /^[A-Za-z0-9._-]{8,64}$/;
const FORWARDED_REQUEST_HEADERS = ["accept", "content-type", "user-agent", "x-csrf-token"];
const RELAYED_RESPONSE_HEADERS = [
  "cache-control",
  "content-disposition",
  "content-type",
  "retry-after",
];
const SESSION_COOKIES = new Set(["elecpay_access", "elecpay_refresh", "elecpay_csrf"]);

/**
 * Routes ouvertes dont la réponse porte des jetons dans son corps (`TokenResponse` du contrat) :
 * liste testée contre `backend/openapi.json` (relay-contract.test.ts).
 */
export const TOKEN_BODY_ROUTES: readonly string[] = ["me/password"];
export const BODY_TOKEN_FIELDS: readonly string[] = ["access_token", "refresh_token"];
const BACKSLASH = String.fromCharCode(92);

/** Préfixes de l'API ouverts au back-office (aucune route réservée à l'application client). */
export function isAllowedPath(segments: readonly string[]): boolean {
  const [first, second] = segments;
  switch (first) {
    case "health":
      return segments.length === 1;
    case "me":
      return true;
    case "admin":
      return segments.length >= 2;
    case "auth":
      return (second === "web" || second === "password") && segments.length >= 3;
    default:
      return false;
  }
}

function isSafeSegment(segment: string): boolean {
  if (segment === "" || segment === "." || segment === "..") return false;
  if (segment.includes("/") || segment.includes(BACKSLASH)) return false;
  return [...segment].every((char) => {
    const code = char.charCodeAt(0);
    return code >= 0x20 && code !== 0x7f;
  });
}

function newRequestId(): string {
  return crypto.randomUUID().replaceAll("-", "");
}

/** Erreur au format commun de l'API. */
export function relayError(
  status: number,
  code: string,
  message: string,
  requestId: string,
): Response {
  return Response.json(
    { error: { code, message, details: {} } },
    { status, headers: { "cache-control": "no-store", "x-request-id": requestId } },
  );
}

/** Une requête qui modifie vient-elle du back-office lui-même ? */
function isSameOrigin(request: Request): boolean {
  const origin = request.headers.get("origin");
  if (!origin) return false;
  const host = request.headers.get("host") ?? new URL(request.url).host;
  let originHost: string;
  try {
    originHost = new URL(origin).host;
  } catch {
    return false;
  }
  const site = request.headers.get("sec-fetch-site");
  return originHost === host && (site === null || site === "same-origin");
}

/** Seulement les cookies de session ElecPay (« Send the backend only what it needs »). */
function sessionCookies(header: string | null): string | null {
  if (!header) return null;
  const kept = header
    .split(";")
    .map((part) => part.trim())
    .filter((part) => SESSION_COOKIES.has(part.split("=", 1)[0] ?? ""));
  return kept.length > 0 ? kept.join("; ") : null;
}

export async function relay(
  request: Request,
  segments: readonly string[],
  options: RelayOptions,
): Promise<Response> {
  const now = options.now ?? Date.now;
  const started = now();
  const incoming = request.headers.get("x-request-id");
  const requestId = incoming && SAFE_REQUEST_ID.test(incoming) ? incoming : newRequestId();
  const method = request.method.toUpperCase();
  const encodedPath = segments.map(encodeURIComponent).join("/");
  const path = `/api/v1/${encodedPath}`;
  const log =
    options.log ??
    ((entry: RelayLogEntry) => {
      console.info(JSON.stringify({ relay: entry }));
    });
  const finish = (response: Response): Response => {
    log({ method, path, status: response.status, durationMs: now() - started, requestId });
    return response;
  };

  if (!ALLOWED_METHODS.has(method)) {
    return finish(relayError(405, "METHOD_NOT_ALLOWED", "Méthode non acceptée.", requestId));
  }
  if (!segments.every(isSafeSegment) || !isAllowedPath(segments)) {
    return finish(relayError(404, "NOT_FOUND", "Adresse inconnue du back-office.", requestId));
  }
  if (MUTATING_METHODS.has(method) && !isSameOrigin(request)) {
    return finish(
      relayError(
        403,
        "ORIGIN_REFUSED",
        "Requête refusée : elle ne vient pas du back-office. Rechargez la page.",
        requestId,
      ),
    );
  }

  const target = new URL(path, options.apiOrigin);
  target.search = new URL(request.url).search;
  if (target.origin !== options.apiOrigin || target.pathname !== path) {
    return finish(relayError(404, "NOT_FOUND", "Adresse inconnue du back-office.", requestId));
  }

  const headers = new Headers();
  for (const name of FORWARDED_REQUEST_HEADERS) {
    const value = request.headers.get(name);
    if (value !== null) headers.set(name, value);
  }
  const cookie = sessionCookies(request.headers.get("cookie"));
  if (cookie) headers.set("cookie", cookie);
  headers.set("x-request-id", requestId);
  headers.set("ngrok-skip-browser-warning", "1");

  let body: ArrayBuffer | undefined;
  if (method !== "GET" && method !== "HEAD") {
    const declared = Number(request.headers.get("content-length") ?? "0");
    if (declared > MAX_BODY_BYTES) {
      return finish(relayError(413, "PAYLOAD_TOO_LARGE", "Données trop volumineuses.", requestId));
    }
    body = await request.arrayBuffer();
    if (body.byteLength > MAX_BODY_BYTES) {
      return finish(relayError(413, "PAYLOAD_TOO_LARGE", "Données trop volumineuses.", requestId));
    }
  }

  let upstream: Response;
  try {
    upstream = await (options.fetch ?? fetch)(target, {
      method,
      headers,
      body,
      redirect: "manual",
      signal: AbortSignal.timeout(options.timeoutMs ?? RELAY_TIMEOUT_MS),
    });
  } catch (error) {
    const timedOut =
      error instanceof Error && (error.name === "TimeoutError" || error.name === "AbortError");
    return finish(
      timedOut
        ? relayError(
            504,
            "API_TIMEOUT",
            "L'API ElecPay met trop de temps à répondre. Réessayez dans un instant.",
            requestId,
          )
        : relayError(
            502,
            "API_UNREACHABLE",
            "L'API ElecPay ne répond pas. Le PC qui l'héberge est peut-être éteint.",
            requestId,
          ),
    );
  }

  // Page d'erreur de ngrok (tunnel fermé : PC éteint, API arrêtée) ou redirection : jamais relayée
  // telle quelle (elle enverrait le navigateur vers un autre domaine).
  if (upstream.headers.has("ngrok-error-code")) {
    await upstream.body?.cancel();
    return finish(
      relayError(
        502,
        "API_UNREACHABLE",
        "L'API ElecPay n'est pas joignable (tunnel fermé). Le PC qui l'héberge est peut-être éteint.",
        requestId,
      ),
    );
  }
  if (upstream.status >= 300 && upstream.status < 400) {
    await upstream.body?.cancel();
    return finish(
      relayError(502, "API_UNEXPECTED", "Réponse inattendue de l'API ElecPay.", requestId),
    );
  }

  const responseHeaders = new Headers();
  for (const name of RELAYED_RESPONSE_HEADERS) {
    const value = upstream.headers.get(name);
    if (value !== null) responseHeaders.set(name, value);
  }
  for (const setCookie of upstream.headers.getSetCookie()) {
    responseHeaders.append("set-cookie", setCookie);
  }
  if (!responseHeaders.has("cache-control")) responseHeaders.set("cache-control", "no-store");
  responseHeaders.set("x-request-id", upstream.headers.get("x-request-id") ?? requestId);
  let responseBody: BodyInit | null = method === "HEAD" ? null : upstream.body;
  if (responseBody !== null && TOKEN_BODY_ROUTES.includes(segments.join("/"))) {
    const cleaned = await withoutTokens(upstream);
    if (cleaned === null) {
      return finish(
        relayError(502, "API_UNEXPECTED", "Réponse inattendue de l'API ElecPay.", requestId),
      );
    }
    responseBody = cleaned;
  }
  return finish(new Response(responseBody, { status: upstream.status, headers: responseHeaders }));
}

/** Corps JSON sans ses jetons ; `null` si le corps n'est pas un objet JSON (jamais relayé tel quel). */
async function withoutTokens(upstream: Response): Promise<string | null> {
  try {
    const data: unknown = JSON.parse(await upstream.text());
    if (typeof data !== "object" || data === null || Array.isArray(data)) return null;
    const kept = Object.fromEntries(
      Object.entries(data).filter(([field]) => !BODY_TOKEN_FIELDS.includes(field)),
    );
    return JSON.stringify(kept);
  } catch {
    return null;
  }
}
