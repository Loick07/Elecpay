// Session sur l'API de test (jetons d'accès d'UNE minute) : rafraîchissement invisible, session
// terminée pendant le travail, déconnexion (tous les onglets), déconnexion après inactivité.
// Compte support (sans double authentification).
import { capture } from "./support/capture";
import { expectHome, sessionCookies, signIn, SUPPORT } from "./support/demo";
import { expect, expectAccessible, test } from "./support/test";

const ACCESS_TOKEN_LIFETIME_MS = 60_000;

test("jeton d’accès expiré (1 min) : rafraîchi sans rien montrer, le travail continue", async ({
  page,
}) => {
  await page.goto("/connexion");
  await signIn(page, SUPPORT);
  await expectHome(page, SUPPORT);
  // Le navigateur oublie le cookie d'accès à son expiration : la prochaine lecture reçoit 401,
  // le client rafraîchit la session une fois et rejoue la requête.
  await page.waitForTimeout(ACCESS_TOKEN_LIFETIME_MS + 5_000);
  await page.goto("/mon-compte");
  await expect(page.getByRole("region", { name: "Profil" })).toBeVisible();
  await expect(page.getByRole("alertdialog")).toHaveCount(0);
  expect(await sessionCookies(page)).toEqual(["elecpay_access", "elecpay_csrf", "elecpay_refresh"]);
});

test("session terminée pendant le travail : fenêtre « Session expirée », puis retour à la page", async ({
  page,
}) => {
  await page.goto("/connexion");
  await signIn(page, SUPPORT);
  await expectHome(page, SUPPORT);
  await page.goto("/mon-compte");
  await expect(page.getByRole("region", { name: "Profil" })).toBeVisible();

  // Session fermée ailleurs (jetons perdus) : la prochaine action est refusée par l'API.
  await page.context().clearCookies({ name: "elecpay_access" });
  await page.context().clearCookies({ name: "elecpay_refresh" });
  await page.getByRole("button", { name: "Modifier le nom" }).click();
  await page.getByLabel("Nom complet").fill("Agent Support Modifié");
  await page.getByRole("button", { name: "Enregistrer" }).click();

  const dialog = page.getByRole("alertdialog", { name: "Session expirée" });
  await expect(dialog).toBeVisible();
  await expect(dialog).toContainText("Votre session a expiré. Reconnectez-vous pour continuer.");
  await expectAccessible(page);
  // Sous la fenêtre, le formulaire ne parle pas d'« Authentification requise » (message technique).
  await expect(page.getByText("Authentification requise.")).toHaveCount(0);
  await capture(page, "session-expiree", "screen");
  await dialog.getByRole("button", { name: "Se reconnecter" }).click();

  await expect(page).toHaveURL(/\/connexion\?retour=%2Fmon-compte&raison=session$/);
  await expect(
    page.getByText("Votre session a expiré. Reconnectez-vous pour continuer."),
  ).toBeVisible();
  await signIn(page, SUPPORT);
  await expect(page).toHaveURL(/\/mon-compte$/);
  // Le nom n'a pas été changé : la requête refusée n'a rien modifié.
  await expect(
    page.getByRole("region", { name: "Profil" }).getByText("Agent Support Démo"),
  ).toBeVisible();
});

test("déconnexion : cookies effacés, les autres onglets reviennent aussi à la connexion", async ({
  page,
}) => {
  await page.goto("/connexion");
  await signIn(page, SUPPORT);
  await expectHome(page, SUPPORT);
  const other = await page.context().newPage();
  await other.goto("/mon-compte");
  await expect(other.getByRole("region", { name: "Profil" })).toBeVisible();

  await page.getByRole("button", { name: "Se déconnecter" }).click();
  await expect(page).toHaveURL(/\/connexion\?raison=deconnexion$/);
  await expect(page.getByText("Vous êtes déconnecté.")).toBeVisible();
  await expect(other).toHaveURL(/\/connexion\?raison=deconnexion$/);
  expect(await sessionCookies(page)).toEqual([]);

  // Plus de session : les pages de l'équipe renvoient à la connexion, sans parler d'expiration.
  await page.goto("/");
  await expect(page).toHaveURL(/\/connexion$/);
});

test("30 min sans activité : avertissement 1 min avant, puis déconnexion (DA1.2)", async ({
  page,
}) => {
  await page.clock.install();
  await page.goto("/connexion");
  await signIn(page, SUPPORT);
  await expectHome(page, SUPPORT);

  await page.clock.fastForward("29:01");
  const warning = page.getByRole("alertdialog", { name: "Toujours là ?" });
  await expect(warning).toBeVisible();
  await expectAccessible(page);
  await capture(page, "inactivite", "screen");

  await page.clock.fastForward("01:00");
  await expect(page).toHaveURL(/\/connexion\?raison=inactivite$/);
  await expect(
    page.getByText(
      "Vous avez été déconnecté après 30 minutes sans activité. Reconnectez-vous pour continuer.",
    ),
  ).toBeVisible();
  expect(await sessionCookies(page)).toEqual([]);
});
