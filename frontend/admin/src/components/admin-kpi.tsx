// Tuile d'indicateur (`frontend/design/components/AdminKpi`) : libellé `admin-label`, valeur
// `admin-kpi` en chiffres tabulaires, variation dans la couleur de son sens (texte `*-text`,
// lisible) ; fond `surface-1`, bordure `line`, sans ombre. Avec `href`, toute la tuile ouvre la
// liste filtrée correspondante.
import Link from "next/link";
import type { ReactNode } from "react";

import { cn } from "@/lib/utils";

type DeltaTone = "success" | "warning" | "error" | "neutral";

const DELTA_CLASSES: Record<DeltaTone, string> = {
  success: "text-success-text",
  warning: "text-warning-text",
  error: "text-error-text",
  neutral: "text-ink-muted",
};

export function AdminKpi({
  label,
  value,
  unit,
  delta,
  href,
}: {
  label: string;
  value: ReactNode;
  unit?: string;
  delta?: { text: string; tone: DeltaTone };
  href?: string;
}) {
  const content = (
    <>
      <span className="text-admin-label text-ink-muted">{label}</span>
      <span className="text-admin-kpi text-ink tabular-nums">
        {value}
        {unit ? <span className="text-ink-muted text-[13px] font-medium"> {unit}</span> : null}
      </span>
      {delta ? (
        <span className={cn("text-admin-label", DELTA_CLASSES[delta.tone])}>{delta.text}</span>
      ) : null}
    </>
  );
  const classes = "bg-surface-1 border-line flex min-w-0 flex-col gap-1.5 rounded-md border p-4";
  return href ? (
    <Link href={href} className={cn(classes, "hover:bg-surface-2 transition-colors")}>
      {content}
    </Link>
  ) : (
    <div className={classes}>{content}</div>
  );
}
