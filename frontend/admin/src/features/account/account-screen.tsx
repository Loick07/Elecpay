"use client";

// Écran « Mon compte » (A1.5 ; sans maquette, construit selon la charte : DA1.1).
// - Profil : nom modifiable (`PATCH /me`, règles du backend), téléphone (identifiant de connexion,
//   non modifiable ici), rôle, e-mail.
// - Mot de passe (`POST /me/password`) : l'API ferme TOUTES les sessions, y compris celle-ci (les
//   nouveaux jetons qu'elle renvoie sont retirés par le relais) → déconnexion, puis connexion avec le
//   nouveau mot de passe (« mot-de-passe »).
// - Double authentification (`GET /me/2fa`) : état, nouveaux codes de secours (`POST
//   /me/2fa/backup-codes`, code de l'application) montrés une seule fois ; inactive (support) :
//   bandeau « recommandée » vers la page Sécurité (DA1.5).
import { zodResolver } from "@hookform/resolvers/zod";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { KeyRound, ShieldCheck } from "lucide-react";
import Link from "next/link";
import { type ReactNode, useId, useState } from "react";
import { useForm } from "react-hook-form";
import { z } from "zod";

import { Alert } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { PasswordField } from "@/components/ui/password-field";
import { TextField } from "@/components/ui/text-field";
import { api, unwrap } from "@/lib/api/client";
import { ApiError, describeError, fieldErrors } from "@/lib/api/errors";
import { formatDate, formatPhone } from "@/lib/format";
import {
  meQueryKey,
  ROLE_LABELS,
  type TeamMember,
  useTeamMember,
} from "@/lib/session/session-context";
import { useLogout } from "@/lib/session/use-logout";
import { appCodeField, fullNameField, passwordChangeSchema } from "@/lib/validation";

import { BackupCodesList } from "../security/backup-codes";
import { twoFactorStatusKey } from "../security/two-factor-setup";
import { TeamPage } from "../session/team-page";

/** Seuil d'alerte : peu de codes de secours restants. */
export const FEW_BACKUP_CODES = 3;

export function AccountScreen() {
  return (
    <TeamPage title="Mon compte">
      <div className="grid gap-6 lg:grid-cols-2">
        <ProfileSection />
        <TwoFactorSection />
        <PasswordSection />
      </div>
    </TeamPage>
  );
}

function Section({
  title,
  description,
  children,
}: {
  title: string;
  description?: ReactNode;
  children: ReactNode;
}) {
  const titleId = useId();
  return (
    <section
      aria-labelledby={titleId}
      className="bg-surface-1 shadow-card flex flex-col gap-5 rounded-lg p-6"
    >
      <header className="flex flex-col gap-1">
        {/* Titre de carte des maquettes du back-office (Inter 600, 15 px / 22 px). */}
        <h2 id={titleId} className="text-ink text-[15px] leading-[22px] font-semibold">
          {title}
        </h2>
        {description ? <p className="text-admin-body text-ink-muted">{description}</p> : null}
      </header>
      {children}
    </section>
  );
}

// --- Profil -------------------------------------------------------------------------------------

const nameSchema = z.object({ fullName: fullNameField });

function ProfileSection() {
  const member = useTeamMember();
  const [editing, setEditing] = useState(false);
  const [saved, setSaved] = useState(false);
  return (
    <Section title="Profil">
      {saved ? <Alert tone="success">Nom enregistré.</Alert> : null}
      {editing ? (
        <NameForm
          member={member}
          onDone={(changed) => {
            setEditing(false);
            setSaved(changed);
          }}
        />
      ) : (
        <div className="flex flex-col gap-4">
          <dl className="text-admin-body grid grid-cols-[minmax(8rem,auto)_1fr] gap-x-6 gap-y-3">
            <dt className="text-ink-muted">Nom</dt>
            <dd className="text-ink">{member.full_name}</dd>
            <dt className="text-ink-muted">Téléphone</dt>
            <dd className="text-ink">{formatPhone(member.phone)}</dd>
            <dt className="text-ink-muted">Rôle</dt>
            <dd className="text-ink">{ROLE_LABELS[member.role] ?? member.role}</dd>
            <dt className="text-ink-muted">E-mail</dt>
            <dd className="text-ink">{member.email ?? "Non renseigné"}</dd>
            <dt className="text-ink-muted">Membre depuis</dt>
            <dd className="text-ink">le {formatDate(member.created_at)}</dd>
          </dl>
          <p className="text-admin-label text-ink-muted">
            Le téléphone sert à vous connecter : il ne se change pas ici.
          </p>
          <div>
            <Button
              onClick={() => {
                setSaved(false);
                setEditing(true);
              }}
            >
              Modifier le nom
            </Button>
          </div>
        </div>
      )}
    </Section>
  );
}

