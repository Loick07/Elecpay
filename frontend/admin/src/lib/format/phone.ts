// Numéros de téléphone du Congo-Brazzaville : mêmes règles que le backend
// (`backend/app/core/validation.py`, `normalize_congo_phone`) et que l'application mobile, pour
// refuser une saisie AVANT l'envoi avec le même message que l'API.
import { unitSpace } from "./typography";

const COUNTRY_CODE = "242";
const NATIONAL_LENGTH = 9;
/** Mobiles : 04, 05, 06 ; fixes : 22. */
const VALID_PREFIXES = ["04", "05", "06", "22"];
const SEPARATORS = /[\s.\-()/]/g;
const WRONG_LENGTH = "Numéro invalide : 9 chiffres attendus (ex. 06 123 45 67)";

/** Saisie refusée, avec le message à afficher sous le champ. */
export class PhoneFormatError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "PhoneFormatError";
  }
}

/** « 06 123 45 67 », « 00242… », « +242… » → « +242061234567 ». Lève `PhoneFormatError`. */
export function normalizeCongoPhone(raw: string): string {
  let digits = raw.trim().replace(SEPARATORS, "");
  if (digits.startsWith("+")) digits = digits.slice(1);
  else if (digits.startsWith("00")) digits = digits.slice(2);
  if (digits === "") throw new PhoneFormatError(WRONG_LENGTH);
  if (!/^[0-9]+$/.test(digits)) {
    throw new PhoneFormatError(
      "Numéro invalide : seuls les chiffres, espaces et « + » sont acceptés",
    );
  }
  let national: string;
  if (digits.length === COUNTRY_CODE.length + NATIONAL_LENGTH && digits.startsWith(COUNTRY_CODE)) {
    national = digits.slice(COUNTRY_CODE.length);
  } else if (digits.length === NATIONAL_LENGTH) {
    national = digits;
  } else {
    throw new PhoneFormatError(WRONG_LENGTH);
  }
  if (!VALID_PREFIXES.some((prefix) => national.startsWith(prefix))) {
    throw new PhoneFormatError("Numéro invalide : il doit commencer par 04, 05, 06 ou 22");
  }
  return `+${COUNTRY_CODE}${national}`;
}

/** Message d'erreur pour une saisie, ou `null` si elle est valide (champs de formulaire). */
export function phoneError(raw: string): string | null {
  try {
    normalizeCongoPhone(raw);
    return null;
  } catch (error) {
    if (error instanceof PhoneFormatError) return error.message;
    throw error;
  }
}

/**
 * Affichage : « +242061234567 » → « +242 06 123 45 67 » (espaces insécables). Une valeur d'une autre
 * forme (ex. numéro déjà masqué par l'API, « +242 06 *** ** 67 ») est rendue telle quelle.
 */
export function formatPhone(normalized: string): string {
  const match = /^\+242(\d{2})(\d{3})(\d{2})(\d{2})$/.exec(normalized);
  if (!match) return normalized;
  return ["+242", match[1], match[2], match[3], match[4]].join(unitSpace);
}
