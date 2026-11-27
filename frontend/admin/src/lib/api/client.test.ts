// @vitest-environment node
import { describe, expect, it } from "vitest";

import { createApiClient, CSRF_HEADER, readCookie, unwrap } from "./client";
import { ApiError, NETWORK_ERROR } from "./errors";

/** Fausse API : enregistre les requêtes (aucun réseau). */
function fakeApi(answer: () => Response = () => Response.json({ status: "ok" })) {
  const requests: Request[] = [];
  const fetch = (async (request: Request) => {
    requests.push(request);
    return answer();
  }) as unknown as typeof globalThis.fetch;
  return { requests, fetch };
}

describe("jeton anti-CSRF", () => {
  it("recopié sur une requête qui modifie, jamais sur une lecture", async () => {
    const api = fakeApi(() => new Response(null, { status: 204 }));
    const client = createApiClient({
      baseUrl: "http://localhost:3000",
      fetch: api.fetch,
      readCookies: () => "autre=1; elecpay_csrf=jeton%2Babc; x=y",
    });
    await client.GET("/api/v1/health");
    await client.POST("/api/v1/auth/web/logout");
    expect(api.requests[0]?.headers.has(CSRF_HEADER)).toBe(false);
    expect(api.requests[1]?.headers.get(CSRF_HEADER)).toBe("jeton+abc");
  });

  it("relu à chaque requête (il change après chaque rafraîchissement de session)", async () => {
    const api = fakeApi(() => new Response(null, { status: 204 }));
    let cookie = "elecpay_csrf=ancien";
    const client = createApiClient({
      baseUrl: "http://localhost:3000",
      fetch: api.fetch,
      readCookies: () => cookie,
    });
    await client.POST("/api/v1/auth/web/logout");
    cookie = "elecpay_csrf=nouveau";
    await client.POST("/api/v1/auth/web/logout");
    expect(api.requests.map((r) => r.headers.get(CSRF_HEADER))).toEqual(["ancien", "nouveau"]);
  });

  it("lecture d’un cookie", () => {
    expect(readCookie("elecpay_csrf", "a=1; elecpay_csrf=abc=def")).toBe("abc=def");
    expect(readCookie("elecpay_csrf", "a=1")).toBeNull();
    expect(readCookie("elecpay_csrf", "")).toBeNull();
  });
});

describe("unwrap : les données ou une ApiError", () => {
  it("appelle le relais du même domaine, chemin du contrat", async () => {
    const api = fakeApi();
    const client = createApiClient({ baseUrl: "http://localhost:3000", fetch: api.fetch });
    const health = await unwrap(client.GET("/api/v1/health"));
    expect(health).toEqual({ status: "ok" });
    expect(api.requests[0]?.url).toBe("http://localhost:3000/api/v1/health");
    expect(api.requests[0]?.credentials).toBe("same-origin");
  });

  it("erreur de l’API : ApiError avec le message et la référence", async () => {
    const api = fakeApi(() =>
      Response.json(
        { error: { code: "FORBIDDEN", message: "Action réservée.", details: {} } },
        { status: 403, headers: { "x-request-id": "ref-87654321" } },
      ),
    );
    const client = createApiClient({ baseUrl: "http://localhost:3000", fetch: api.fetch });
    const failure = await unwrap(client.GET("/api/v1/admin/stats")).catch((e: unknown) => e);
    expect(failure).toBeInstanceOf(ApiError);
    expect(failure).toMatchObject({ status: 403, code: "FORBIDDEN", requestId: "ref-87654321" });
  });

  it("réseau coupé : ApiError NETWORK", async () => {
    const client = createApiClient({
      baseUrl: "http://localhost:3000",
      fetch: (async () => {
        throw new TypeError("Failed to fetch");
      }) as unknown as typeof globalThis.fetch,
    });
    const failure = await unwrap(client.GET("/api/v1/health")).catch((e: unknown) => e);
    expect(failure).toMatchObject({ code: NETWORK_ERROR });
  });
});
