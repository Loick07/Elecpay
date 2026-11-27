import { fileURLToPath } from "node:url";

/** La charte (source unique) et la feuille générée, à partir de `frontend/admin/`. */
export const TOKENS_JSON = fileURLToPath(new URL("../../design/tokens.json", import.meta.url));
export const DESIGN_TOKENS_CSS = fileURLToPath(new URL("../../design/tokens.css", import.meta.url));
export const GENERATED_CSS = fileURLToPath(
  new URL("../src/styles/tokens.generated.css", import.meta.url),
);
