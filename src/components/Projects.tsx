"use client";

import { useMemo, useState } from "react";
import { AnimatePresence, motion } from "framer-motion";
import {
  projects,
  type ProjectCategory,
} from "@/data/portfolio";
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

  const filtered = useMemo(
    () =>
      active === "All"
        ? projects
        : projects.filter((p) => p.category === active),
    [active],
  );

  return (
    <section id="projects" className="relative scroll-mt-20 py-24 sm:py-28">
      <div className="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8">
        <SectionHeading
          eyebrow="02 — Projects"
          title="Selected builds"
          description="Interactive case studies with live demos, repos, and stack depth — tilt a card to feel the voltage."
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
                "rounded-md border px-3 py-1.5 font-mono text-xs tracking-wide transition",
                active === f
                  ? "border-cyan/50 bg-cyan/15 text-cyan shadow-[0_0_18px_rgba(0,240,255,0.2)]"
                  : "border-white/10 text-zinc-400 hover:border-cyan/30 hover:text-cyan",
              )}
            >
              {f}
            </button>
          ))}
        </div>

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
      </div>
    </section>
  );
}
