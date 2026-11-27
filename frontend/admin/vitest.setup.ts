// Assertions du DOM (toBeVisible, toHaveAccessibleName…), enregistrées sur l'`expect` de Vitest.
// Avec Vitest 5, l'`expect` GLOBAL n'est pas celui que ce fichier étend : chaque test importe donc
// `expect`, `describe` et `it` depuis "vitest" (les types globaux sont retirés de tsconfig.json,
// le contrôle des types refuse un oubli). Les globales restent actives pour une seule raison :
// Testing Library s'en sert pour nettoyer la page entre deux tests.
import * as matchers from "@testing-library/jest-dom/matchers";
import { expect } from "vitest";

expect.extend(matchers);
