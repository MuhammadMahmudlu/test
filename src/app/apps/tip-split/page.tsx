import AppShell from "@/components/apps/AppShell";
import TipSplitApp from "@/components/apps/TipSplitApp";
import { getMiniApp } from "@/data/apps";
import { notFound } from "next/navigation";

export const metadata = {
  title: "Tip Split — Muhammad Elshan",
};

export default function TipSplitPage() {
  const app = getMiniApp("tip-split");
  if (!app) notFound();
  return (
    <AppShell app={app}>
      <TipSplitApp />
    </AppShell>
  );
}
