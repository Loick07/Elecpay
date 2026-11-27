// Connexion au back-office sur l'API de test : sans session, client refusé, mauvais mot de passe,
// support (sans double authentification), admin (mot de passe puis code), cookies de session sûrs,
// Mon compte (nouveaux codes de secours, nom).
import { capture } from "./support/capture";
import {
  ADMIN,
  CLIENT_PHONE,
  countLoginAttempt,
  DEMO_PASSWORD,
  expectHome,
  freshCode,
  sessionCookies,
  signIn,
  SUPPORT,
} from "./support/demo";
import { expect, expectAccessible, test } from "./support/test";

// Messages de l'écran de connexion (l'annonceur de changement de page de Next porte aussi le rôle
// « alert » : toujours chercher dans la carte).

test("sans session : une page de l’équipe renvoie à la connexion, avec la page demandée", async ({
  page,
}) => {
  await page.goto("/mon-compte");
  await expect(page).toHaveURL(/\/connexion\?retour=%2Fmon-compte$/);
  await expect(page.getByRole("heading", { level: 1, name: "Connexion" })).toBeVisible();
  await expect(page.getByText("Mode démo")).toBeVisible();
  await expectAccessible(page);
  await capture(page, "connexion");
  await page.setViewportSize({ width: 390, height: 844 });
  await expectAccessible(page);
  await capture(page, "connexion-390");
});

test("un client ne peut pas se connecter au back-office", async ({ page }) => {
  await page.goto("/connexion");
  countLoginAttempt();
  await page.getByLabel("Numéro de téléphone").fill(CLIENT_PHONE);
  await page.getByLabel("Mot de passe", { exact: true }).fill(DEMO_PASSWORD);
  await page.getByRole("button", { name: "Se connecter" }).click();
  await expect(page.getByRole("region", { name: "Connexion" }).getByRole("alert")).toContainText(
    "Cet espace est réservé à l'équipe ElecPay.",
  );
  await expect(page).toHaveURL(/\/connexion$/);
  expect(await sessionCookies(page)).toEqual([]);
});

test("mauvais mot de passe : refusé, avec la référence à citer", async ({ page }) => {
  await page.goto("/connexion");
  countLoginAttempt();
  await page.getByLabel("Numéro de téléphone").fill(SUPPORT.phone);
  await page.getByLabel("Mot de passe", { exact: true }).fill("Mauvais2026!");
  await page.getByRole("button", { name: "Se connecter" }).click();
  const alert = page.getByRole("region", { name: "Connexion" }).getByRole("alert");
  await expect(alert).toContainText("Numéro ou mot de passe incorrect.");
  await expect(alert).toContainText("Référence :");
  await expectAccessible(page);
  await capture(page, "connexion-refusee");
});

test("support : connecté sans code ; Mon compte recommande la double authentification (DA1.5)", async ({
  page,
}) => {
  await page.goto("/connexion");
  await signIn(page, SUPPORT);
  await expectHome(page, SUPPORT);
  await expectAccessible(page);
  await capture(page, "accueil-support");

  await page.getByRole("link", { name: "Mon compte" }).click();
  await expect(page).toHaveURL(/\/mon-compte$/);
  const twoFactor = page.getByRole("region", { name: "Double authentification" });
  await expect(twoFactor.getByText("Double authentification recommandée.")).toBeVisible();
  await expect(
    twoFactor.getByRole("link", { name: "Configurer la double authentification" }),
  ).toHaveAttribute("href", "/securite?retour=%2Fmon-compte");
  await expectAccessible(page);
  await capture(page, "mon-compte-support");
  await page.setViewportSize({ width: 390, height: 844 });
  await expectAccessible(page);
  await capture(page, "mon-compte-390");
  await page.setViewportSize({ width: 1440, height: 900 });

  // Page Sécurité : clé et QR code DESSINÉ par le navigateur (image SVG autonome), sans activer
  // (aucun code saisi : le compte reste sans double authentification pour les autres parcours).
  await twoFactor.getByRole("link", { name: "Configurer la double authentification" }).click();
  await expect(page).toHaveURL(/\/securite\?retour=%2Fmon-compte$/);
  await page.getByRole("button", { name: "Configurer la double authentification" }).click();
  const qr = page.getByRole("img", {
    name: "QR code à scanner avec votre application d’authentification",
  });
  await expect(qr).toBeVisible();
  await expect
    .poll(() => qr.evaluate((image: HTMLImageElement) => image.naturalWidth))
    .toBeGreaterThan(0);
  await expectAccessible(page);
  await capture(page, "securite-qr-code");
});

