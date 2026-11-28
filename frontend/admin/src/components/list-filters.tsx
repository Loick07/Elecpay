"use client";

// Barre de filtres des listes (maquettes A2, A5, A7) : recherche (loupe, 40 px) et pastilles de
// filtre. La recherche n'interroge l'API qu'après une pause de saisie (400 ms : quotas de ngrok) ;
// les pastilles sont des boutons à bascule (`aria-pressed`), un seul choix à la fois.
import { Search } from "lucide-react";
import { useEffect, useId, useRef, useState } from "react";

import { cn } from "@/lib/utils";

export const SEARCH_DELAY_MS = 400;

export function SearchField({
  label,
  placeholder,
  value,
  onSearch,
}: {
  /** Nom lu par les lecteurs d'écran (« Rechercher un utilisateur »). */
  label: string;
  placeholder: string;
  /** Valeur de l'adresse (`q`). */
  value: string;
  onSearch: (query: string) => void;
}) {
  const [draft, setDraft] = useState(value);
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const id = useId();

  // L'adresse change ailleurs (« Précédent », lien) : le champ suit.
  const [shown, setShown] = useState(value);
  if (value !== shown) {
    setShown(value);
    setDraft(value);
  }

  useEffect(() => () => clearTimeout(timer.current ?? undefined), []);

  function change(next: string) {
    setDraft(next);
    clearTimeout(timer.current ?? undefined);
    timer.current = setTimeout(() => onSearch(next.trim()), SEARCH_DELAY_MS);
  }

  return (
    <div className="bg-surface-1 border-line focus-within:border-current-base flex min-h-10 max-w-[420px] flex-[1_1_280px] items-center gap-2 rounded-[10px] border px-3">
      <Search aria-hidden="true" className="text-ink-muted size-4 shrink-0" />
      <label htmlFor={id} className="sr-only">
        {label}
      </label>
      <input
        id={id}
        type="search"
        value={draft}
        placeholder={placeholder}
        onChange={(event) => change(event.target.value)}
        onKeyDown={(event) => {
          if (event.key === "Enter") {
            clearTimeout(timer.current ?? undefined);
            onSearch(draft.trim());
          }
        }}
        className="text-admin-body text-ink placeholder:text-ink-faint min-w-0 flex-1 bg-transparent outline-none"
      />
    </div>
  );
}

export function FilterChips<V extends string>({
  label,
  options,
  value,
  onChange,
}: {
  /** Nom du groupe (« Filtrer par rôle »). */
  label: string;
  options: readonly { value: V; label: string }[];
  value: V;
  onChange: (value: V) => void;
}) {
  return (
    <div role="group" aria-label={label} className="flex flex-wrap gap-1.5">
      {options.map((option) => {
        const selected = option.value === value;
        return (
          <button
            key={option.value}
            type="button"
            aria-pressed={selected}
            onClick={() => onChange(option.value)}
            className={cn(
              "text-ink min-h-9 rounded-full border px-3 text-[13px] leading-5 font-medium",
              selected ? "border-volt bg-volt-soft" : "border-line bg-surface-1 hover:bg-surface-2",
            )}
          >
            {option.label}
          </button>
        );
      })}
    </div>
  );
}
