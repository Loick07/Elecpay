// Dates, heures et périodes au format de la charte, en français : portage de
// `frontend/mobile/lib/core/format/dates.dart` (mêmes cas de test).
//
// Deux sortes de dates arrivent de l'API :
// - un INSTANT (`date-time`, ex. `issued_at`) : affiché à l'heure de Brazzaville (UTC+1, sans heure
//   d'été), comme le backend (`backend/app/core/timezone.py`), quel que soit le fuseau du navigateur ;
// - une DATE DU CALENDRIER (`date`, ex. `due_date`) : affichée telle quelle, sans conversion.
import { enDash } from "./typography";

/** Décalage de Brazzaville par rapport à UTC, en millisecondes. */
const BRAZZAVILLE_OFFSET_MS = 60 * 60 * 1000;
const DAY_MS = 24 * 60 * 60 * 1000;

const MONTHS_SHORT = [
  "janv.",
  "févr.",
  "mars",
  "avr.",
  "mai",
  "juin",
  "juil.",
  "août",
  "sept.",
  "oct.",
  "nov.",
  "déc.",
] as const;

const MONTHS_LONG = [
  "janvier",
  "février",
  "mars",
  "avril",
  "mai",
  "juin",
  "juillet",
  "août",
  "septembre",
  "octobre",
  "novembre",
  "décembre",
] as const;

/** Lundi en premier, comme `weekday` de Dart. */
const WEEKDAYS = ["lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi", "dimanche"] as const;

/** Date du calendrier (`date` de l'API, « 2026-11-18 ») : jamais convertie de fuseau. */
export type CalendarDate = { year: number; month: number; day: number };

/** Instant (`date-time` de l'API) : chaîne ISO 8601 ou `Date`. */
export type Instant = string | Date;

/** « 2026-11-18 » → date du calendrier. Lève une erreur si la forme est inattendue. */
export function calendarDate(iso: string): CalendarDate {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(iso);
  if (!match) throw new Error(`Date du calendrier inattendue : « ${iso} »`);
  return { year: Number(match[1]), month: Number(match[2]), day: Number(match[3]) };
}

function time(instant: Instant): number {
  const ms = (instant instanceof Date ? instant : new Date(instant)).getTime();
  if (Number.isNaN(ms)) throw new Error(`Instant inattendu : « ${String(instant)} »`);
  return ms;
}

type Local = CalendarDate & { hour: number; minute: number; weekday: number };

/** L'instant vu à Brazzaville (`weekday` : 0 = lundi … 6 = dimanche). */
function toBrazzaville(instant: Instant): Local {
  const d = new Date(time(instant) + BRAZZAVILLE_OFFSET_MS);
  return {
    year: d.getUTCFullYear(),
    month: d.getUTCMonth() + 1,
    day: d.getUTCDate(),
    hour: d.getUTCHours(),
    minute: d.getUTCMinutes(),
    weekday: (d.getUTCDay() + 6) % 7,
  };
}

const two = (n: number) => n.toString().padStart(2, "0");
/** « 1er » le premier du mois, sinon le nombre. */
const dayText = (day: number) => (day === 1 ? "1er" : `${day}`);
const short = (month: number) => MONTHS_SHORT[month - 1] ?? "?";
const long = (month: number) => MONTHS_LONG[month - 1] ?? "?";
const capitalized = (word: string) => `${word.charAt(0).toUpperCase()}${word.slice(1)}`;
const monthIndex = (d: CalendarDate) => d.year * 12 + d.month;

/** Date du calendrier : « 18 nov. 2026 », « 1er sept. 2026 ». */
export function formatCalendarDate(date: CalendarDate): string {
  return `${dayText(date.day)} ${short(date.month)} ${date.year}`;
}

/** Date du calendrier sans l'année : « 18 nov. », « 1er sept. ». */
export function formatDayMonth(date: CalendarDate): string {
  return `${dayText(date.day)} ${short(date.month)}`;
}

/** Instant, jour seulement, à Brazzaville : « 25 nov. 2026 ». */
export function formatDate(instant: Instant): string {
  return formatCalendarDate(toBrazzaville(instant));
}

/**
 * Instant avec l'heure, à Brazzaville : « 12 nov. à 08:15 » ; l'année est ajoutée si ce n'est pas
 * celle de `now` (« 12 nov. 2025 à 08:15 »).
 */
