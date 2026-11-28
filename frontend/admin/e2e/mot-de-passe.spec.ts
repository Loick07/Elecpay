// Mot de passe du super admin (un seul compte pour ces parcours, dans l'ordre) : changé dans Mon
// compte (toutes les sessions fermées → reconnexion), puis oublié (code de démo affiché, aucun SMS).
import { capture } from "./support/capture";
import {
  ADMIN_MENU,
  expectHome,
  menuLabels,
  sessionCookies,
  signIn,
  SUPER_ADMIN,
} from "./support/demo";
import { expect, expectAccessible, test } from "./support/test";

const CHANGED = "Superviseur2027!";
const RESET = "Superviseur2028!";

test.describe.configure({ mode: "serial" });

test("changé dans Mon compte : déconnexion de partout, puis connexion avec le nouveau", async ({
  page,
}) => {
  await page.goto("/connexion");
  await signIn(page, SUPER_ADMIN);
  await expectHome(page, SUPER_ADMIN);
  await expect.poll(() => menuLabels(page)).toEqual(ADMIN_MENU);
  await page.getByRole("link", { name: "Mon compte" }).click();

  const form = page.getByRole("region", { name: "Mot de passe" });
  await form.getByLabel("Mot de passe actuel").fill("Demo2026!");
  await form.getByLabel("Nouveau mot de passe", { exact: true }).fill(CHANGED);
  await form.getByLabel("Confirmer le nouveau mot de passe").fill(CHANGED);
  await form.getByRole("button", { name: "Changer le mot de passe" }).click();

  await expect(page).toHaveURL(/\/connexion\?raison=mot-de-passe$/);
  await expect(
    page.getByText("Mot de passe changé. Reconnectez-vous avec votre nouveau mot de passe."),
  ).toBeVisible();
  expect(await sessionCookies(page)).toEqual([]);

  await signIn(page, SUPER_ADMIN, CHANGED);
  await expectHome(page, SUPER_ADMIN);
});

test("oublié : code de démo affiché (aucun SMS), nouveau mot de passe, connexion", async ({
  page,
}) => {
  await page.goto("/connexion");
  await page.getByRole("link", { name: "Mot de passe oublié ou première connexion ?" }).click();
  await expect(
    page.getByRole("heading", { level: 1, name: "Mot de passe oublié ou première connexion" }),
  ).toBeVisible();
  await page.getByLabel("Numéro de téléphone").fill(SUPER_ADMIN.phone);
  await page.getByRole("button", { name: "Recevoir un code" }).click();

  const demo = page.getByRole("status").filter({ hasText: "Mode démo (aucun SMS envoyé)" });
  await expect(demo).toBeVisible();
  const code = (await demo.locator(".font-mono").textContent())?.trim() ?? "";
  expect(code).toMatch(/^\d{6}$/);
  await expectAccessible(page);
  await capture(page, "mot-de-passe-oublie-code");

  await page.getByLabel("Code reçu par SMS").fill(code);
  await page.getByLabel("Nouveau mot de passe", { exact: true }).fill(RESET);
  await page.getByLabel("Confirmer le mot de passe").fill(RESET);
  await page.getByRole("button", { name: "Enregistrer le mot de passe" }).click();

  await expect(page).toHaveURL(/\/connexion\?raison=reinitialise$/);
  await expect(
    page.getByText("Mot de passe enregistré. Vous pouvez vous connecter."),
  ).toBeVisible();
  await signIn(page, SUPER_ADMIN, RESET);
  await expectHome(page, SUPER_ADMIN);
});
