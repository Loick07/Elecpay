"use client";

// Tableau du back-office (`frontend/design/components/AdminTable`, maquettes A2 à A10) : TanStack
// Table (colonnes) + rendu de la charte : Inter `admin-table`, chiffres tabulaires, montants à
// droite, lignes de 44 px, survol `surface-2`, en-têtes `admin-label` ; défile horizontalement
// sur un petit écran (zone atteignable au clavier).
// - ouvrir le détail : le PREMIER élément de la ligne est un bouton (clavier, lecteur d'écran) ;
//   un clic n'importe où sur la ligne fait de même ;
// - pagination côté serveur (20 lignes, PAGE_SIZE), page et filtres dans l'adresse
//   (`useListParams`) ; aucun tri : l'API n'en propose pas ;
// - états : chargement (squelettes), vide (ce qui manque), erreur (message, référence, Réessayer),
//   relecture (l'ancienne page reste affichée, atténuée) ;
// - aucune action d'une ligne ne peut passer une transaction en « Réussie » (aucune n'existe).
import { createColumnHelper, type RowData, tableFeatures, useTable } from "@tanstack/react-table";
import { type ReactNode, useMemo } from "react";

import { Button } from "@/components/ui/button";
import { EmptyState, ErrorState } from "@/components/ui/state-block";
import { describeError } from "@/lib/api/errors";
import { cn } from "@/lib/utils";

const features = tableFeatures({});
const NO_ROWS: never[] = [];
const SKELETON_ROWS = 5;

export type AdminColumn<T extends RowData> = {
  id: string;
  header: string;
  cell: (row: T) => ReactNode;
  /** Montants et nombres : à droite. */
  align?: "left" | "right";
};

export type TablePagination = {
  page: number;
  size: number;
  total: number;
  onPageChange: (page: number) => void;
};

/** « 10 affichés · page 1 sur 129 » (maquette A2). */
export function pageSummary(shown: number, page: number, size: number, total: number): string {
  const pages = Math.max(1, Math.ceil(total / size));
  return `${shown} ${shown > 1 ? "affichés" : "affiché"} · page ${page} sur ${pages}`;
}

