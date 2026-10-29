import Link from "next/link";
import { ArrowLeft } from "lucide-react";

export default function AppsLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="min-h-svh bg-void text-ink">
      <header className="sticky top-0 z-40 border-b border-line bg-void/90 backdrop-blur-xl">
        <div className="mx-auto flex h-14 max-w-3xl items-center justify-between px-4 sm:px-6">
          <Link
            href="/#projects"
            className="inline-flex items-center gap-2 text-sm font-semibold tracking-wide text-ink-muted uppercase transition hover:text-crimson"
          >
            <ArrowLeft size={16} /> Portfolio
          </Link>
          <Link
            href="/apps"
            className="text-sm font-bold tracking-wide text-crimson uppercase hover:underline"
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
