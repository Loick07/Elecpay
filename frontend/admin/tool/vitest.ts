// Lance Vitest depuis le dossier du projet écrit avec sa casse OFFICIELLE (`npm test`).
//
// Pourquoi (défaut trouvé le 27/11/2026, reproduit à coup sûr) : sous Windows, si Node démarre dans
// `c:\…` (lettre de lecteur en minuscule, ce que donnent certains shells lancés par VS Code), Vitest
// charge son propre module DEUX fois — une fois par le chemin du processus (`c:\…`), une fois par le
// chemin officiel que retrouve Vite (`C:\…`). Le test parle alors à une copie qui ne connaît pas les
// tests en cours : « Vitest failed to find the current suite ». Sans effet sous Linux (CI).
import { spawnSync } from "node:child_process";
import { realpathSync } from "node:fs";
import { join } from "node:path";

const cwd = realpathSync.native(process.cwd());
const vitest = realpathSync.native(join(cwd, "node_modules", "vitest", "vitest.mjs"));
const result = spawnSync(process.execPath, [vitest, ...process.argv.slice(2)], {
  cwd,
  stdio: "inherit",
});
process.exit(result.status ?? 1);
