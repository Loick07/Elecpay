// Règles du contrôle « rien de sensible dans le code envoyé au navigateur » (tool/bundle-check.ts),
// séparées pour être testées (tool/bundle-check.test.ts).

/** Jamais dans le code du navigateur : secrets de démo publics, adresses et noms côté serveur. */
export const FORBIDDEN_IN_BROWSER = [
  "Demo2026!", // mot de passe des comptes de démo (aucun identifiant prérempli)
  "ELECPAYDEMO2FASECRETPOURLESTESTS", // secret de double authentification de démo
  "ngrok-free.dev", // le navigateur ne connaît pas l'adresse de l'API (relais)
  "127.0.0.1:8000", // API locale de démonstration
  "ELECPAY_API_URL", // variables du serveur
  "ELECPAY_PROXY_SECRET",
];

/** Variables `NEXT_PUBLIC_…` (recopiées dans le code du navigateur) autorisées : aucune. */
export const ALLOWED_PUBLIC_VARIABLES: readonly string[] = [];

export type SourceFile = { path: string; content: string };
export type Finding = { path: string; problem: string };

/** Valeurs des variables secrètes du serveur à chercher aussi (vides ou trop courtes : ignorées). */
export function secretValues(env: Record<string, string | undefined>): string[] {
  return ["ELECPAY_API_URL", "ELECPAY_PROXY_SECRET"]
    .map((name) => env[name])
    .filter((value): value is string => typeof value === "string" && value.length >= 8)
    .map((value) => value.replace(/^https?:\/\//, ""));
}

export function forbiddenInBundle(files: SourceFile[], forbidden: string[]): Finding[] {
  const findings: Finding[] = [];
  for (const file of files) {
    for (const needle of forbidden) {
      if (file.content.includes(needle)) {
        findings.push({ path: file.path, problem: `contient « ${needle} »` });
      }
    }
  }
  return findings;
}

export function publicVariables(
  files: SourceFile[],
  allowed: readonly string[] = ALLOWED_PUBLIC_VARIABLES,
): Finding[] {
  const findings: Finding[] = [];
  for (const file of files) {
    // Une variable a un nom après le préfixe (le préfixe seul, dans un commentaire, n'en est pas une).
    for (const match of file.content.matchAll(/NEXT_PUBLIC_[A-Z0-9_]+/g)) {
      if (!allowed.includes(match[0])) {
        findings.push({
          path: file.path,
          problem: `variable publique « ${match[0]} » non autorisée`,
        });
      }
    }
  }
  return findings;
}
