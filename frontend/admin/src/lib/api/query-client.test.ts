import { expect, it } from "vitest";

import { createQueryClient, STALE_TIME_MS } from "./query-client";

it("lectures (DA2.3) : 30 s de fraîcheur, aucune interrogation périodique, aucune relance", () => {
  const defaults = createQueryClient().getDefaultOptions();
  expect(STALE_TIME_MS).toBe(30_000);
  expect(defaults.queries).toMatchObject({
    staleTime: 30_000,
    refetchOnWindowFocus: true,
    refetchInterval: false,
    retry: false,
  });
  expect(defaults.mutations).toMatchObject({ retry: false });
});
