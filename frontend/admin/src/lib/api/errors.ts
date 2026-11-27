// Erreurs de l'API au format commun (`{"error": {"code", "message", "details"}}`,
// `backend/docs/AUTHENTIFICATION.md`). Les messages de l'API sont déjà en français et destinés à
// l'équipe : on les affiche tels quels, avec la référence (`X-Request-ID`) à citer au support.

export type ApiErrorInit = {
  status: number;
  code: string;
  message: string;
  details?: Record<string, unknown>;
  requestId?: string | null;
};

export class ApiError extends Error {
  readonly status: number;
  readonly code: string;
  readonly details: Record<string, unknown>;
  readonly requestId: string | null;

  constructor(init: ApiErrorInit) {
    super(init.message);
    this.name = "ApiError";
    this.status = init.status;
    this.code = init.code;
    this.details = init.details ?? {};
    this.requestId = init.requestId ?? null;
  }
}

/** Code d'une requête qui n'a pas pu partir (pas de réseau, navigateur hors ligne). */
export const NETWORK_ERROR = "NETWORK";

type ErrorBody = { error: { code: string; message: string; details?: Record<string, unknown> } };

function isErrorBody(body: unknown): body is ErrorBody {
  if (typeof body !== "object" || body === null || !("error" in body)) return false;
  const error = (body as { error: unknown }).error;
  return (
    typeof error === "object" &&
    error !== null &&
    typeof (error as { code?: unknown }).code === "string" &&
    typeof (error as { message?: unknown }).message === "string"
  );
}

function defaultMessage(status: number): string {
  if (status >= 500)
    return "Le serveur ElecPay a rencontré un problème. Réessayez dans un instant.";
  if (status === 404) return "Élément introuvable.";
  return "La demande n'a pas abouti.";
}

/** Erreur à partir d'une réponse de l'API (ou du relais), même si son corps n'est pas au format commun. */
export function apiErrorFrom(response: Response, body: unknown): ApiError {
  const requestId = response.headers.get("x-request-id");
  if (isErrorBody(body)) {
    return new ApiError({ status: response.status, requestId, ...body.error });
  }
  return new ApiError({
    status: response.status,
    code: `HTTP_${response.status}`,
    message: defaultMessage(response.status),
    requestId,
  });
}

export function networkError(): ApiError {
  return new ApiError({
    status: 0,
    code: NETWORK_ERROR,
    message: "Connexion impossible au back-office. Vérifiez votre connexion internet.",
  });
}

/**
 * Messages par champ d'une erreur 422 (`details.fields[]` : `{field: "body.reason", message}`),
 * rangés par nom de champ (`reason`).
 */
export function fieldErrors(error: ApiError): Record<string, string> {
  const fields = error.details.fields;
  if (!Array.isArray(fields)) return {};
  const out: Record<string, string> = {};
  for (const item of fields) {
    if (typeof item !== "object" || item === null) continue;
    const { field, message } = item as { field?: unknown; message?: unknown };
    if (typeof field !== "string" || typeof message !== "string") continue;
    const name = field.split(".").at(-1) ?? field;
    out[name] ??= message;
  }
  return out;
}

/** Ce qu'un écran affiche pour une erreur quelconque : un message et, si possible, une référence. */
export function describeError(error: unknown): { message: string; reference: string | null } {
  if (error instanceof ApiError) return { message: error.message, reference: error.requestId };
  return { message: "Une erreur inattendue est survenue. Réessayez.", reference: null };
}
