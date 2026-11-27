// @vitest-environment node
// Le script de l'API de développement ne peut viser QUE sa base et son port (écrits en dur).
import { readFileSync } from "node:fs";

import { expect, it } from "vitest";

const script = readFileSync(new URL("./dev-api.ps1", import.meta.url), "utf8");

it("base elecpay_admin_dev et port 8001 écrits en dur, aucun paramètre pour les changer", () => {
  expect(script).toContain("$database = 'elecpay_admin_dev'");
  expect(script).toContain("$port = 8001");
  // Les .ps1 sont en CRLF dans le dépôt : en mode multiligne, `$` s'arrête aussi avant « \r ».
  expect(script).toMatch(/^param\(\[switch\]\$Reset\)$/m);
  expect(script).not.toMatch(/\$port\s*=\s*8000/);
  expect(script).not.toMatch(/elecpay_public'|elecpay_e2e'|\/elecpay\?/);
});
