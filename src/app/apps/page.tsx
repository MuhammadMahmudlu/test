import Link from "next/link";
import { miniApps } from "@/data/apps";

export const metadata = {
  title: "Mini Apps — Muhammad Elshan",
  description: "Small interactive apps by Muhammad Elshan",
};

export default function AppsIndexPage() {
  return (
    <div>
      <p className="mb-2 font-mono text-[10px] tracking-[0.2em] text-accent uppercase">
        Lab
      </p>
      <h1 className="font-display text-3xl font-bold text-ink sm:text-4xl">
        Mini apps
      </h1>
      <p className="mt-2 text-ink-muted">
        Small utilities shipped in this portfolio repo — open a live demo or jump
        to the source on GitHub.
      </p>

      <div className="mt-8 grid gap-4 sm:grid-cols-2">
        {miniApps.map((app) => (
          <Link
            key={app.id}
            href={`/apps/${app.slug}`}
            className="rounded-3xl border border-line bg-surface-elevated p-5 shadow-[0_14px_40px_-28px_rgba(15,23,42,0.35)] transition hover:-translate-y-0.5 hover:border-accent/35 hover:shadow-[0_20px_44px_-24px_rgba(99,102,241,0.35)]"
          >
            <p className="font-mono text-[10px] tracking-wider text-accent uppercase">
              {app.category}
            </p>
            <h2 className="mt-1 font-display text-xl font-semibold text-ink">
              {app.title}
            </h2>
            <p className="mt-2 text-sm text-ink-muted">{app.description}</p>
          </Link>
        ))}
      </div>
    </div>
  );
}
