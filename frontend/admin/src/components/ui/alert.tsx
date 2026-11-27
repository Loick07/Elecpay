// Message dans la page : erreur (lue aussitôt par les lecteurs d'écran, `role="alert"`), avertissement,
// réussite ou information (`role="status"`). Toujours une couleur, une icône ET des mots ; une erreur de
// l'API porte sa référence (« Référence : … », à citer au support).
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
      className={cn("text-admin-body flex gap-3 rounded-md p-4", box, className)}
    >
      <Icon aria-hidden="true" className={cn("mt-0.5 size-5 shrink-0", icon)} />
      <div className="flex flex-col gap-1">
        <div>{children}</div>
        {reference ? (
          <p className="text-reference text-ink-muted font-mono">Référence : {reference}</p>
        ) : null}
      </div>
    </div>
  );
}
