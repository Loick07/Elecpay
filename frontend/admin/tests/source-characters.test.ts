// @vitest-environment node
// Aucun caractère INVISIBLE écrit en dur dans le code (comme `frontend/mobile/test/
// source_characters_test.dart`) : une espace insécable tapée telle quelle ne se voit pas à la
// relecture. Les formats les construisent par leur code (`src/lib/format/typography.ts`).
import { readdirSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

import { expect, it } from "vitest";

const ROOT = fileURLToPath(new URL("..", import.meta.url));
const FOLDERS = ["src", "tool", "tests"];
const EXTENSIONS = /\.(ts|tsx|mts|css|json|mjs)$/;
/** Espaces insécables (U+00A0, U+202F, U+2007), caractères de largeur nulle, marque d'ordre. */
const INVISIBLE = new RegExp(
  `[${[0x00a0, 0x202f, 0x2007, 0x200b, 0x200c, 0x200d, 0x2060, 0xfeff]
    .map((code) => String.fromCharCode(code))
    .join("")}]`,
);

function files(folder: string): string[] {
  return readdirSync(folder).flatMap((name) => {
    const path = join(folder, name);
    if (statSync(path).isDirectory()) return files(path);
    return EXTENSIONS.test(name) ? [path] : [];
  });
}

it("aucun caractère invisible dans src/, tool/ et tests/", () => {
  const found: string[] = [];
  for (const folder of FOLDERS) {
    for (const file of files(join(ROOT, folder))) {
      readFileSync(file, "utf8")
        .split("\n")
        .forEach((line, index) => {
          if (INVISIBLE.test(line)) found.push(`${file}:${index + 1}`);
        });
    }
  }
  expect(found).toEqual([]);
});
