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
      `https://api.github.com/users/${GITHUB_USER}/repos?sort=updated&per_page=30`,
      {
        headers: {
          Accept: "application/vnd.github+json",
          "User-Agent": "elshan-portfolio",
        },
        cache: "no-store",
      },
    );

    if (!res.ok) {
      console.warn("[projects] GitHub API status", res.status);
      return local;
    }

    const repos = (await res.json()) as RemoteRepo[];
    if (!Array.isArray(repos)) {
      console.warn("[projects] unexpected GitHub payload");
      return local;
    }

    const remote = repos
      .filter((r) => !r.fork && !EXCLUDE.has(r.name))
      .slice(0, 8)
      .map(remoteRepoToProject);

    return [...local, ...remote];
  } catch (err) {
    console.warn("[projects] GitHub fetch failed", err);
    return local;
  }
}
