// Assertions du DOM (toBeVisible, toHaveAccessibleName…) : configuration standard de jest-dom.
// Les tests importent `describe`, `it` et `expect` depuis "vitest" (choix de clarté ; les types
// globaux ne sont pas déclarés dans tsconfig.json). Les globales restent actives pour que Testing
// Library nettoie la page entre deux tests. Toujours lancer Vitest par `npm test` (tool/vitest.ts).
import "@testing-library/jest-dom/vitest";
