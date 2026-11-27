import { act, renderHook } from "@testing-library/react";
import { afterEach, beforeEach, expect, it, vi } from "vitest";

import { ApiError } from "@/lib/api/errors";

import { retryDeadline, useRetryLock } from "./use-countdown";

const tooMany = (seconds?: number) =>
  new ApiError({
    status: 429,
    code: "TOO_MANY_ATTEMPTS",
    message: "Trop de tentatives.",
    details: seconds === undefined ? {} : { retry_after_seconds: seconds },
  });

beforeEach(() => vi.useFakeTimers());
afterEach(() => vi.useRealTimers());

it("part de la durée EXACTE de l’API, décompte chaque seconde, puis se lève", () => {
  const { result } = renderHook(() => useRetryLock());
  act(() => vi.advanceTimersByTime(90_000)); // la page est ouverte depuis longtemps
  act(() => result.current.block(tooMany(3)));
  expect(result.current.remaining).toBe(3000);
  act(() => vi.advanceTimersByTime(1000));
  expect(result.current.remaining).toBe(2000);
  act(() => vi.advanceTimersByTime(2000));
  expect(result.current.remaining).toBe(0);
});

it("une autre erreur que 429 ne bloque pas", () => {
  const { result } = renderHook(() => useRetryLock());
  act(() =>
    result.current.block(new ApiError({ status: 401, code: "INVALID_CREDENTIALS", message: "x" })),
  );
  expect(result.current.remaining).toBe(0);
});

it("429 sans durée : 60 s par défaut", () => {
  expect(retryDeadline(tooMany(), 1_000)).toBe(61_000);
  expect(retryDeadline(tooMany(125), 0)).toBe(125_000);
  expect(retryDeadline(new Error("x"), 0)).toBeNull();
});
