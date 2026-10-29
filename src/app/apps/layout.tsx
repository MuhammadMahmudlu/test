import Link from "next/link";
import { ArrowLeft } from "lucide-react";

export default function AppsLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="min-h-svh bg-surface text-ink">
      <header className="sticky top-0 z-40 border-b border-line/80 bg-surface/90 backdrop-blur-xl">
        <div className="mx-auto flex h-14 max-w-3xl items-center justify-between px-4 sm:px-6">
          <Link
            href="/#projects"
            className="inline-flex items-center gap-2 text-sm font-semibold text-ink-muted transition hover:text-accent"
          >
            <ArrowLeft size={16} /> Back to portfolio
          </Link>
          <Link
            href="/apps"
            className="text-sm font-semibold text-accent hover:underline"
          >
            All apps
          </Link>
        </div>
      </header>
      <main className="mx-auto max-w-3xl px-4 py-8 sm:px-6 sm:py-10">
        {children}
      </main>
    </div>
  );
}
