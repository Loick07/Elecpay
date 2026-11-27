// Zod sans compilation à la volée (option prévue par Zod pour les environnements à CSP) : sinon il
// essaie `Function("")` au premier contrôle, ce que la CSP stricte refuse (violation `script-src`
// dans la console, vue le 27/11/2026 sur le serveur de production). Chargé par les fournisseurs
// communs de TOUTES les pages (src/app/providers.tsx) et par les règles de saisie.
import { z } from "zod";

z.config({ jitless: true });
