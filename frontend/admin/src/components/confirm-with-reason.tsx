"use client";

// Confirmation d'une action sensible AVEC MOTIF (charte : « un motif et une confirmation dans la
// page » ; annuler une facture, désactiver un compte…). Fenêtre `alertdialog` de Radix : titre et
// conséquences lus, focus gardé à l'intérieur, jamais fermée par un clic à côté ni pendant l'envoi.
// - motif : mêmes limites que le backend (`REASON_LIMITS`), compteur de caractères ;
// - l'action part une seule fois (bouton désactivé pendant l'envoi) ; refus de l'API → message et
//   référence DANS la fenêtre, le motif saisi est gardé ;
// - réussite : la fenêtre se ferme (l'écran affiche l'avis et relit ses données) ;
// - à la fermeture, le focus revient à ce qui l'avait ouverte (sans `Trigger` de Radix, il tombait
//   sur la page : vu le 28/11/2026 dans les parcours).
import { zodResolver } from "@hookform/resolvers/zod";
import { useMutation } from "@tanstack/react-query";
import { AlertDialog as Primitive } from "radix-ui";
import { type ReactNode, useEffect, useId, useRef } from "react";
import { useForm, useWatch } from "react-hook-form";
import { z } from "zod";

import { Alert } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { inputClasses } from "@/components/ui/text-field";
import { ApiError, describeError, fieldErrors } from "@/lib/api/errors";
import { cn } from "@/lib/utils";
import { reasonField } from "@/lib/validation";

export function ConfirmWithReason({
  open,
  onOpenChange,
  title,
  description,
  reasonLabel = "Motif",
  limits,
  confirmLabel,
  pendingLabel,
  onConfirm,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  title: string;
  /** Conséquences de l'action, dites avant de confirmer. */
  description: ReactNode;
  reasonLabel?: string;
  limits: { min: number; max: number };
  confirmLabel: string;
  pendingLabel: string;
  /** Envoi à l'API ; une erreur rejetée reste affichée dans la fenêtre. */
  onConfirm: (reason: string) => Promise<unknown>;
}) {
  const schema = z.object({ reason: reasonField(limits.min, limits.max) });
  const form = useForm<z.input<typeof schema>, unknown, z.output<typeof schema>>({
    resolver: zodResolver(schema),
    defaultValues: { reason: "" },
  });
  const action = useMutation({
    mutationFn: ({ reason }: z.output<typeof schema>) => onConfirm(reason),
    onSuccess: () => onOpenChange(false),
    onError: (error) => {
      const message = error instanceof ApiError ? fieldErrors(error).reason : undefined;
      if (message) form.setError("reason", { message });
    },
  });
  const { reset: resetForm } = form;
  const { reset: resetAction } = action;

  // Chaque ouverture repart d'un motif vide, sans l'erreur précédente.
  useEffect(() => {
    if (open) {
      resetForm({ reason: "" });
      resetAction();
    }
  }, [open, resetForm, resetAction]);

  const fieldId = useId();
  const opener = useRef<HTMLElement | null>(null);
  const hintId = `${fieldId}-aide`;
  const errorId = `${fieldId}-erreur`;
  const typed = useWatch({ control: form.control, name: "reason" });
  const length = [...(typed ?? "")].length;
  const error = form.formState.errors.reason?.message;
  const failure = action.error && !error ? describeError(action.error) : null;

  return (
    <Primitive.Root open={open} onOpenChange={(next) => !action.isPending && onOpenChange(next)}>
      <Primitive.Portal>
        <Primitive.Overlay className="fixed inset-0 z-40 bg-[rgb(5_13_26/0.55)]" />
        <Primitive.Content
          // À l'ouverture, le focus va sur le motif (la première chose à faire) ; « Annuler » est
          // juste après au clavier.
          onOpenAutoFocus={(event) => {
            event.preventDefault();
            const active = document.activeElement;
            opener.current = active instanceof HTMLElement ? active : null;
            document.getElementById(fieldId)?.focus();
          }}
          onCloseAutoFocus={(event) => {
            event.preventDefault();
            if (opener.current?.isConnected) opener.current.focus();
          }}
          className="bg-surface-1 shadow-float fixed top-1/2 left-1/2 z-50 flex max-h-[calc(100vh-2rem)] w-[min(32rem,calc(100vw-2rem))] -translate-x-1/2 -translate-y-1/2 flex-col gap-4 overflow-y-auto rounded-lg p-6"
        >
          <Primitive.Title className="text-admin-h1 text-ink">{title}</Primitive.Title>
          <Primitive.Description asChild>
            <div className="text-admin-body text-ink-muted flex flex-col gap-2">{description}</div>
          </Primitive.Description>
          <form
            noValidate
            className="flex flex-col gap-4"
            onSubmit={form.handleSubmit((values) => action.mutate(values))}
          >
            {failure ? (
              <Alert tone="error" reference={failure.reference}>
                {failure.message}
              </Alert>
            ) : null}
            <div className="flex flex-col gap-1.5">
              <label htmlFor={fieldId} className="text-admin-label text-ink-muted">
                {reasonLabel}
              </label>
              <textarea
                id={fieldId}
                rows={4}
                aria-invalid={error ? true : undefined}
                aria-describedby={error ? `${errorId} ${hintId}` : hintId}
                className={cn(inputClasses, "min-h-28 resize-y py-3")}
                {...form.register("reason")}
              />
              <p id={hintId} className="text-admin-label text-ink-muted flex justify-between gap-3">
                <span>
                  Au moins {limits.min} caractères. Inscrit au journal d’activité avec votre nom.
                </span>
                <span className={cn("tabular-nums", length > limits.max && "text-error-text")}>
                  {length} / {limits.max}
                </span>
              </p>
              {error ? (
                <p id={errorId} className="text-admin-label text-error-text">
                  {error}
                </p>
              ) : null}
            </div>
            <div className="flex flex-wrap justify-end gap-3">
              <Primitive.Cancel asChild>
                <Button size="sm" disabled={action.isPending}>
                  Annuler
                </Button>
              </Primitive.Cancel>
              <Button
                type="submit"
                size="sm"
                variant="danger"
                loading={action.isPending}
                loadingLabel={pendingLabel}
              >
                {confirmLabel}
              </Button>
            </div>
          </form>
        </Primitive.Content>
      </Primitive.Portal>
    </Primitive.Root>
  );
}
