// Régénère `src/lib/api/schema.d.ts` depuis le contrat : `npm run generate:api`.
import { readFileSync, writeFileSync } from "node:fs";

import { OPENAPI_JSON, SCHEMA_TS } from "./api-paths.ts";
import { generateApiTypes } from "./api-types-generator.ts";

writeFileSync(SCHEMA_TS, await generateApiTypes(readFileSync(OPENAPI_JSON, "utf8")));
console.warn(`Écrit : ${SCHEMA_TS}`);
