"use client";

import { motion } from "framer-motion";
import { useState } from "react";
import { skillEdges, skillGraph, skills } from "@/data/portfolio";
import { cn } from "@/lib/utils";
import SectionHeading from "./SectionHeading";

export default function Skills() {
  const [mode, setMode] = useState<"graph" | "bars">("graph");
  const [active, setActive] = useState<string | null>(null);

  const nodesById = Object.fromEntries(skillGraph.map((n) => [n.id, n]));

  return (
    <section id="skills" className="relative scroll-mt-20 py-24 sm:py-28">
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_at_center,rgba(138,43,226,0.08),transparent_55%)]"
      />
      <div className="relative z-10 mx-auto max-w-6xl px-4 sm:px-6 lg:px-8">
        <div className="mb-8 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
          <SectionHeading
            eyebrow="03 — Skills"
            title="Tech constellation"
            description="An interactive map of languages, frameworks, and infrastructure I ship with daily."
          />
          <div className="mb-12 flex gap-2 self-start sm:self-auto">
            {(["graph", "bars"] as const).map((m) => (
              <button
                key={m}
                type="button"
                onClick={() => setMode(m)}
                className={cn(
                  "rounded-md border px-3 py-1.5 font-mono text-xs capitalize transition",
                  mode === m
                    ? "border-cyan/50 bg-cyan/15 text-cyan"
                    : "border-white/10 text-zinc-400 hover:text-cyan",
                )}
              >
                {m}
              </button>
            ))}
          </div>
        </div>

        {mode === "graph" ? (
          <motion.div
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 1 }}
            viewport={{ once: true }}
            className="relative mx-auto aspect-[16/11] w-full max-w-3xl overflow-hidden rounded-2xl border border-white/10 bg-[#0b0b14]/80"
          >
            <svg
              viewBox="0 0 100 100"
              className="absolute inset-0 h-full w-full"
              aria-hidden
            >
              {skillEdges.map(([a, b]) => {
                const na = nodesById[a];
                const nb = nodesById[b];
                if (!na || !nb) return null;
                const lit = active === a || active === b;
                return (
                  <line
                    key={`${a}-${b}`}
                    x1={na.x}
                    y1={na.y}
                    x2={nb.x}
                    y2={nb.y}
                    stroke={lit ? "#00f0ff" : "rgba(138,43,226,0.35)"}
                    strokeWidth={lit ? 0.45 : 0.25}
                  />
                );
              })}
            </svg>

            {skillGraph.map((node, i) => (
              <motion.button
                key={node.id}
                type="button"
                data-cursor="interactive"
                initial={{ opacity: 0, scale: 0.6 }}
                whileInView={{ opacity: 1, scale: 1 }}
                viewport={{ once: true }}
                animate={{
                  y: [0, i % 2 === 0 ? -4 : 4, 0],
                }}
                transition={{
                  delay: i * 0.04,
                  y: {
                    duration: 3.2 + i * 0.15,
                    repeat: Infinity,
                    ease: "easeInOut",
                  },
                }}
                onMouseEnter={() => setActive(node.id)}
                onMouseLeave={() => setActive(null)}
                onFocus={() => setActive(node.id)}
                onBlur={() => setActive(null)}
                style={{ left: `${node.x}%`, top: `${node.y}%` }}
                className={cn(
                  "absolute -translate-x-1/2 -translate-y-1/2 rounded-full border px-3 py-2 font-mono text-[11px] tracking-wide transition",
                  active === node.id
                    ? "border-cyan bg-cyan/20 text-cyan shadow-[0_0_24px_rgba(0,240,255,0.45)]"
                    : "border-neon-purple/40 bg-void/90 text-zinc-200 hover:border-cyan/50 hover:text-cyan",
                )}
              >
                {node.label}
              </motion.button>
            ))}
          </motion.div>
        ) : (
          <div className="grid gap-4 sm:grid-cols-2">
            {skills.map((skill, i) => (
              <motion.div
                key={skill.name}
                initial={{ opacity: 0, x: -12 }}
                whileInView={{ opacity: 1, x: 0 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.03 }}
                className="rounded-xl border border-white/10 bg-white/[0.03] p-4"
              >
                <div className="mb-2 flex items-center justify-between gap-3">
                  <div>
                    <p className="font-display text-base text-white">
                      {skill.name}
                    </p>
                    <p className="font-mono text-[10px] tracking-wider text-zinc-500 uppercase">
                      {skill.category}
                    </p>
                  </div>
                  <span className="font-mono text-sm text-cyan">
                    {skill.level}%
                  </span>
                </div>
                <div className="h-1.5 overflow-hidden rounded-full bg-white/10">
                  <motion.div
                    initial={{ width: 0 }}
                    whileInView={{ width: `${skill.level}%` }}
                    viewport={{ once: true }}
                    transition={{ duration: 0.8, ease: "easeOut" }}
                    className="h-full rounded-full bg-gradient-to-r from-cyan to-neon-purple"
                  />
                </div>
              </motion.div>
            ))}
          </div>
        )}
      </div>
    </section>
  );
}
