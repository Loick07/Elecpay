// En-tête d'une page de l'équipe, dans le cadre (maquettes : titre `admin-h1`, sous-titre 13 px
// `ink-muted` — compte, date de mise à jour —, actions à droite : export, « Actualiser »…). Le menu
// latéral, le badge « Mode démo » et le membre connecté sont dans le cadre (`AppShell`).
import type { ReactNode } from "react";

export function TeamPage({
  title,
  description,
  actions,
  children,
}: {
  title: string;
  description?: ReactNode;
  actions?: ReactNode;
  children: ReactNode;
}) {
  return (
    <>
      <header className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-admin-h1 text-ink">{title}</h1>
          {description ? (
            <p className="text-ink-muted mt-0.5 text-[13px] leading-5">{description}</p>
          ) : null}
        </div>
        {actions ? <div className="flex flex-wrap items-center gap-2">{actions}</div> : null}
      </header>
      {children}
    </>
  );
}
