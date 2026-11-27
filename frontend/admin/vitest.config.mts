import { fileURLToPath } from "node:url";

import react from "@vitejs/plugin-react";
import { defineConfig } from "vitest/config";

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: { "@": fileURLToPath(new URL("./src", import.meta.url)) },
  },
  test: {
    environment: "jsdom",
    globals: true,
    setupFiles: ["./vitest.setup.ts"],
    include: ["src/**/*.test.{ts,tsx}", "tool/**/*.test.ts", "tests/**/*.test.ts"],
    // Aucun test ne touche le réseau réel : l'API est toujours simulée.
    restoreMocks: true,
    // 20 s par test au plus (5 s par défaut) : la saisie au clavier simulée (user-event) est lente sur
    // un PC chargé. Ce que les tests vérifient ne change pas.
    testTimeout: 20_000,
  },
});
