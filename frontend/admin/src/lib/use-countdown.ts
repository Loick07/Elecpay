"use client";

// Blocage après « Trop de tentatives » (429) : le bouton reste bloqué pendant `retry_after_seconds`
// (comme `RetryLock` du mobile), avec un compte à rebours relu chaque seconde.
// La fin du blocage ET l'heure du refus sont enregistrées ensemble, au moment de l'erreur :
// l'affichage part exactement de la durée donnée par l'API (défaut corrigé le 27/11/2026 : l'heure
// « actuelle » relevée à l'ouverture de la page faisait afficher 0:32 au lieu de 0:30).
import { useEffect, useState } from "react";

import { ApiError } from "@/lib/api/errors";

/** Fin du blocage d'une erreur 429 (`details.retry_after_seconds`, 60 s si absent), sinon `null`. */
export function retryDeadline(error: unknown, now: number): number | null {
  if (!(error instanceof ApiError) || error.status !== 429) return null;
  const seconds = Number(error.details.retry_after_seconds);
  return now + (Number.isFinite(seconds) && seconds > 0 ? seconds : 60) * 1000;
}

type Lock = { deadline: number; now: number };

export function useRetryLock(): { remaining: number; block: (error: unknown) => void } {
  const [lock, setLock] = useState<Lock | null>(null);
  const deadline = lock?.deadline ?? null;
  useEffect(() => {
    if (deadline === null) return undefined;
    const timer = setInterval(() => {
      const now = Date.now();
      setLock(now >= deadline ? null : { deadline, now });
    }, 1000);
    return () => clearInterval(timer);
  }, [deadline]);
  return {
    remaining: lock ? Math.max(0, lock.deadline - lock.now) : 0,
    block: (error) => {
      const now = Date.now();
      const until = retryDeadline(error, now);
      setLock(until === null ? null : { deadline: until, now });
    },
  };
}
