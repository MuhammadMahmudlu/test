import Link from "next/link";
import { GitHubIcon } from "@/components/icons";
import { appGithubUrl, type MiniApp } from "@/data/apps";

export default function AppShell({
  app,
  children,
}: {
  app: MiniApp;
  children: React.ReactNode;
}) {
  return (
    <div>
      <p className="mb-2 font-mono text-[10px] tracking-[0.22em] text-crimson uppercase">
        Mini app · {app.category}
      </p>
      <h1 className="font-display text-5xl text-ink sm:text-6xl">{app.title}</h1>
      <p className="mt-2 max-w-2xl text-ink-muted">{app.longDescription}</p>
      <div className="mt-4 flex flex-wrap items-center gap-2">
        {app.stack.map((tag) => (
          <span
            key={tag}
            className="border border-line bg-elevated px-2.5 py-1 font-mono text-[10px] text-ink-muted"
          >
            {tag}
          </span>
        ))}
        <a
          href={appGithubUrl(app.slug)}
          target="_blank"
          rel="noopener noreferrer"
          className="inline-flex items-center gap-1.5 border border-line px-2.5 py-1 text-[11px] font-semibold text-ink-muted uppercase hover:border-crimson hover:text-crimson"
        >
          <GitHubIcon size={12} /> Source
        </a>
        <Link
          href="/apps"
          className="text-[11px] font-bold tracking-wide text-crimson uppercase hover:underline"
        >
          Browse all
        </Link>
      </div>
      <div className="mt-8">{children}</div>
    </div>
  );
}
