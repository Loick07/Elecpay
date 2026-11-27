// Régénère le thème depuis la charte : `npm run generate:tokens`
// (src/styles/tokens.generated.css et src/styles/tokens.generated.ts).
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";

import { generateTokensCss, generateTokensTs } from "./tokens-generator.ts";
import { GENERATED_CSS, GENERATED_TS, TOKENS_JSON } from "./tokens-paths.ts";

const tokens = readFileSync(TOKENS_JSON, "utf8");
mkdirSync(dirname(GENERATED_CSS), { recursive: true });
writeFileSync(GENERATED_CSS, generateTokensCss(tokens));
writeFileSync(GENERATED_TS, generateTokensTs(tokens));
console.warn(`Écrits : ${GENERATED_CSS} et ${GENERATED_TS}`);
