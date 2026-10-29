import {
  appGithubUrl,
  appLivePath,
  GITHUB_USER,
  miniApps,
  type MiniApp,
} from "@/data/apps";
import type { Project } from "@/data/portfolio";

export function miniAppToProject(app: MiniApp): Project {
  return {
    id: app.id,
    title: app.title,
    description: app.description,
    longDescription: app.longDescription,
    category: app.category,
    stack: app.stack,
    metrics: app.metrics,
    liveUrl: appLivePath(app.slug),
    githubUrl: appGithubUrl(app.slug),
    featured: app.featured,
  };
}

export type RemoteRepo = {
  id: number;
  name: string;
  description: string | null;
  html_url: string;
  homepage: string | null;
  language: string | null;
  stargazers_count: number;
  fork: boolean;
  topics?: string[];
};

const EXCLUDE = new Set(["test"]);

export function remoteRepoToProject(repo: RemoteRepo): Project {
  const stack = [
    repo.language,
    ...(repo.topics ?? []).slice(0, 3),
  ].filter(Boolean) as string[];

  return {
    id: `gh-${repo.name}`,
    title: repo.name,
    description: repo.description || `Public repository · ${repo.language ?? "code"}`,
    longDescription:
      repo.description ||
      `${repo.name} — synced dynamically from github.com/${GITHUB_USER}.`,
    category: "Open Source",
    stack: stack.length ? stack : ["GitHub"],
    metrics: [
      { label: "Stars", value: String(repo.stargazers_count) },
      { label: "Source", value: "GH" },
      { label: "Lang", value: repo.language ?? "—" },
    ],
    liveUrl: repo.homepage || repo.html_url,
    githubUrl: repo.html_url,
  };
}

export async function fetchDynamicProjects(): Promise<Project[]> {
  const local = miniApps.map(miniAppToProject);

  try {
    const res = await fetch(
      `https://api.github.com/users/${GITHUB_USER}/repos?sort=updated&per_page=20`,
      {
        headers: {
          Accept: "application/vnd.github+json",
          "User-Agent": "elshan-portfolio",
        },
        next: { revalidate: 3600 },
      },
    );

    if (!res.ok) return local;

    const repos = (await res.json()) as RemoteRepo[];
    const remote = repos
      .filter((r) => !r.fork && !EXCLUDE.has(r.name))
      .slice(0, 8)
      .map(remoteRepoToProject);

    // Local mini-apps first (featured demos), then GitHub repos
    const remoteIds = new Set(remote.map((p) => p.id));
    return [...local, ...remote.filter((p) => !remoteIds.has(p.id))];
  } catch {
    return local;
  }
}
