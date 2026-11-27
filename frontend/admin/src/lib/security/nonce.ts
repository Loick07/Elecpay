// Nonce de la page partagé avec les bibliothèques qui injectent des balises <style> (blocage du
// défilement des fenêtres Radix : react-remove-scroll → react-style-singleton → get-nonce). Sans
// lui, la CSP stricte (style-src avec nonce) refusait ces <style> (vu le 27/11/2026 sur le serveur
// de production). Le nonce est lu sur les scripts de Next, qui le portent déjà.
import { setNonce } from "get-nonce";

export function shareNonceWithStyleInjectors(): void {
  if (typeof document === "undefined") return;
  const nonce = document.querySelector<HTMLScriptElement>("script[nonce]")?.nonce;
  if (nonce) setNonce(nonce);
}
