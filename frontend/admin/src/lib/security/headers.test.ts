// @vitest-environment node
import { describe, expect, it } from "vitest";

import { contentSecurityPolicy, newNonce, SECURITY_HEADERS } from "./headers";

const directives = (csp: string) =>
  new Map(
    csp.split("; ").map((directive) => {
      const [name = "", ...values] = directive.split(" ");
      return [name, values.join(" ")];
    }),
  );

describe("politique de contenu (CSP), en production", () => {
  const csp = directives(
    contentSecurityPolicy({ nonce: "abc123", development: false, https: true }),
  );

  it("scripts : seulement le nonce de la page, ni eval ni script en ligne", () => {
    expect(csp.get("script-src")).toBe("'self' 'nonce-abc123' 'strict-dynamic'");
    expect(csp.get("style-src")).toBe("'self' 'nonce-abc123'");
  });

  it("le navigateur ne parle qu’au domaine du back-office", () => {
    expect(csp.get("connect-src")).toBe("'self'");
    expect(csp.get("default-src")).toBe("'self'");
  });

  it("jamais dans un cadre, aucun objet, base et formulaires verrouillés", () => {
    expect(csp.get("frame-ancestors")).toBe("'none'");
    expect(csp.get("object-src")).toBe("'none'");
    expect(csp.get("base-uri")).toBe("'none'");
    expect(csp.get("form-action")).toBe("'self'");
    expect(csp.has("upgrade-insecure-requests")).toBe(true);
  });

  it("aucun 'unsafe-eval' ni 'unsafe-inline' pour les scripts et les balises <style>", () => {
    const text = contentSecurityPolicy({ nonce: "n", development: false, https: true });
    expect(text).not.toContain("unsafe-eval");
    expect(directives(text).get("script-src")).not.toContain("unsafe-inline");
    expect(directives(text).get("style-src")).not.toContain("unsafe-inline");
  });
});

it("HTTP (serveur local de test) : pas de passage forcé en HTTPS", () => {
  const csp = contentSecurityPolicy({ nonce: "n", development: false, https: false });
  expect(directives(csp).has("upgrade-insecure-requests")).toBe(false);
});

it("développement : eval et rechargement à chaud permis, seulement là", () => {
  const csp = directives(contentSecurityPolicy({ nonce: "n", development: true, https: false }));
  expect(csp.get("script-src")).toContain("'unsafe-eval'");
  expect(csp.get("connect-src")).toBe("'self' ws:");
});

it("nonce : 128 bits, différent à chaque page", () => {
  const nonces = new Set(Array.from({ length: 50 }, newNonce));
  expect(nonces.size).toBe(50);
  for (const nonce of nonces) expect(atob(nonce)).toHaveLength(16);
});

it("en-têtes fixes : ni cadre, ni indexation, ni fuite de l’adresse d’origine", () => {
  const headers = new Map(SECURITY_HEADERS.map(({ key, value }) => [key, value]));
  expect(headers.get("X-Frame-Options")).toBe("DENY");
  expect(headers.get("X-Content-Type-Options")).toBe("nosniff");
  expect(headers.get("Referrer-Policy")).toBe("no-referrer");
  expect(headers.get("X-Robots-Tag")).toBe("noindex, nofollow");
  expect(headers.get("Strict-Transport-Security")).toMatch(/^max-age=31536000/);
  expect(headers.get("Permissions-Policy")).toContain("camera=()");
});
