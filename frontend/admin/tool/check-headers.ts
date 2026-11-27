// Contrôle des en-têtes de sécurité sur le VRAI serveur de production (`next build` puis `next start`),
// en CI et en local : `node tool/check-headers.ts [adresse]` (défaut http://localhost:3000).
// Vérifie : CSP avec un nonce neuf à chaque page, nonce porté par CHAQUE <script> de la page,
// en-têtes fixes sur les pages ET sur le relais, aucun « X-Powered-By ».
import { SECURITY_HEADERS } from "../src/lib/security/headers.ts";

const base = process.argv[2] ?? "http://localhost:3000";
const problems: string[] = [];

function check(condition: boolean, problem: string): void {
  if (!condition) problems.push(problem);
}

function checkFixedHeaders(response: Response, where: string): void {
  for (const { key, value } of SECURITY_HEADERS) {
    check(response.headers.get(key) === value, `${where} : en-tête ${key} absent ou différent`);
  }
  check(!response.headers.has("x-powered-by"), `${where} : en-tête X-Powered-By présent`);
}

async function page(): Promise<{ nonce: string | null; html: string; response: Response }> {
  const response = await fetch(`${base}/`);
  const csp = response.headers.get("content-security-policy") ?? "";
  const nonce = /'nonce-([^']+)'/.exec(csp)?.[1] ?? null;
  return { nonce, html: await response.text(), response };
}

const first = await page();
const second = await page();
check(first.response.status === 200, `page : statut ${first.response.status}`);
checkFixedHeaders(first.response, "page");
check(first.nonce !== null, "page : CSP sans nonce");
check(first.nonce !== second.nonce, "page : le nonce ne change pas d'une page à l'autre");
const csp = first.response.headers.get("content-security-policy") ?? "";
check(csp.includes("frame-ancestors 'none'"), "page : CSP sans frame-ancestors 'none'");
check(csp.includes("connect-src 'self'"), "page : CSP sans connect-src 'self'");
check(!csp.includes("unsafe-eval"), "page : CSP avec 'unsafe-eval' (mode développement ?)");
const scripts = [...first.html.matchAll(/<script\b[^>]*>/g)].map((m) => m[0]);
check(scripts.length > 0, "page : aucune balise <script> trouvée");
for (const tag of scripts) {
  check(tag.includes(`nonce="${first.nonce}"`), `page : <script> sans le nonce : ${tag.slice(0, 80)}`);
}

const relay = await fetch(`${base}/api/v1/health`);
checkFixedHeaders(relay, "relais");
check(
  (relay.headers.get("content-type") ?? "").includes("application/json"),
  `relais : réponse non JSON (${relay.status})`,
);

if (problems.length > 0) {
  console.error(`En-têtes de sécurité : ${problems.length} problème(s)\n- ${problems.join("\n- ")}`);
  process.exit(1);
}
console.warn(
  `En-têtes de sécurité : conformes (${scripts.length} scripts avec nonce, relais : ${relay.status}).`,
);
