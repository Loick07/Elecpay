// @vitest-environment node
import { describe, expect, it } from "vitest";

import { apiOrigin, DEV_API_URL, RelayConfigError } from "./config";
import { MAX_BODY_BYTES, relay, type RelayLogEntry } from "./relay";

const API = "https://api.exemple.cg";
const SITE = "http://localhost:3000";

type Call = { url: URL; init: RequestInit };

/** Fausse API : enregistre les appels, répond ce qu'on lui donne (aucun réseau). */
function fakeApi(answer: () => Response | Promise<Response> = () => Response.json({ ok: true })) {
  const calls: Call[] = [];
  const fetch = (async (url: URL, init: RequestInit) => {
    calls.push({ url, init });
    return answer();
  }) as unknown as typeof globalThis.fetch;
  return { calls, fetch };
}

function browserRequest(
  path: string,
  init: RequestInit & { headers?: Record<string, string> } = {},
) {
  return new Request(`${SITE}${path}`, {
    ...init,
    headers: { host: "localhost:3000", ...init.headers },
  });
}

async function run(
  path: string,
  segments: string[],
  init: RequestInit & { headers?: Record<string, string> } = {},
  answer?: () => Response | Promise<Response>,
) {
  const api = fakeApi(answer);
  const logs: RelayLogEntry[] = [];
  const response = await relay(browserRequest(path, init), segments, {
    apiOrigin: API,
    fetch: api.fetch,
    log: (entry) => logs.push(entry),
  });
  return { response, calls: api.calls, logs };
}

const sentHeaders = (call: Call | undefined) => new Headers(call?.init.headers);

describe("chemins ouverts au back-office", () => {
  it.each([
    [["health"]],
    [["me"]],
    [["me", "2fa", "setup"]],
    [["admin", "users"]],
    [["admin", "users", "42"]],
    [["auth", "web", "login"]],
    [["auth", "password", "forgot"]],
  ])("%j : transmis à l’API", async (segments) => {
    const { response, calls } = await run(`/api/v1/${segments.join("/")}`, segments);
    expect(response.status).toBe(200);
    expect(calls[0]?.url.href).toBe(`${API}/api/v1/${segments.join("/")}`);
  });

  it.each([
    [["payments"]],
    [["bills", "12", "pdf"]],
    [["auth", "login"]],
    [["auth", "refresh"]],
    [["admin"]],
    [["health", "x"]],
    [["admin", "..", "payments"]],
    [["admin", "."]],
    [["admin", "users/42"]],
    [["admin", "a\\b"]],
    [["admin", ""]],
  ])("%j : refusé (404), l’API n’est jamais appelée", async (segments) => {
    const { response, calls } = await run("/api/v1/x", segments);
    expect(response.status).toBe(404);
    expect(await response.json()).toEqual({
      error: { code: "NOT_FOUND", message: "Adresse inconnue du back-office.", details: {} },
    });
    expect(calls).toHaveLength(0);
  });

  it("les paramètres de recherche sont transmis ; les segments sont ré-encodés", async () => {
    const { calls } = await run("/api/v1/admin/users?q=06%20123&page=2", ["admin", "users"]);
    expect(calls[0]?.url.href).toBe(`${API}/api/v1/admin/users?q=06%20123&page=2`);
    const encoded = await run("/api/v1/admin/x", ["admin", "a b?c#d"]);
    expect(encoded.calls[0]?.url.pathname).toBe("/api/v1/admin/a%20b%3Fc%23d");
    expect(encoded.calls[0]?.url.search).toBe("");
  });

  it("méthode inconnue : 405", async () => {
    const { response, calls } = await run("/api/v1/health", ["health"], { method: "OPTIONS" });
    expect(response.status).toBe(405);
    expect(calls).toHaveLength(0);
  });
});

describe("en-têtes envoyés à l’API", () => {
  it("liste blanche, cookies ElecPay seulement, en-tête ngrok ajouté", async () => {
    const { calls } = await run("/api/v1/admin/users", ["admin", "users"], {
      headers: {
        accept: "application/json",
        "user-agent": "Mozilla/5.0 (Windows NT 10.0) Firefox/140.0",
        cookie: "elecpay_access=A; _ga=pisteur; elecpay_refresh=R; elecpay_csrf=C; autre=1",
        authorization: "Bearer volé",
        "x-forwarded-for": "6.6.6.6",
        "x-real-ip": "6.6.6.6",
        referer: `${SITE}/utilisateurs`,
        origin: SITE,
      },
    });
    const headers = sentHeaders(calls[0]);
    expect(headers.get("cookie")).toBe("elecpay_access=A; elecpay_refresh=R; elecpay_csrf=C");
    expect(headers.get("user-agent")).toBe("Mozilla/5.0 (Windows NT 10.0) Firefox/140.0");
    expect(headers.get("accept")).toBe("application/json");
    expect(headers.get("ngrok-skip-browser-warning")).toBe("1");
    for (const name of [
      "authorization",
      "x-forwarded-for",
      "x-real-ip",
      "referer",
      "origin",
      "host",
    ]) {
      expect(headers.has(name), name).toBe(false);
    }
    expect(calls[0]?.init.redirect).toBe("manual");
  });

  it("aucun cookie ElecPay : aucun en-tête Cookie", async () => {
    const { calls } = await run("/api/v1/health", ["health"], { headers: { cookie: "_ga=1" } });
    expect(sentHeaders(calls[0]).has("cookie")).toBe(false);
  });

  it("référence : celle du navigateur si elle est sûre, sinon une nouvelle", async () => {
    const kept = await run("/api/v1/health", ["health"], {
      headers: { "x-request-id": "Ref-1234.abc_9" },
    });
    expect(sentHeaders(kept.calls[0]).get("x-request-id")).toBe("Ref-1234.abc_9");
    const replaced = await run("/api/v1/health", ["health"], {
      headers: { "x-request-id": "<script>" },
    });
    expect(sentHeaders(replaced.calls[0]).get("x-request-id")).toMatch(/^[0-9a-f]{32}$/);
  });
});

