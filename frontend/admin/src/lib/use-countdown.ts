"use client";

// Temps restant (ms) jusqu'à `deadline` (horodatage), relu chaque seconde ; 0 une fois passé.
// Sert au « Trop de tentatives » (429) : le bouton est bloqué pendant `retry_after_seconds`.
import { useEffect, useState } from "react";

import { ApiError } from "@/lib/api/errors";

export function useCountdown(deadline: number | null): number {
  const [now, setNow] = useState(() => Date.now());
  useEffect(() => {
    if (deadline === null) return undefined;
    const timer = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(timer);
  }, [deadline]);
  return deadline === null ? 0 : Math.max(0, deadline - now);
}

/** Fin du blocage d'une erreur 429 (`details.retry_after_seconds`, 60 s si absent), sinon `null`. */
export function retryDeadline(error: unknown, now: number): number | null {
  if (!(error instanceof ApiError) || error.status !== 429) return null;
  const seconds = Number(error.details.retry_after_seconds);
  return now + (Number.isFinite(seconds) && seconds > 0 ? seconds : 60) * 1000;
}
