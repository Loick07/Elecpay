"use client";

// Avis (« Facture annulée. », « Export prêt. ») : coin bas-droit, lus par les lecteurs d'écran
// (zone `aria-live` toujours présente, polie pour une réussite, immédiate pour une erreur),
// refermés seuls après 6 s ou par « Fermer ». Une erreur qui demande d'agir reste DANS l'écran,
// avec sa référence : l'avis ne sert qu'à confirmer ou signaler en passant.
import { CircleAlert, CircleCheck, X } from "lucide-react";
import {
  createContext,
  type ReactNode,
  useCallback,
  useContext,
  useEffect,
  useRef,
  useState,
} from "react";

import { cn } from "@/lib/utils";

export const TOAST_DURATION_MS = 6_000;

type Tone = "success" | "error";
type Toast = { id: number; tone: Tone; message: string };
type Show = (message: string, tone?: Tone) => void;

const ToastContext = createContext<Show | null>(null);

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([]);
  const next = useRef(0);
  const timers = useRef(new Map<number, ReturnType<typeof setTimeout>>());

  const dismiss = useCallback((id: number) => {
    clearTimeout(timers.current.get(id));
    timers.current.delete(id);
    setToasts((current) => current.filter((toast) => toast.id !== id));
  }, []);

  const show = useCallback<Show>(
    (message, tone = "success") => {
      next.current += 1;
      const id = next.current;
      setToasts((current) => [...current, { id, tone, message }]);
      timers.current.set(
        id,
        setTimeout(() => dismiss(id), TOAST_DURATION_MS),
      );
    },
    [dismiss],
  );

  useEffect(() => {
    const pending = timers.current;
    return () => pending.forEach((timer) => clearTimeout(timer));
  }, []);

  const list = (tone: Tone) =>
    toasts
      .filter((toast) => toast.tone === tone)
      .map((toast) => <ToastItem key={toast.id} toast={toast} onClose={() => dismiss(toast.id)} />);

  return (
    <ToastContext.Provider value={show}>
      {children}
      <section
        aria-label="Avis"
        className="pointer-events-none fixed right-4 bottom-4 z-50 flex w-[min(24rem,calc(100vw-2rem))] flex-col gap-2"
      >
        <div aria-live="polite" className="flex flex-col gap-2">
          {list("success")}
        </div>
        <div aria-live="assertive" className="flex flex-col gap-2">
          {list("error")}
        </div>
      </section>
    </ToastContext.Provider>
  );
}

function ToastItem({ toast, onClose }: { toast: Toast; onClose: () => void }) {
  const Icon = toast.tone === "error" ? CircleAlert : CircleCheck;
  return (
    <div className="bg-surface-1 shadow-float border-line pointer-events-auto flex items-start gap-3 rounded-md border p-4">
      <Icon
        aria-hidden="true"
        className={cn(
          "mt-0.5 size-5 shrink-0",
          toast.tone === "error" ? "text-error" : "text-success",
        )}
      />
      <p className="text-admin-body text-ink flex-1">{toast.message}</p>
      <button
        type="button"
        onClick={onClose}
        aria-label="Fermer l’avis"
        className="text-ink-muted hover:text-ink -m-1 grid size-8 place-items-center rounded-sm"
      >
        <X aria-hidden="true" className="size-4" />
      </button>
    </div>
  );
}

/** Affiche un avis : `toast("Facture annulée.")`, `toast("Export impossible.", "error")`. */
export function useToast(): Show {
  const show = useContext(ToastContext);
  if (!show) throw new Error("useToast : à utiliser sous ToastProvider (cadre AppShell).");
  return show;
}
