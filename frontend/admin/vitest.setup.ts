// Assertions du DOM (toBeVisible, toHaveAccessibleName…) : configuration standard de jest-dom.
// Les tests importent `describe`, `it` et `expect` depuis "vitest" (choix de clarté ; les types
// globaux ne sont pas déclarés dans tsconfig.json). Les globales restent actives pour que Testing
// Library nettoie la page entre deux tests. Toujours lancer Vitest par `npm test` (tool/vitest.ts).
import "@testing-library/jest-dom/vitest";

import { configure } from "@testing-library/react";
import { afterAll, afterEach, beforeAll } from "vitest";

import { server } from "./src/test/msw-server";

// Attente d'un élément (`findBy…`, `waitFor`) : 5 s au lieu de 1 s. Sur le PC de Loick chargé (suite
// complète : 158 s au lieu de 60), une réponse simulée arrivait parfois après 1 s (vu le 27/11/2026).
// Ce que les tests vérifient ne change pas ; seule la patience augmente.
configure({ asyncUtilTimeout: 5_000 });

// API simulée pour tous les tests : une requête non prévue fait échouer le test (jamais le réseau réel).
// MSW 3 : l'option s'appelle `onUnhandledFrame` (l'ancien `onUnhandledRequest` était ignoré sans
// erreur : la garde ne fonctionnait pas ; prouvée par tests/no-network.test.ts).
beforeAll(() => server.listen({ onUnhandledFrame: "error" }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
