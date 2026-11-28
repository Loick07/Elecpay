"use client";

// Panneau latéral de détail (charte : « le détail dans un panneau latéral » ; maquette A4) : une
// colonne À CÔTÉ de la liste (`flex: 1 1 300px`, la liste `flex: 2 1 560px`), qui passe dessous
// sur un petit écran. Ce n'est pas une fenêtre : le reste de la page reste utilisable.
// - à l'ouverture (ou quand l'élément affiché change), le focus va sur le titre du panneau ;
// - « Fermer » ou Échap le referment, et le focus revient à ce qui l'avait ouvert.
import { X } from "lucide-react";
import { type ReactNode, useCallback, useEffect, useId, useRef } from "react";

/** Liste et panneau côte à côte (maquette A4). */
export function ListWithPanel({ list, panel }: { list: ReactNode; panel?: ReactNode }) {
  return (
    <div className="flex flex-wrap items-start gap-3">
      <div className="min-w-0 flex-[2_1_560px]">{list}</div>
      {panel ? <div className="min-w-0 flex-[1_1_300px] lg:sticky lg:top-6">{panel}</div> : null}
    </div>
  );
}

export function DetailPanel({
  title,
  subtitle,
  badge,
  onClose,
  actions,
  children,
}: {
  title: string;
  subtitle?: ReactNode;
  /** Référence, statut… affichés au-dessus du titre. */
  badge?: ReactNode;
  onClose: () => void;
  actions?: ReactNode;
  children: ReactNode;
}) {
  const titleId = useId();
  const panel = useRef<HTMLElement>(null);
  const heading = useRef<HTMLHeadingElement>(null);
  const opener = useRef<HTMLElement | null>(null);

  // Ce qui avait le focus à l'ouverture (le bouton de la ligne), pour l'y ramener ; une autre
  // ligne ouverte ensuite devient le nouveau point de retour.
  useEffect(() => {
    const active = document.activeElement;
    if (active instanceof HTMLElement && !panel.current?.contains(active)) {
      opener.current = active;
    }
    heading.current?.focus();
  }, [title]);

  const close = useCallback(() => {
    onClose();
    const target = opener.current;
    if (target?.isConnected) requestAnimationFrame(() => target.focus());
  }, [onClose]);

  // Échap, quand le focus est dans le panneau, le referme.
  useEffect(() => {
    const element = panel.current;
    if (!element) return;
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key !== "Escape") return;
      event.stopPropagation();
      close();
    };
    element.addEventListener("keydown", onKeyDown);
    return () => element.removeEventListener("keydown", onKeyDown);
  }, [close]);

  return (
    <section
      ref={panel}
      aria-labelledby={titleId}
      className="bg-surface-1 border-line flex flex-col gap-3 rounded-md border p-[18px]"
    >
      <div className="flex items-start justify-between gap-3">
        <div className="flex min-w-0 flex-col gap-1.5">
          {badge ? <div className="flex flex-wrap items-center gap-2">{badge}</div> : null}
          <h2
            id={titleId}
            ref={heading}
            tabIndex={-1}
            className="text-ink rounded-sm text-base leading-6 font-semibold"
          >
            {title}
          </h2>
          {subtitle ? <p className="text-ink-muted text-[13px] leading-5">{subtitle}</p> : null}
        </div>
        <button
          type="button"
          onClick={close}
          aria-label="Fermer le panneau"
          className="text-ink-muted hover:text-ink hover:bg-surface-2 -m-1 grid size-9 shrink-0 place-items-center rounded-sm"
        >
          <X aria-hidden="true" className="size-4" />
        </button>
      </div>
      <div className="text-admin-body text-ink flex flex-col gap-3">{children}</div>
      {actions ? <div className="flex flex-wrap gap-2">{actions}</div> : null}
    </section>
  );
}
