// Types TypeScript du contrat d'API (`backend/openapi.json`, qui fait foi) → `src/lib/api/schema.d.ts`.
// Après un changement du contrat : `npm run generate:api` ; le test `tool/api-types.test.ts` échoue
// tant que le fichier généré n'est pas à jour (la CI se relance quand openapi.json change, DA0.8).
import openapiTS, { astToString } from "openapi-typescript";

const HEADER = [
  "// CODE GÉNÉRÉ depuis backend/openapi.json : ne pas modifier à la main.",
  "// Régénérer : npm run generate:api (vérifié par tool/api-types.test.ts).",
  "",
  "",
].join("\n");

export async function generateApiTypes(openapiJson: string): Promise<string> {
  const ast = await openapiTS(JSON.parse(openapiJson));
  return `${HEADER}${astToString(ast)}`;
}
