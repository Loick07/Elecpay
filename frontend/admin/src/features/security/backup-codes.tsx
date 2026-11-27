"use client";

// Codes de secours montrés UNE SEULE FOIS (activation sur la page Sécurité, nouveaux codes dans Mon
// compte) : liste, copier, télécharger (.txt), puis confirmation « mis en lieu sûr » avant de
// continuer : l'API ne les redonnera jamais.
import { Copy, Download } from "lucide-react";
import { useId, useState } from "react";

import { Button } from "@/components/ui/button";

export function BackupCodesList({
  codes,
  confirmLabel,
  onConfirm,
}: {
  codes: readonly string[];
  confirmLabel: string;
  onConfirm: () => void;
}) {
  const [saved, setSaved] = useState(false);
  const checkboxId = useId();
  const text = `Codes de secours ElecPay (back-office) : chacun ne sert qu'une fois.\n\n${codes.join("\n")}\n`;

  function download() {
    const url = URL.createObjectURL(new Blob([text], { type: "text/plain;charset=utf-8" }));
    const link = document.createElement("a");
    link.href = url;
    link.download = "elecpay-codes-de-secours.txt";
    link.click();
    URL.revokeObjectURL(url);
  }

  return (
    <div className="flex flex-col gap-5">
      <ul
        aria-label="Codes de secours"
        className="bg-surface-2 grid grid-cols-2 gap-2 rounded-md p-4"
      >
        {codes.map((code) => (
          <li key={code} className="text-reference text-ink font-mono tracking-wider">
            {code}
          </li>
        ))}
      </ul>
      <div className="flex flex-wrap gap-3">
        <CopyButton text={text} label="Copier les codes" />
        <Button icon={<Download aria-hidden="true" className="size-4" />} onClick={download}>
          Télécharger (.txt)
        </Button>
      </div>
      <div className="flex items-start gap-3">
        <input
          id={checkboxId}
          type="checkbox"
          checked={saved}
          onChange={(event) => setSaved(event.target.checked)}
          className="accent-volt mt-1 size-4"
        />
        <label htmlFor={checkboxId} className="text-ink">
          J’ai mis ces codes en lieu sûr.
        </label>
      </div>
      <Button variant="primary" block disabled={!saved} onClick={onConfirm}>
        {confirmLabel}
      </Button>
    </div>
  );
}

export function CopyButton({ text, label }: { text: string; label: string }) {
  const [copied, setCopied] = useState(false);
  return (
    <Button
      icon={<Copy aria-hidden="true" className="size-4" />}
      onClick={() => {
        void navigator.clipboard?.writeText(text).then(() => setCopied(true));
      }}
    >
      <span aria-live="polite">{copied ? "Copié" : label}</span>
    </Button>
  );
}
