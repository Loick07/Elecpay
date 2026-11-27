// API simulée des tests (MSW). Branchée sur TOUS les tests par vitest.setup.ts, avec
// `onUnhandledRequest: "error"` : une requête qu'aucun test n'a prévue fait échouer le test
// (aucun test ne touche le réseau réel). Chaque test déclare ses réponses par `server.use(...)`.
import { setupServer } from "msw/node";

export const server = setupServer();

/** Adresse des requêtes du navigateur dans les tests (jsdom) : le relais du même domaine. */
export const TEST_ORIGIN = "http://localhost:3000";
