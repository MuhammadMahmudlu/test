"use client";

import { useEffect, useMemo, useState } from "react";
import { AnimatePresence, motion } from "framer-motion";
import type { Project, ProjectCategory } from "@/data/portfolio";
import { cn } from "@/lib/utils";
import ProjectCard from "./ProjectCard";
import SectionHeading from "./SectionHeading";

const filters: ProjectCategory[] = [
  "All",
  "Full-Stack",
  "Frontend",
  "Backend",
  "Open Source",
];

export default function Projects() {
  const [active, setActive] = useState<ProjectCategory>("All");
  const [projects, setProjects] = useState<Project[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const res = await fetch("/api/projects");
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const data = (await res.json()) as { projects: Project[] };
        if (!cancelled) {
          setProjects(data.projects ?? []);
          setError(null);
        }
      } catch (e) {
        if (!cancelled) {
          setError(e instanceof Error ? e.message : "Failed to load projects");
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  const filtered = useMemo(
    () =>
      active === "All"
        ? projects
        : projects.filter((p) => p.category === active),
    [active, projects],
  );

  return (
    <section id="projects" className="relative scroll-mt-20 py-24 sm:py-28">
      <div className="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8">
        <SectionHeading
          eyebrow="02 — Projects"
          title="Apps & builds"
          description="Live mini-apps from this repo, plus public GitHub projects synced dynamically."
        />

        <div
          role="tablist"
          aria-label="Project categories"
          className="mb-10 flex flex-wrap gap-2"
        >
          {filters.map((f) => (
            <button
              key={f}
              role="tab"
              aria-selected={active === f}
              type="button"
              onClick={() => setActive(f)}
              className={cn(
                "rounded-full border px-3.5 py-1.5 text-xs font-semibold tracking-wide transition",
                active === f
                  ? "border-accent bg-accent text-white shadow-[0_10px_24px_-14px_rgba(99,102,241,0.9)]"
                  : "border-line bg-surface-elevated text-ink-muted hover:border-accent/40 hover:text-accent",
              )}
            >
              {f}
            </button>
          ))}
        </div>

        {loading && (
          <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
            {Array.from({ length: 6 }).map((_, i) => (
              <div
                key={i}
                className="h-56 animate-pulse rounded-3xl border border-line bg-slate-100"
              />
            ))}
          </div>
        )}

        {error && !loading && (
          <p className="rounded-2xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-700">
            Could not load projects: {error}
          </p>
        )}

        {!loading && !error && (
          <motion.div
            layout
            className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3"
            style={{ perspective: 1200 }}
          >
            <AnimatePresence mode="popLayout">
              {filtered.map((project, i) => (
                <motion.div
                  key={project.id}
                  layout
                  initial={{ opacity: 0, scale: 0.96 }}
                  animate={{ opacity: 1, scale: 1 }}
                  exit={{ opacity: 0, scale: 0.96 }}
                  transition={{ duration: 0.25 }}
                >
                  <ProjectCard project={project} index={i} />
                </motion.div>
              ))}
            </AnimatePresence>
          </motion.div>
        )}

        {!loading && !error && filtered.length === 0 && (
          <p className="text-sm text-ink-muted">No projects in this category.</p>
        )}
      </div>
    </section>
  );
}
