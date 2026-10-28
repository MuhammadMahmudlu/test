"use client";

import { motion, useMotionTemplate, useMotionValue } from "framer-motion";
import { ArrowDown, Sparkles } from "lucide-react";
import { useCallback } from "react";
import { profile } from "@/data/portfolio";
import NeonScene from "./NeonScene";
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

  const spotlight = useMotionTemplate`radial-gradient(520px circle at ${mouseX}px ${mouseY}px, rgba(0,240,255,0.14), transparent 55%)`;

  return (
    <section
      id="top"
      onMouseMove={onMove}
      className="relative flex min-h-[100svh] items-center overflow-hidden pt-20 pb-16"
    >
      <motion.div
        aria-hidden
        className="pointer-events-none absolute inset-0 z-[1]"
        style={{ background: spotlight }}
      />

      <div
        aria-hidden
        className="pointer-events-none absolute -top-24 left-1/2 z-[1] h-72 w-[70%] -translate-x-1/2 bg-[radial-gradient(ellipse_at_center,rgba(138,43,226,0.22),transparent_70%)] blur-2xl"
      />

      <div className="relative z-10 mx-auto grid w-full max-w-6xl items-center gap-10 px-4 sm:px-6 lg:grid-cols-[1.15fr_0.85fr] lg:gap-8 lg:px-8">
        <div>
          <motion.p
            initial={{ opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
            className="mb-4 inline-flex items-center gap-2 font-mono text-xs tracking-[0.22em] text-cyan uppercase"
          >
            <Sparkles size={14} className="text-neon-purple" />
            {profile.title}
          </motion.p>

          <motion.h1
            initial={{ opacity: 0, y: 28 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.65, delay: 0.08 }}
            className="font-display text-[clamp(2.6rem,8vw,5.2rem)] leading-[0.95] font-bold tracking-tight text-white"
          >
            {profile.name.split(" ")[0]}
            <br />
            <span className="bg-gradient-to-r from-cyan via-white to-neon-purple bg-clip-text text-transparent">
              {profile.name.split(" ").slice(1).join(" ")}
            </span>
          </motion.h1>

          <motion.p
            initial={{ opacity: 0, y: 18 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.55, delay: 0.18 }}
            className="mt-5 max-w-lg text-base leading-relaxed text-zinc-400 sm:text-lg"
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
              className="group relative inline-flex items-center gap-2 overflow-hidden rounded-md bg-cyan px-5 py-3 font-mono text-sm font-semibold tracking-wide text-void transition hover:shadow-[0_0_28px_rgba(0,240,255,0.45)]"
            >
              View projects
              <ArrowDown
                size={16}
                className="transition group-hover:translate-y-0.5"
              />
            </a>
            <a
              href="#contact"
              className="inline-flex items-center rounded-md border border-neon-purple/50 bg-neon-purple/10 px-5 py-3 font-mono text-sm tracking-wide text-white transition hover:border-neon-purple hover:bg-neon-purple/20 hover:shadow-[0_0_24px_rgba(138,43,226,0.35)]"
            >
              Contact
            </a>
          </motion.div>

          <div className="mt-10">
            <TerminalIntro />
          </div>
        </div>

        <motion.div
          initial={{ opacity: 0, scale: 0.92 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 0.8, delay: 0.25 }}
          className="relative mx-auto flex w-full justify-center"
        >
          <div
            aria-hidden
            className="absolute inset-8 rounded-full bg-[radial-gradient(circle,rgba(0,240,255,0.18),transparent_65%)] blur-xl"
          />
          <NeonScene />
        </motion.div>
      </div>
    </section>
  );
}