function NameForm({ member, onDone }: { member: TeamMember; onDone: (changed: boolean) => void }) {
  const queryClient = useQueryClient();
  const form = useForm<z.input<typeof nameSchema>, unknown, z.output<typeof nameSchema>>({
    resolver: zodResolver(nameSchema),
    defaultValues: { fullName: member.full_name },
  });
  const update = useMutation({
    mutationFn: ({ fullName }: z.output<typeof nameSchema>) =>
      unwrap(api.PATCH("/api/v1/me", { body: { full_name: fullName } })),
    onSuccess: (updated) => {
      queryClient.setQueryData(meQueryKey, updated); // en-tête et page à jour, sans relecture
      onDone(true);
    },
    onError: (error) => {
      if (error instanceof ApiError && fieldErrors(error).full_name) {
        form.setError("fullName", { message: fieldErrors(error).full_name });
      }
    },
  });
  const failure = update.error ? describeError(update.error) : null;
  return (
    <form
      noValidate
      className="flex flex-col gap-4"
      onSubmit={form.handleSubmit((values) =>
        values.fullName === member.full_name ? onDone(false) : update.mutate(values),
      )}
    >
      {failure && !form.formState.errors.fullName ? (
        <Alert tone="error" reference={failure.reference}>
          {failure.message}
        </Alert>
      ) : null}
      <TextField
        label="Nom complet"
        autoComplete="name"
        error={form.formState.errors.fullName?.message}
        {...form.register("fullName")}
      />
      <div className="flex flex-wrap gap-3">
        <Button
          type="submit"
          variant="primary"
          loading={update.isPending}
          loadingLabel="Enregistrement…"
        >
          Enregistrer
        </Button>
        <Button onClick={() => onDone(false)} disabled={update.isPending}>
          Annuler
        </Button>
      </div>
    </form>
  );
}

// --- Mot de passe -------------------------------------------------------------------------------

function PasswordSection() {
  const logout = useLogout();
  const form = useForm<
    z.input<typeof passwordChangeSchema>,
    unknown,
    z.output<typeof passwordChangeSchema>
  >({
    resolver: zodResolver(passwordChangeSchema),
    defaultValues: { current: "", password: "", confirmation: "" },
  });
  const change = useMutation({
    mutationFn: ({ current, password }: z.output<typeof passwordChangeSchema>) =>
      unwrap(
        api.POST("/api/v1/me/password", {
          body: { current_password: current, new_password: password },
        }),
      ),
    // Toutes les sessions sont fermées par l'API : on se déconnecte proprement (cookies effacés,
    // autres onglets prévenus) et la page de connexion dit pourquoi.
    onSuccess: () => logout.mutate("mot-de-passe"),
    onError: (error) => {
      if (!(error instanceof ApiError)) return;
      if (error.code === "WRONG_CURRENT_PASSWORD") {
        form.setError("current", { message: error.message });
      } else if (error.code === "SAME_PASSWORD") {
        form.setError("password", { message: error.message });
      } else if (fieldErrors(error).new_password) {
        form.setError("password", { message: fieldErrors(error).new_password });
      }
    },
  });
  const failure =
    change.error && !(change.error instanceof ApiError && change.error.status === 400)
      ? describeError(change.error)
      : null;
  const busy = change.isPending || change.isSuccess;

  return (
    <Section
      title="Mot de passe"
      description="Après le changement, tous vos appareils sont déconnectés, celui-ci compris : reconnectez-vous avec le nouveau mot de passe."
    >
      <form
        noValidate
        className="flex flex-col gap-4"
        onSubmit={form.handleSubmit((values) => change.mutate(values))}
      >
        {failure && !form.formState.errors.password ? (
          <Alert tone="error" reference={failure.reference}>
            {failure.message}
          </Alert>
        ) : null}
        <PasswordField
          label="Mot de passe actuel"
          autoComplete="current-password"
          error={form.formState.errors.current?.message}
          {...form.register("current")}
        />
        <PasswordField
          label="Nouveau mot de passe"
          autoComplete="new-password"
          hint="8 caractères minimum, au moins une lettre et un chiffre."
          error={form.formState.errors.password?.message}
          {...form.register("password")}
        />
        <PasswordField
          label="Confirmer le nouveau mot de passe"
          autoComplete="new-password"
          error={form.formState.errors.confirmation?.message}
          {...form.register("confirmation")}
        />
        <div>
          <Button
            type="submit"
            variant="primary"
            icon={<KeyRound aria-hidden="true" className="size-4" />}
            loading={busy}
            loadingLabel="Changement…"
          >
            Changer le mot de passe
          </Button>
        </div>
      </form>
    </Section>
  );
}

