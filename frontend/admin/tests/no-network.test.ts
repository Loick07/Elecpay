// La garde « aucun test ne touche le réseau réel » (vitest.setup.ts) fonctionne : une requête
// qu'aucun test n'a prévue est refusée PAR MSW (et non par le réseau).
import { expect, it } from "vitest";

it("une requête non prévue est refusée par l’API simulée", async () => {
  const failure = await fetch("http://localhost:3000/api/v1/health").catch(
    (error: unknown) => error,
  );
  expect(failure).toBeInstanceOf(Error);
  const messages = [failure as Error, (failure as Error).cause]
    .map((error) => (error instanceof Error ? error.message : String(error)))
    .join(" | ");
  expect(messages).toMatch(/MSW|onUnhandledFrame/);
});
