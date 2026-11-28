"use client";

// « Exporter (CSV) » (maquettes A2 et A5) : la liste AVEC SES FILTRES, telle que l'API la produit
// (les numéros masqués le restent). Réservé aux admins par l'API (403 sinon) : le bouton n'est
// montré qu'avec le niveau `admin`. Réussite ou refus : un avis.
import { useMutation } from "@tanstack/react-query";
import { Download } from "lucide-react";

import { Button } from "@/components/ui/button";
import { useToast } from "@/components/ui/toaster";
import { type ExportPath, fetchFile, saveFile } from "@/lib/api/download";
import { describeError } from "@/lib/api/errors";
import { usePermissions } from "@/lib/permissions/permissions";

export function ExportCsvButton({
  path,
  query,
  fallbackName,
}: {
  path: ExportPath;
  query: Record<string, string | undefined>;
  /** Nom du fichier si l'API n'en donne pas. */
  fallbackName: string;
}) {
  const permissions = usePermissions();
  const toast = useToast();
  const exporting = useMutation({
    mutationFn: () => fetchFile(path, query),
    onSuccess: ({ blob, filename }) => {
      const name = filename ?? fallbackName;
      saveFile(blob, name);
      toast(`Export prêt : ${name}.`);
    },
    onError: (error) => {
      const { message, reference } = describeError(error);
      toast(
        `Export impossible. ${message}${reference ? ` (référence : ${reference})` : ""}`,
        "error",
      );
    },
  });
  if (!permissions.hasLevel("admin")) return null;
  return (
    <Button
      size="sm"
      icon={<Download aria-hidden="true" className="size-4" />}
      loading={exporting.isPending}
      loadingLabel="Export en cours…"
      onClick={() => exporting.mutate()}
    >
      Exporter (CSV)
    </Button>
  );
}
