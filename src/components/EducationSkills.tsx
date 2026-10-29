"use client";

import { motion } from "framer-motion";
import { education, skillGroups } from "@/data/portfolio";
import SectionHeading from "./SectionHeading";

export default function EducationSkills() {
  return (
    <section id="skills" className="relative scroll-mt-20 py-24 sm:py-28">
      <div
        aria-hidden
        className="pointer-events-none absolute inset-y-0 left-0 w-1/2 bg-[radial-gradient(ellipse_at_left,rgba(220,38,38,0.08),transparent_60%)]"
      />
      <div className="relative z-10 mx-auto max-w-6xl px-4 sm:px-6 lg:px-8">
        <SectionHeading
          eyebrow="02 — Foundation"
          title="Education & Skills"
          description="Structural grid of learning and full-stack capability — sharp tools, deliberate depth."
        />

        <div className="mb-14 grid gap-4 md:grid-cols-2">
          {education.map((ed, i) => (
            <motion.article
              key={ed.school}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-40px" }}
              transition={{ delay: i * 0.08 }}
              className="border border-line bg-charcoal p-5 sm:p-6"
            >
              <p className="font-mono text-[10px] tracking-[0.2em] text-crimson uppercase">
                {ed.period}
              </p>
              <h3 className="mt-2 font-display text-3xl text-ink">{ed.degree}</h3>
              <p className="mt-1 text-sm font-semibold text-ink-muted">{ed.school}</p>
              <p className="mt-3 text-sm leading-relaxed text-ink-muted">
                {ed.detail}
              </p>
            </motion.article>
          ))}
        </div>

        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {skillGroups.map((group, i) => (
            <motion.div
              key={group.title}
              initial={{ opacity: 0, y: 18 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-40px" }}
              transition={{ delay: i * 0.06 }}
              data-cursor="interactive"
              className="border border-line bg-elevated p-5 transition hover:border-crimson/50"
            >
              <h3 className="font-display text-2xl text-crimson">{group.title}</h3>
              <ul className="mt-4 space-y-2">
                {group.items.map((item) => (
                  <li
                    key={item}
                    className="flex items-center gap-2 border-t border-line pt-2 text-sm text-ink"
                  >
                    <span className="h-1 w-1 bg-crimson" />
                    {item}
                  </li>
                ))}
              </ul>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}
