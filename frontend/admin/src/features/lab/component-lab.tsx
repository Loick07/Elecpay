"use client";

// ÉCRAN D'ESSAI des composants communs (A2.3, « Terminé quand » : un écran utilise tableau,
// panneau et confirmation). Il n'existe QUE si le serveur a `ELECPAY_ESSAI=1` (tests de bout en
// bout, essais locaux) : jamais en ligne. Lecture seule de `GET /admin/users` ; la confirmation
// avec motif n'envoie RIEN à l'API. Les vrais écrans (Utilisateurs en A3…) le remplacent.
import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { useState } from "react";

import { type AdminColumn, AdminTable } from "@/components/admin-table";
import { AdminKpi } from "@/components/admin-kpi";
import { ConfirmWithReason } from "@/components/confirm-with-reason";
import { DetailPanel, ListWithPanel } from "@/components/detail-panel";
import { ExportCsvButton } from "@/components/export-csv-button";
import { FilterChips, SearchField } from "@/components/list-filters";
import { RefreshControl } from "@/components/refresh-control";
import { StatusBadge } from "@/components/status-badge";
import { Button } from "@/components/ui/button";
import { useToast } from "@/components/ui/toaster";
import { api, unwrap } from "@/lib/api/client";
import type { components } from "@/lib/api/schema";
import { formatDate, formatDateTime, formatDecimal, formatFcfa, formatPhone } from "@/lib/format";
import { PAGE_SIZE, useListParams } from "@/lib/list-params";
import { ROLE_LABELS } from "@/lib/session/session-context";
import { billStatuses, transactionStatuses, transactionUnknown } from "@/lib/status/statuses";
import { cn } from "@/lib/utils";
import { REASON_LIMITS } from "@/lib/validation";

import { TeamPage } from "../shell/team-page";

type UserRow = components["schemas"]["AdminUserRow"];
type UserKind = components["schemas"]["UserKind"];

const FILTERS = ["q", "kind"] as const;
const KINDS: readonly { value: "" | UserKind; label: string }[] = [
  { value: "", label: "Tous" },
  { value: "client", label: "Clients" },
  { value: "delegated_payer", label: "Payeurs délégués" },
  { value: "team", label: "Équipe ElecPay" },
];
const STATUSES = [
  ...Object.values(billStatuses),
  ...Object.values(transactionStatuses),
  transactionUnknown,
];

function roleText(user: UserRow): string {
  const role = ROLE_LABELS[user.role] ?? user.role;
  return user.is_delegated_payer ? `${role} · payeur délégué` : role;
}

function unpaidText(user: UserRow): string {
  if (user.unpaid.count === 0) return "—";
  return `${user.unpaid.count} · ${formatFcfa(user.unpaid.amount)}`;
}

function AccountBadge({ active }: { active: boolean }) {
  return (
    <span
      className={cn(
        "inline-flex h-[22px] items-center rounded-[6px] px-2 text-[11px] leading-[14px] font-semibold",
        active ? "bg-success-soft text-success-text" : "bg-surface-2 text-ink-muted",
      )}
    >
      {active ? "Actif" : "Désactivé"}
    </span>
  );
}

