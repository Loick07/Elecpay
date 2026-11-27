import type { Metadata } from "next";

import { AccountScreen } from "@/features/account/account-screen";

export const metadata: Metadata = { title: "Mon compte" };

export default function MonComptePage() {
  return <AccountScreen />;
}
