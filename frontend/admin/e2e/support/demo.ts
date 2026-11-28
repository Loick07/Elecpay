// Comptes de démo du seed (backend/docs/ADMIN.md, « Comptes de démo ») et codes de double
// authentification calculés depuis le secret de démo PUBLIC : sur la base elecpay_admin_e2e
// seulement (garde-fou de playwright.config.ts).
import { expect, type Page } from "@playwright/test";
import { TOTP } from "otpauth";

export const DEMO_PASSWORD = "Demo2026!";
const DEMO_TWO_FACTOR_SECRET = "ELECPAYDEMO2FASECRETPOURLESTESTS";
const PERIOD_S = 30;

export type DemoAccount = {
  phone: string;
  /** Premier mot du nom : « Bonjour … » sur l'accueil. */
  firstName: string;
  twoFactor: boolean;
};

export const SUPER_ADMIN: DemoAccount = {
  phone: "06 000 00 01",
  firstName: "Superviseur",
  twoFactor: true,
};
export const ADMIN: DemoAccount = {
  phone: "06 000 00 02",
  firstName: "Administrateur",
  twoFactor: true,
};
export const SUPPORT: DemoAccount = { phone: "06 000 00 03", firstName: "Agent", twoFactor: false };
/** Un client : le back-office lui est fermé. */
export const CLIENT_PHONE = "06 000 01 01";

const totp = new TOTP({ secret: DEMO_TWO_FACTOR_SECRET, digits: 6, period: PERIOD_S });
/** Dernière fenêtre de 30 s utilisée par compte : l'API refuse un code déjà servi (rejeu). */
const lastStep = new Map<string, number>();

/** Code à 6 chiffres JAMAIS servi pour ce compte (attend la fenêtre suivante s'il le faut). */
export async function freshCode(account: DemoAccount): Promise<string> {
  let step = Math.floor(Date.now() / 1000 / PERIOD_S);
  const previous = lastStep.get(account.phone);
  if (previous !== undefined && step <= previous) {
    const wait = (previous + 1) * PERIOD_S * 1000 - Date.now() + 500;
    await new Promise((resolve) => setTimeout(resolve, wait));
    step = Math.floor(Date.now() / 1000 / PERIOD_S);
  }
  lastStep.set(account.phone, step);
  return totp.generate({ timestamp: step * PERIOD_S * 1000 });
}

/**
 * Budget de tentatives de connexion d'un passage : l'API en accepte 20 par IP et par quart d'heure
 * (`LOGIN_ATTEMPTS_PER_IP`, mot de passe ET code comptent chacun). Le passage en fait environ 16 ;
 * au-delà de 18, on s'arrête avec un message clair plutôt qu'un « Trop de tentatives » mystérieux.
 */
const LOGIN_ATTEMPTS_BUDGET = 18;
let loginAttempts = 0;

export function countLoginAttempt(): void {
  loginAttempts += 1;
  if (loginAttempts > LOGIN_ATTEMPTS_BUDGET) {
    throw new Error(
      `Plus de ${LOGIN_ATTEMPTS_BUDGET} tentatives de connexion dans ce passage : la limite de l'API ` +
        "(20 par IP et par quart d'heure) serait atteinte. Regrouper les parcours.",
    );
  }
}

/** Connexion complète depuis la page de connexion (mot de passe, puis code si le compte en a un). */
export async function signIn(
  page: Page,
  account: DemoAccount,
  password: string = DEMO_PASSWORD,
): Promise<void> {
  countLoginAttempt();
  await page.getByLabel("Numéro de téléphone").fill(account.phone);
  await page.getByLabel("Mot de passe", { exact: true }).fill(password);
  await page.getByRole("button", { name: "Se connecter" }).click();
  if (account.twoFactor) {
    countLoginAttempt();
    await page.getByLabel("Code de vérification").fill(await freshCode(account));
    await page.getByRole("button", { name: "Valider le code" }).click();
  }
}

/** Noms des cookies de session présents (jamais leurs valeurs). */
export async function sessionCookies(page: Page): Promise<string[]> {
  return (await page.context().cookies())
    .map((cookie) => cookie.name)
    .filter((name) => name.startsWith("elecpay_"))
    .sort();
}

export async function expectHome(page: Page, account: DemoAccount): Promise<void> {
  await expect(page).toHaveURL(/\/$/);
  await expect(page.getByText(`Bonjour ${account.firstName}.`)).toBeVisible();
}

/** Libellés des entrées du menu latéral (sans les pastilles). */
export async function menuLabels(page: Page): Promise<string[]> {
  return page
    .getByRole("navigation", { name: "Menu principal" })
    .getByRole("link")
    .evaluateAll((links) => links.map((link) => link.querySelector("span")?.textContent ?? ""));
}

export const STAFF_MENU = [
  "Tableau de bord",
  "Utilisateurs",
  "Compteurs",
  "Factures",
  "Transactions",
  "Notifications",
  "Paramètres et rôles",
];
export const ADMIN_MENU = [...STAFF_MENU.slice(0, 6), "Journal d’activité", "Paramètres et rôles"];
