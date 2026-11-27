"use client";

// Connexion du back-office (A1.1 + A1.2) : numéro et mot de passe (`POST /auth/web/login`), puis,
// si l'API le demande, le code de double authentification (`POST /auth/web/login/2fa`, défi de
// 5 min). Session ouverte par cookies httpOnly (posés par l'API à travers le relais) ; retour à la
// page demandée (`?retour=`, chemin interne seulement).
import { zodResolver } from "@hookform/resolvers/zod";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import type { z } from "zod";

import { Alert } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { PasswordField } from "@/components/ui/password-field";
import { TextField } from "@/components/ui/text-field";
import { api, unwrap } from "@/lib/api/client";
import { ApiError, describeError } from "@/lib/api/errors";
import type { components } from "@/lib/api/schema";
import { formatCountdown, formatTime } from "@/lib/format";
import { announceSession } from "@/lib/session/events";
import { safeReturnPath } from "@/lib/session/return-path";
import { retryDeadline, useCountdown } from "@/lib/use-countdown";
import { loginSchema, twoFactorSchema } from "@/lib/validation";

import { AuthShell } from "./auth-shell";

type Challenge = components["schemas"]["TwoFactorChallenge"];

/** Raisons d'arriver sur la connexion (`?raison=`), avec le texte de la charte. */
const REASONS: Record<string, { tone: "info" | "success"; text: string }> = {
  session: { tone: "info", text: "Votre session a expiré. Reconnectez-vous pour continuer." },
  inactivite: {
    tone: "info",
    text: "Vous avez été déconnecté après 30 minutes sans activité. Reconnectez-vous pour continuer.",
  },
  deconnexion: { tone: "success", text: "Vous êtes déconnecté." },
  "mot-de-passe": {
    tone: "success",
    text: "Mot de passe changé. Reconnectez-vous avec votre nouveau mot de passe.",
  },
  reinitialise: { tone: "success", text: "Mot de passe enregistré. Vous pouvez vous connecter." },
};

export function LoginScreen() {
  const params = useSearchParams();
  const router = useRouter();
  const queryClient = useQueryClient();
  const [challenge, setChallenge] = useState<Challenge | null>(null);
  const [restartNotice, setRestartNotice] = useState<string | null>(null);
  const reason = REASONS[params.get("raison") ?? ""];

  function finish() {
    queryClient.clear(); // rien d'une session précédente ne reste en mémoire
    announceSession("connexion");
    router.replace(safeReturnPath(params.get("retour")));
  }

  return (
    <AuthShell
      title={challenge ? "Double authentification" : "Connexion"}
      description={
        challenge
          ? "Saisissez le code à 6 chiffres affiché par votre application d’authentification."
          : "Connectez-vous avec votre numéro de téléphone."
      }
    >
      {reason && !challenge && !restartNotice ? (
        <Alert tone={reason.tone}>{reason.text}</Alert>
      ) : null}
      {challenge ? (
        <TwoFactorStep
          challenge={challenge}
          onDone={finish}
          onRestart={(notice) => {
            setChallenge(null);
            setRestartNotice(notice);
          }}
        />
      ) : (
        <PasswordStep
          notice={restartNotice}
          onChallenge={(next) => {
            setRestartNotice(null);
            setChallenge(next);
          }}
          onDone={finish}
        />
      )}
    </AuthShell>
  );
}