test("admin : mot de passe puis code ; cookies sûrs ; nouveaux codes de secours et nom", async ({
  page,
}) => {
  await page.goto("/connexion");
  countLoginAttempt();
  await page.getByLabel("Numéro de téléphone").fill(ADMIN.phone);
  await page.getByLabel("Mot de passe", { exact: true }).fill(DEMO_PASSWORD);
  await page.getByRole("button", { name: "Se connecter" }).click();
  await expect(
    page.getByRole("heading", { level: 1, name: "Double authentification" }),
  ).toBeVisible();
  await expectAccessible(page);
  await capture(page, "connexion-code");
  countLoginAttempt();
  await page.getByLabel("Code de vérification").fill(await freshCode(ADMIN));
  await page.getByRole("button", { name: "Valider le code" }).click();
  await expectHome(page, ADMIN);

  // Cookies de session : jetons illisibles par le code de la page (httpOnly), jamais envoyés en
  // clair ailleurs qu'à ce PC (Secure), jamais par un autre site (SameSite=Strict).
  const cookies = await page.context().cookies();
  const byName = new Map(cookies.map((cookie) => [cookie.name, cookie]));
  expect(await sessionCookies(page)).toEqual(["elecpay_access", "elecpay_csrf", "elecpay_refresh"]);
  for (const name of ["elecpay_access", "elecpay_refresh"]) {
    expect(byName.get(name)).toMatchObject({ httpOnly: true, secure: true, sameSite: "Strict" });
  }
  expect(byName.get("elecpay_csrf")).toMatchObject({ httpOnly: false, sameSite: "Strict" });
  expect(byName.get("elecpay_access")?.path).toBe("/api/v1");
  expect(byName.get("elecpay_refresh")?.path).toBe("/api/v1/auth/web");

  // Mon compte : nouveaux codes de secours (code de l'application), montrés une seule fois.
  await page.getByRole("link", { name: "Mon compte" }).click();
  const twoFactor = page.getByRole("region", { name: "Double authentification" });
  await expect(
    twoFactor.getByText(/^Active depuis le .* code\(s\) de secours restant\(s\)\.$/),
  ).toBeVisible();
  await expectAccessible(page);
  await capture(page, "mon-compte-admin");
  await twoFactor.getByRole("button", { name: "Nouveaux codes de secours" }).click();
  await page.getByLabel("Code à 6 chiffres").fill(await freshCode(ADMIN));
  await page.getByRole("button", { name: "Générer de nouveaux codes" }).click();
  const codes = page.getByRole("list", { name: "Codes de secours" }).getByRole("listitem");
  await expect(codes).toHaveCount(10);
  await expect(codes.first()).toHaveText(/^[A-Z0-9]{4}-[A-Z0-9]{4}$/);
  await expectAccessible(page);
  await capture(page, "nouveaux-codes-de-secours");
  await page.getByLabel("J’ai mis ces codes en lieu sûr.").check();
  await page.getByRole("button", { name: "Terminé" }).click();
  await expect(twoFactor.getByText(/10 code\(s\) de secours restant\(s\)\./)).toBeVisible();

  // Nom : normalisé par l'API, l'en-tête suit, et il reste après rechargement.
  await page.getByRole("button", { name: "Modifier le nom" }).click();
  await page.getByLabel("Nom complet").fill("  Administrateur   Principal ");
  await page.getByRole("button", { name: "Enregistrer" }).click();
  await expect(page.getByText("Nom enregistré.")).toBeVisible();
  await page.reload();
  await expect(
    page.getByRole("region", { name: "Profil" }).getByText("Administrateur Principal"),
  ).toBeVisible();
});
