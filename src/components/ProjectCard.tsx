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

  useEffect(() => {
    setMounted(true);
  }, []);

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
  const glare = useMotionTemplate`radial-gradient(circle at ${glareX}% ${glareY}%, rgba(99,102,241,0.16), transparent 55%)`;

  const onMove = (e: React.PointerEvent) => {
    const el = ref.current;
    if (!el) return;
    const rect = el.getBoundingClientRect();
    mx.set((e.clientX - rect.left) / rect.width);
    my.set((e.clientY - rect.top) / rect.height);
  };

  const onLeave = () => {
    mx.set(0.5);
    my.set(0.5);
  };

  const dialog =
    open && mounted
      ? createPortal(
          <div
            role="dialog"
            aria-modal="true"
            aria-label={`${project.title} details`}
            className="fixed inset-0 z-[90] flex items-end justify-center bg-slate-900/40 p-4 backdrop-blur-sm sm:items-center"
            onClick={() => setOpen(false)}
          >
            <motion.div
              initial={{ opacity: 0, y: 24, scale: 0.98 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              className="relative max-h-[85vh] w-full max-w-lg overflow-y-auto rounded-3xl border border-line bg-surface-elevated p-6 shadow-[0_30px_80px_-28px_rgba(15,23,42,0.45)]"
              onClick={(e) => e.stopPropagation()}
            >
              <button
                type="button"
                aria-label="Close"
                onClick={() => setOpen(false)}
                className="absolute top-4 right-4 text-ink-muted hover:text-accent"
              >
                <X size={18} />
              </button>
              <p className="font-mono text-[10px] tracking-[0.2em] text-accent uppercase">
                {project.category}
              </p>
              <h3 className="mt-2 font-display text-2xl text-ink">
                {project.title}
              </h3>
              <p className="mt-3 text-sm leading-relaxed text-ink-muted">
                {project.longDescription}
              </p>
              <div className="mt-5 grid grid-cols-3 gap-2">
                {project.metrics.map((m) => (
                  <div
                    key={m.label}
                    className="rounded-2xl border border-line bg-slate-50 px-2 py-3 text-center"
                  >
                    <p className="font-display text-lg text-accent">{m.value}</p>
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
                    className="rounded-full border border-accent/20 bg-accent-soft px-2.5 py-1 font-mono text-[11px] text-accent-deep"
                  >
                    {tag}
                  </span>
                ))}
              </div>
              <div className="mt-6 flex gap-2">
                <a
                  href={project.liveUrl}
                  {...(project.liveUrl.startsWith("http")
                    ? { target: "_blank", rel: "noopener noreferrer" }
                    : {})}
                  className="inline-flex flex-1 items-center justify-center gap-2 rounded-full bg-accent py-2.5 text-sm font-semibold text-white"
                >
                  <ExternalLink size={14} /> Live demo
                </a>
                <a
                  href={project.githubUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex flex-1 items-center justify-center gap-2 rounded-full border border-line bg-white py-2.5 text-sm font-semibold text-ink"
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
        style={{
          rotateX,
          rotateY,
          transformStyle: "preserve-3d",
        }}
        onPointerMove={onMove}
        onPointerLeave={onLeave}
        data-cursor="interactive"
        className="group relative rounded-3xl border border-line bg-surface-elevated p-5 shadow-[0_14px_40px_-28px_rgba(15,23,42,0.35)] transition hover:border-accent/35 hover:shadow-[0_24px_50px_-24px_rgba(99,102,241,0.4)] sm:p-6"
      >
        <motion.div
          aria-hidden
          className="pointer-events-none absolute inset-0 rounded-3xl opacity-0 transition group-hover:opacity-100"
          style={{ background: glare }}
        />

        <div className="relative" style={{ transform: "translateZ(24px)" }}>
          <div className="mb-3 flex items-center justify-between gap-3">
            <span className="font-mono text-[10px] tracking-[0.2em] text-accent uppercase">
              {project.category}
            </span>
            {project.featured && (
              <span className="rounded-full bg-accent-soft px-2.5 py-0.5 font-mono text-[10px] font-medium text-accent-deep">
                Featured
              </span>
            )}
          </div>

          <h3 className="font-display text-xl text-ink sm:text-2xl">
            {project.title}
          </h3>
          <p className="mt-2 text-sm leading-relaxed text-ink-muted">
            {project.description}
          </p>

          <div className="mt-4 flex flex-wrap gap-1.5">
            {project.stack.slice(0, 4).map((tag) => (
              <span
                key={tag}
                className="rounded-full border border-line bg-slate-50 px-2.5 py-0.5 font-mono text-[10px] text-slate-600"
              >
                {tag}
              </span>
            ))}
          </div>

          <div className="mt-5 flex flex-wrap items-center gap-2">
            <button
              type="button"
              onClick={() => setOpen(true)}
              className="rounded-full bg-accent px-3.5 py-1.5 text-xs font-semibold text-white transition hover:bg-accent-deep"
            >
              Details
            </button>
            <a
              href={project.liveUrl}
              {...(project.liveUrl.startsWith("http")
                ? { target: "_blank", rel: "noopener noreferrer" }
                : {})}
              className="inline-flex items-center gap-1.5 rounded-full border border-line px-3 py-1.5 text-xs font-medium text-ink-muted transition hover:border-accent/40 hover:text-accent"
            >
              <ExternalLink size={12} /> Live
            </a>
            <a
              href={project.githubUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-1.5 rounded-full border border-line px-3 py-1.5 text-xs font-medium text-ink-muted transition hover:border-accent/40 hover:text-accent"
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
