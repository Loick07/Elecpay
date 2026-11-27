"use client";

// Déconnexion après 30 minutes sans activité (décision DA1.2 : le jeton de rafraîchissement vaut
// 30 jours, une session de l'équipe ne doit pas rester ouverte sur un poste partagé), avec un
// avertissement 1 minute avant (« Rester connecté »). L'activité de N'IMPORTE QUEL onglet compte
// (horodatage partagé dans le stockage local). Pendant l'avertissement, seul « Rester connecté »
// relance la session (bouger la souris ne suffit pas).
import { useCallback, useEffect, useRef, useState } from "react";

export const INACTIVITY_LIMIT_MS = 30 * 60_000;
export const INACTIVITY_WARNING_MS = 60_000;
export const ACTIVITY_STORAGE_KEY = "elecpay-derniere-activite";
const ACTIVITY_EVENTS = ["pointerdown", "pointermove", "keydown", "wheel", "touchstart"] as const;
/** Une écriture dans le stockage partagé toutes les 5 s au plus. */
const SHARE_EVERY_MS = 5_000;

function sharedActivity(): number {
  const value = Number(globalThis.localStorage?.getItem(ACTIVITY_STORAGE_KEY));
  return Number.isFinite(value) ? value : 0;
}

export function useInactivity({
  onTimeout,
  limitMs = INACTIVITY_LIMIT_MS,
  warningMs = INACTIVITY_WARNING_MS,
}: {
  onTimeout: () => void;
  limitMs?: number;
  warningMs?: number;
}): { warning: boolean; remainingMs: number; stayActive: () => void } {
  const lastActivity = useRef(0);
  const lastShared = useRef(0);
  const warningRef = useRef(false);
  const timedOut = useRef(false);
  const timeoutRef = useRef(onTimeout);
  const [state, setState] = useState({ warning: false, remainingMs: limitMs });

  useEffect(() => {
    timeoutRef.current = onTimeout;
  }, [onTimeout]);

  const record = useCallback((now: number) => {
    lastActivity.current = now;
    if (now - lastShared.current >= SHARE_EVERY_MS) {
      lastShared.current = now;
      globalThis.localStorage?.setItem(ACTIVITY_STORAGE_KEY, String(now));
    }
  }, []);

  useEffect(() => {
    record(Date.now());
    const onActivity = () => {
      if (!warningRef.current) record(Date.now());
    };
    for (const event of ACTIVITY_EVENTS)
      window.addEventListener(event, onActivity, { passive: true });
    const timer = setInterval(() => {
      const now = Date.now();
      const idle = now - Math.max(lastActivity.current, sharedActivity());
      const remainingMs = Math.max(0, limitMs - idle);
      if (remainingMs === 0) {
        if (!timedOut.current) {
          timedOut.current = true;
          timeoutRef.current();
        }
        return;
      }
      const warning = remainingMs <= warningMs;
      warningRef.current = warning;
      setState((previous) =>
        previous.warning === warning && (!warning || previous.remainingMs === remainingMs)
          ? previous
          : { warning, remainingMs },
      );
    }, 1000);
    return () => {
      clearInterval(timer);
      for (const event of ACTIVITY_EVENTS) window.removeEventListener(event, onActivity);
    };
  }, [limitMs, warningMs, record]);

  const stayActive = useCallback(() => {
    warningRef.current = false;
    lastShared.current = 0; // partagé tout de suite avec les autres onglets
    record(Date.now());
    setState({ warning: false, remainingMs: limitMs });
  }, [limitMs, record]);

  return { ...state, stayActive };
}