describe("requêtes qui modifient : seulement depuis le back-office", () => {
  const login = (headers: Record<string, string>) =>
    run("/api/v1/auth/web/login", ["auth", "web", "login"], {
      method: "POST",
      body: JSON.stringify({ phone: "060000002", password: "secret" }),
      headers: { "content-type": "application/json", ...headers },
    });

  it("même origine : transmise avec son corps et le jeton anti-CSRF", async () => {
    const { response, calls } = await login({
      origin: SITE,
      "sec-fetch-site": "same-origin",
      "x-csrf-token": "jeton",
    });
    expect(response.status).toBe(200);
    expect(calls[0]?.init.method).toBe("POST");
    expect(new TextDecoder().decode(calls[0]?.init.body as ArrayBuffer)).toContain("060000002");
    expect(sentHeaders(calls[0]).get("x-csrf-token")).toBe("jeton");
    expect(sentHeaders(calls[0]).get("content-type")).toBe("application/json");
  });

  it.each([
    ["sans Origin", {}],
    ["autre site", { origin: "https://pirate.example" }],
    ["même hôte, autre port", { origin: "http://localhost:4000" }],
    ["Origin illisible", { origin: "null" }],
    ["Sec-Fetch-Site cross-site", { origin: SITE, "sec-fetch-site": "cross-site" }],
    ["Sec-Fetch-Site same-site", { origin: SITE, "sec-fetch-site": "same-site" }],
  ])("%s : 403, rien n’est envoyé", async (_label, headers) => {
    const { response, calls } = await login(headers);
    expect(response.status).toBe(403);
    expect(((await response.json()) as { error: { code: string } }).error.code).toBe(
      "ORIGIN_REFUSED",
    );
    expect(calls).toHaveLength(0);
  });

  it("corps trop volumineux : 413", async () => {
    const { response, calls } = await run(
      "/api/v1/admin/announcements",
      ["admin", "announcements"],
      {
        method: "POST",
        body: "x".repeat(MAX_BODY_BYTES + 1),
        headers: { origin: SITE },
      },
    );
    expect(response.status).toBe(413);
    expect(calls).toHaveLength(0);
  });
});

describe("réponse de l’API renvoyée au navigateur", () => {
  it("cookies de session, type, pièce jointe et référence ; ni compression ni CSP de l’API", async () => {
    const { response } = await run(
      "/api/v1/admin/users/export.csv",
      ["admin", "users", "export.csv"],
      {},
      () => {
        const headers = new Headers({
          "content-type": "text/csv; charset=utf-8",
          "content-disposition": 'attachment; filename="utilisateurs.csv"',
          "content-encoding": "gzip",
          "content-security-policy": "default-src 'none'",
          "x-request-id": "ref-api-12345",
          server: "uvicorn",
        });
        headers.append(
          "set-cookie",
          "elecpay_access=A2; Path=/api/v1; HttpOnly; Secure; SameSite=strict",
        );
        headers.append("set-cookie", "elecpay_csrf=C2; Path=/; Secure; SameSite=strict");
        return new Response("nom;telephone\n", { status: 200, headers });
      },
    );
    expect(response.headers.getSetCookie()).toEqual([
      "elecpay_access=A2; Path=/api/v1; HttpOnly; Secure; SameSite=strict",
      "elecpay_csrf=C2; Path=/; Secure; SameSite=strict",
    ]);
    expect(response.headers.get("content-type")).toBe("text/csv; charset=utf-8");
    expect(response.headers.get("content-disposition")).toBe(
      'attachment; filename="utilisateurs.csv"',
    );
    expect(response.headers.get("x-request-id")).toBe("ref-api-12345");
    expect(response.headers.get("cache-control")).toBe("no-store");
    for (const name of ["content-encoding", "content-security-policy", "server"]) {
      expect(response.headers.has(name), name).toBe(false);
    }
    expect(await response.text()).toBe("nom;telephone\n");
  });

  it("une erreur de l’API (403, 429…) est relayée telle quelle", async () => {
    const { response } = await run("/api/v1/admin/stats", ["admin", "stats"], {}, () =>
      Response.json(
        { error: { code: "TWO_FACTOR_SETUP_REQUIRED", message: "…", details: {} } },
        { status: 403 },
      ),
    );
    expect(response.status).toBe(403);
    expect(((await response.json()) as { error: { code: string } }).error.code).toBe(
      "TWO_FACTOR_SETUP_REQUIRED",
    );
  });
});

