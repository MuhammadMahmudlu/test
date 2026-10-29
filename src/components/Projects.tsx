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
          eyebrow="01 — Selected"
          title="Projects"
          description="Live mini-apps from this repo plus public GitHub work — synced dynamically."
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
                "border px-3.5 py-1.5 text-xs font-bold tracking-[0.14em] uppercase transition",
                active === f
                  ? "border-crimson bg-crimson text-white"
                  : "border-line text-ink-muted hover:border-crimson hover:text-crimson",
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
                className="h-56 animate-pulse border border-line bg-elevated"
              />
            ))}
          </div>
        )}

        {error && !loading && (
          <p className="border border-crimson/40 bg-crimson/10 px-4 py-3 text-sm text-crimson-bright">
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
      </div>
    </section>
  );
}
