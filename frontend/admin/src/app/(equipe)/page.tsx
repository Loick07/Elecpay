import type { Metadata } from "next";

import { HomePlaceholder } from "@/features/home/home-placeholder";

// Accueil provisoire de l'équipe : remplacé par le tableau de bord en A9 (DECOUPAGES.md, DA2.4).
export const metadata: Metadata = { title: "Tableau de bord" };

export default function HomePage() {
  return <HomePlaceholder />;
}
