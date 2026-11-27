// @vitest-environment node
// Le lanceur des tests de bout en bout ne peut supprimer et recréer QUE sa base, et ne lance ses
// serveurs QUE sur ses ports (écrits en dur, aucun paramètre pour les changer).
import { readFileSync } from "node:fs";

import { expect, it } from "vitest";

const script = readFileSync(new URL("./e2e.ps1", import.meta.url), "utf8");

it("base elecpay_admin_e2e, API sur 8010 et back-office sur 3010 écrits en dur", () => {
  expect(script).toContain("$database = 'elecpay_admin_e2e'");
  expect(script).toContain("$apiPort = 8010");
  expect(script).toContain("$sitePort = 3010");
  // Seuls paramètres : ne pas reconstruire, filtrer les parcours (jamais une base ni un port).
  // Les .ps1 sont en CRLF dans le dépôt : en mode multiligne, `$` s'arrête aussi avant « \r ».
  expect(script).toMatch(/^param\(\[switch\]\$SkipBuild, \[string\]\$Grep\)\r?$/m);
  expect(script.match(/^param\(/gm)).toHaveLength(1);
});

it("la seule base supprimée est la sienne ; jamais les autres bases ni l'API publique", () => {
  const drops = script.match(/DROP DATABASE[^;\n]*/g) ?? [];
  expect(drops).toEqual(["DROP DATABASE IF EXISTS $database"]);
  expect(script).not.toMatch(/elecpay_public'|elecpay_e2e'|elecpay_admin_dev'|\/elecpay\?/);
  expect(script).not.toMatch(/8000/);
});

it("jetons d'une minute, garde-fou de Playwright posé, serveurs toujours arrêtés", () => {
  expect(script).toContain("$env:ACCESS_TOKEN_MINUTES = '1'");
  expect(script).toContain("$env:ELECPAY_E2E_DATABASE = $database");
  expect(script).toContain('$env:ELECPAY_API_URL = "http://127.0.0.1:$apiPort"');
  expect(script).toMatch(/finally \{\s+# 6\. Toujours arrêter les deux serveurs/);
});
