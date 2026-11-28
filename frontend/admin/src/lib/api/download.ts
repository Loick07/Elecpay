// Fichiers de l'API (exports CSV) : le relais transmet le flux et `Content-Disposition` ; le
// navigateur enregistre le fichier sous le nom donné par l'API. Mêmes erreurs que `unwrap` (message
// et référence ; API injoignable → erreur réseau).
import { api } from "./client";
import { ApiError, apiErrorFrom, networkError } from "./errors";

export type ExportPath = "/api/v1/admin/users/export.csv" | "/api/v1/admin/bills/export.csv";

/** Nom du fichier dans `Content-Disposition` (`filename="…"` ou `filename*=UTF-8''…`). */
export function filenameFrom(header: string | null): string | null {
  if (!header) return null;
  const encoded = /filename\*=UTF-8''([^;]+)/i.exec(header)?.[1];
  if (encoded) {
    try {
      return decodeURIComponent(encoded.trim());
    } catch {
      return null;
    }
  }
  return /filename="?([^";]+)"?/i.exec(header)?.[1]?.trim() ?? null;
}

export async function fetchFile(
  path: ExportPath,
  query: Record<string, string | undefined>,
): Promise<{ blob: Blob; filename: string | null }> {
  let result: { data?: Blob; error?: unknown; response: Response };
  try {
    // Les paramètres des deux exports diffèrent ; l'API valide chacun d'eux.
    result = (await api.GET(path, { params: { query } as never, parseAs: "blob" })) as {
      data?: Blob;
      error?: unknown;
      response: Response;
    };
  } catch (error) {
    if (error instanceof ApiError) throw error;
    throw networkError();
  }
  if (!result.response.ok || result.error !== undefined || !result.data) {
    throw apiErrorFrom(result.response, result.error);
  }
  return {
    blob: result.data,
    filename: filenameFrom(result.response.headers.get("content-disposition")),
  };
}

/** Enregistre le fichier dans le navigateur (lien temporaire). */
export function saveFile(blob: Blob, filename: string): void {
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = filename;
  link.click();
  URL.revokeObjectURL(url);
}
