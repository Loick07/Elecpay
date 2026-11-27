import { getNonce } from "get-nonce";
import { afterEach, expect, it } from "vitest";

import { shareNonceWithStyleInjectors } from "./nonce";

afterEach(() => document.head.replaceChildren());

// L'ordre compte : get-nonce garde la valeur pour tout le fichier.
it("aucun script avec nonce : rien n'est transmis", () => {
  document.head.append(document.createElement("script"));
  shareNonceWithStyleInjectors();
  expect(getNonce()).toBeUndefined();
});

it("le nonce des scripts de Next est transmis aux <style> injectés par Radix", () => {
  const script = document.createElement("script");
  script.setAttribute("nonce", "nonce-de-la-page");
  document.head.append(script);
  shareNonceWithStyleInjectors();
  expect(getNonce()).toBe("nonce-de-la-page");
});
