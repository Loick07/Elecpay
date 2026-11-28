import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { useState } from "react";
import { expect, it } from "vitest";

import { axeViolations } from "@/test/axe";

import { AlertDialog } from "./alert-dialog";
import { Button } from "./button";

function Screen() {
  const [open, setOpen] = useState(false);
  return (
    <>
      <label>
        Nom complet
        <input />
      </label>
      <button type="button" onClick={() => setOpen(true)}>
        Simuler l’inactivité
      </button>
      <AlertDialog
        open={open}
        title="Toujours là ?"
        description="Sans activité, vous serez déconnecté dans 1:00."
        actions={
          <Button variant="primary" onClick={() => setOpen(false)}>
            Rester connecté
          </Button>
        }
      />
    </>
  );
}

it("fenêtre lue (titre, description), focus sur l’action, puis rendu à l’élément d’avant", async () => {
  render(<Screen />);
  const user = userEvent.setup();
  const opener = screen.getByRole("button", { name: "Simuler l’inactivité" });
  await user.click(opener);
  const dialog = await screen.findByRole("alertdialog", { name: "Toujours là ?" });
  expect(dialog).toHaveAccessibleDescription("Sans activité, vous serez déconnecté dans 1:00.");
  expect(screen.getByRole("button", { name: "Rester connecté" })).toHaveFocus();
  expect(await axeViolations(document.body)).toEqual([]);
  await user.click(screen.getByRole("button", { name: "Rester connecté" }));
  await waitFor(() => expect(opener).toHaveFocus());
});
