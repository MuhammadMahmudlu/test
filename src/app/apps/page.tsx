import Link from "next/link";
import { miniApps } from "@/data/apps";

export const metadata = {
  title: "Mini Apps — Muhammad Elshan",
  description: "Small interactive apps by Muhammad Elshan",
};

export default function AppsIndexPage() {
  return (
    <div>
      <p className="mb-2 font-mono text-[10px] tracking-[0.22em] text-crimson uppercase">
        Lab
      </p>
      <h1 className="font-display text-5xl text-ink sm:text-6xl">Mini apps</h1>
      <p className="mt-2 text-ink-muted">
        Utilities shipped in this portfolio — open a live demo or jump to GitHub
        source.
      </p>

      <div className="mt-8 grid gap-4 sm:grid-cols-2">
        {miniApps.map((app) => (
          <Link
            key={app.id}
            href={`/apps/${app.slug}`}
            className="border border-line bg-charcoal p-5 transition hover:border-crimson/60 hover:shadow-[0_0_30px_rgba(220,38,38,0.15)]"
          >
            <p className="font-mono text-[10px] tracking-wider text-crimson uppercase">
              {app.category}
            </p>
            <h2 className="mt-1 font-display text-3xl text-ink">{app.title}</h2>
            <p className="mt-2 text-sm text-ink-muted">{app.description}</p>
          </Link>
        ))}
      </div>
    </div>
  );
}
