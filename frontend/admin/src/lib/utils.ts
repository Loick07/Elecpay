// `cn` (convention de shadcn/ui) : assemble des classes Tailwind et garde la dernière en cas de
// conflit. `tailwind-merge` reçoit les noms de la CHARTE (générés depuis tokens.json) : sans eux, il
// prendrait `text-admin-body` (une taille) pour une couleur et l'effacerait devant `text-ink`.
import { type ClassValue, clsx } from "clsx";
import { extendTailwindMerge } from "tailwind-merge";

import { BLURS, SHADOWS, TEXT_STYLES } from "@/styles/tokens.generated";

const twMerge = extendTailwindMerge({
  extend: {
    theme: { text: [...TEXT_STYLES], shadow: [...SHADOWS], blur: [...BLURS] },
  },
});

export function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs));
}
