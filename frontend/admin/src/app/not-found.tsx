import type { Metadata } from "next";
import Link from "next/link";

// Page « introuvable » du back-office, selon la charte. Remplace celle de Next, qui écrivait une
// balise <style> sans nonce, refusée par la CSP (vu le 27/11/2026).
export const metadata: Metadata = { title: "Page introuvable" };

export default function NotFound() {
  return (
    <main className="mx-auto flex min-h-screen max-w-md flex-col justify-center gap-4 p-6">
      <h1 className="text-admin-h1 text-ink">Page introuvable</h1>
      <p className="text-ink-muted">Cette adresse ne correspond à aucune page du back-office.</p>
      <Link href="/" className="text-admin-body text-volt-text underline-offset-4 hover:underline">
        Retour à l’accueil
      </Link>
    </main>
  );
}