export function formatDateTime(instant: Instant, now: Instant): string {
  const local = toBrazzaville(instant);
  const sameYear = local.year === toBrazzaville(now).year;
  const day = `${dayText(local.day)} ${short(local.month)}${sameYear ? "" : ` ${local.year}`}`;
  return `${day} à ${two(local.hour)}:${two(local.minute)}`;
}

/** Heure seule, à Brazzaville : « 14:31 ». */
export function formatTime(instant: Instant): string {
  const local = toBrazzaville(instant);
  return `${two(local.hour)}:${two(local.minute)}`;
}

/** Compte à rebours minutes:secondes (« 2:45 ») ; arrondi à la seconde supérieure. */
export function formatCountdown(remainingMs: number): string {
  const seconds = remainingMs < 0 ? 0 : Math.ceil(remainingMs / 1000);
  return `${Math.floor(seconds / 60)}:${two(seconds % 60)}`;
}

/** Jour de l'en-tête, à Brazzaville : « Jeudi 12 novembre », « Dimanche 1er mars ». */
export function formatWeekdayDate(instant: Instant): string {
  const local = toBrazzaville(instant);
  return `${capitalized(WEEKDAYS[local.weekday] ?? "")} ${dayText(local.day)} ${long(local.month)}`;
}

/** Nom du mois seul, avec sa majuscule : « Octobre ». */
export function formatMonthName(month: number): string {
  return capitalized(long(month));
}

/** Mois : « Octobre 2026 ». */
export function formatMonthYear(year: number, month: number): string {
  return `${formatMonthName(month)} ${year}`;
}

/** Date d'API (« 2026-10-14 ») d'une date du calendrier. */
export function formatApiDate(date: CalendarDate): string {
  return `${date.year}-${two(date.month)}-${two(date.day)}`;
}

/** Urgence d'une échéance : plus de 5 jours → normale ; 5 jours ou moins → proche ; dépassée → retard. */
export type DueUrgency = "normal" | "soon" | "overdue";

/**
 * Compte à rebours jusqu'à `due` (date du calendrier), vu le jour de `now` à Brazzaville :
 * « dans 6 jours », « demain », « aujourd’hui », « en retard de 3 jours ».
 */
export function dueCountdown(
  due: CalendarDate,
  now: Instant,
): { text: string; urgency: DueUrgency } {
  const local = toBrazzaville(now);
  const days = Math.round(
    (Date.UTC(due.year, due.month - 1, due.day) -
      Date.UTC(local.year, local.month - 1, local.day)) /
      DAY_MS,
  );
  if (days < 0) {
    const late = -days;
    return { text: `en retard de ${late} jour${late > 1 ? "s" : ""}`, urgency: "overdue" };
  }
  const text = days === 0 ? "aujourd’hui" : days === 1 ? "demain" : `dans ${days} jours`;
  return { text, urgency: days <= 5 ? "soon" : "normal" };
}

/**
 * Période d'une facture (dates du calendrier, fin incluse) : « 1er sept. – 31 oct. 2026 · 2 mois » ;
 * sur deux années : « 1er déc. 2026 – 31 janv. 2027 · 2 mois ».
 */
export function formatBillPeriod(start: CalendarDate, end: CalendarDate): string {
  const months = monthIndex(end) - monthIndex(start) + 1;
  const from =
    start.year === end.year
      ? `${dayText(start.day)} ${short(start.month)}`
      : formatCalendarDate(start);
  return `${from} ${enDash} ${formatCalendarDate(end)} · ${months} mois`;
}

/** Titre d'un groupe de factures : « Septembre – octobre 2026 » ; « Octobre 2026 ». */
export function formatBillPeriodGroup(start: CalendarDate, end: CalendarDate): string {
  if (monthIndex(start) === monthIndex(end)) return formatMonthYear(end.year, end.month);
  const from = formatMonthName(start.month);
  const to = long(end.month);
  if (start.year === end.year) return `${from} ${enDash} ${to} ${end.year}`;
  return `${from} ${start.year} ${enDash} ${to} ${end.year}`;
}

/** Période courte (listes) : « sept.–oct. 2026 » ; « déc. 2026–janv. 2027 » ; « oct. 2026 ». */
export function formatBillPeriodShort(start: CalendarDate, end: CalendarDate): string {
  if (monthIndex(start) === monthIndex(end)) return `${short(end.month)} ${end.year}`;
  if (start.year === end.year)
    return `${short(start.month)}${enDash}${short(end.month)} ${end.year}`;
  return `${short(start.month)} ${start.year}${enDash}${short(end.month)} ${end.year}`;
}
