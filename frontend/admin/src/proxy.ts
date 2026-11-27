// Proxy de Next (anciennement « middleware ») : politique de contenu (CSP) avec un nonce NEUF pour
// chaque page. Next lit le nonce dans l'en-tête de la requête et l'applique à ses propres scripts
// (node_modules/next/dist/docs/01-app/02-guides/content-security-policy.md). Pas sur le relais
// `/api/*` ni sur les fichiers statiques (aucun HTML).
import { type NextRequest, NextResponse } from "next/server";

import { contentSecurityPolicy, newNonce } from "@/lib/security/headers";

export function proxy(request: NextRequest) {
  const nonce = newNonce();
  const https =
    request.nextUrl.protocol === "https:" || request.headers.get("x-forwarded-proto") === "https";
  const csp = contentSecurityPolicy({
    nonce,
    development: process.env.NODE_ENV === "development",
    https,
  });
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-nonce", nonce);
  requestHeaders.set("Content-Security-Policy", csp);
  const response = NextResponse.next({ request: { headers: requestHeaders } });
  response.headers.set("Content-Security-Policy", csp);
  return response;
}

export const config = {
  matcher: [
    {
      source: "/((?!api/|_next/static|_next/image|favicon.ico|icon.png).*)",
      missing: [
        { type: "header", key: "next-router-prefetch" },
        { type: "header", key: "purpose", value: "prefetch" },
      ],
    },
  ],
};
