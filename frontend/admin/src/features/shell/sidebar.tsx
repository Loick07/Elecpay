"use client";

// Menu latéral bleu nuit (maquette `Menu.dc.html`, thème Nuit dans un écran Jour) : logo, entrées
// avec icône (18 px) et pastille, puis « Mode démo » et le membre connecté (Mon compte, Se
// déconnecter). Entrées masquées selon les droits lus dans `GET /admin/permissions` (ex. Journal
// invisible pour le support) : le serveur refuse de toute façon.
// Petits écrans (DA2.1, moins de 1024 px) : le menu passe au-dessus du contenu, replié derrière un
// bouton « Menu ».
// Pastilles : anomalies de relevé à traiter (`GET /admin/meters`, `counters.open_anomalies`) et
// transactions en attente (`GET /admin/transactions?status=en_attente`, `total`), une page d'un
// élément chacune ; réglages communs des lectures (DA2.3 : aucune interrogation périodique).
import { useQuery } from "@tanstack/react-query";
import {
  ArrowLeftRight,
  Bell,
  FileText,
  Gauge,
  LayoutDashboard,
  LogOut,
  type LucideIcon,
  Menu,
  ScrollText,
  Settings,
  Users,
  X,
  Zap,
} from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useId, useState } from "react";

import { HealthDemoBadge } from "@/components/demo-badge";
import { api, unwrap } from "@/lib/api/client";
import { type Level, usePermissions } from "@/lib/permissions/permissions";
import { ROLE_LABELS, useTeamMember } from "@/lib/session/session-context";
import { useLogout } from "@/lib/session/use-logout";
import { cn } from "@/lib/utils";

type Badge = "anomalies" | "pending";

export type NavItem = {
  href: string;
  label: string;
  icon: LucideIcon;
  /** Niveau exigé ; sans niveau : toute l'équipe. */
  level?: Level;
  badge?: Badge;
};

export const NAV_ITEMS: readonly NavItem[] = [
  { href: "/", label: "Tableau de bord", icon: LayoutDashboard },
  { href: "/utilisateurs", label: "Utilisateurs", icon: Users },
  { href: "/compteurs", label: "Compteurs", icon: Gauge, badge: "anomalies" },
  { href: "/factures", label: "Factures", icon: FileText },
  { href: "/transactions", label: "Transactions", icon: ArrowLeftRight, badge: "pending" },
  { href: "/notifications", label: "Notifications", icon: Bell },
  { href: "/journal", label: "Journal d’activité", icon: ScrollText, level: "admin" },
  { href: "/parametres", label: "Paramètres et rôles", icon: Settings },
];

const BADGE_TEXT: Record<Badge, (count: number) => string> = {
  anomalies: (count) => `${count} ${count > 1 ? "anomalies" : "anomalie"} à traiter`,
  pending: (count) => `${count} ${count > 1 ? "transactions" : "transaction"} en attente`,
};

export const menuCountsKeys = {
  anomalies: ["admin", "menu", "anomalies"],
  pending: ["admin", "menu", "pending"],
} as const;

/** L'entrée est-elle la page affichée ? (« / » seulement pour l'accueil, sinon la rubrique.) */
export function isCurrent(href: string, pathname: string): boolean {
  if (href === "/") return pathname === "/";
  return pathname === href || pathname.startsWith(`${href}/`);
}

/** Initiales de l'avatar : « Agent Support Démo » → « AS ». */
export function initials(fullName: string): string {
  return fullName
    .trim()
    .split(/\s+/)
    .slice(0, 2)
    .map((word) => word.charAt(0).toUpperCase())
    .join("");
}

function useMenuCounts(enabled: boolean): Record<Badge, number | undefined> {
  const anomalies = useQuery({
    queryKey: menuCountsKeys.anomalies,
    queryFn: () => unwrap(api.GET("/api/v1/admin/meters", { params: { query: { size: 1 } } })),
    select: (data) => data.counters.open_anomalies,
    enabled,
  });
  const pending = useQuery({
    queryKey: menuCountsKeys.pending,
    queryFn: () =>
      unwrap(
        api.GET("/api/v1/admin/transactions", {
          params: { query: { status: "en_attente", size: 1 } },
        }),
      ),
    select: (data) => data.total,
    enabled,
  });
  return { anomalies: anomalies.data, pending: pending.data };
}

