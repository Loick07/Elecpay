// Rafraîchissement de la session (cookies) : UN SEUL à la fois, dans l'onglet ET entre les onglets.
// Un jeton de rafraîchissement déjà utilisé ferme toute la session (401 REFRESH_TOKEN_REUSED,
// backend/docs/AUTHENTIFICATION.md) : deux rafraîchissements concurrents la feraient tomber.
// - dans l'onglet : les requêtes refusées en même temps attendent le même rafraîchissement ;
// - entre onglets : verrou du navigateur (Web Locks, `elecpay-refresh`) ;
// - si le jeton anti-CSRF a changé depuis l'envoi de la requête, un autre rafraîchissement vient
//   d'avoir lieu (le cookie `elecpay_csrf` est renouvelé à chaque fois) : rien à refaire, on rejoue.

export type RefreshOutcome = "refreshed" | "expired" | "unreachable";

export type Refresher = (csrfAtRequest: string | null) => Promise<RefreshOutcome>;

type LockRequester = {
  request: <T>(name: string, callback: () => Promise<T>) => Promise<T>;
};

export const REFRESH_LOCK = "elecpay-refresh";

export function createRefresher(deps: {
  refresh: () => Promise<RefreshOutcome>;
  readCsrf: () => string | null;
  locks?: LockRequester | undefined;
}): Refresher {
  let inFlight: Promise<RefreshOutcome> | null = null;

  const attempt = async (csrfAtRequest: string | null): Promise<RefreshOutcome> => {
    const current = deps.readCsrf();
    if (csrfAtRequest !== null && current !== null && current !== csrfAtRequest) return "refreshed";
    return deps.refresh();
  };

  return (csrfAtRequest) => {
    inFlight ??= (
      deps.locks
        ? deps.locks.request(REFRESH_LOCK, () => attempt(csrfAtRequest))
        : attempt(csrfAtRequest)
    ).finally(() => {
      inFlight = null;
    });
    return inFlight;
  };
}

/** `POST /auth/web/refresh` (cookie de rafraîchissement + jeton anti-CSRF). */
export async function refreshSession(
  fetchFn: (request: Request) => Promise<Response>,
  baseUrl: string,
  csrf: string | null,
): Promise<RefreshOutcome> {
  // Pas de jeton anti-CSRF : aucune session ouverte dans ce navigateur, rien à rafraîchir.
  if (!csrf) return "expired";
  let response: Response;
  try {
    response = await fetchFn(
      new Request(`${baseUrl}/api/v1/auth/web/refresh`, {
        method: "POST",
        credentials: "same-origin",
        headers: csrf ? { "X-CSRF-Token": csrf } : {},
      }),
    );
  } catch {
    return "unreachable";
  }
  if (response.ok) return "refreshed";
  if (response.status === 401 || response.status === 403) return "expired";
  return "unreachable"; // 5xx, relais : l'API ne répond pas, la session n'est pas jugée
}