describe("API injoignable ou réponse inattendue : message clair au format commun", () => {
  const codeOf = async (response: Response) =>
    ((await response.json()) as { error: { code: string; message: string } }).error;

  it("connexion impossible : 502 API_UNREACHABLE, avec une référence", async () => {
    const { response } = await run("/api/v1/health", ["health"], {}, () => {
      throw new TypeError("fetch failed");
    });
    expect(response.status).toBe(502);
    expect((await codeOf(response)).code).toBe("API_UNREACHABLE");
    expect(response.headers.get("x-request-id")).toMatch(/^[0-9a-f]{32}$/);
  });

  it("délai dépassé : 504 API_TIMEOUT", async () => {
    const { response } = await run("/api/v1/health", ["health"], {}, () => {
      throw new DOMException("trop long", "TimeoutError");
    });
    expect(response.status).toBe(504);
    expect((await codeOf(response)).code).toBe("API_TIMEOUT");
  });

  it("page d’erreur de ngrok (tunnel fermé) : 502, jamais la page HTML", async () => {
    const { response } = await run(
      "/api/v1/health",
      ["health"],
      {},
      () =>
        new Response("<html>ERR_NGROK_3200</html>", {
          status: 404,
          headers: { "content-type": "text/html", "ngrok-error-code": "ERR_NGROK_3200" },
        }),
    );
    expect(response.status).toBe(502);
    expect((await codeOf(response)).message).toContain("tunnel fermé");
  });

  it("redirection : 502, jamais suivie ni relayée", async () => {
    const { response } = await run(
      "/api/v1/health",
      ["health"],
      {},
      () => new Response(null, { status: 307, headers: { location: "https://ailleurs.example/" } }),
    );
    expect(response.status).toBe(502);
    expect(response.headers.has("location")).toBe(false);
  });
});

it("journal : méthode, chemin sans paramètres, statut ; jamais de cookie ni de recherche", async () => {
  const { logs } = await run("/api/v1/admin/users?q=061234567", ["admin", "users"], {
    headers: { cookie: "elecpay_access=SECRET" },
  });
  expect(logs).toHaveLength(1);
  expect(logs[0]).toMatchObject({ method: "GET", path: "/api/v1/admin/users", status: 200 });
  expect(JSON.stringify(logs)).not.toMatch(/SECRET|061234567/);
});

describe("adresse de l’API (ELECPAY_API_URL, côté serveur)", () => {
  it.each(["development", "test", "production"])(
    "%s sans variable (ou vide) : refusé, AUCUNE API par défaut",
    (nodeEnv) => {
      expect(() => apiOrigin(undefined, nodeEnv)).toThrow(/manquante : aucune API par défaut/);
      expect(() => apiOrigin("", nodeEnv)).toThrow(RelayConfigError);
    },
  );

  it.each([
    ["http://127.0.0.1:8000", "development"],
    ["http://localhost:8000", "development"],
    ["http://[::1]:8000", "test"],
    ["http://127.0.0.1:8000", "production"],
    ["http://localhost:8000", "production"],
  ])("%s (%s) : l’API PUBLIQUE de ce PC, toujours refusée", (value, nodeEnv) => {
    expect(() => apiOrigin(value, nodeEnv)).toThrow(/API PUBLIQUE/);
  });

  it("développement et test : seulement une API de ce PC (jamais l’adresse ngrok publique)", () => {
    expect(apiOrigin(DEV_API_URL, "development")).toBe("http://127.0.0.1:8001");
    expect(apiOrigin("http://localhost:8010", "test")).toBe("http://localhost:8010");
    for (const nodeEnv of ["development", "test"]) {
      expect(() => apiOrigin("https://omnivore-pardon-sixth.ngrok-free.dev", nodeEnv)).toThrow(
        /seulement une API de ce PC/,
      );
    }
  });

  it("production : HTTPS, ou HTTP vers ce PC (tests de bout en bout, port 8010)", () => {
    expect(apiOrigin("https://omnivore-pardon-sixth.ngrok-free.dev", "production")).toBe(
      "https://omnivore-pardon-sixth.ngrok-free.dev",
    );
    expect(apiOrigin("http://127.0.0.1:8010", "production")).toBe("http://127.0.0.1:8010");
    expect(() => apiOrigin("http://api.exemple.cg", "production")).toThrow(/HTTPS/);
  });

  it.each([
    "https://api.exemple.cg/api/v1",
    "https://api.exemple.cg/?x=1",
    "https://moi:secret@api.exemple.cg",
    "pas une adresse",
  ])("« %s » : refusé (l’origine seule est attendue)", (value) => {
    expect(() => apiOrigin(value, "production")).toThrow(RelayConfigError);
  });
});
