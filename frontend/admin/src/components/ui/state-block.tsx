// Blocs d'état de la charte (`frontend/design/components/StateBlock`, table « États d'écran ») :
// une pastille, un titre qui nomme la situation, une phrase qui dit quoi faire, une action.
// - vide : pastille neutre ; - erreur : pastille `error-soft`, message clair, référence à citer,
//   « Réessayer » ; - accès refusé : pastille neutre, aucune action (le serveur a décidé).
import { Inbox, type LucideIcon, ServerCrash, ShieldX } from "lucide-react";
import type { ReactNode } from "react";

import { cn } from "@/lib/utils";

import { Button } from "./button";

type StateBlockProps = {
  icon: LucideIcon;
  title: string;
  description?: ReactNode;
  tone?: "neutral" | "error";
  action?: ReactNode;
  /** Annoncé aussitôt (erreur) ou poliment (le reste). */
  role?: "alert" | "status";
  className?: string;
};

export function StateBlock({
  icon: Icon,
  title,
  description,
  tone = "neutral",
  action,
  role = "status",
  className,
}: StateBlockProps) {
  return (
    <div
      role={role}
      className={cn(
        "bg-surface-1 border-line flex flex-col items-center gap-3 rounded-lg border px-6 py-10 text-center",
        className,
      )}
    >
      <span
        aria-hidden="true"
        className={cn(
          "grid size-12 place-items-center rounded-full",
          tone === "error" ? "bg-error-soft text-error" : "bg-surface-2 text-ink-muted",
        )}
      >
        <Icon className="size-6" />
      </span>
      <p className="text-ink text-[15px] leading-[22px] font-semibold">{title}</p>
      {description ? (
        <div className="text-admin-body text-ink-muted max-w-[48ch]">{description}</div>
      ) : null}
      {action}
    </div>
  );
}

/** Liste vide : ce qui manque, et pourquoi. */
export function EmptyState({ title, description }: { title: string; description?: ReactNode }) {
  return <StateBlock icon={Inbox} title={title} description={description} />;
}

/** Lecture impossible : message clair, référence à citer au support, « Réessayer ». */
export function ErrorState({
  message,
  reference,
  onRetry,
  retrying = false,
}: {
  message: string;
  reference?: string | null;
  onRetry?: () => void;
  retrying?: boolean;
}) {
  return (
    <StateBlock
      icon={ServerCrash}
      tone="error"
      role="alert"
      title="Impossible de charger ces données"
      description={
        <>
          <p>{message}</p>
          {reference ? (
            <p className="text-reference text-ink-muted mt-1 font-mono">Référence : {reference}</p>
          ) : null}
        </>
      }
      action={
        onRetry ? (
          <Button onClick={onRetry} loading={retrying} loadingLabel="Nouvel essai…">
            Réessayer
          </Button>
        ) : undefined
      }
    />
  );
}

/** Écran ou action que le rôle du membre ne permet pas (décidé par le serveur). */
export function AccessDenied() {
  return (
    <StateBlock
      icon={ShieldX}
      title="Accès refusé"
      description="Votre rôle ne permet pas d’ouvrir cet écran. Demandez à un super admin si vous en avez besoin."
    />
  );
}
