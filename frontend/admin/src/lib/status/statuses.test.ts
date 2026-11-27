// @vitest-environment node
import { readFileSync } from "node:fs";

import {
  Ban,
  Check,
  CircleQuestionMark,
  Clock,
  Hourglass,
  TimerOff,
  TriangleAlert,
  X,
} from "lucide-react";
import { describe, expect, it } from "vitest";

import {
  billStatus,
  billStatuses,
  toneClasses,
  transactionStatus,
  transactionStatuses,
} from "./statuses";

type Schemas = Record<string, { enum?: string[] }>;
const schemas = (
  JSON.parse(
    readFileSync(new URL("../../../../../backend/openapi.json", import.meta.url), "utf8"),
  ) as { components: { schemas: Schemas } }
).components.schemas;

/** Valeurs d'une énumération du contrat. */
function contractEnum(name: string): string[] {
  const values = schemas[name]?.enum;
  if (!values) throw new Error(`Énumération ${name} absente de openapi.json`);
  return [...values].sort();
}

describe("contre le contrat (backend/openapi.json)", () => {
  it("statuts de facture : exactement BillStatus", () => {
    expect(Object.keys(billStatuses).sort()).toEqual(contractEnum("BillStatus"));
  });

  it("statuts de transaction : exactement TransactionStatus", () => {
    expect(Object.keys(transactionStatuses).sort()).toEqual(contractEnum("TransactionStatus"));
  });
});

it("libellés, couleurs et icônes de la charte (mêmes que l’application)", () => {
  const all = { ...billStatuses, ...transactionStatuses };
  const expected = {
    unpaid: ["À payer", "current", Clock],
    pending_payment: ["Paiement en cours", "warning", Hourglass],
    paid: ["Payée", "success", Check],
    overdue: ["En retard", "error", TriangleAlert],
    cancelled: ["Annulée", "muted", Ban],
    en_attente: ["En attente", "warning", Hourglass],
    reussie: ["Réussie", "success", Check],
    echouee: ["Échouée", "error", X],
    expiree: ["Expirée", "muted", TimerOff],
  } as const;
  for (const [status, [label, tone, icon]] of Object.entries(expected)) {
    expect(all[status], status).toEqual({ label, tone, icon });
  }
});

it("statut inconnu : jamais « Échouée » pour une transaction, neutre pour une facture", () => {
  for (const status of [null, undefined, "", "inconnu", "nouveau_statut"]) {
    expect(transactionStatus(status)).toEqual({
      label: "Vérification en cours",
      tone: "warning",
      icon: CircleQuestionMark,
    });
  }
  expect(billStatus("nouveau_statut")).toMatchObject({ label: "Statut à vérifier", tone: "muted" });
  expect(billStatus("paid").label).toBe("Payée");
});

it("le jaune `volt` n’est jamais une couleur de statut ; le texte utilise les couleurs `*-text`", () => {
  for (const classes of Object.values(toneClasses)) {
    expect(Object.values(classes).join(" ")).not.toMatch(/volt/);
  }
  for (const tone of ["current", "warning", "success", "error"] as const) {
    expect(toneClasses[tone].text).toBe(`text-${tone}-text`);
  }
});
