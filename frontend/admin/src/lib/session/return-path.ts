// Page où revenir après la connexion (`?retour=…`) : UNIQUEMENT un chemin du back-office lui-même.
// Une adresse d'un autre site (« //pirate.example », « https://… », « /\pirate.example ») serait une
// redirection ouverte : elle est remplacée par la page d'accueil.
const BASE = "http://back-office.invalid";

export function safeReturnPath(raw: string | null | undefined): string {
  if (!raw || !raw.startsWith("/") || raw.startsWith("//") || raw.includes("\\")) return "/";
  let url: URL;
  try {
    url = new URL(raw, BASE);
  } catch {
    return "/";
  }
  if (url.origin !== BASE) return "/";
  const path = `${url.pathname}${url.search}${url.hash}`;
  // Jamais retour vers les pages de connexion elles-mêmes.
  if (url.pathname === "/connexion" || url.pathname.startsWith("/mot-de-passe-oublie")) return "/";
  return path;
}

/** Adresse de la page de connexion, avec la page où revenir et la raison affichée. */
export function loginUrl(returnPath?: string | null, reason?: string): string {
  const params = new URLSearchParams();
  const target = safeReturnPath(returnPath);
  if (target !== "/") params.set("retour", target);
  if (reason) params.set("raison", reason);
  const query = params.toString();
  return query ? `/connexion?${query}` : "/connexion";
}
