import { act, renderHook } from "@testing-library/react";
import { afterEach, beforeEach, expect, it, vi } from "vitest";

import { ACTIVITY_STORAGE_KEY, useInactivity } from "./inactivity";

const MINUTE = 60_000;

beforeEach(() => {
  vi.useFakeTimers();
  localStorage.clear();
});
afterEach(() => vi.useRealTimers());

function setup() {
  const onTimeout = vi.fn();
  const hook = renderHook(() => useInactivity({ onTimeout }));
  return { onTimeout, hook };
}

it("29 min sans activité : avertissement ; 30 min : déconnexion (une seule fois)", () => {
  const { onTimeout, hook } = setup();
  act(() => vi.advanceTimersByTime(28 * MINUTE));
  expect(hook.result.current.warning).toBe(false);
  act(() => vi.advanceTimersByTime(MINUTE + 1000));
  expect(hook.result.current.warning).toBe(true);
  expect(hook.result.current.remainingMs).toBeLessThanOrEqual(60_000);
  expect(onTimeout).not.toHaveBeenCalled();
  act(() => vi.advanceTimersByTime(2 * MINUTE));
  expect(onTimeout).toHaveBeenCalledTimes(1);
});

it("une activité (touche, clic) repousse l’échéance", () => {
  const { onTimeout, hook } = setup();
  act(() => vi.advanceTimersByTime(20 * MINUTE));
  act(() => {
    window.dispatchEvent(new KeyboardEvent("keydown"));
  });
  act(() => vi.advanceTimersByTime(20 * MINUTE));
  expect(hook.result.current.warning).toBe(false);
  expect(onTimeout).not.toHaveBeenCalled();
});

it("pendant l’avertissement, bouger la souris ne suffit pas : « Rester connecté » relance", () => {
  const { onTimeout, hook } = setup();
  act(() => vi.advanceTimersByTime(29 * MINUTE + 5000));
  expect(hook.result.current.warning).toBe(true);
  act(() => {
    window.dispatchEvent(new Event("pointermove"));
  });
  act(() => vi.advanceTimersByTime(1000));
  expect(hook.result.current.warning).toBe(true);
  act(() => hook.result.current.stayActive());
  expect(hook.result.current.warning).toBe(false);
  act(() => vi.advanceTimersByTime(10 * MINUTE));
  expect(onTimeout).not.toHaveBeenCalled();
});

it("l’activité d’un AUTRE onglet compte (horodatage partagé)", () => {
  const { onTimeout, hook } = setup();
  act(() => vi.advanceTimersByTime(25 * MINUTE));
  localStorage.setItem(ACTIVITY_STORAGE_KEY, String(Date.now()));
  act(() => vi.advanceTimersByTime(25 * MINUTE));
  expect(hook.result.current.warning).toBe(false);
  expect(onTimeout).not.toHaveBeenCalled();
});
