"use client";

import { motion } from "framer-motion";
import { skills } from "@/data/portfolio";
import SectionHeading from "./SectionHeading";

export default function Skills() {
  return (
    <section id="skills" className="relative scroll-mt-20 py-24 sm:py-28">
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_at_center,rgba(99,102,241,0.06),transparent_55%)]"
      />
      <div className="relative z-10 mx-auto max-w-6xl px-4 sm:px-6 lg:px-8">
        <SectionHeading
          eyebrow="03 — Skills"
          title="Technologies I ship with"
          description="Animated proficiency badges across languages, frameworks, and infrastructure."
        />

        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {skills.map((skill, i) => (
            <motion.div
              key={skill.name}
              initial={{ opacity: 0, y: 16 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-40px" }}
              transition={{ delay: i * 0.03 }}
              whileHover={{ y: -3, scale: 1.01 }}
              data-cursor="interactive"
              className="rounded-2xl border border-line bg-surface-elevated p-4 shadow-[0_12px_36px_-28px_rgba(15,23,42,0.4)] transition hover:border-accent/30 hover:shadow-[0_18px_40px_-24px_rgba(99,102,241,0.35)]"
            >
              <div className="mb-3 flex items-center justify-between gap-3">
                <div>
                  <p className="font-display text-base font-semibold text-ink">
                    {skill.name}
                  </p>
                  <p className="font-mono text-[10px] tracking-wider text-ink-muted uppercase">
                    {skill.category}
                  </p>
                </div>
                <span className="rounded-full bg-accent-soft px-2.5 py-1 font-mono text-xs font-semibold text-accent-deep">
                  {skill.level}%
                </span>
              </div>
              <div className="h-2 overflow-hidden rounded-full bg-slate-100">
                <motion.div
                  initial={{ width: 0 }}
                  whileInView={{ width: `${skill.level}%` }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.85, ease: "easeOut" }}
                  className="h-full rounded-full bg-gradient-to-r from-accent to-violet-500"
                />
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}
