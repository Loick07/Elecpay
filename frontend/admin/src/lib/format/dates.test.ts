// Mêmes cas que `frontend/mobile/test/core/format/dates_test.dart`.
import { describe, expect, it } from "vitest";

import {
  calendarDate,
  dueCountdown,
  formatApiDate,
  formatBillPeriod,
  formatBillPeriodGroup,
  formatBillPeriodShort,
  formatCalendarDate,
  formatCountdown,
  formatDate,
  formatDateTime,
  formatDayMonth,
  formatMonthName,
  formatMonthYear,
  formatTime,
  formatWeekdayDate,
} from "./dates";

const d = (year: number, month: number, day = 1) => ({ year, month, day });

describe("dates du calendrier (jamais converties)", () => {
  it("« 18 nov. 2026 », « 1er sept. 2026 »", () => {
    expect(formatCalendarDate(d(2026, 11, 18))).toBe("18 nov. 2026");
    expect(formatCalendarDate(d(2026, 9))).toBe("1er sept. 2026");
  });

  it("les 12 abréviations de la charte", () => {
    const months = Array.from({ length: 12 }, (_, i) => formatCalendarDate(d(2026, i + 1, 15)));
    expect(months).toEqual([
      "15 janv. 2026",
      "15 févr. 2026",
      "15 mars 2026",
      "15 avr. 2026",
      "15 mai 2026",
      "15 juin 2026",
      "15 juil. 2026",
      "15 août 2026",
      "15 sept. 2026",
      "15 oct. 2026",
      "15 nov. 2026",
      "15 déc. 2026",
    ]);
  });

  it("lecture d’une date de l’API, sans fuseau", () => {
    expect(calendarDate("2026-11-18")).toEqual(d(2026, 11, 18));
    expect(() => calendarDate("2026-11-18T10:00:00Z")).toThrow(/inattendue/);
    expect(formatApiDate(d(2026, 3, 5))).toBe("2026-03-05");
  });

  it("sans l’année : « 18 nov. », « 1er sept. », « 3 mai »", () => {
    expect(formatDayMonth(d(2026, 11, 18))).toBe("18 nov.");
    expect(formatDayMonth(d(2026, 9))).toBe("1er sept.");
    expect(formatDayMonth(d(2026, 5, 3))).toBe("3 mai");
  });
});

describe("instants, à l’heure de Brazzaville (UTC+1)", () => {
  const now = "2026-11-12T09:00:00Z";

  it("jour seul ; 23:05 UTC le 31 déc. est déjà le 1er janv. à Brazzaville", () => {
    expect(formatDate("2026-11-25T10:00:00Z")).toBe("25 nov. 2026");
    expect(formatDate("2026-12-31T23:05:00Z")).toBe("1er janv. 2027");
  });

  it("avec l’heure ; l’année seulement si ce n’est pas l’année en cours", () => {
    expect(formatDateTime("2026-11-12T07:15:00Z", now)).toBe("12 nov. à 08:15");
    expect(formatDateTime("2025-11-12T07:15:00Z", now)).toBe("12 nov. 2025 à 08:15");
  });

  it("le même instant donne le même texte, quel que soit son fuseau d’écriture", () => {
    expect(formatDateTime("2026-11-12T08:15:00+01:00", now)).toBe("12 nov. à 08:15");
    expect(formatDateTime(new Date(Date.UTC(2026, 10, 12, 7, 15)), now)).toBe("12 nov. à 08:15");
  });

  it("heure seule", () => {
    expect(formatTime("2026-11-12T13:31:00Z")).toBe("14:31");
    expect(formatTime("2026-11-12T23:05:00Z")).toBe("00:05");
  });

  it("jour de l’en-tête : « Jeudi 12 novembre », « Dimanche 1er mars »", () => {
    expect(formatWeekdayDate("2026-11-12T09:00:00Z")).toBe("Jeudi 12 novembre");
    expect(formatWeekdayDate("2026-02-28T23:30:00Z")).toBe("Dimanche 1er mars");
  });

  it("refuse un instant illisible", () => {
    expect(() => formatDate("pas une date")).toThrow(/inattendu/);
  });
});

