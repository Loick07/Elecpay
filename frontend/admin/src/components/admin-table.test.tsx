import { screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";

import { ApiError } from "@/lib/api/errors";
import { axeViolations } from "@/test/axe";
import { renderWithProviders } from "@/test/render";

import { type AdminColumn, AdminTable, pageSummary } from "./admin-table";

type Row = { id: number; name: string; homes: number };

const COLUMNS: AdminColumn<Row>[] = [
  { id: "name", header: "Utilisateur", cell: (row) => row.name },
  { id: "homes", header: "Foyers", cell: (row) => row.homes, align: "right" },
];
const ROWS: Row[] = [
  { id: 1, name: "Loick Makosso", homes: 2 },
  { id: 2, name: "Grâce Ngoma", homes: 1 },
];

function renderTable(props: Partial<Parameters<typeof AdminTable<Row>>[0]> = {}) {
  return renderWithProviders(
    <AdminTable<Row>
      label="Utilisateurs"
      columns={COLUMNS}
      rows={ROWS}
      rowKey={(row) => String(row.id)}
      loading={false}
      empty={{ title: "Aucun utilisateur ne correspond à cette recherche." }}
      {...props}
    />,
  );
}

describe("tableau du back-office", () => {
  it("en-têtes, lignes, nombres à droite, zone défilante atteignable au clavier", async () => {
    const { container } = renderTable();
    const table = screen.getByRole("table", { name: "Utilisateurs" });
    expect(
      within(table)
        .getAllByRole("columnheader")
        .map((th) => th.textContent),
    ).toEqual(["Utilisateur", "Foyers"]);
    expect(within(table).getAllByRole("row")).toHaveLength(3);
    expect(within(table).getByRole("columnheader", { name: "Foyers" })).toHaveClass("text-right");
    expect(screen.getByRole("region", { name: "Utilisateurs" })).toHaveAttribute("tabindex", "0");
    expect(await axeViolations(container)).toEqual([]);
  });

  it("ouvrir le détail : bouton de la première cellule (clavier) ou clic sur la ligne", async () => {
    const onOpen = vi.fn();
    renderTable({ onOpen, selectedKey: "2" });
    const user = userEvent.setup();
    await user.tab(); // zone défilante
    await user.tab();
    expect(screen.getByRole("button", { name: "Loick Makosso" })).toHaveFocus();
    await user.keyboard("{Enter}");
    expect(onOpen).toHaveBeenLastCalledWith(ROWS[0]);
    await user.click(screen.getByText("1"));
    expect(onOpen).toHaveBeenLastCalledWith(ROWS[1]);
    expect(onOpen).toHaveBeenCalledTimes(2);
    expect(screen.getByText("Grâce Ngoma").closest("tr")).toHaveAttribute("aria-current", "true");
  });

  it("chargement : squelettes, tableau occupé, « Chargement… » lu", () => {
    renderTable({ rows: undefined, loading: true });
    expect(screen.getByRole("table")).toHaveAttribute("aria-busy", "true");
    expect(screen.getByRole("status")).toHaveTextContent("Chargement…");
  });

  it("vide : ce qui manque, dit clairement", () => {
    renderTable({ rows: [] });
    expect(screen.getByText("Aucun utilisateur ne correspond à cette recherche.")).toBeVisible();
  });

  it("erreur : message, référence, « Réessayer »", async () => {
    const onRetry = vi.fn();
    renderTable({
      rows: undefined,
      error: new ApiError({
        status: 502,
        code: "API_UNREACHABLE",
        message: "L'API ElecPay ne répond pas.",
        requestId: "ref-liste-1",
      }),
      onRetry,
    });
    const alert = screen.getByRole("alert");
    expect(alert).toHaveTextContent("L'API ElecPay ne répond pas.");
    expect(alert).toHaveTextContent("Référence : ref-liste-1");
    expect(screen.queryByRole("table")).toBeNull();
    await userEvent.setup().click(screen.getByRole("button", { name: "Réessayer" }));
    expect(onRetry).toHaveBeenCalledOnce();
  });

  it("pagination : résumé de la maquette, Précédent / Suivant aux bornes", async () => {
    const onPageChange = vi.fn();
    const { rerender } = renderTable({
      pagination: { page: 1, size: 20, total: 45, onPageChange },
    });
    const pages = screen.getByRole("navigation", { name: "Pages" });
    expect(pages).toHaveTextContent("2 affichés · page 1 sur 3");
    expect(within(pages).getByRole("button", { name: "Précédent" })).toBeDisabled();
    await userEvent.setup().click(within(pages).getByRole("button", { name: "Suivant" }));
    expect(onPageChange).toHaveBeenCalledWith(2);
    rerender(
      <AdminTable<Row>
        label="Utilisateurs"
        columns={COLUMNS}
        rows={ROWS}
        rowKey={(row) => String(row.id)}
        loading={false}
        empty={{ title: "Vide" }}
        pagination={{ page: 3, size: 20, total: 45, onPageChange }}
      />,
    );
    expect(screen.getByRole("button", { name: "Suivant" })).toBeDisabled();
    expect(screen.getByRole("button", { name: "Précédent" })).toBeEnabled();
  });

  it("résumé : singulier, et jamais « page 1 sur 0 »", () => {
    expect(pageSummary(1, 1, 20, 1)).toBe("1 affiché · page 1 sur 1");
    expect(pageSummary(0, 1, 20, 0)).toBe("0 affiché · page 1 sur 1");
  });
});
