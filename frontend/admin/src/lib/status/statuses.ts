// Statuts de la charte (table « Statuts » de `frontend/design/CHARTE.md`) : toujours une couleur, une
// icône ET un mot (la couleur seule ne suffit jamais). Mêmes libellés, couleurs et icônes que
// l'application (`frontend/mobile/lib/core/widgets/statuses.dart`) ; les clés sont EXACTEMENT les
// valeurs du contrat `backend/openapi.json` (vérifié par `statuses.test.ts`).
import {
  Ban,
  Check,
  CircleQuestionMark,
  Clock,
  Hourglass,
  type LucideIcon,
  TimerOff,
  TriangleAlert,
  X,
} from "lucide-react";

/** Famille de couleur d'un statut. Le jaune `volt` n'est JAMAIS une couleur de statut. */
export type StatusTone = "current" | "warning" | "success" | "error" | "muted";

export type StatusStyle = { label: string; tone: StatusTone; icon: LucideIcon };

/**
 * Classes Tailwind (thème généré depuis la charte) : texte `*-text` (lisible ≥ 4,5:1 sur le fond
 * doux), icône de la couleur de base, fond doux du badge.
 */
export const toneClasses: Record<StatusTone, { text: string; icon: string; background: string }> = {
  current: { text: "text-current-text", icon: "text-current-base", background: "bg-current-soft" },
  warning: { text: "text-warning-text", icon: "text-warning", background: "bg-warning-soft" },
  success: { text: "text-success-text", icon: "text-success", background: "bg-success-soft" },
  error: { text: "text-error-text", icon: "text-error", background: "bg-error-soft" },
  muted: { text: "text-ink-muted", icon: "text-ink-muted", background: "bg-surface-3" },
};

/** Statuts d'une facture (`BillStatus` du contrat). */
export const billStatuses: Record<string, StatusStyle> = {
  unpaid: { label: "À payer", tone: "current", icon: Clock },
  pending_payment: { label: "Paiement en cours", tone: "warning", icon: Hourglass },
  paid: { label: "Payée", tone: "success", icon: Check },
  overdue: { label: "En retard", tone: "error", icon: TriangleAlert },
  cancelled: { label: "Annulée", tone: "muted", icon: Ban },
};

/** Statuts d'une transaction (`TransactionStatus` du contrat). */
export const transactionStatuses: Record<string, StatusStyle> = {
  en_attente: { label: "En attente", tone: "warning", icon: Hourglass },
  reussie: { label: "Réussie", tone: "success", icon: Check },
  echouee: { label: "Échouée", tone: "error", icon: X },
  expiree: { label: "Expirée", tone: "muted", icon: TimerOff },
};

/** Paiement dont on n'a pas la réponse (délai dépassé, état inconnu) : JAMAIS « Échouée ». */
export const transactionUnknown: StatusStyle = {
  label: "Vérification en cours",
  tone: "warning",
  icon: CircleQuestionMark,
};

/** Statut de facture qu'une version future de l'API ajouterait : affichage neutre, sans deviner. */
export const billUnknown: StatusStyle = {
  label: "Statut à vérifier",
  tone: "muted",
  icon: CircleQuestionMark,
};

/** Style d'un statut de facture reçu de l'API. */
export function billStatus(status: string): StatusStyle {
  return billStatuses[status] ?? billUnknown;
}

/** Style d'un statut de transaction ; absent ou inconnu : « Vérification en cours ». */
export function transactionStatus(status: string | null | undefined): StatusStyle {
  return (status ? transactionStatuses[status] : undefined) ?? transactionUnknown;
}
