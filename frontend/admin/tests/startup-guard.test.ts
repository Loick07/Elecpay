// @vitest-environment node
// Preuve que la cible de l'API est vérifiée AU DÉMARRAGE (next.config.ts, décision de Loick du
// 27/11/2026) : un VRAI `next dev` sans ELECPAY_API_URL, ou visant l'API publique (port 8000),
// s'arrête de lui-même avec le message attendu au lieu de démarrer. (Les variables de l'environnement
// passent avant `.env.local` : un `.env.local` présent sur le PC ne change rien à ces deux essais.)
import { spawn } from "node:child_process";
import { realpathSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

import { describe, expect, it } from "vitest";

const ROOT = realpathSync.native(fileURLToPath(new URL("..", import.meta.url)));
const NEXT = join(ROOT, "node_modules", "next", "dist", "bin", "next");
/** Au-delà, le serveur a démarré : le garde-fou n'a pas joué. */
const WAIT_MS = 90_000;

type Outcome = { exitCode: number | null; output: string; started: boolean };

function startDevServer(apiUrl: string): Promise<Outcome> {
  return new Promise((resolve) => {
    // Sans NODE_ENV (celui de Vitest vaut « test ») : `next dev` choisit lui-même « development ».
    const env = {
      ...Object.fromEntries(Object.entries(process.env).filter(([name]) => name !== "NODE_ENV")),
      ELECPAY_API_URL: apiUrl,
      NEXT_TELEMETRY_DISABLED: "1",
    };
    // Conversion volontaire : les types de Next rendent NODE_ENV obligatoire, ce test l'enlève.
    const child = spawn(process.execPath, [NEXT, "dev", "--port", "39123"], {
      cwd: ROOT,
      env: env as unknown as NodeJS.ProcessEnv,
    });
    let output = "";
    child.stdout.on("data", (chunk: Buffer) => (output += chunk.toString()));
    child.stderr.on("data", (chunk: Buffer) => (output += chunk.toString()));
    const timer = setTimeout(() => {
      child.kill();
      resolve({ exitCode: null, output, started: true });
    }, WAIT_MS);
    child.on("exit", (exitCode) => {
      clearTimeout(timer);
      resolve({ exitCode, output, started: false });
    });
  });
}

describe("le serveur refuse de démarrer sans cible sûre", () => {
  it(
    "ELECPAY_API_URL oubliée : refus, aucune API par défaut",
    async () => {
      const outcome = await startDevServer("");
      expect(outcome.started, outcome.output).toBe(false);
      expect(outcome.exitCode).not.toBe(0);
      expect(outcome.output).toContain("ELECPAY_API_URL manquante : aucune API par défaut");
    },
    WAIT_MS + 30_000,
  );

  it(
    "ELECPAY_API_URL vers le port 8000 (API publique) : refus",
    async () => {
      const outcome = await startDevServer("http://127.0.0.1:8000");
      expect(outcome.started, outcome.output).toBe(false);
      expect(outcome.exitCode).not.toBe(0);
      expect(outcome.output).toContain("c'est l'API PUBLIQUE");
    },
    WAIT_MS + 30_000,
  );
});
