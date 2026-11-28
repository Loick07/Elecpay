import { screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { useState } from "react";
import { describe, expect, it, vi } from "vitest";

import { ApiError } from "@/lib/api/errors";
import { REASON_LIMITS } from "@/lib/validation";
import { axeViolations } from "@/test/axe";
import { renderWithProviders } from "@/test/render";

import { ConfirmWithReason } from "./confirm-with-reason";

function Screen({ onConfirm }: { onConfirm: (reason: string) => Promise<unknown> }) {
  const [open, setOpen] = useState(false);
  return (
    <>
      <button type="button" onClick={() => setOpen(true)}>
        Annuler la facture
      </button>
      <p>{open ? "ouverte" : "fermée"}</p>
      <ConfirmWithReason
        open={open}
        onOpenChange={setOpen}
        title="Annuler la facture N° 20261105-0042 ?"
        description="La facture n’est jamais supprimée : elle passe « Annulée », avec votre motif."
        limits={REASON_LIMITS.long}
        confirmLabel="Annuler la facture"
        pendingLabel="Annulation…"
        onConfirm={onConfirm}
      />
    </>
  );
}

async function open(user: ReturnType<typeof userEvent.setup>) {
  await user.click(screen.getByRole("button", { name: "Annuler la facture" }));
  return screen.findByRole("alertdialog", { name: "Annuler la facture N° 20261105-0042 ?" });
}

describe("confirmation avec motif", () => {
  it("motif trop court : refusé avant l’envoi ; compteur de caractères ; axe", async () => {
    const onConfirm = vi.fn(async () => undefined);
    renderWithProviders(<Screen onConfirm={onConfirm} />);
    const user = userEvent.setup();
    const dialog = await open(user);
    expect(dialog).toHaveTextContent("La facture n’est jamais supprimée");
    const field = screen.getByLabelText("Motif");
    expect(field).toHaveFocus();
    await user.type(field, "Erreur");
    expect(screen.getByText("6 / 255")).toBeVisible();
    await user.click(screen.getByRole("button", { name: "Annuler la facture", hidden: false }));
    expect(await screen.findByText("Motif trop court : 10 caractères minimum.")).toBeVisible();
    expect(field).toHaveAttribute("aria-invalid", "true");
    expect(onConfirm).not.toHaveBeenCalled();
    expect(await axeViolations(document.body)).toEqual([]);
  });

  it("motif valide : envoyé UNE fois, normalisé ; fenêtre fermée à la réussite", async () => {
    let finish: () => void = () => undefined;
    const onConfirm = vi.fn(
      () =>
        new Promise<void>((resolve) => {
          finish = resolve;
        }),
    );
    renderWithProviders(<Screen onConfirm={onConfirm} />);
    const user = userEvent.setup();
    await open(user);
    await user.type(screen.getByLabelText("Motif"), "  Index   de fin  erroné ");
    const confirm = screen.getAllByRole("button", { name: "Annuler la facture" }).at(-1)!;
    await user.click(confirm);
    expect(await screen.findByRole("button", { name: "Annulation…" })).toBeDisabled();
    expect(screen.getByRole("button", { name: "Annuler" })).toBeDisabled();
    await user.keyboard("{Escape}");
    expect(screen.getByRole("alertdialog")).toBeVisible(); // pas fermée pendant l'envoi
    finish();
    await waitFor(() => expect(screen.queryByRole("alertdialog")).toBeNull());
    expect(onConfirm).toHaveBeenCalledExactlyOnceWith("Index de fin erroné");
    expect(screen.getByText("fermée")).toBeVisible();
    // Le focus revient à ce qui avait ouvert la fenêtre.
    await waitFor(() =>
      expect(screen.getByRole("button", { name: "Annuler la facture" })).toHaveFocus(),
    );
  });

  it("refus de l’API : message et référence dans la fenêtre, motif gardé ; réouverture : tout neuf", async () => {
    const onConfirm = vi.fn(async () => {
      throw new ApiError({
        status: 409,
        code: "BILL_NOT_CANCELLABLE",
        message: "Facture payée : annulation impossible.",
        requestId: "ref-annul-1",
      });
    });
    renderWithProviders(<Screen onConfirm={onConfirm} />);
    const user = userEvent.setup();
    await open(user);
    await user.type(screen.getByLabelText("Motif"), "Index de fin erroné");
    await user.click(screen.getAllByRole("button", { name: "Annuler la facture" }).at(-1)!);
    const alert = await screen.findByRole("alert");
    expect(alert).toHaveTextContent("Facture payée : annulation impossible.");
    expect(alert).toHaveTextContent("Référence : ref-annul-1");
    expect(screen.getByLabelText("Motif")).toHaveValue("Index de fin erroné");

    await user.click(screen.getByRole("button", { name: "Annuler" }));
    expect(screen.queryByRole("alertdialog")).toBeNull();
    await waitFor(() =>
      expect(screen.getByRole("button", { name: "Annuler la facture" })).toHaveFocus(),
    );
    await open(user);
    expect(screen.getByLabelText("Motif")).toHaveValue("");
    expect(screen.queryByRole("alert")).toBeNull();
  });

  it("motif refusé par l’API (422) : message sous le champ", async () => {
    const onConfirm = vi.fn(async () => {
      throw new ApiError({
        status: 422,
        code: "VALIDATION_ERROR",
        message: "Données invalides.",
        details: { fields: [{ field: "body.reason", message: "Ce champ ne peut pas être vide" }] },
      });
    });
    renderWithProviders(<Screen onConfirm={onConfirm} />);
    const user = userEvent.setup();
    await open(user);
    await user.type(screen.getByLabelText("Motif"), "Motif assez long");
    await user.click(screen.getAllByRole("button", { name: "Annuler la facture" }).at(-1)!);
    expect(await screen.findByText("Ce champ ne peut pas être vide")).toBeVisible();
    expect(screen.queryByRole("alert")).toBeNull();
  });
});
