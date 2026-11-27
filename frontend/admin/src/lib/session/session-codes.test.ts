// @vitest-environment node
// Garde-fou : chaque 401 « de session » du backend est classé par le back-office (rafraîchir, ou
// session perdue). Les autres 401 (code faux…) restent des erreurs ordinaires. Si le backend ajoute
// une sous-classe de NotAuthenticatedError, ce test échoue tant qu'elle n'est pas classée.
import { readFileSync } from "node:fs";

import { expect, it } from "vitest";

import { REFRESHABLE_CODES, SESSION_LOST_CODES } from "./session-middleware";

const ERRORS_PY = new URL("../../../../../backend/app/modules/auth/errors.py", import.meta.url);

/** Codes des classes `NotAuthenticatedError` et de toutes ses sous-classes (lecture du source). */
function sessionCodesOfBackend(): string[] {
  const source = readFileSync(ERRORS_PY, "utf8");
  const classes = [
    ...source.matchAll(/^class (\w+)\((\w+)\):([\s\S]*?)(?=^class |(?![\s\S]))/gm),
  ].map(([, name, parent, body]) => ({
    name,
    parent,
    code: /^\s+code = "(\w+)"/m.exec(body ?? "")?.[1],
  }));
  const isSession = (name: string | undefined): boolean => {
    if (name === "NotAuthenticatedError") return true;
    const found = classes.find((entry) => entry.name === name);
    return found ? isSession(found.parent) : false;
  };
  return classes
    .filter((entry) => isSession(entry.name))
    .map((entry) => entry.code ?? "")
    .sort();
}

it("les 401 de session du backend sont tous classés (et rien d'autre)", () => {
  const backend = sessionCodesOfBackend();
  expect(backend).toContain("TOKEN_EXPIRED"); // la lecture du source a bien fonctionné
  expect(backend).toEqual([...REFRESHABLE_CODES, ...SESSION_LOST_CODES].sort());
});

it("un code de vérification faux n'est pas un 401 de session", () => {
  expect(REFRESHABLE_CODES.has("TWO_FACTOR_CODE_INVALID")).toBe(false);
  expect(SESSION_LOST_CODES.has("TWO_FACTOR_CODE_INVALID")).toBe(false);
});
