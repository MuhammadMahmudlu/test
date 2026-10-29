import AppShell from "@/components/apps/AppShell";
import PomodoroApp from "@/components/apps/PomodoroApp";
import { getMiniApp } from "@/data/apps";
import { notFound } from "next/navigation";

export const metadata = {
  title: "Focus Pomodoro — Muhammad Elshan",
};

export default function PomodoroPage() {
  const app = getMiniApp("pomodoro");
  if (!app) notFound();
  return (
    <AppShell app={app}>
      <PomodoroApp />
    </AppShell>
  );
}
