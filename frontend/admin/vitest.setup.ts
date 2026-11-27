// Assertions du DOM (toBeVisible, toHaveAccessibleName…) : configuration standard de jest-dom.
// Les tests importent `describe`, `it` et `expect` depuis "vitest" (choix de clarté ; les types
// globaux ne sont pas déclarés dans tsconfig.json). Les globales restent actives pour que Testing
// Library nettoie la page entre deux tests. Toujours lancer Vitest par `npm test` (tool/vitest.ts).
import "@testing-library/jest-dom/vitest";

import { afterAll, afterEach, beforeAll } from "vitest";

import { server } from "./src/test/msw-server";

// API simulée pour tous les tests : une requête non prévue fait échouer le test (jamais le réseau réel).
// MSW 3 : l'option s'appelle `onUnhandledFrame` (l'ancien `onUnhandledRequest` était ignoré sans
// erreur : la garde ne fonctionnait pas ; prouvée par tests/no-network.test.ts).
beforeAll(() => server.listen({ onUnhandledFrame: "error" }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
