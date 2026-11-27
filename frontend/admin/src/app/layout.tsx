import type { Metadata } from "next";
import { Inter, JetBrains_Mono } from "next/font/google";
import { connection } from "next/server";

import "./globals.css";
import { Providers } from "./providers";

// Polices de la charte : Inter (back-office) et JetBrains Mono (références). `next/font` copie les
// fichiers au moment de la construction : le navigateur ne contacte jamais Google.
const inter = Inter({ variable: "--font-inter", subsets: ["latin"], display: "swap" });
const mono = JetBrains_Mono({
  variable: "--font-jetbrains-mono",
  subsets: ["latin"],
  display: "swap",
});

export const metadata: Metadata = {
  title: { default: "ElecPay — Back-office", template: "%s · ElecPay — Back-office" },
  description: "Back-office d'administration ElecPay, réservé à l'équipe.",
  robots: { index: false, follow: false }, // jamais indexé par les moteurs de recherche
};

export default async function RootLayout({ children }: LayoutProps<"/">) {
  // Rendu à chaque requête : la CSP de src/proxy.ts porte un nonce neuf que Next applique à ses
  // scripts ; une page prérendue au moment de la construction n'en aurait pas (bloquée par la CSP).
  await connection();
  // `suppressHydrationWarning` : certaines extensions du navigateur ajoutent des attributs à <html> ou
  // <body> avant React (vu chez Loick le 27/11/2026 : `__processed_…__` sur <body>, « 1 Issue » de
  // Next). React n'ignore alors que les ATTRIBUTS de ces deux balises (notre code ne les change
  // jamais) ; tout le contenu de la page reste contrôlé.
  return (
    <html lang="fr" className={`${inter.variable} ${mono.variable}`} suppressHydrationWarning>
      <body suppressHydrationWarning>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
