"use client";

import {
  motion,
  useMotionTemplate,
  useMotionValue,
  useSpring,
  useTransform,
} from "framer-motion";
import { ExternalLink, X } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { createPortal } from "react-dom";
import type { Project } from "@/data/portfolio";
import { GitHubIcon } from "./icons";

type Props = {
  project: Project;
  index: number;
};

export default function ProjectCard({ project, index }: Props) {
  const ref = useRef<HTMLDivElement>(null);
  const [open, setOpen] = useState(false);
  const [mounted, setMounted] = useState(false);

  useEffect(() => setMounted(true), []);

  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") setOpen(false);
    };
    document.addEventListener("keydown", onKey);
    const prev = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      document.removeEventListener("keydown", onKey);
      document.body.style.overflow = prev;
    };
  }, [open]);

  const mx = useMotionValue(0.5);
  const my = useMotionValue(0.5);
  const rotateX = useSpring(useTransform(my, [0, 1], [8, -8]), {
    stiffness: 220,
    damping: 22,
  });
  const rotateY = useSpring(useTransform(mx, [0, 1], [-10, 10]), {
    stiffness: 220,
    damping: 22,
  });
  const glareX = useTransform(mx, [0, 1], [0, 100]);
  const glareY = useTransform(my, [0, 1], [0, 100]);
  const glare = useMotionTemplate`radial-gradient(circle at ${glareX}% ${glareY}%, rgba(239,68,68,0.18), transparent 55%)`;

  const onMove = (e: React.PointerEvent) => {
    const el = ref.current;
    if (!el) return;
    const rect = el.getBoundingClientRect();
    mx.set((e.clientX - rect.left) / rect.width);
    my.set((e.clientY - rect.top) / rect.height);
  };

  const external = project.liveUrl.startsWith("http");

  const dialog =
    open && mounted
      ? createPortal(
          <div
            role="dialog"
            aria-modal="true"
            aria-label={`${project.title} details`}
            className="fixed inset-0 z-[90] flex items-end justify-center bg-black/75 p-4 backdrop-blur-sm sm:items-center"
            onClick={() => setOpen(false)}
          >
            <motion.div
              initial={{ opacity: 0, y: 24, scale: 0.98 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              className="relative max-h-[85vh] w-full max-w-lg overflow-y-auto border border-line bg-charcoal p-6 shadow-[0_0_60px_rgba(220,38,38,0.15)]"
              onClick={(e) => e.stopPropagation()}
            >
              <button
                type="button"
                aria-label="Close"
                onClick={() => setOpen(false)}
                className="absolute top-4 right-4 text-ink-muted hover:text-crimson"
              >
                <X size={18} />
              </button>
              <p className="font-mono text-[10px] tracking-[0.22em] text-crimson uppercase">
                {project.category}
              </p>
              <h3 className="mt-2 font-display text-4xl text-ink">{project.title}</h3>
              <p className="mt-3 text-sm leading-relaxed text-ink-muted">
                {project.longDescription}
              </p>
              <div className="mt-5 grid grid-cols-3 gap-2">
                {project.metrics.map((m) => (
                  <div
                    key={m.label}
                    className="border border-line bg-elevated px-2 py-3 text-center"
                  >
                    <p className="font-display text-2xl text-crimson">{m.value}</p>
                    <p className="font-mono text-[10px] tracking-wide text-ink-muted uppercase">
                      {m.label}
                    </p>
                  </div>
                ))}
              </div>
              <div className="mt-5 flex flex-wrap gap-1.5">
                {project.stack.map((tag) => (
                  <span
                    key={tag}
                    className="border border-crimson/30 bg-crimson/10 px-2.5 py-1 font-mono text-[11px] text-crimson-bright"
                  >
                    {tag}
                  </span>
                ))}
              </div>
              <div className="mt-6 flex gap-2">
                <a
                  href={project.liveUrl}
                  {...(external
                    ? { target: "_blank", rel: "noopener noreferrer" }
                    : {})}
                  className="inline-flex flex-1 items-center justify-center gap-2 bg-crimson py-2.5 text-sm font-bold text-white uppercase"
                >
                  <ExternalLink size={14} /> Live
                </a>
                <a
                  href={project.githubUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex flex-1 items-center justify-center gap-2 border border-line py-2.5 text-sm font-bold text-ink uppercase"
                >
                  <GitHubIcon size={14} /> GitHub
                </a>
              </div>
            </motion.div>
          </div>,
          document.body,
        )
      : null;

  return (
    <>
      <motion.article
        ref={ref}
        initial={{ opacity: 0, y: 28 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true, margin: "-40px" }}
        transition={{ delay: Math.min(index * 0.06, 0.3) }}
        whileHover={{ y: -6 }}
        style={{ rotateX, rotateY, transformStyle: "preserve-3d" }}
        onPointerMove={onMove}
        onPointerLeave={() => {
          mx.set(0.5);
          my.set(0.5);
        }}
        data-cursor="interactive"
        className="group relative border border-line bg-charcoal p-5 transition hover:border-crimson/60 hover:shadow-[0_0_40px_rgba(220,38,38,0.18)] sm:p-6"
      >
        <motion.div
          aria-hidden
          className="pointer-events-none absolute inset-0 opacity-0 transition group-hover:opacity-100"
          style={{ background: glare }}
        />
        <div className="relative" style={{ transform: "translateZ(24px)" }}>
          <div className="mb-3 flex items-center justify-between gap-3">
            <span className="font-mono text-[10px] tracking-[0.22em] text-crimson uppercase">
              {project.category}
            </span>
            {project.featured && (
              <span className="border border-crimson/40 bg-crimson/15 px-2 py-0.5 font-mono text-[10px] text-crimson-bright">
                Featured
              </span>
            )}
          </div>
          <h3 className="font-display text-3xl text-ink sm:text-4xl">
            {project.title}
          </h3>
          <p className="mt-2 text-sm leading-relaxed text-ink-muted">
            {project.description}
          </p>
          <div className="mt-4 flex flex-wrap gap-1.5">
            {project.stack.slice(0, 4).map((tag) => (
              <span
                key={tag}
                className="border border-line bg-elevated px-2 py-0.5 font-mono text-[10px] text-ink-muted"
              >
                {tag}
              </span>
            ))}
          </div>
          <div className="mt-5 flex flex-wrap gap-2">
            <button
              type="button"
              onClick={() => setOpen(true)}
              className="bg-crimson px-3.5 py-1.5 text-xs font-bold tracking-wide text-white uppercase hover:bg-crimson-bright"
            >
              Details
            </button>
            <a
              href={project.liveUrl}
              {...(external
                ? { target: "_blank", rel: "noopener noreferrer" }
                : {})}
              className="inline-flex items-center gap-1.5 border border-line px-3 py-1.5 text-xs font-semibold text-ink-muted uppercase hover:border-crimson hover:text-crimson"
            >
              <ExternalLink size={12} /> Live
            </a>
            <a
              href={project.githubUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-1.5 border border-line px-3 py-1.5 text-xs font-semibold text-ink-muted uppercase hover:border-crimson hover:text-crimson"
            >
              <GitHubIcon size={12} /> GitHub
            </a>
          </div>
        </div>
      </motion.article>
      {dialog}
    </>
  );
}
