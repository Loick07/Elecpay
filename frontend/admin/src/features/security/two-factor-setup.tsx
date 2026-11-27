"use client";

// Page « Sécurité » (A1.2) : configuration de la double authentification, OBLIGATOIRE pour admin et
// super admin (l'API refuse leurs routes /admin sans elle : 403 TWO_FACTOR_SETUP_REQUIRED),
// recommandée pour le support (DA1.5).
// 1. état (`GET /me/2fa`) ; 2. clé et QR code (`POST /me/2fa/setup`) : le QR code est affiché comme
// une IMAGE (jamais injecté dans la page) ; 3. premier code (`POST /me/2fa/enable`) ; 4. les codes de
// secours, montrés UNE SEULE FOIS : copier, télécharger, et confirmer les avoir mis en lieu sûr.
import { zodResolver } from "@hookform/resolvers/zod";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Copy, Download, ShieldCheck } from "lucide-react";
import { useRouter, useSearchParams } from "next/navigation";
import { useId, useState } from "react";
import { useForm } from "react-hook-form";
import { z } from "zod";

import { Alert } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { TextField } from "@/components/ui/text-field";
import { api, unwrap } from "@/lib/api/client";
import { describeError } from "@/lib/api/errors";
import type { components } from "@/lib/api/schema";
import { formatDate } from "@/lib/format";
import { safeReturnPath } from "@/lib/session/return-path";

import { AuthShell } from "../auth/auth-shell";

type Setup = components["schemas"]["TwoFactorSetupResponse"];

export const twoFactorStatusKey = ["me", "2fa"] as const;

const firstCodeSchema = z.object({
  code: z
    .string()
    .transform((raw) => raw.replace(/\s+/g, ""))
    .refine((code) => /^\d{6}$/.test(code), "Saisissez les 6 chiffres affichés par l’application."),
});

/** Clé lisible : groupes de 4 caractères (« ELEC PAYD … »). */
export function groupKey(secret: string): string {
  return secret.match(/.{1,4}/g)?.join(" ") ?? secret;
}

const SVG_NAMESPACE = 'xmlns="http://www.w3.org/2000/svg"';

/**
 * QR code de l'API (SVG) affiché comme image : `data:` (permis par la CSP, `img-src`). L'API le
 * produit avec `segno.svg_inline()`, SANS `xmlns` (fait pour être collé dans du HTML) : une image
 * SVG autonome sans `xmlns` n'est pas dessinée par les navigateurs (vu dans Edge le 27/11/2026),
 * d'où l'ajout.
 */
export function qrImageSource(svg: string): string {
  const standalone =
    svg.startsWith("<svg") && !svg.includes(SVG_NAMESPACE)
      ? `<svg ${SVG_NAMESPACE}${svg.slice("<svg".length)}`
      : svg;
  return `data:image/svg+xml;charset=utf-8,${encodeURIComponent(standalone)}`;
}

export function TwoFactorSetup() {
  const status = useQuery({
    queryKey: twoFactorStatusKey,
    queryFn: () => unwrap(api.GET("/api/v1/me/2fa")),
  });
  const [setup, setSetup] = useState<Setup | null>(null);
  const [backupCodes, setBackupCodes] = useState<string[] | null>(null);

  if (backupCodes) return <BackupCodes codes={backupCodes} />;

  return (
    <AuthShell
      title="Double authentification"
      description="Un code à 6 chiffres, donné par une application d’authentification de votre téléphone (Google Authenticator, Microsoft Authenticator…), vous sera demandé à chaque connexion."
    >
      {status.isPending ? (
        <p role="status" className="text-ink-muted">
          Chargement…
        </p>
      ) : status.isError ? (
        <Alert tone="error" reference={describeError(status.error).reference}>
          {describeError(status.error).message}
        </Alert>
      ) : status.data.enabled ? (
        <Alert tone="success">
          Double authentification active
          {status.data.enabled_at ? ` depuis le ${formatDate(status.data.enabled_at)}` : ""} ;{" "}
          {status.data.backup_codes_left} code(s) de secours restant(s).
        </Alert>
      ) : setup ? (
        <ConfirmStep setup={setup} onEnabled={setBackupCodes} />
      ) : (
        <StartStep required={status.data.required} onStarted={setSetup} />
      )}
    </AuthShell>
  );
}

