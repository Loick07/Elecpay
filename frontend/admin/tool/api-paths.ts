import { fileURLToPath } from "node:url";

/** Le contrat d'API (source unique) et les types générés, à partir de `frontend/admin/`. */
export const OPENAPI_JSON = fileURLToPath(
  new URL("../../../backend/openapi.json", import.meta.url),
);
export const SCHEMA_TS = fileURLToPath(new URL("../src/lib/api/schema.d.ts", import.meta.url));
