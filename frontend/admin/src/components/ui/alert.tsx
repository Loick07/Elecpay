// Message dans la page : erreur (lue aussitôt par les lecteurs d'écran, `role="alert"`), avertissement,
// réussite ou information (`role="status"`). Toujours une couleur, une icône ET des mots ; une erreur de
// l'API porte sa référence (« Référence : … », à citer au support).
// La teinte douce de la charte est posée sur une base BLANCHE opaque (`surface-1`) : le contraste du
// texte ne dépend pas de l'endroit où l'alerte est placée (sur le fond de page, le bleu d'une
// information tombait à 4,49:1, sous le seuil de 4,5:1 : vu par axe le 28/11/2026). Contrastes
// vérifiés depuis les jetons par alert-contrast.test.ts.
import { CircleAlert, CircleCheck, Info, TriangleAlert } from "lucide-react";
import type { ReactNode } from "react";

import { cn } from "@/lib/utils";

type Tone = "error" | "warning" | "success" | "info";

const TONES: Record<Tone, { box: string; icon: string; Icon: typeof Info }> = {
  error: { box: "bg-error-soft text-error-text", icon: "text-error", Icon: CircleAlert },
  warning: { box: "bg-warning-soft text-warning-text", icon: "text-warning", Icon: TriangleAlert },
  success: { box: "bg-success-soft text-success-text", icon: "text-success", Icon: CircleCheck },
  info: { box: "bg-current-soft text-current-text", icon: "text-current-base", Icon: Info },
};

export function Alert({
  tone,
  children,
  reference,
  className,
}: {
  tone: Tone;
  children: ReactNode;
  reference?: string | null;
  className?: string;
}) {
  const { box, icon, Icon } = TONES[tone];
  return (
    <div
      role={tone === "error" ? "alert" : "status"}
      className={cn("bg-surface-1 text-admin-body rounded-md", className)}
    >
      <div className={cn("flex gap-3 rounded-md p-4", box)}>
        <Icon aria-hidden="true" className={cn("mt-0.5 size-5 shrink-0", icon)} />
        <div className="flex flex-col gap-1">
          <div>{children}</div>
          {reference ? (
            <p className="text-reference text-ink-muted font-mono">Référence : {reference}</p>
          ) : null}
        </div>
      </div>
    </div>
  );
}
