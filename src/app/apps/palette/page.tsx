import AppShell from "@/components/apps/AppShell";
import PaletteApp from "@/components/apps/PaletteApp";
import { getMiniApp } from "@/data/apps";
import { notFound } from "next/navigation";

export const metadata = {
  title: "Palette Lab — Muhammad Elshan",
};

export default function PalettePage() {
  const app = getMiniApp("palette");
  if (!app) notFound();
  return (
    <AppShell app={app}>
      <PaletteApp />
    </AppShell>
  );
}
