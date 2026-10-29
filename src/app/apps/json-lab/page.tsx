import AppShell from "@/components/apps/AppShell";
import JsonLabApp from "@/components/apps/JsonLabApp";
import { getMiniApp } from "@/data/apps";
import { notFound } from "next/navigation";

export const metadata = {
  title: "JSON Lab — Muhammad Elshan",
};

export default function JsonLabPage() {
  const app = getMiniApp("json-lab");
  if (!app) notFound();
  return (
    <AppShell app={app}>
      <JsonLabApp />
    </AppShell>
  );
}
