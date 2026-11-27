// @vitest-environment node
// Garde-fou contre le contrat (backend/openapi.json) : toute route OUVERTE par le relais dont la
// réponse peut contenir des jetons (`access_token`, `refresh_token`, à n'importe quelle profondeur)
// est dans TOKEN_BODY_ROUTES, donc filtrée. Une nouvelle route de ce genre fait échouer ce test.
import { readFileSync } from "node:fs";

import { expect, it } from "vitest";

import { BODY_TOKEN_FIELDS, isAllowedPath, TOKEN_BODY_ROUTES } from "./relay";

type Schema = Record<string, unknown>;
type OpenApi = {
  paths: Record<
    string,
    Record<
      string,
      { responses?: Record<string, { content?: Record<string, { schema?: Schema }> }> }
    >
  >;
  components: { schemas: Record<string, Schema> };
};

const contract = JSON.parse(
  readFileSync(new URL("../../../../../backend/openapi.json", import.meta.url), "utf8"),
) as OpenApi;

function carriesTokens(schema: unknown, seen = new Set<string>()): boolean {
  if (typeof schema !== "object" || schema === null) return false;
  const node = schema as Schema;
  if (typeof node.$ref === "string") {
    const name = node.$ref.split("/").at(-1) ?? "";
    if (seen.has(name)) return false;
    seen.add(name);
    return carriesTokens(contract.components.schemas[name], seen);
  }
  const properties = (node.properties ?? {}) as Record<string, unknown>;
  if (BODY_TOKEN_FIELDS.some((field) => field in properties)) return true;
  const children = [
    ...Object.values(properties),
    node.items,
    node.additionalProperties,
    ...((node.anyOf ?? []) as unknown[]),
    ...((node.oneOf ?? []) as unknown[]),
    ...((node.allOf ?? []) as unknown[]),
  ];
  return children.some((child) => carriesTokens(child, seen));
}

function openRoutesWithTokens(): string[] {
  const found = new Set<string>();
  for (const [path, operations] of Object.entries(contract.paths)) {
    const route = path.replace(/^\/api\/v1\//, "");
    const segments = route.split("/").map((segment) => (segment.startsWith("{") ? "1" : segment));
    if (!isAllowedPath(segments)) continue;
    for (const operation of Object.values(operations)) {
      for (const response of Object.values(operation.responses ?? {})) {
        for (const media of Object.values(response.content ?? {})) {
          if (carriesTokens(media.schema)) found.add(route);
        }
      }
    }
  }
  return [...found].sort();
}

it("toute route ouverte qui renvoie des jetons est filtrée par le relais", () => {
  expect(openRoutesWithTokens()).toEqual([...TOKEN_BODY_ROUTES].sort());
});

it("la recherche trouve bien les jetons du contrat (routes du mobile, fermées par le relais)", () => {
  const response = contract.paths["/api/v1/auth/refresh"]?.post?.responses?.["200"];
  expect(carriesTokens(response?.content?.["application/json"]?.schema)).toBe(true);
  expect(isAllowedPath(["auth", "refresh"])).toBe(false);
});
