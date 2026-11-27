import { defineConfig, globalIgnores } from "eslint/config";
import nextVitals from "eslint-config-next/core-web-vitals";
import nextTs from "eslint-config-next/typescript";
import jsxA11y from "eslint-plugin-jsx-a11y";

const eslintConfig = defineConfig([
  ...nextVitals,
  ...nextTs,
  // Accessibilité : toutes les règles strictes de jsx-a11y (le plugin est déjà déclaré par
  // eslint-config-next ; on durcit seulement ses règles).
  { rules: jsxA11y.flatConfigs.strict.rules },
  {
    rules: {
      // Jamais de HTML injecté tel quel (le QR code de la double authentification est une image).
      "react/no-danger": "error",
      "no-console": ["error", { allow: ["warn", "error"] }],
    },
  },
  globalIgnores([
    ".next/**",
    "out/**",
    "build/**",
    "coverage/**",
    "next-env.d.ts",
    "src/lib/api/schema.d.ts", // généré depuis backend/openapi.json
  ]),
]);

export default eslintConfig;
