"use client";

import { motion, useScroll, useTransform } from "framer-motion";
import { useRef } from "react";
import { experience } from "@/data/portfolio";
import SectionHeading from "./SectionHeading";

export default function Experience() {
  const ref = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({
    target: ref,
    offset: ["start 80%", "end 20%"],
  });
  const lineHeight = useTransform(scrollYProgress, [0, 1], ["0%", "100%"]);

  return (
    <section id="experience" className="relative scroll-mt-20 py-24 sm:py-28">
      <div className="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8">
        <SectionHeading
          eyebrow="04 — Experience"
          title="Career timeline"
          description="Roles where systems thinking, shipping speed, and interface craft collided."
        />

        <div ref={ref} className="relative ml-2 sm:ml-4">
          <div
            aria-hidden
            className="absolute top-2 left-[7px] h-[calc(100%-1rem)] w-px bg-white/10 sm:left-[11px]"
          />
          <motion.div
            aria-hidden
            style={{ height: lineHeight }}
            className="absolute top-2 left-[7px] w-px origin-top bg-gradient-to-b from-cyan via-neon-purple to-cyan shadow-[0_0_12px_rgba(0,240,255,0.6)] sm:left-[11px]"
          />

          <ol className="space-y-10">
            {experience.map((job, i) => (
              <motion.li
                key={job.id}
                initial={{ opacity: 0, x: -20 }}
                whileInView={{ opacity: 1, x: 0 }}
                viewport={{ once: true, margin: "-80px" }}
                transition={{ delay: i * 0.08 }}
                className="relative pl-10 sm:pl-14"
              >
                <span
                  aria-hidden
                  className="absolute top-1.5 left-0 flex h-4 w-4 items-center justify-center rounded-full border border-cyan bg-void shadow-[0_0_14px_rgba(0,240,255,0.55)] sm:h-6 sm:w-6"
                >
                  <span className="h-1.5 w-1.5 rounded-full bg-cyan sm:h-2 sm:w-2" />
                </span>

                <div
                  data-cursor="interactive"
                  className="rounded-2xl border border-white/10 bg-white/[0.03] p-5 transition hover:border-cyan/30 hover:shadow-[0_0_28px_rgba(0,240,255,0.08)] sm:p-6"
                >
                  <div className="flex flex-wrap items-baseline justify-between gap-2">
                    <h3 className="font-display text-xl text-white sm:text-2xl">
                      {job.role}
                    </h3>
                    <span className="font-mono text-xs text-cyan">
                      {job.period}
                    </span>
                  </div>
                  <p className="mt-1 text-sm text-neon-purple">
                    {job.company} · {job.location}
                  </p>
                  <ul className="mt-4 space-y-2">
                    {job.highlights.map((h) => (
                      <li
                        key={h}
                        className="flex gap-2 text-sm leading-relaxed text-zinc-400"
                      >
                        <span className="mt-2 h-1 w-1 shrink-0 rounded-full bg-cyan" />
                        {h}
                      </li>
                    ))}
                  </ul>
                </div>
              </motion.li>
            ))}
          </ol>
        </div>
      </div>
    </section>
  );
}