describe("compte à rebours de l’échéance", () => {
  const today = "2026-11-12T09:00:00Z"; // 12 nov. 2026 à 10:00 à Brazzaville

  it("loin : « dans 6 jours », urgence normale", () => {
    expect(dueCountdown(d(2026, 11, 18), today)).toEqual({
      text: "dans 6 jours",
      urgency: "normal",
    });
  });

  it("à 5 jours ou moins : proche", () => {
    expect(dueCountdown(d(2026, 11, 17), today)).toEqual({ text: "dans 5 jours", urgency: "soon" });
    expect(dueCountdown(d(2026, 11, 13), today)).toEqual({ text: "demain", urgency: "soon" });
    expect(dueCountdown(d(2026, 11, 12), today)).toEqual({ text: "aujourd’hui", urgency: "soon" });
  });

  it("après l’échéance : en retard, singulier et pluriel", () => {
    expect(dueCountdown(d(2026, 11, 11), today)).toEqual({
      text: "en retard de 1 jour",
      urgency: "overdue",
    });
    expect(dueCountdown(d(2026, 11, 9), today).text).toBe("en retard de 3 jours");
  });

  it("le jour se compte à Brazzaville (23:30 UTC = déjà le lendemain)", () => {
    expect(dueCountdown(d(2026, 11, 13), "2026-11-12T23:30:00Z").text).toBe("aujourd’hui");
  });

  it("changement d’année", () => {
    expect(dueCountdown(d(2027, 1, 2), "2026-12-30T10:00:00Z").text).toBe("dans 3 jours");
  });
});

it("compte à rebours minutes:secondes", () => {
  expect(formatCountdown(42_000)).toBe("0:42");
  expect(formatCountdown(165_000)).toBe("2:45");
  expect(formatCountdown(15 * 60_000)).toBe("15:00");
  expect(formatCountdown(1_200)).toBe("0:02");
  expect(formatCountdown(0)).toBe("0:00");
  expect(formatCountdown(-3_000)).toBe("0:00");
});

it("mois : « Octobre 2026 », « Août 2026 », « Janvier 2027 », « Octobre »", () => {
  expect(formatMonthYear(2026, 10)).toBe("Octobre 2026");
  expect(formatMonthYear(2026, 8)).toBe("Août 2026");
  expect(formatMonthYear(2027, 1)).toBe("Janvier 2027");
  expect(formatMonthName(10)).toBe("Octobre");
});

describe("période d’une facture bimestrielle", () => {
  it("« 1er sept. – 31 oct. 2026 · 2 mois »", () => {
    expect(formatBillPeriod(d(2026, 9), d(2026, 10, 31))).toBe("1er sept. – 31 oct. 2026 · 2 mois");
  });

  it("sur deux années : les deux années sont écrites", () => {
    expect(formatBillPeriod(d(2026, 12), d(2027, 1, 31))).toBe(
      "1er déc. 2026 – 31 janv. 2027 · 2 mois",
    );
  });

  it("février (28 jours) et période d’un seul mois", () => {
    expect(formatBillPeriod(d(2027, 1), d(2027, 2, 28))).toBe("1er janv. – 28 févr. 2027 · 2 mois");
    expect(formatBillPeriod(d(2026, 10), d(2026, 10, 31))).toBe("1er oct. – 31 oct. 2026 · 1 mois");
  });

  it("version courte des listes : « sept.–oct. 2026 »", () => {
    expect(formatBillPeriodShort(d(2026, 9), d(2026, 10, 31))).toBe("sept.–oct. 2026");
    expect(formatBillPeriodShort(d(2026, 12), d(2027, 1, 31))).toBe("déc. 2026–janv. 2027");
    expect(formatBillPeriodShort(d(2026, 10), d(2026, 10, 31))).toBe("oct. 2026");
  });

  it("titre d’un groupe : « Septembre – octobre 2026 »", () => {
    expect(formatBillPeriodGroup(d(2026, 9), d(2026, 10, 31))).toBe("Septembre – octobre 2026");
    expect(formatBillPeriodGroup(d(2026, 12), d(2027, 1, 31))).toBe("Décembre 2026 – janvier 2027");
    expect(formatBillPeriodGroup(d(2026, 10), d(2026, 10, 31))).toBe("Octobre 2026");
  });
});