function PasswordStep({
  notice,
  onChallenge,
  onDone,
}: {
  notice: string | null;
  onChallenge: (challenge: Challenge) => void;
  onDone: () => void;
}) {
  const [blockedUntil, setBlockedUntil] = useState<number | null>(null);
  const remaining = useCountdown(blockedUntil);
  const blocked = remaining > 0;
  const form = useForm<z.input<typeof loginSchema>, unknown, z.output<typeof loginSchema>>({
    resolver: zodResolver(loginSchema),
    defaultValues: { phone: "", password: "" },
  });
  const login = useMutation({
    mutationFn: (values: z.output<typeof loginSchema>) =>
      unwrap(api.POST("/api/v1/auth/web/login", { body: values })),
    onSuccess: (result) => {
      if ("two_factor_required" in result) onChallenge(result);
      else onDone();
    },
    onError: (error) => setBlockedUntil(retryDeadline(error, Date.now())),
  });
  const failure = login.error ? describeError(login.error) : null;

  return (
    <form
      noValidate
      className="flex flex-col gap-5"
      onSubmit={form.handleSubmit((values) => login.mutate(values))}
    >
      {notice ? <Alert tone="info">{notice}</Alert> : null}
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
      <PasswordField
        label="Mot de passe"
        autoComplete="current-password"
        error={form.formState.errors.password?.message}
        {...form.register("password")}
      />
      <Button
        type="submit"
        variant="primary"
        block
        loading={login.isPending}
        loadingLabel="Connexion…"
        disabled={blocked}
      >
        {blocked ? `Réessayer dans ${formatCountdown(remaining)}` : "Se connecter"}
      </Button>
      <Link
        href="/mot-de-passe-oublie"
        className="text-admin-body text-volt-text self-center underline-offset-4 hover:underline"
      >
        Mot de passe oublié ou première connexion ?
      </Link>
    </form>
  );
}

function TwoFactorStep({
  challenge,
  onDone,
  onRestart,
}: {
  challenge: Challenge;
  onDone: () => void;
  onRestart: (notice: string | null) => void;
}) {
  const [blockedUntil, setBlockedUntil] = useState<number | null>(null);
  const remaining = useCountdown(blockedUntil);
  const blocked = remaining > 0;
  const form = useForm<z.input<typeof twoFactorSchema>, unknown, z.output<typeof twoFactorSchema>>({
    resolver: zodResolver(twoFactorSchema),
    defaultValues: { code: "" },
  });
  const { setFocus } = form;
  useEffect(() => setFocus("code"), [setFocus]);
  const verify = useMutation({
    mutationFn: ({ code }: z.output<typeof twoFactorSchema>) =>
      unwrap(
        api.POST("/api/v1/auth/web/login/2fa", {
          body: { challenge_token: challenge.challenge_token, code },
        }),
      ),
    onSuccess: onDone,
    onError: (error) => {
      // Défi expiré (5 min) : on recommence par le mot de passe, avec le message de l'API.
      if (isExpiredChallenge(error)) {
        onRestart(describeError(error).message);
        return;
      }
      setBlockedUntil(retryDeadline(error, Date.now()));
    },
  });
  const failure =
    verify.error && !isExpiredChallenge(verify.error) ? describeError(verify.error) : null;

  return (
    <form
      noValidate
      className="flex flex-col gap-5"
      onSubmit={form.handleSubmit((values) => verify.mutate(values))}
    >
      {failure ? (
        <Alert tone="error" reference={failure.reference}>
          {failure.message}
        </Alert>
      ) : null}
      <TextField
        label="Code de vérification"
        autoComplete="one-time-code"
        spellCheck={false}
        hint={`Ou un code de secours (ABCD-EFGH). Ce défi expire à ${formatTime(challenge.expires_at)}.`}
        error={form.formState.errors.code?.message}
        {...form.register("code")}
      />
      <Button
        type="submit"
        variant="primary"
        block
        loading={verify.isPending}
        loadingLabel="Vérification…"
        disabled={blocked}
      >
        {blocked ? `Réessayer dans ${formatCountdown(remaining)}` : "Valider le code"}
      </Button>
      <Button variant="ghost" className="self-center" onClick={() => onRestart(null)}>
        Recommencer la connexion
      </Button>
    </form>
  );
}

function isExpiredChallenge(error: unknown): boolean {
  return error instanceof ApiError && error.code === "TWO_FACTOR_CHALLENGE_INVALID";
}
