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
      <p className="mb-2 font-mono text-[10px] tracking-[0.2em] text-accent uppercase">
        Mini app · {app.category}
      </p>
      <h1 className="font-display text-3xl font-bold tracking-tight text-ink sm:text-4xl">
        {app.title}
      </h1>
      <p className="mt-2 max-w-2xl text-ink-muted">{app.longDescription}</p>
      <div className="mt-4 flex flex-wrap items-center gap-2">
        {app.stack.map((tag) => (
          <span
            key={tag}
            className="rounded-full border border-line bg-white px-2.5 py-1 font-mono text-[10px] text-slate-600"
          >
            {tag}
          </span>
        ))}
        <a
          href={appGithubUrl(app.slug)}
          target="_blank"
          rel="noopener noreferrer"
          className="inline-flex items-center gap-1.5 rounded-full border border-line px-2.5 py-1 text-[11px] font-semibold text-ink-muted hover:border-accent/40 hover:text-accent"
        >
          <GitHubIcon size={12} /> Source
        </a>
        <Link
          href="/apps"
          className="text-[11px] font-semibold text-accent hover:underline"
        >
          Browse all apps
        </Link>
      </div>
      <div className="mt-8">{children}</div>
    </div>
  );
}
