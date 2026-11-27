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
  return (
    <html lang="fr" className={`${inter.variable} ${mono.variable}`}>
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
