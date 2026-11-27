// En-têtes de sécurité du back-office (PLAN.md, A0.5). La politique de contenu (CSP) est tirée à
// chaque page par `src/proxy.ts` (nonce aléatoire) ; les autres en-têtes sont fixes
// (`next.config.ts`, toutes les réponses, relais compris).
//
// Choix :
// - scripts : seulement ceux du back-office portant le nonce de la page (`'strict-dynamic'`) ;
// - `connect-src 'self'` : le navigateur ne parle QU'AU domaine du back-office (le relais) ;
// - `style-src-attr 'unsafe-inline'` : React écrit des attributs `style="…"` dans le HTML ; ils ne
//   peuvent pas exécuter de code (les balises <style> restent soumises au nonce) ;
// - images : le domaine et `data:` (QR code de la double authentification, A1) ;
// - jamais dans un cadre (`frame-ancestors 'none'`), formulaires vers le domaine seulement ;
// - `upgrade-insecure-requests` seulement en HTTPS (sinon le serveur local de test, en HTTP, casserait).

export type CspOptions = { nonce: string; development: boolean; https: boolean };

export function contentSecurityPolicy({ nonce, development, https }: CspOptions): string {
  const directives = [
    "default-src 'self'",
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'${development ? " 'unsafe-eval'" : ""}`,
    development ? "style-src 'self' 'unsafe-inline'" : `style-src 'self' 'nonce-${nonce}'`,
    "style-src-attr 'unsafe-inline'",
    "img-src 'self' data: blob:",
    "font-src 'self'",
    development ? "connect-src 'self' ws:" : "connect-src 'self'",
    "object-src 'none'",
    "base-uri 'none'",
    "form-action 'self'",
    "frame-ancestors 'none'",
  ];
  if (https) directives.push("upgrade-insecure-requests");
  return directives.join("; ");
}

/** Nonce aléatoire d'une page (128 bits, base64). */
export function newNonce(): string {
  return btoa(String.fromCharCode(...crypto.getRandomValues(new Uint8Array(16))));
}

/** En-têtes fixes, sur toutes les réponses. */
export const SECURITY_HEADERS: ReadonlyArray<{ key: string; value: string }> = [
  { key: "X-Content-Type-Options", value: "nosniff" },
  { key: "X-Frame-Options", value: "DENY" },
  { key: "Referrer-Policy", value: "no-referrer" },
  {
    key: "Permissions-Policy",
    value: "camera=(), microphone=(), geolocation=(), payment=(), usb=()",
  },
  { key: "Cross-Origin-Opener-Policy", value: "same-origin" },
  { key: "Cross-Origin-Resource-Policy", value: "same-origin" },
  { key: "Strict-Transport-Security", value: "max-age=31536000; includeSubDomains" },
  { key: "X-Robots-Tag", value: "noindex, nofollow" },
];
