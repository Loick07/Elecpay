"use client";

// Page et filtres d'une liste DANS L'ADRESSE (PLAN.md, A2.3 : « tri et filtres dans l'adresse ») :
// un lien copié rouvre la même vue, « Précédent » du navigateur revient au filtre d'avant.
// - un filtre qui change ramène à la page 1 ; la page 1 et les filtres vides ne sont pas écrits ;
// - aucune route d'administration ne propose de tri : l'ordre est celui du serveur (un tri sur la
//   seule page affichée tromperait).
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { useCallback, useMemo } from "react";

export const PAGE_SIZE = 20;

/** Lit `page` (≥ 1, 1 si absente ou illisible) et les filtres demandés (`""` si absents). */
export function readListParams<K extends string>(
  params: URLSearchParams,
  keys: readonly K[],
): { page: number; filters: Record<K, string> } {
  const raw = Number.parseInt(params.get("page") ?? "", 10);
  const page = Number.isFinite(raw) && raw >= 1 ? raw : 1;
  const filters = Object.fromEntries(keys.map((key) => [key, params.get(key) ?? ""])) as Record<
    K,
    string
  >;
  return { page, filters };
}

/** Nouvelle adresse après un changement (filtres ou page). */
export function nextQuery(
  current: URLSearchParams,
  changes: Record<string, string | number | null | undefined>,
): string {
  const next = new URLSearchParams(current.toString());
  for (const [key, value] of Object.entries(changes)) {
    if (value === null || value === undefined || value === "") next.delete(key);
    else next.set(key, String(value));
  }
  if (!("page" in changes)) next.delete("page");
  if (next.get("page") === "1") next.delete("page");
  return next.toString();
}

export function useListParams<K extends string>(keys: readonly K[]) {
  const params = useSearchParams();
  const router = useRouter();
  const pathname = usePathname();
  // `keys` est une constante du module appelant : une clé de cache stable.
  const signature = keys.join(",");
  const { page, filters } = useMemo(
    () => readListParams(params, signature.split(",") as unknown as readonly K[]),
    [params, signature],
  );
  const update = useCallback(
    (changes: Partial<Record<K | "page", string | number | null>>) => {
      const query = nextQuery(params, changes);
      router.replace(query ? `${pathname}?${query}` : pathname, { scroll: false });
    },
    [params, pathname, router],
  );
  return { page, filters, update };
}