export function AdminTable<T extends RowData>({
  label,
  columns,
  rows,
  rowKey,
  onOpen,
  selectedKey,
  loading,
  refetching = false,
  error,
  onRetry,
  empty,
  pagination,
}: {
  /** Nom du tableau pour les lecteurs d'écran (« Utilisateurs »). */
  label: string;
  columns: readonly AdminColumn<T>[];
  rows: readonly T[] | undefined;
  rowKey: (row: T) => string;
  /** Ouvre le détail de la ligne (panneau latéral). */
  onOpen?: (row: T) => void;
  /** Ligne affichée dans le panneau. */
  selectedKey?: string | null;
  loading: boolean;
  refetching?: boolean;
  error?: unknown;
  onRetry?: () => void;
  empty: { title: string; description?: string };
  pagination?: TablePagination;
}) {
  // TanStack ne connaît que les identifiants et les titres des colonnes. Les cellules sont rendues
  // ICI, par un simple appel de fonction : rendues par `FlexRender`, une colonne recréée par la page
  // devenait un nouveau composant, et React recréait le bouton de la ligne (le panneau ne pouvait
  // plus lui rendre le focus : défaut trouvé le 28/11/2026).
  const signature = JSON.stringify(columns.map((column) => [column.id, column.header]));
  const tableColumns = useMemo(() => {
    const helper = createColumnHelper<typeof features, T>();
    return (JSON.parse(signature) as [string, string][]).map(([id, header]) =>
      helper.display({ id, header }),
    );
  }, [signature]);
  const byId = new Map(columns.map((column) => [column.id, column]));

  function renderCell(columnId: string, row: T, index: number): ReactNode {
    const content = byId.get(columnId)?.cell(row) ?? null;
    if (index !== 0 || !onOpen) return content;
    return (
      <button
        type="button"
        onClick={(event) => {
          event.stopPropagation();
          onOpen(row);
        }}
        className="-mx-1 rounded-sm px-1 text-left"
      >
        {content}
      </button>
    );
  }
  const table = useTable({
    features,
    columns: tableColumns,
    data: (rows as T[] | undefined) ?? NO_ROWS,
    getRowId: (row) => rowKey(row),
  });

  if (error && !rows) {
    const { message, reference } = describeError(error);
    return (
      <ErrorState message={message} reference={reference} onRetry={onRetry} retrying={refetching} />
    );
  }

  const cellPadding = (index: number, last: boolean) =>
    cn(index === 0 ? "pl-4" : "pl-3", last ? "pr-4" : "pr-3");
  const headers = table.getHeaderGroups()[0]?.headers ?? [];

  return (
    <div className="flex flex-col gap-3">
      <div
        role="region"
        aria-label={label}
        // Zone qui défile sur un petit écran : atteignable au clavier pour défiler (WCAG 2.1.1,
        // règle axe « scrollable-region-focusable »).
        // eslint-disable-next-line jsx-a11y/no-noninteractive-tabindex -- voir ci-dessus
        tabIndex={0}
        className="bg-surface-1 border-line overflow-x-auto rounded-md border"
      >
        <table
          aria-label={label}
          aria-busy={loading || refetching || undefined}
          className={cn(
            "text-admin-table w-full border-collapse tabular-nums",
            refetching && "opacity-60 transition-opacity",
          )}
        >
          <thead>
            <tr>
              {headers.map((header, index) => (
                <th
                  key={header.id}
                  scope="col"
                  className={cn(
                    "text-admin-label text-ink-muted border-line border-b py-3 whitespace-nowrap",
                    byId.get(header.column.id)?.align === "right" ? "text-right" : "text-left",
                    cellPadding(index, index === headers.length - 1),
                  )}
                >
                  {byId.get(header.column.id)?.header}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {loading && !rows
              ? Array.from({ length: SKELETON_ROWS }, (_, rowIndex) => (
                  <tr key={rowIndex} aria-hidden="true">
                    {headers.map((header, index) => (
                      <td
                        key={header.id}
                        className={cn(
                          "border-line h-11 border-b py-2.5",
                          cellPadding(index, index === headers.length - 1),
                        )}
                      >
                        <span className="bg-surface-3 block h-3.5 w-3/4 animate-pulse rounded-sm motion-reduce:animate-none" />
                      </td>
                    ))}
                  </tr>
                ))
              : table.getRowModel().rows.map((row) => (
                  <tr
                    key={row.id}
                    aria-current={selectedKey === row.id ? "true" : undefined}
                    onClick={onOpen ? () => onOpen(row.original) : undefined}
                    className={cn(
                      "hover:bg-surface-2",
                      onOpen && "cursor-pointer",
                      selectedKey === row.id && "bg-surface-2",
                    )}
                  >
                    {row.getAllCells().map((cell, index, cells) => (
                      <td
                        key={cell.id}
                        className={cn(
                          "border-line h-11 border-b py-2.5 whitespace-nowrap",
                          byId.get(cell.column.id)?.align === "right" ? "text-right" : "text-left",
                          cellPadding(index, index === cells.length - 1),
                        )}
                      >
                        {renderCell(cell.column.id, row.original, index)}
                      </td>
                    ))}
                  </tr>
                ))}
          </tbody>
        </table>
        {loading && !rows ? (
          <p role="status" className="sr-only">
            Chargement…
          </p>
        ) : null}
        {rows && rows.length === 0 ? (
          <div className="p-4">
            <EmptyState title={empty.title} description={empty.description} />
          </div>
        ) : null}
      </div>

      {error && rows ? (
        <ErrorState
          message={describeError(error).message}
          reference={describeError(error).reference}
          onRetry={onRetry}
          retrying={refetching}
        />
      ) : null}

      {pagination && rows ? (
        <Pagination pagination={pagination} shown={rows.length} busy={refetching} />
      ) : null}
    </div>
  );
}

function Pagination({
  pagination: { page, size, total, onPageChange },
  shown,
  busy,
}: {
  pagination: TablePagination;
  shown: number;
  busy: boolean;
}) {
  const pages = Math.max(1, Math.ceil(total / size));
  return (
    <nav
      aria-label="Pages"
      className="text-ink-muted flex flex-wrap items-center justify-between gap-2 text-[13px] leading-5"
    >
      <span aria-live="polite">{pageSummary(shown, page, size, total)}</span>
      <div className="flex gap-1.5">
        <Button
          size="sm"
          disabled={page <= 1 || busy}
          onClick={() => onPageChange(page - 1)}
          className="min-h-9 px-3 text-[13px]"
        >
          Précédent
        </Button>
        <Button
          size="sm"
          disabled={page >= pages || busy}
          onClick={() => onPageChange(page + 1)}
          className="min-h-9 px-3 text-[13px]"
        >
          Suivant
        </Button>
      </div>
    </nav>
  );
}
