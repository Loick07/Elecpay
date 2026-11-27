// Bouton de la charte (`frontend/design/components/Button`) : le libellé dit exactement l'action.
// - primary (`volt`) : l'action principale, une seule par écran ;
// - secondary : action utile mais secondaire (opaque : le verre est réservé au mobile) ;
// - ghost (`volt-text`) : lien d'action ;
// - danger (`error-soft` / `error-text`) : action destructive (avec confirmation et motif).
// Chargement : même taille, un cercle tourne, le libellé dit ce qui se passe, plus cliquable.
import { cva, type VariantProps } from "class-variance-authority";
import { LoaderCircle } from "lucide-react";
import type { ComponentProps, ReactNode } from "react";

import { cn } from "@/lib/utils";

export const buttonVariants = cva(
  "text-admin-body inline-flex min-h-12 items-center justify-center gap-2 rounded-md border border-transparent px-5 font-semibold transition-colors duration-150 ease-out disabled:cursor-not-allowed disabled:opacity-45",
  {
    variants: {
      variant: {
        primary: "bg-volt text-on-volt hover:bg-volt-press",
        secondary: "border-line bg-surface-1 text-ink hover:bg-surface-2",
        ghost: "text-volt-text min-h-0 bg-transparent px-0 underline-offset-4 hover:underline",
        danger: "bg-error-soft text-error-text",
      },
      block: { true: "w-full" },
    },
    defaultVariants: { variant: "secondary" },
  },
);

type ButtonProps = ComponentProps<"button"> &
  VariantProps<typeof buttonVariants> & {
    /** En cours : bouton désactivé, cercle qui tourne, `loadingLabel` à la place du libellé. */
    loading?: boolean;
    loadingLabel?: string;
    icon?: ReactNode;
  };

export function Button({
  variant,
  block,
  loading = false,
  loadingLabel,
  icon,
  className,
  disabled,
  children,
  type = "button",
  ...props
}: ButtonProps) {
  return (
    <button
      type={type}
      className={cn(buttonVariants({ variant, block }), className)}
      disabled={disabled || loading}
      aria-busy={loading || undefined}
      {...props}
    >
      {loading ? (
        <LoaderCircle
          aria-hidden="true"
          className="size-5 animate-spin motion-reduce:animate-none"
        />
      ) : (
        icon
      )}
      {loading && loadingLabel ? loadingLabel : children}
    </button>
  );
}
