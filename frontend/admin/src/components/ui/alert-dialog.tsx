"use client";

// Fenêtre qui demande une réponse (session expirée, déconnexion prochaine) : AlertDialog de Radix,
// la base de shadcn/ui. Accessible : rôle `alertdialog`, titre et description lus, focus gardé à
// l'intérieur, jamais fermée par un clic à côté.
import { AlertDialog as Primitive } from "radix-ui";
import type { ReactNode } from "react";

export function AlertDialog({
  open,
  title,
  description,
  actions,
}: {
  open: boolean;
  title: string;
  description: ReactNode;
  /** Boutons (un `Button`, le premier reçoit le focus). */
  actions: ReactNode;
}) {
  return (
    <Primitive.Root open={open}>
      <Primitive.Portal>
        <Primitive.Overlay className="fixed inset-0 z-40 bg-[rgb(5_13_26/0.55)]" />
        <Primitive.Content className="bg-surface-1 shadow-float fixed top-1/2 left-1/2 z-50 flex w-[min(28rem,calc(100vw-2rem))] -translate-x-1/2 -translate-y-1/2 flex-col gap-4 rounded-lg p-6">
          <Primitive.Title className="text-admin-h1 text-ink">{title}</Primitive.Title>
          <Primitive.Description className="text-ink-muted">{description}</Primitive.Description>
          <div className="flex flex-wrap justify-end gap-3">{actions}</div>
        </Primitive.Content>
      </Primitive.Portal>
    </Primitive.Root>
  );
}
