"use client";

import {
  motion,
  useMotionTemplate,
  useMotionValue,
  useSpring,
  useTransform,
} from "framer-motion";
import { ExternalLink, X } from "lucide-react";
import { useRef, useState } from "react";
import type { Project } from "@/data/portfolio";
import { GitHubIcon } from "./icons";

type Props = {
  project: Project;
  index: number;
};

export default function ProjectCard({ project, index }: Props) {
  const ref = useRef<HTMLDivElement>(null);
  const [open, setOpen] = useState(false);

  const mx = useMotionValue(0.5);
  const my = useMotionValue(0.5);
  const rotateX = useSpring(useTransform(my, [0, 1], [10, -10]), {
    stiffness: 220,
    damping: 22,
  });
  const rotateY = useSpring(useTransform(mx, [0, 1], [-12, 12]), {
    stiffness: 220,
    damping: 22,
  });

  const glareX = useTransform(mx, [0, 1], [0, 100]);
  const glareY = useTransform(my, [0, 1], [0, 100]);
  const glare = useMotionTemplate`radial-gradient(circle at ${glareX}% ${glareY}%, rgba(0,240,255,0.22), transparent 55%)`;

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

  return (
    <>
      <motion.article
        ref={ref}
        initial={{ opacity: 0, y: 28 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true, margin: "-40px" }}
        transition={{ delay: Math.min(index * 0.06, 0.3) }}
        style={{
          rotateX,
          rotateY,
          transformStyle: "preserve-3d",
          perspective: 900,
        }}
        onPointerMove={onMove}
        onPointerLeave={onLeave}
        data-cursor="interactive"
        className="group relative rounded-2xl border border-white/10 bg-white/[0.03] p-[1px]"
      >
        {/* Electric border trace */}
        <div
          aria-hidden
          className="pointer-events-none absolute inset-0 rounded-2xl opacity-0 transition duration-500 group-hover:opacity-100"
          style={{
            background:
              "conic-gradient(from 180deg, transparent, #00f0ff, transparent, #8a2be2, transparent)",
            mask: "linear-gradient(#000 0 0) content-box, linear-gradient(#000 0 0)",
            maskComposite: "exclude",
            WebkitMaskComposite: "xor",
            padding: 1,
          }}
        />

        <div className="relative overflow-hidden rounded-[15px] bg-[#0c0c14] p-5 sm:p-6">
          <motion.div
            aria-hidden
            className="pointer-events-none absolute inset-0 opacity-0 transition group-hover:opacity-100"
            style={{ background: glare }}
          />

          <div className="relative" style={{ transform: "translateZ(28px)" }}>
            <div className="mb-3 flex items-center justify-between gap-3">
              <span className="font-mono text-[10px] tracking-[0.2em] text-neon-purple uppercase">
                {project.category}
              </span>
              {project.featured && (
                <span className="rounded border border-cyan/30 bg-cyan/10 px-2 py-0.5 font-mono text-[10px] text-cyan">
                  Featured
                </span>
              )}
            </div>

            <h3 className="font-display text-xl text-white sm:text-2xl">
              {project.title}
            </h3>
            <p className="mt-2 text-sm leading-relaxed text-zinc-400">
              {project.description}
            </p>

            <div className="mt-4 flex flex-wrap gap-1.5">
              {project.stack.slice(0, 4).map((tag) => (
                <span
                  key={tag}
                  className="rounded border border-white/10 bg-white/[0.04] px-2 py-0.5 font-mono text-[10px] text-zinc-300"
                >
                  {tag}
                </span>
              ))}
            </div>

            <div className="mt-5 flex flex-wrap items-center gap-2">
              <button
                type="button"
                onClick={() => setOpen(true)}
                className="rounded-md border border-cyan/35 bg-cyan/10 px-3 py-1.5 font-mono text-xs text-cyan transition hover:bg-cyan/20"
              >
                Details
              </button>
              <a
                href={project.liveUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-1.5 rounded-md border border-white/15 px-3 py-1.5 font-mono text-xs text-zinc-300 transition hover:border-cyan/40 hover:text-cyan"
              >
                <ExternalLink size={12} /> Live
              </a>
              <a
                href={project.githubUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-1.5 rounded-md border border-white/15 px-3 py-1.5 font-mono text-xs text-zinc-300 transition hover:border-neon-purple/50 hover:text-neon-purple"
              >
                <GitHubIcon size={12} /> GitHub
              </a>
            </div>
          </div>
        </div>
      </motion.article>

      {open && (
        <div
          role="dialog"
          aria-modal="true"
          aria-label={`${project.title} details`}
          className="fixed inset-0 z-[80] flex items-end justify-center bg-black/70 p-4 backdrop-blur-sm sm:items-center"
          onClick={() => setOpen(false)}
        >
          <motion.div
            initial={{ opacity: 0, y: 24, scale: 0.98 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            className="relative max-h-[85vh] w-full max-w-lg overflow-y-auto rounded-2xl border border-cyan/25 bg-[#0d0d16] p-6 shadow-[0_0_50px_rgba(0,240,255,0.12)]"
            onClick={(e) => e.stopPropagation()}
          >
            <button
              type="button"
              aria-label="Close"
              onClick={() => setOpen(false)}
              className="absolute top-4 right-4 text-zinc-400 hover:text-cyan"
            >
              <X size={18} />
            </button>
            <p className="font-mono text-[10px] tracking-[0.2em] text-neon-purple uppercase">
              {project.category}
            </p>
            <h3 className="mt-2 font-display text-2xl text-white">
              {project.title}
            </h3>
            <p className="mt-3 text-sm leading-relaxed text-zinc-400">
              {project.longDescription}
            </p>
            <div className="mt-5 grid grid-cols-3 gap-2">
              {project.metrics.map((m) => (
                <div
                  key={m.label}
                  className="rounded-lg border border-white/10 bg-white/[0.03] px-2 py-3 text-center"
                >
                  <p className="font-display text-lg text-cyan">{m.value}</p>
                  <p className="font-mono text-[10px] tracking-wide text-zinc-500 uppercase">
                    {m.label}
                  </p>
                </div>
              ))}
            </div>
            <div className="mt-5 flex flex-wrap gap-1.5">
              {project.stack.map((tag) => (
                <span
                  key={tag}
                  className="rounded border border-cyan/20 bg-cyan/5 px-2 py-1 font-mono text-[11px] text-cyan"
                >
                  {tag}
                </span>
              ))}
            </div>
            <div className="mt-6 flex gap-2">
              <a
                href={project.liveUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex flex-1 items-center justify-center gap-2 rounded-md bg-cyan py-2.5 font-mono text-sm font-semibold text-void"
              >
                <ExternalLink size={14} /> Live demo
              </a>
              <a
                href={project.githubUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex flex-1 items-center justify-center gap-2 rounded-md border border-neon-purple/40 bg-neon-purple/15 py-2.5 font-mono text-sm text-white"
              >
                <GitHubIcon size={14} /> GitHub
              </a>
            </div>
          </motion.div>
        </div>
      )}
    </>
  );
}
