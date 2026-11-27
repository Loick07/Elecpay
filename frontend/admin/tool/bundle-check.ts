// Contrôle, après `next build` : rien de sensible dans le code envoyé au navigateur (`.next/static`)
// et aucune variable `NEXT_PUBLIC_` dans le code source. En CI : `node tool/bundle-check.ts`.
import { readdirSync, readFileSync, statSync } from "node:fs";
import { join, relative } from "node:path";
import { fileURLToPath } from "node:url";

import {
  FORBIDDEN_IN_BROWSER,
  forbiddenInBundle,
  publicVariables,
  secretValues,
  type SourceFile,
} from "./bundle-rules.ts";

const ROOT = fileURLToPath(new URL("..", import.meta.url));

function read(folder: string, extensions: RegExp): SourceFile[] {
  return readdirSync(folder).flatMap((name) => {
    const path = join(folder, name);
    if (statSync(path).isDirectory()) return read(path, extensions);
    return extensions.test(name)
      ? [{ path: relative(ROOT, path), content: readFileSync(path, "utf8") }]
      : [];
  });
}

const STATIC = join(ROOT, ".next", "static");
let bundle: SourceFile[];
try {
  bundle = read(STATIC, /\.(js|css|html|json|txt|map)$/);
} catch {
  console.error("Aucun .next/static : lancer d'abord `npm run build`.");
  process.exit(1);
}
const forbidden = [...FORBIDDEN_IN_BROWSER, ...secretValues(process.env)];
const findings = [
  ...forbiddenInBundle(bundle, forbidden),
  ...publicVariables(read(join(ROOT, "src"), /\.(ts|tsx)$/)),
];

if (findings.length > 0) {
  console.error(`Code du navigateur : ${findings.length} problème(s)`);
  for (const finding of findings) console.error(`- ${finding.path} : ${finding.problem}`);
  process.exit(1);
}
console.warn(
  `Code du navigateur : ${bundle.length} fichiers contrôlés, ${forbidden.length} valeurs interdites absentes.`,
);