export function Sidebar() {
  const pathname = usePathname();
  const member = useTeamMember();
  const permissions = usePermissions();
  const logout = useLogout();
  const [open, setOpen] = useState(false);
  const menuId = useId();
  const counts = useMenuCounts(permissions.ready && permissions.hasLevel("staff"));
  const items = NAV_ITEMS.filter((item) => !item.level || permissions.hasLevel(item.level));

  return (
    <aside
      data-theme="dark"
      className="bg-bg text-ink flex flex-col gap-5 px-3.5 py-4 lg:sticky lg:top-0 lg:h-screen lg:w-58 lg:shrink-0 lg:overflow-y-auto lg:py-5"
    >
      <div className="flex items-center justify-between gap-3 px-2">
        <Link href="/" className="flex items-center gap-2.5 rounded-md">
          <span className="bg-volt text-on-volt grid size-8 place-items-center rounded-[10px]">
            <Zap aria-hidden="true" fill="currentColor" className="size-4.5" />
          </span>
          <span className="flex flex-col">
            <span className="text-[15px] leading-5 font-bold">ElecPay</span>
            <span className="text-ink-muted text-[11px] leading-[14px] font-medium">
              Back-office
            </span>
          </span>
        </Link>
        <button
          type="button"
          aria-expanded={open}
          aria-controls={menuId}
          onClick={() => setOpen((shown) => !shown)}
          className="text-admin-body text-ink border-line inline-flex min-h-10 items-center gap-2 rounded-md border px-3 font-medium lg:hidden"
        >
          {open ? (
            <X aria-hidden="true" className="size-4" />
          ) : (
            <Menu aria-hidden="true" className="size-4" />
          )}
          Menu
        </button>
      </div>

      <div id={menuId} className={cn("flex-1 flex-col gap-5", open ? "flex" : "hidden", "lg:flex")}>
        <nav aria-label="Menu principal" className="flex flex-col gap-0.5">
          {items.map((item) => {
            const current = isCurrent(item.href, pathname);
            const count = item.badge ? counts[item.badge] : undefined;
            const Icon = item.icon;
            return (
              <Link
                key={item.href}
                href={item.href}
                aria-current={current ? "page" : undefined}
                onClick={() => setOpen(false)}
                className={cn(
                  "text-admin-body flex min-h-10 items-center gap-2.5 rounded-[10px] px-2.5",
                  current
                    ? "bg-volt/14 text-ink font-semibold"
                    : "text-ink-muted hover:text-ink font-medium hover:bg-white/6",
                )}
              >
                <Icon
                  aria-hidden="true"
                  strokeWidth={1.75}
                  className={cn("size-4.5 shrink-0", current && "text-volt")}
                />
                <span className="flex-1">{item.label}</span>
                {item.badge && count ? (
                  <>
                    <span
                      aria-hidden="true"
                      className="bg-warning-soft text-warning grid h-5 min-w-5 place-items-center rounded-full px-1.5 text-[11px] leading-[14px] font-semibold"
                    >
                      {count}
                    </span>
                    <span className="sr-only">, {BADGE_TEXT[item.badge](count)}</span>
                  </>
                ) : null}
              </Link>
            );
          })}
        </nav>

        <div className="mt-auto flex flex-col gap-2.5 px-2">
          <div className="self-start">
            <HealthDemoBadge />
          </div>
          <div className="flex items-center gap-2.5">
            <span
              aria-hidden="true"
              className="bg-current-soft text-current-text grid size-8 shrink-0 place-items-center rounded-full text-xs leading-4 font-semibold"
            >
              {initials(member.full_name)}
            </span>
            <span className="flex min-w-0 flex-col">
              <span className="truncate text-[13px] leading-[18px] font-medium">
                {member.full_name}
              </span>
              <span className="text-ink-muted text-xs leading-4">
                {ROLE_LABELS[member.role] ?? member.role}
              </span>
            </span>
          </div>
          <div className="flex flex-wrap items-center gap-x-4 gap-y-1">
            <Link
              href="/mon-compte"
              aria-current={isCurrent("/mon-compte", pathname) ? "page" : undefined}
              onClick={() => setOpen(false)}
              className="text-admin-label text-ink-muted hover:text-ink aria-[current=page]:text-ink inline-flex min-h-8 items-center underline-offset-4 hover:underline"
            >
              Mon compte
            </Link>
            <button
              type="button"
              disabled={logout.isPending}
              onClick={() => logout.mutate("deconnexion")}
              className="text-admin-label text-ink-muted hover:text-ink inline-flex min-h-8 items-center gap-1.5"
            >
              <LogOut aria-hidden="true" className="size-3.5" />
              {logout.isPending ? "Déconnexion…" : "Se déconnecter"}
            </button>
          </div>
        </div>
      </div>
    </aside>
  );
}
