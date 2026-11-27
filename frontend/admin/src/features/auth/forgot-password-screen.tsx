"use client";

// « Mot de passe oublié ou première connexion » (A1.3). Un membre invité par un super admin choisit
// ici son mot de passe, avec le code reçu par SMS (l'invitation n'en donne aucun).
// 1. numéro → `POST /auth/password/forgot` (en mode démo, l'API renvoie le code : affiché, comme sur
//    le mobile) ; 2. code + nouveau mot de passe (deux fois) → `POST /auth/password/reset` ;
// 3. retour à la connexion (« Mot de passe enregistré »).
import { zodResolver } from "@hookform/resolvers/zod";
import { useMutation } from "@tanstack/react-query";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { useForm } from "react-hook-form";
import { z } from "zod";

import { Alert } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { PasswordField } from "@/components/ui/password-field";
import { TextField } from "@/components/ui/text-field";
import { api, unwrap } from "@/lib/api/client";
import { ApiError, describeError, fieldErrors } from "@/lib/api/errors";
import { formatCountdown } from "@/lib/format";
import { useRetryLock } from "@/lib/use-countdown";
import { newPasswordField, phoneField, smsCodeField } from "@/lib/validation";

import { AuthShell } from "./auth-shell";

const phoneSchema = z.object({ phone: phoneField });
const resetSchema = z
  .object({ code: smsCodeField, password: newPasswordField, confirmation: z.string() })
  .refine((values) => values.password === values.confirmation, {
    path: ["confirmation"],
    message: "Les deux mots de passe ne sont pas identiques.",
  });

type Sent = { phone: string; message: string; demoCode: string | null };

export function ForgotPasswordScreen() {
  const [sent, setSent] = useState<Sent | null>(null);
  return (
    <AuthShell
      title="Mot de passe oublié ou première connexion"
      description={
        sent
          ? "Étape 2 sur 2 : saisissez le code reçu par SMS et choisissez votre mot de passe."
          : "Étape 1 sur 2 : nous envoyons un code par SMS au numéro de votre compte."
      }
    >
      {sent ? (
        <ResetStep sent={sent} onNewCode={() => setSent(null)} />
      ) : (
        <PhoneStep onSent={setSent} />
      )}
      <Link
        href="/connexion"
        className="text-admin-body text-volt-text self-center underline-offset-4 hover:underline"
      >
        Retour à la connexion
      </Link>
    </AuthShell>
  );
}

function PhoneStep({ onSent }: { onSent: (sent: Sent) => void }) {
  const lock = useRetryLock();
  const remaining = lock.remaining;
  const form = useForm<z.input<typeof phoneSchema>, unknown, z.output<typeof phoneSchema>>({
    resolver: zodResolver(phoneSchema),
    defaultValues: { phone: "" },
  });
  const forgot = useMutation({
    mutationFn: ({ phone }: z.output<typeof phoneSchema>) =>
      unwrap(api.POST("/api/v1/auth/password/forgot", { body: { phone } })).then((answer) => ({
        phone,
        message: answer.message,
        demoCode: answer.demo_code ?? null,
      })),
    onSuccess: onSent,
    onError: (error) => lock.block(error),
  });
  const failure = forgot.error ? describeError(forgot.error) : null;
  return (
    <form
      noValidate
      className="flex flex-col gap-5"
      onSubmit={form.handleSubmit((values) => forgot.mutate(values))}
    >
      {failure ? (
        <Alert tone="error" reference={failure.reference}>
          {failure.message}
        </Alert>
      ) : null}
      <TextField
        label="Numéro de téléphone"
        placeholder="06 123 45 67"
        inputMode="tel"
        autoComplete="username"
        error={form.formState.errors.phone?.message}
        {...form.register("phone")}
      />
      <Button
        type="submit"
        variant="primary"
        block
        loading={forgot.isPending}
        loadingLabel="Envoi…"
        disabled={remaining > 0}
      >
        {remaining > 0 ? `Réessayer dans ${formatCountdown(remaining)}` : "Recevoir un code"}
      </Button>
    </form>
  );
}

function ResetStep({ sent, onNewCode }: { sent: Sent; onNewCode: () => void }) {
  const router = useRouter();
  const lock = useRetryLock();
  const remaining = lock.remaining;
  const form = useForm<z.input<typeof resetSchema>, unknown, z.output<typeof resetSchema>>({
    resolver: zodResolver(resetSchema),
    defaultValues: { code: "", password: "", confirmation: "" },
  });
  const reset = useMutation({
    mutationFn: ({ code, password }: z.output<typeof resetSchema>) =>
      unwrap(
        api.POST("/api/v1/auth/password/reset", {
          body: { phone: sent.phone, code, new_password: password },
        }),
      ),
    onSuccess: () => router.replace("/connexion?raison=reinitialise"),
    onError: (error) => {
      lock.block(error);
      if (error instanceof ApiError) {
        const fields = fieldErrors(error);
        if (fields.new_password) form.setError("password", { message: fields.new_password });
      }
    },
  });
  const failure = reset.error ? describeError(reset.error) : null;
  const badCode = reset.error instanceof ApiError && reset.error.code === "RESET_CODE_INVALID";

  return (
    <form
      noValidate
      className="flex flex-col gap-5"
      onSubmit={form.handleSubmit((values) => reset.mutate(values))}
    >
      <Alert tone="info">{sent.message}</Alert>
      {sent.demoCode ? (
        <Alert tone="warning">
          Mode démo (aucun SMS envoyé) : votre code est{" "}
          <span className="text-reference font-mono">{sent.demoCode}</span>.
        </Alert>
      ) : null}
      {failure ? (
        <Alert tone="error" reference={failure.reference}>
          {failure.message}
          {badCode ? (
            <>
              {" "}
              <button type="button" onClick={onNewCode} className="font-semibold underline">
                Demander un nouveau code
              </button>
            </>
          ) : null}
        </Alert>
      ) : null}
      <TextField
        label="Code reçu par SMS"
        inputMode="numeric"
        autoComplete="one-time-code"
        error={form.formState.errors.code?.message}
        {...form.register("code")}
      />
      <PasswordField
        label="Nouveau mot de passe"
        autoComplete="new-password"
        hint="8 caractères minimum, au moins une lettre et un chiffre."
        error={form.formState.errors.password?.message}
        {...form.register("password")}
      />
      <PasswordField
        label="Confirmer le mot de passe"
        autoComplete="new-password"
        error={form.formState.errors.confirmation?.message}
        {...form.register("confirmation")}
      />
      <Button
        type="submit"
        variant="primary"
        block
        loading={reset.isPending}
        loadingLabel="Enregistrement…"
        disabled={remaining > 0}
      >
        {remaining > 0
          ? `Réessayer dans ${formatCountdown(remaining)}`
          : "Enregistrer le mot de passe"}
      </Button>
    </form>
  );
}
