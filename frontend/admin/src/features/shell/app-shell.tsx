"use client";

// Cadre des écrans de l'équipe (maquettes du back-office, largeur de référence 1440 px) : menu
// latéral bleu nuit à gauche, contenu à droite ; sous 1024 px, le menu passe au-dessus (DA2.1).
// Chaque page apporte son en-tête (titre, sous-titre, actions : `TeamPage`). Avis (`useToast`)
// disponibles dans toutes les pages du cadre.
import type { ReactNode } from "react";

import { ToastProvider } from "@/components/ui/toaster";

import { Sidebar } from "./sidebar";

export function AppShell({ children }: { children: ReactNode }) {
  return (
    <ToastProvider>
      <div className="flex min-h-screen flex-col lg:flex-row">
        <a
          href="#contenu"
          className="bg-surface-1 text-ink shadow-card sr-only rounded-md px-4 py-2 focus:not-sr-only focus:fixed focus:top-3 focus:left-3 focus:z-50"
        >
          Aller au contenu
        </a>
        <Sidebar />
        <main
          id="contenu"
          tabIndex={-1}
          className="flex min-w-0 flex-1 flex-col gap-5 px-4 py-6 outline-none sm:px-8 sm:pb-8"
        >
          {children}
        </main>
      </div>
    </ToastProvider>
  );
}
