// @vitest-environment node
import { describe, expect, it, vi } from "vitest";

import { createApiClient, unwrap } from "@/lib/api/client";
import { ApiError, NETWORK_ERROR } from "@/lib/api/errors";

import type { SessionEvent } from "./events";

const ORIGIN = "http://localhost:3000";
const error = (status: number, code: string) =>
  Response.json({ error: { code, message: code, details: {} } }, { status });

type Options = {
  /** Réponse de POST /auth/web/refresh. */
  refresh?: () => Response | Promise<Response>;
  /** Code renvoyé tant que la session n'est pas rafraîchie. */
  expiredCode?: string;
};

/** Fausse API : session expirée jusqu'au rafraîchissement, qui renouvelle le jeton anti-CSRF. */
function fakeApi(options: Options = {}) {
  const state = { csrf: "csrf-1", refreshed: false, refreshCalls: 0 };
  const sent: { method: string; path: string; csrf: string | null }[] = [];
  const fetch = (async (request: Request) => {
    const path = new URL(request.url).pathname;
    sent.push({ method: request.method, path, csrf: request.headers.get("X-CSRF-Token") });
    if (path === "/api/v1/auth/web/refresh") {
      state.refreshCalls += 1;
      await new Promise((resolve) => setTimeout(resolve, 20)); // le temps que d'autres attendent
      const answer = options.refresh ? await options.refresh() : Response.json({});
      if (answer.ok) {
        state.refreshed = true;
        state.csrf = `csrf-${state.refreshCalls + 1}`;
      }
      return answer;
    }
    if (path === "/api/v1/auth/web/login") return error(401, "INVALID_CREDENTIALS");
    if (!state.refreshed) return error(401, options.expiredCode ?? "TOKEN_EXPIRED");
    return Response.json({ ok: path });
  }) as unknown as typeof globalThis.fetch;
  const events: SessionEvent[] = [];
  const client = createApiClient({
    baseUrl: ORIGIN,
    fetch,
    readCookies: () => `elecpay_csrf=${state.csrf}`,
    announce: (event) => events.push(event),
    locks: undefined,
  });
  return { client, state, sent, events };
}

describe("session expirée : un rafraîchissement, puis la requête est rejouée", () => {
  it.each(["TOKEN_EXPIRED", "NOT_AUTHENTICATED"])("%s : rejouée avec succès", async (code) => {
    const { client, state, events } = fakeApi({ expiredCode: code });
    await expect(unwrap(client.GET("/api/v1/me"))).resolves.toEqual({ ok: "/api/v1/me" });
    expect(state.refreshCalls).toBe(1);
    expect(events).toEqual([]);
  });

  it("trois requêtes refusées en même temps : UN SEUL rafraîchissement", async () => {
    const { client, state } = fakeApi();
    const results = await Promise.all([
      unwrap(client.GET("/api/v1/me")),
      unwrap(client.GET("/api/v1/me/2fa")),
      unwrap(client.GET("/api/v1/admin/stats")),
    ]);
    expect(results).toHaveLength(3);
    expect(state.refreshCalls).toBe(1);
  });

  it("le rafraîchissement porte le jeton anti-CSRF ; le rejeu porte le NOUVEAU", async () => {
    const { client, sent } = fakeApi();
    await unwrap(client.POST("/api/v1/auth/web/logout")).catch(() => undefined);
    await unwrap(client.PATCH("/api/v1/me", { body: { full_name: "Nouveau Nom" } }));
    const patches = sent.filter((request) => request.method === "PATCH");
    expect(patches.map((request) => request.csrf)).toEqual(["csrf-1", "csrf-2"]);
    expect(sent.find((request) => request.path === "/api/v1/auth/web/refresh")?.csrf).toBe(
      "csrf-1",
    );
  });

  it("un autre onglet a déjà rafraîchi (jeton anti-CSRF changé) : on rejoue sans rafraîchir", async () => {
    const { client, state } = fakeApi();
    const call = unwrap(client.GET("/api/v1/me"));
    // Pendant le trajet de la requête, un autre onglet rafraîchit la session.
    state.refreshed = true;
    state.csrf = "csrf-autre-onglet";
    await expect(call).resolves.toEqual({ ok: "/api/v1/me" });
    expect(state.refreshCalls).toBe(0);
  });
});

describe("session terminée ou API injoignable", () => {
  it("rafraîchissement refusé : événement « expiree », la requête échoue en 401", async () => {
    const { client, events } = fakeApi({ refresh: () => error(401, "REFRESH_TOKEN_REUSED") });
    const failure = await unwrap(client.GET("/api/v1/me")).catch((e: unknown) => e);
    expect(failure).toBeInstanceOf(ApiError);
    expect((failure as ApiError).status).toBe(401);
    expect(events).toEqual(["expiree"]);
  });

  it("aucun cookie anti-CSRF (jamais connecté) : « expiree » sans appel de rafraîchissement", async () => {
    const sent: string[] = [];
    const events: SessionEvent[] = [];
    const client = createApiClient({
      baseUrl: ORIGIN,
      fetch: (async (request: Request) => {
        sent.push(new URL(request.url).pathname);
        return error(401, "NOT_AUTHENTICATED");
      }) as unknown as typeof globalThis.fetch,
      readCookies: () => "",
      announce: (event) => events.push(event),
      locks: undefined,
    });
    await unwrap(client.GET("/api/v1/me")).catch(() => undefined);
    expect(sent).toEqual(["/api/v1/me"]);
    expect(events).toEqual(["expiree"]);
  });

  it("jeton illisible (TOKEN_INVALID) : « expiree » sans tenter de rafraîchir", async () => {
    const { client, state, events } = fakeApi({ expiredCode: "TOKEN_INVALID" });
    await unwrap(client.GET("/api/v1/me")).catch(() => undefined);
    expect(state.refreshCalls).toBe(0);
    expect(events).toEqual(["expiree"]);
  });

  it("API injoignable pendant le rafraîchissement : erreur réseau, JAMAIS « expiree »", async () => {
    const { client, events } = fakeApi({ refresh: () => error(502, "API_UNREACHABLE") });
    const failure = await unwrap(client.GET("/api/v1/me")).catch((e: unknown) => e);
    expect(failure).toMatchObject({ code: NETWORK_ERROR });
    expect(events).toEqual([]);
  });

  it("routes /auth/* : jamais rejouées (un 401 y veut dire « mauvais mot de passe »)", async () => {
    const { client, state } = fakeApi();
    const failure = await unwrap(
      client.POST("/api/v1/auth/web/login", { body: { phone: "+242060000002", password: "x" } }),
    ).catch((e: unknown) => e);
    expect(failure).toMatchObject({ status: 401, code: "INVALID_CREDENTIALS" });
    expect(state.refreshCalls).toBe(0);
  });
});

it("403 TWO_FACTOR_SETUP_REQUIRED : événement « double-authentification-requise »", async () => {
  const events: SessionEvent[] = [];
  const client = createApiClient({
    baseUrl: ORIGIN,
    fetch: vi.fn(async () =>
      error(403, "TWO_FACTOR_SETUP_REQUIRED"),
    ) as unknown as typeof globalThis.fetch,
    readCookies: () => "",
    announce: (event) => events.push(event),
    locks: undefined,
  });
  await unwrap(client.GET("/api/v1/admin/stats")).catch(() => undefined);
  expect(events).toEqual(["double-authentification-requise"]);
});