export function ComponentLab() {
  const { page, filters, update } = useListParams(FILTERS);
  const kind = (KINDS.some((option) => option.value === filters.kind) ? filters.kind : "") as
    "" | UserKind;
  const users = useQuery({
    queryKey: ["admin", "users", { page, q: filters.q, kind }],
    queryFn: () =>
      unwrap(
        api.GET("/api/v1/admin/users", {
          params: {
            query: { page, size: PAGE_SIZE, q: filters.q || undefined, kind: kind || undefined },
          },
        }),
      ),
    placeholderData: keepPreviousData,
  });
  const [selected, setSelected] = useState<UserRow | null>(null);
  const [confirming, setConfirming] = useState(false);
  const toast = useToast();
  const now = new Date();

  const columns: AdminColumn<UserRow>[] = [
    {
      id: "user",
      header: "Utilisateur",
      cell: (user) => (
        <span className="flex flex-col">
          <span className="text-admin-body font-medium">{user.full_name}</span>
          <span className="text-ink-muted text-xs leading-4">{formatPhone(user.phone)}</span>
        </span>
      ),
    },
    { id: "role", header: "Rôle", cell: roleText },
    { id: "homes", header: "Foyers", cell: (user) => user.households, align: "right" },
    { id: "unpaid", header: "Factures impayées", cell: unpaidText },
    {
      id: "last",
      header: "Dernière connexion",
      cell: (user) =>
        user.last_login_at ? formatDateTime(user.last_login_at, now) : "Jamais connecté",
    },
    { id: "status", header: "Statut", cell: (user) => <AccountBadge active={user.is_active} /> },
  ];

  return (
    <TeamPage
      title="Essai des composants"
      description="Page d’essai de l’étape A2, absente en ligne : lecture de GET /admin/users ; la confirmation n’envoie rien."
      actions={
        <>
          <RefreshControl
            updatedAt={users.dataUpdatedAt}
            refreshing={users.isFetching}
            onRefresh={() => void users.refetch()}
          />
          <ExportCsvButton
            path="/api/v1/admin/users/export.csv"
            query={{ q: filters.q || undefined, kind: kind || undefined }}
            fallbackName="utilisateurs.csv"
          />
        </>
      }
    >
      <section aria-label="Indicateurs" className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        <AdminKpi
          label="Comptes"
          value={users.data ? formatDecimal(users.data.accounts, 0) : "—"}
        />
        <AdminKpi
          label="Comptes actifs"
          value={users.data ? formatDecimal(users.data.active_accounts, 0) : "—"}
          delta={{ text: "Exemple de variation", tone: "success" }}
        />
      </section>

      <section aria-label="Statuts de la charte" className="flex flex-wrap gap-2">
        {STATUSES.map((status) => (
          <StatusBadge key={status.label} status={status} />
        ))}
      </section>

      <div className="flex flex-wrap items-center gap-2">
        <SearchField
          label="Rechercher un utilisateur"
          placeholder="Nom ou téléphone"
          value={filters.q}
          onSearch={(q) => update({ q })}
        />
        <FilterChips
          label="Filtrer par type de compte"
          options={KINDS}
          value={kind}
          onChange={(value) => update({ kind: value })}
        />
      </div>

      <ListWithPanel
        list={
          <AdminTable<UserRow>
            label="Utilisateurs"
            columns={columns}
            rows={users.data?.items}
            rowKey={(user) => String(user.id)}
            onOpen={setSelected}
            selectedKey={selected ? String(selected.id) : null}
            loading={users.isPending}
            refetching={users.isFetching && !users.isPending}
            error={users.error}
            onRetry={() => void users.refetch()}
            empty={{
              title: "Aucun utilisateur ne correspond à cette recherche.",
              description: "Essayez un autre nom, un autre numéro ou un autre filtre.",
            }}
            pagination={
              users.data
                ? {
                    page,
                    size: PAGE_SIZE,
                    total: users.data.total,
                    onPageChange: (next) => update({ page: next }),
                  }
                : undefined
            }
          />
        }
        panel={
          selected ? (
            <DetailPanel
              title={selected.full_name}
              subtitle={`${roleText(selected)} · ${formatPhone(selected.phone)}`}
              badge={<AccountBadge active={selected.is_active} />}
              onClose={() => setSelected(null)}
              actions={
                <Button size="sm" variant="danger" onClick={() => setConfirming(true)}>
                  Essayer la confirmation avec motif
                </Button>
              }
            >
              <dl className="grid grid-cols-2 gap-2.5 text-[13px] leading-5 tabular-nums">
                <div className="flex flex-col">
                  <dt className="text-ink-muted text-xs">Foyers</dt>
                  <dd className="font-semibold">{selected.households}</dd>
                </div>
                <div className="flex flex-col">
                  <dt className="text-ink-muted text-xs">Factures impayées</dt>
                  <dd className="font-semibold">{unpaidText(selected)}</dd>
                </div>
                <div className="flex flex-col">
                  <dt className="text-ink-muted text-xs">E-mail</dt>
                  <dd className="font-semibold break-all">{selected.email ?? "Non renseigné"}</dd>
                </div>
                <div className="flex flex-col">
                  <dt className="text-ink-muted text-xs">Inscrit le</dt>
                  <dd className="font-semibold">{formatDate(selected.created_at)}</dd>
                </div>
              </dl>
            </DetailPanel>
          ) : undefined
        }
      />

      <ConfirmWithReason
        open={confirming}
        onOpenChange={setConfirming}
        title={`Essai : action sensible sur le compte de ${selected?.full_name ?? ""}`}
        description={
          <>
            <p>Page d’essai : rien n’est envoyé à l’API, aucun compte n’est modifié.</p>
            <p>Un vrai écran dirait ici les conséquences de l’action.</p>
          </>
        }
        limits={REASON_LIMITS.long}
        confirmLabel="Confirmer l’essai"
        pendingLabel="Vérification…"
        onConfirm={async (reason) => {
          toast(`Essai réussi : motif « ${reason} » accepté, aucune action envoyée.`);
        }}
      />
    </TeamPage>
  );
}
