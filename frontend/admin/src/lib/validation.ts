// Règles de saisie des formulaires (React Hook Form + Zod) : les MÊMES que le backend
// (`backend/app/core/validation.py`) et que l'application mobile (`validation.dart`), avec les mêmes
// messages, pour refuser une saisie avant l'envoi. Le backend reste seul juge : il revérifie tout.
import "./zod-config";

import { z } from "zod";

import { normalizeCongoPhone, PhoneFormatError } from "@/lib/format";

export const PASSWORD_MIN_LENGTH = 8;
export const PASSWORD_MAX_LENGTH = 128;
export const FULL_NAME_MIN_LENGTH = 2;
export const FULL_NAME_MAX_LENGTH = 120;

const LETTER = /\p{L}/u;
const DIGIT = /\p{Nd}/u;

/** Message d'erreur du mot de passe (celui du backend), ou `null` s'il est accepté. */
export function passwordError(password: string): string | null {
  if (password.length < PASSWORD_MIN_LENGTH) {
    return `Mot de passe trop court : ${PASSWORD_MIN_LENGTH} caractères minimum`;
  }
  if (password.length > PASSWORD_MAX_LENGTH) {
    return `Mot de passe trop long : ${PASSWORD_MAX_LENGTH} caractères maximum`;
  }
  if (!DIGIT.test(password)) return "Le mot de passe doit contenir au moins un chiffre";
  if (!LETTER.test(password)) return "Le mot de passe doit contenir au moins une lettre";
  if (password !== password.trim()) {
    return "Le mot de passe ne doit pas commencer ni finir par un espace";
  }
  return null;
}

/** Nom normalisé comme le backend (`normalize_full_name`) : « Grâce   Ngoma » → « Grâce Ngoma ». */
export function normalizeFullName(raw: string): string {
  return raw.split(/\s+/).filter(Boolean).join(" ");
}

/** Message d'erreur du nom (celui du backend), ou `null`. Longueur en caractères, comme Python. */
export function fullNameError(raw: string): string | null {
  const name = normalizeFullName(raw);
  const length = [...name].length;
  if (length < FULL_NAME_MIN_LENGTH) return "Nom trop court";
  if (length > FULL_NAME_MAX_LENGTH) {
    return `Nom trop long : ${FULL_NAME_MAX_LENGTH} caractères maximum`;
  }
  if (!LETTER.test(name)) return "Le nom doit contenir des lettres";
  return null;
}

export const fullNameField = z
  .string()
  .superRefine((raw, context) => {
    const message = fullNameError(raw);
    if (message) context.addIssue({ code: "custom", message });
  })
  .transform(normalizeFullName);

/** Numéro saisi librement (« 06 123 45 67 ») → « +242061234567 » ; message du backend sinon. */
export const phoneField = z
  .string()
  .trim()
  .min(1, "Saisissez votre numéro de téléphone.")
  .transform((raw, context) => {
    try {
      return normalizeCongoPhone(raw);
    } catch (error) {
      if (!(error instanceof PhoneFormatError)) throw error;
      context.addIssue({ code: "custom", message: error.message });
      return z.NEVER;
    }
  });

/** Nouveau mot de passe : règles du backend. */
export const newPasswordField = z.string().superRefine((password, context) => {
  const message = passwordError(password);
  if (message) context.addIssue({ code: "custom", message });
});

/**
 * Code de double authentification : les 6 chiffres de l'application d'authentification, ou un code
 * de secours « ABCD-EFGH » (espaces ignorés, majuscules, tiret ajouté s'il manque).
 */
export const twoFactorCodeField = z
  .string()
  .transform((raw) => raw.replace(/\s+/g, "").toUpperCase())
  .transform((code, context) => {
    if (/^\d{6}$/.test(code)) return code;
    const backup = /^([A-Z0-9]{4})-?([A-Z0-9]{4})$/.exec(code);
    if (backup) return `${backup[1]}-${backup[2]}`;
    context.addIssue({
      code: "custom",
      message:
        code === ""
          ? "Saisissez le code à 6 chiffres de votre application d’authentification."
          : "Code invalide : 6 chiffres, ou un code de secours du type ABCD-EFGH.",
    });
    return z.NEVER;
  });

/** Code à 6 chiffres de l'application d'authentification SEULEMENT (activation, nouveaux codes). */
export const appCodeField = z
  .string()
  .transform((raw) => raw.replace(/\s+/g, ""))
  .refine((code) => /^\d{6}$/.test(code), "Saisissez les 6 chiffres affichés par l’application.");

/** Code reçu par SMS (mot de passe oublié, première connexion) : 6 chiffres. */
export const smsCodeField = z
  .string()
  .transform((raw) => raw.replace(/\s+/g, ""))
  .refine((code) => /^\d{6}$/.test(code), "Le code reçu par SMS a 6 chiffres.");

export const loginSchema = z.object({
  phone: phoneField,
  password: z.string().min(1, "Saisissez votre mot de passe."),
});

export const twoFactorSchema = z.object({ code: twoFactorCodeField });

/** Changement du mot de passe (Mon compte) : l'actuel, puis le nouveau deux fois. */
export const passwordChangeSchema = z
  .object({
    current: z.string().min(1, "Saisissez votre mot de passe actuel."),
    password: newPasswordField,
    confirmation: z.string(),
  })
  .refine((values) => values.password === values.confirmation, {
    path: ["confirmation"],
    message: "Les deux mots de passe ne sont pas identiques.",
  });