function StartStep({
  required,
  onStarted,
}: {
  required: boolean;
  onStarted: (setup: Setup) => void;
}) {
  const start = useMutation({
    mutationFn: () => unwrap(api.POST("/api/v1/me/2fa/setup")),
    onSuccess: onStarted,
  });
  const failure = start.error ? describeError(start.error) : null;
  return (
    <div className="flex flex-col gap-5">
      <Alert tone={required ? "warning" : "info"}>
        {required
          ? "Obligatoire pour votre rôle : l’administration reste fermée tant qu’elle n’est pas activée."
          : "Recommandée : elle protège votre compte même si votre mot de passe est découvert."}
      </Alert>
      {failure ? (
        <Alert tone="error" reference={failure.reference}>
          {failure.message}
        </Alert>
      ) : null}
      <Button
        variant="primary"
        block
        icon={<ShieldCheck aria-hidden="true" className="size-5" />}
        loading={start.isPending}
        loadingLabel="Préparation…"
        onClick={() => start.mutate()}
      >
        Configurer la double authentification
      </Button>
    </div>
  );
}

function ConfirmStep({ setup, onEnabled }: { setup: Setup; onEnabled: (codes: string[]) => void }) {
  const queryClient = useQueryClient();
  const form = useForm<z.input<typeof firstCodeSchema>, unknown, z.output<typeof firstCodeSchema>>({
    resolver: zodResolver(firstCodeSchema),
    defaultValues: { code: "" },
  });
  const enable = useMutation({
    mutationFn: ({ code }: z.output<typeof firstCodeSchema>) =>
      unwrap(api.POST("/api/v1/me/2fa/enable", { body: { code } })),
    onSuccess: ({ backup_codes }) => {
      void queryClient.invalidateQueries({ queryKey: twoFactorStatusKey });
      onEnabled(backup_codes);
    },
  });
  const failure = enable.error ? describeError(enable.error) : null;
  const keyId = useId();

  return (
    <form
      noValidate
      className="flex flex-col gap-5"
      onSubmit={form.handleSubmit((values) => enable.mutate(values))}
    >
      <ol className="text-ink flex list-decimal flex-col gap-2 pl-5">
        <li>Ouvrez votre application d’authentification et ajoutez un compte.</li>
        <li>Scannez ce QR code, ou saisissez la clé à la main.</li>
        <li>Saisissez le code à 6 chiffres qu’elle affiche.</li>
      </ol>
      <div className="flex flex-col items-center gap-3">
        {/* eslint-disable-next-line @next/next/no-img-element -- image `data:` générée par l'API */}
        <img
          src={qrImageSource(setup.qr_svg)}
          alt="QR code à scanner avec votre application d’authentification"
          width={192}
          height={192}
          className="border-line bg-surface-1 rounded-md border p-2"
        />
        <p className="text-admin-label text-ink-muted" id={keyId}>
          Clé à saisir à la main
        </p>
        <p
          aria-labelledby={keyId}
          className="text-reference text-ink bg-surface-2 rounded-sm px-3 py-2 font-mono tracking-wider"
        >
          {groupKey(setup.secret)}
        </p>
        <CopyButton text={setup.secret} label="Copier la clé" />
      </div>
      {failure ? (
        <Alert tone="error" reference={failure.reference}>
          {failure.message}
        </Alert>
      ) : null}
      <TextField
        label="Code à 6 chiffres"
        inputMode="numeric"
        autoComplete="one-time-code"
        error={form.formState.errors.code?.message}
        {...form.register("code")}
      />
      <Button
        type="submit"
        variant="primary"
        block
        loading={enable.isPending}
        loadingLabel="Activation…"
      >
        Activer la double authentification
      </Button>
    </form>
  );
}

function BackupCodes({ codes }: { codes: string[] }) {
  const router = useRouter();
  const params = useSearchParams();
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
    <AuthShell
      title="Vos codes de secours"
      description="Si vous perdez votre téléphone, chacun de ces codes remplace une fois le code de l’application. Ils ne seront plus jamais affichés."
    >
      <Alert tone="success">Double authentification activée.</Alert>
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
      <Button
        variant="primary"
        block
        disabled={!saved}
        onClick={() => router.replace(safeReturnPath(params.get("retour")))}
      >
        Continuer
      </Button>
    </AuthShell>
  );
}

function CopyButton({ text, label }: { text: string; label: string }) {
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
