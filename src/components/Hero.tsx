"use client";

import { motion, useMotionTemplate, useMotionValue } from "framer-motion";
import { ArrowDown, Sparkles } from "lucide-react";
import { useCallback } from "react";
import { profile } from "@/data/portfolio";
import SoftGeometry from "./SoftGeometry";
import TerminalIntro from "./TerminalIntro";

export default function Hero() {
  const mouseX = useMotionValue(0);
  const mouseY = useMotionValue(0);

  const onMove = useCallback(
    (e: React.MouseEvent<HTMLElement>) => {
      const { left, top } = e.currentTarget.getBoundingClientRect();
      mouseX.set(e.clientX - left);
      mouseY.set(e.clientY - top);
    },
    [mouseX, mouseY],
  );

  const spotlight = useMotionTemplate`radial-gradient(560px circle at ${mouseX}px ${mouseY}px, rgba(99,102,241,0.12), transparent 55%)`;

  return (
    <section
      id="top"
      onMouseMove={onMove}
      className="relative flex min-h-[100svh] items-center overflow-hidden pt-20 pb-16"
    >
      <div aria-hidden className="soft-grid pointer-events-none absolute inset-0 z-[1] opacity-70" />
      <motion.div
        aria-hidden
        className="pointer-events-none absolute inset-0 z-[1]"
        style={{ background: spotlight }}
      />
      <div
        aria-hidden
        className="pointer-events-none absolute -top-20 left-1/2 z-[1] h-80 w-[70%] -translate-x-1/2 bg-[radial-gradient(ellipse_at_center,rgba(99,102,241,0.16),transparent_70%)] blur-2xl"
      />

      <div className="relative z-10 mx-auto grid w-full max-w-6xl items-center gap-10 px-4 sm:px-6 lg:grid-cols-[1.15fr_0.85fr] lg:gap-8 lg:px-8">
        <div>
          <motion.p
            initial={{ opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
            className="mb-4 inline-flex items-center gap-2 rounded-full border border-line bg-surface-elevated/80 px-3 py-1 text-xs font-semibold tracking-wide text-accent shadow-sm"
          >
            <Sparkles size={14} />
            {profile.title}
          </motion.p>

          <motion.h1
            initial={{ opacity: 0, y: 28 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.65, delay: 0.08 }}
            className="font-display text-[clamp(2.6rem,8vw,5rem)] leading-[1.02] font-bold text-ink"
          >
            {profile.name.split(" ")[0]}
            <br />
            <span className="bg-gradient-to-r from-accent via-accent-deep to-violet-500 bg-clip-text text-transparent">
              {profile.name.split(" ").slice(1).join(" ")}
            </span>
          </motion.h1>

          <motion.p
            initial={{ opacity: 0, y: 18 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.55, delay: 0.18 }}
            className="mt-5 max-w-lg text-base leading-relaxed text-ink-muted sm:text-lg"
          >
            {profile.tagline}
          </motion.p>

          <motion.div
            initial={{ opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.28 }}
            className="mt-8 flex flex-wrap items-center gap-3"
          >
            <a
              href="#projects"
              className="group inline-flex items-center gap-2 rounded-full bg-accent px-5 py-3 text-sm font-semibold text-white shadow-[0_14px_30px_-14px_rgba(99,102,241,0.9)] transition hover:bg-accent-deep"
            >
              View projects
              <ArrowDown
                size={16}
                className="transition group-hover:translate-y-0.5"
              />
            </a>
            <a
              href="#contact"
              className="inline-flex items-center rounded-full border border-line bg-surface-elevated px-5 py-3 text-sm font-semibold text-ink shadow-sm transition hover:border-accent/40 hover:text-accent"
            >
              Contact
            </a>
          </motion.div>

          <div className="mt-10">
            <TerminalIntro />
          </div>
        </div>

        <motion.div
          initial={{ opacity: 0, scale: 0.94 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 0.8, delay: 0.25 }}
          className="relative mx-auto flex w-full justify-center"
        >
          <SoftGeometry />
        </motion.div>
      </div>
    </section>
  );
}
