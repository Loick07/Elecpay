// Régénère `src/styles/tokens.generated.css` depuis la charte : `npm run generate:tokens`.
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";

import { generateTokensCss } from "./tokens-generator.ts";
import { GENERATED_CSS, TOKENS_JSON } from "./tokens-paths.ts";

const css = generateTokensCss(readFileSync(TOKENS_JSON, "utf8"));
mkdirSync(dirname(GENERATED_CSS), { recursive: true });
writeFileSync(GENERATED_CSS, css);
console.warn(`Écrit : ${GENERATED_CSS}`);
