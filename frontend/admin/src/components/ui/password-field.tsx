"use client";

// Mot de passe : champ de la charte + bouton « Afficher » / « Masquer » (état lu par les lecteurs
// d'écran : `aria-pressed`).
import { Eye, EyeOff } from "lucide-react";
import { type ComponentProps, useState } from "react";

import { TextField } from "./text-field";

type PasswordFieldProps = Omit<ComponentProps<typeof TextField>, "type" | "trailing">;

export function PasswordField(props: PasswordFieldProps) {
  const [visible, setVisible] = useState(false);
  return (
    <TextField
      {...props}
      type={visible ? "text" : "password"}
      trailing={
        <button
          type="button"
          onClick={() => setVisible((shown) => !shown)}
          aria-pressed={visible}
          aria-label={visible ? "Masquer le mot de passe" : "Afficher le mot de passe"}
          className="text-admin-label text-ink-muted hover:text-ink inline-flex min-h-10 items-center gap-1.5 rounded-sm px-2"
        >
          {visible ? (
            <EyeOff aria-hidden="true" className="size-4" />
          ) : (
            <Eye aria-hidden="true" className="size-4" />
          )}
          {visible ? "Masquer" : "Afficher"}
        </button>
      }
    />
  );
}
