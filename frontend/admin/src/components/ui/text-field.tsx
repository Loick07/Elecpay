// Champ de saisie de la charte (`frontend/design/components/TextField`) : libellé toujours visible
// au-dessus, aide ou erreur en dessous, reliées au champ pour les lecteurs d'écran
// (`aria-describedby`, `aria-invalid`). Focus : bordure `current` + halo `current-soft`.
import { type ComponentProps, type ReactNode, useId } from "react";

import { cn } from "@/lib/utils";

export const inputClasses =
  "text-admin-body text-ink placeholder:text-ink-faint border-line bg-surface-1 min-h-12 w-full rounded-md border px-4 focus:border-current-base focus:shadow-[0_0_0_3px_var(--current-soft)] focus-visible:outline-none aria-invalid:border-error";

type TextFieldProps = Omit<ComponentProps<"input">, "id"> & {
  label: string;
  hint?: ReactNode;
  error?: string;
  /** Élément placé à droite dans le champ (ex. bouton « Afficher » du mot de passe). */
  trailing?: ReactNode;
};

export function TextField({ label, hint, error, trailing, className, ...props }: TextFieldProps) {
  const id = useId();
  const hintId = `${id}-aide`;
  const errorId = `${id}-erreur`;
  const describedBy = [hint && !error ? hintId : null, error ? errorId : null]
    .filter(Boolean)
    .join(" ");
  return (
    <div className="flex flex-col gap-1.5">
      <label htmlFor={id} className="text-admin-label text-ink-muted">
        {label}
      </label>
      <div className="relative">
        <input
          id={id}
          aria-invalid={error ? true : undefined}
          aria-describedby={describedBy || undefined}
          className={cn(inputClasses, trailing ? "pr-28" : null, className)}
          {...props}
        />
        {trailing ? (
          <div className="absolute inset-y-0 right-2 flex items-center">{trailing}</div>
        ) : null}
      </div>
      {hint && !error ? (
        <p id={hintId} className="text-admin-label text-ink-muted">
          {hint}
        </p>
      ) : null}
      {error ? (
        <p id={errorId} className="text-admin-label text-error-text">
          {error}
        </p>
      ) : null}
    </div>
  );
}
