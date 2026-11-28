import { act, render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { useState } from "react";
import { afterEach, describe, expect, it, vi } from "vitest";

import { formatTime } from "@/lib/format";
import { billStatuses, transactionStatuses, transactionUnknown } from "@/lib/status/statuses";
import { axeViolations } from "@/test/axe";

import { AdminKpi } from "./admin-kpi";
import { DetailPanel, ListWithPanel } from "./detail-panel";
import { FilterChips, SEARCH_DELAY_MS, SearchField } from "./list-filters";
import { RefreshControl } from "./refresh-control";
import { StatusBadge } from "./status-badge";
import { TOAST_DURATION_MS, ToastProvider, useToast } from "./ui/toaster";

afterEach(() => {
  vi.useRealTimers();
});

describe("badge de statut", () => {
  it("chaque statut : son mot, son icône, ses couleurs (texte lisible `*-text`)", async () => {
    const all = [
      ...Object.values(billStatuses),
      ...Object.values(transactionStatuses),
      transactionUnknown,
    ];
    const { container } = render(
      <div>
        {all.map((status) => (
          <StatusBadge key={status.label} status={status} />
        ))}
      </div>,
    );
    for (const status of all) {
      const badge = screen.getByText(status.label);
      expect(badge.querySelector("svg")).toHaveAttribute("aria-hidden", "true");
    }
    expect(screen.getByText("Payée")).toHaveClass("text-success-text", "bg-success-soft");
    // Base blanche opaque sous la teinte : contraste indépendant du fond (alert-contrast.test.ts).
    expect(screen.getByText("Payée").parentElement).toHaveClass("bg-surface-1");
    expect(screen.getByText("Vérification en cours")).toHaveClass("text-warning-text");
    expect(await axeViolations(container)).toEqual([]);
  });
});

describe("tuile d’indicateur", () => {
  it("libellé, valeur, unité, variation dans la couleur de son sens ; lien vers la liste", async () => {
    const { container } = render(
      <AdminKpi
        label="Encaissé en novembre"
        value="8 942 300"
        unit="FCFA"
        delta={{ text: "+8 % vs octobre", tone: "success" }}
        href="/transactions?status=reussie"
      />,
    );
    const link = screen.getByRole("link", { name: /Encaissé en novembre/ });
    expect(link).toHaveAttribute("href", "/transactions?status=reussie");
    expect(link).toHaveTextContent("8 942 300 FCFA");
    expect(screen.getByText("+8 % vs octobre")).toHaveClass("text-success-text");
    expect(await axeViolations(container)).toEqual([]);
  });

  it("sans lien : une simple tuile", () => {
    render(<AdminKpi label="Factures impayées" value="214" />);
    expect(screen.queryByRole("link")).toBeNull();
    expect(screen.getByText("214")).toBeVisible();
  });
});

describe("« Actualiser » et heure de mise à jour (DA2.3)", () => {
  it("heure de Brazzaville ; un clic relit ; pendant la relecture, bouton occupé", async () => {
    const onRefresh = vi.fn();
    const updatedAt = Date.parse("2026-11-28T09:42:00Z");
    const { rerender } = render(
      <RefreshControl updatedAt={updatedAt} refreshing={false} onRefresh={onRefresh} />,
    );
    expect(screen.getByText(`Mis à jour à ${formatTime(new Date(updatedAt))}`)).toBeVisible();
    await userEvent.setup().click(screen.getByRole("button", { name: "Actualiser" }));
    expect(onRefresh).toHaveBeenCalledOnce();
    rerender(<RefreshControl updatedAt={updatedAt} refreshing onRefresh={onRefresh} />);
    expect(screen.getByRole("button", { name: "Actualisation…" })).toBeDisabled();
  });

  it("jamais lu : pas d’heure affichée", () => {
    render(<RefreshControl updatedAt={0} refreshing={false} onRefresh={vi.fn()} />);
    expect(screen.queryByText(/Mis à jour/)).toBeNull();
  });
});

describe("avis", () => {
  function Trigger() {
    const toast = useToast();
    return (
      <>
        <button type="button" onClick={() => toast("Facture annulée.")}>
          Réussite
        </button>
        <button type="button" onClick={() => toast("Export impossible.", "error")}>
          Erreur
        </button>
      </>
    );
  }

  it("réussite : lue poliment ; erreur : lue aussitôt ; « Fermer l’avis »", async () => {
    render(
      <ToastProvider>
        <Trigger />
      </ToastProvider>,
    );
    const user = userEvent.setup();
    await user.click(screen.getByRole("button", { name: "Réussite" }));
    await user.click(screen.getByRole("button", { name: "Erreur" }));
    const region = screen.getByRole("region", { name: "Avis" });
    expect(within(region).getByText("Facture annulée.").closest("[aria-live]")).toHaveAttribute(
      "aria-live",
      "polite",
    );
    expect(within(region).getByText("Export impossible.").closest("[aria-live]")).toHaveAttribute(
      "aria-live",
      "assertive",
    );
    await user.click(within(region).getAllByRole("button", { name: "Fermer l’avis" })[0]!);
    expect(within(region).queryByText("Facture annulée.")).toBeNull();
    expect(await axeViolations(document.body)).toEqual([]);
  });

  it("refermé seul après 6 s", () => {
    vi.useFakeTimers();
    render(
      <ToastProvider>
        <Trigger />
      </ToastProvider>,
    );
    act(() => screen.getByRole("button", { name: "Réussite" }).click());
    expect(screen.getByText("Facture annulée.")).toBeVisible();
    act(() => vi.advanceTimersByTime(TOAST_DURATION_MS));
    expect(screen.queryByText("Facture annulée.")).toBeNull();
  });

  it("hors du cadre : erreur claire", () => {
    vi.spyOn(console, "error").mockImplementation(() => undefined);
    expect(() => render(<Trigger />)).toThrow("useToast : à utiliser sous ToastProvider");
  });
});

describe("panneau latéral de détail", () => {
  function Screen() {
    const [open, setOpen] = useState<string | null>(null);
    return (
      <ListWithPanel
        list={
          <ul>
            {["Compteur 0412-8833", "Compteur 0219-7741"].map((name) => (
              <li key={name}>
                <button type="button" onClick={() => setOpen(name)}>
                  {name}
                </button>
              </li>
            ))}
          </ul>
        }
        panel={
          open ? (
            <DetailPanel
              title={open}
              subtitle="Loick Makosso · 6 kVA"
              onClose={() => setOpen(null)}
            >
              <p>Index d’hier : 18 736,0</p>
              <button type="button">Classer sans suite</button>
            </DetailPanel>
          ) : undefined
        }
      />
    );
  }

  it("focus sur le titre à l’ouverture ; Échap referme et rend le focus à la ligne", async () => {
    const { container } = render(<Screen />);
    const user = userEvent.setup();
    const first = screen.getByRole("button", { name: "Compteur 0412-8833" });
    await user.click(first);
    const panel = screen.getByRole("region", { name: "Compteur 0412-8833" });
    expect(screen.getByRole("heading", { level: 2, name: "Compteur 0412-8833" })).toHaveFocus();
    expect(within(panel).getByText("Loick Makosso · 6 kVA")).toBeVisible();
    expect(await axeViolations(container)).toEqual([]);

    await user.tab();
    await user.keyboard("{Escape}");
    expect(screen.queryByRole("region", { name: "Compteur 0412-8833" })).toBeNull();
    await vi.waitFor(() => expect(first).toHaveFocus());
  });

  it("une autre ligne : le panneau suit ; « Fermer le panneau » rend le focus à cette ligne", async () => {
    render(<Screen />);
    const user = userEvent.setup();
    await user.click(screen.getByRole("button", { name: "Compteur 0412-8833" }));
    const second = screen.getByRole("button", { name: "Compteur 0219-7741" });
    await user.click(second);
    expect(screen.getByRole("heading", { level: 2, name: "Compteur 0219-7741" })).toHaveFocus();
    await user.click(screen.getByRole("button", { name: "Fermer le panneau" }));
    await vi.waitFor(() => expect(second).toHaveFocus());
  });
});

describe("filtres d’une liste", () => {
  it("recherche : envoyée après une pause de saisie, ou tout de suite avec Entrée", async () => {
    const onSearch = vi.fn();
    render(
      <SearchField
        label="Rechercher un utilisateur"
        placeholder="Nom ou téléphone"
        value=""
        onSearch={onSearch}
      />,
    );
    const user = userEvent.setup();
    const field = screen.getByRole("searchbox", { name: "Rechercher un utilisateur" });
    await user.type(field, " Ngoma ");
    expect(onSearch).not.toHaveBeenCalled();
    await vi.waitFor(() => expect(onSearch).toHaveBeenCalledWith("Ngoma"), {
      timeout: SEARCH_DELAY_MS * 5,
    });
    expect(onSearch).toHaveBeenCalledOnce();
    await user.clear(field);
    await user.type(field, "06 12{Enter}");
    expect(onSearch).toHaveBeenLastCalledWith("06 12");
  });

  it("la recherche suit l’adresse (« Précédent » du navigateur)", () => {
    const { rerender } = render(
      <SearchField label="Rechercher" placeholder="" value="Ngoma" onSearch={vi.fn()} />,
    );
    expect(screen.getByRole("searchbox")).toHaveValue("Ngoma");
    rerender(<SearchField label="Rechercher" placeholder="" value="" onSearch={vi.fn()} />);
    expect(screen.getByRole("searchbox")).toHaveValue("");
  });

  it("pastilles : un choix, état lu (`aria-pressed`)", async () => {
    const onChange = vi.fn();
    const { container } = render(
      <FilterChips
        label="Filtrer par rôle"
        value="all"
        onChange={onChange}
        options={[
          { value: "all", label: "Tous" },
          { value: "client", label: "Clients" },
        ]}
      />,
    );
    expect(screen.getByRole("group", { name: "Filtrer par rôle" })).toBeVisible();
    expect(screen.getByRole("button", { name: "Tous" })).toHaveAttribute("aria-pressed", "true");
    expect(screen.getByRole("button", { name: "Clients" })).toHaveAttribute(
      "aria-pressed",
      "false",
    );
    await userEvent.setup().click(screen.getByRole("button", { name: "Clients" }));
    expect(onChange).toHaveBeenCalledWith("client");
    expect(await axeViolations(container)).toEqual([]);
  });
});