// --- Double authentification --------------------------------------------------------------------

function TwoFactorSection() {
  const status = useQuery({
    queryKey: twoFactorStatusKey,
    queryFn: () => unwrap(api.GET("/api/v1/me/2fa")),
  });
  const [codes, setCodes] = useState<string[] | null>(null);
  const [renewing, setRenewing] = useState(false);

  if (codes) {
    return (
      <Section
        title="Vos nouveaux codes de secours"
        description="Les anciens codes ne marchent plus. Ceux-ci ne seront plus jamais affichés."
      >
        <BackupCodesList
          codes={codes}
          confirmLabel="Terminé"
          onConfirm={() => {
            setCodes(null);
            setRenewing(false);
          }}
        />
      </Section>
    );
  }

  return (
    <Section title="Double authentification">
      {status.isPending ? (
        <p role="status" className="text-ink-muted">
          Chargement…
        </p>
      ) : status.isError ? (
        <Alert tone="error" reference={describeError(status.error).reference}>
          {describeError(status.error).message}
        </Alert>
      ) : status.data.enabled ? (
        <div className="flex flex-col gap-4">
          <Alert tone="success">
            Active
            {status.data.enabled_at
              ? ` depuis le ${formatDate(status.data.enabled_at)}`
              : ""} ; {status.data.backup_codes_left} code(s) de secours restant(s).
          </Alert>
          {status.data.backup_codes_left <= FEW_BACKUP_CODES ? (
            <Alert tone="warning">
              Il vous reste peu de codes de secours : générez-en de nouveaux et gardez-les en lieu
              sûr.
            </Alert>
          ) : null}
          {renewing ? (
            <RenewBackupCodes onRenewed={setCodes} onCancel={() => setRenewing(false)} />
          ) : (
            <div>
              <Button
                icon={<ShieldCheck aria-hidden="true" className="size-4" />}
                onClick={() => setRenewing(true)}
              >
                Nouveaux codes de secours
              </Button>
            </div>
          )}
        </div>
      ) : (
        <div className="flex flex-col gap-4">
          <Alert tone="warning">
            <strong className="font-semibold">Double authentification recommandée.</strong> Elle
            protège votre compte même si votre mot de passe est découvert : un code de votre
            téléphone est demandé à chaque connexion.
          </Alert>
          <div>
            <Link
              href="/securite?retour=%2Fmon-compte"
              className="text-admin-body text-volt-text font-semibold underline-offset-4 hover:underline"
            >
              Configurer la double authentification
            </Link>
          </div>
        </div>
      )}
    </Section>
  );
}

const renewSchema = z.object({ code: appCodeField });

function RenewBackupCodes({
  onRenewed,
  onCancel,
}: {
  onRenewed: (codes: string[]) => void;
  onCancel: () => void;
}) {
  const queryClient = useQueryClient();
  const form = useForm<z.input<typeof renewSchema>, unknown, z.output<typeof renewSchema>>({
    resolver: zodResolver(renewSchema),
    defaultValues: { code: "" },
  });
  const renew = useMutation({
    mutationFn: ({ code }: z.output<typeof renewSchema>) =>
      unwrap(api.POST("/api/v1/me/2fa/backup-codes", { body: { code } })),
    onSuccess: ({ backup_codes }) => {
      void queryClient.invalidateQueries({ queryKey: twoFactorStatusKey });
      onRenewed(backup_codes);
    },
  });
  const failure = renew.error ? describeError(renew.error) : null;
  return (
    <form
      noValidate
      className="flex flex-col gap-4"
      onSubmit={form.handleSubmit((values) => renew.mutate(values))}
    >
      <p className="text-admin-body text-ink">
        Saisissez le code à 6 chiffres de votre application d’authentification. Les anciens codes de
        secours ne marcheront plus.
      </p>
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
      <div className="flex flex-wrap gap-3">
        <Button
          type="submit"
          variant="primary"
          loading={renew.isPending}
          loadingLabel="Génération…"
        >
          Générer de nouveaux codes
        </Button>
        <Button onClick={onCancel} disabled={renew.isPending}>
          Annuler
        </Button>
      </div>
    </form>
  );
}
