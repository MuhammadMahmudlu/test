"use client";

import { motion } from "framer-motion";
import { Code2, Cpu, Layers, Zap } from "lucide-react";
import { profile } from "@/data/portfolio";
import SectionHeading from "./SectionHeading";

const pillars = [
  {
    icon: Code2,
    title: "Interface craft",
    text: "Motion-aware UIs that stay accessible and buttery at 60 FPS.",
  },
  {
    icon: Layers,
    title: "Full-stack systems",
    text: "APIs, data models, and auth flows designed for real product load.",
  },
  {
    icon: Cpu,
    title: "Performance first",
    text: "Streaming, caching, and edge patterns that keep experiences snappy.",
  },
  {
    icon: Zap,
    title: "Ship velocity",
    text: "From prototype to production with clean CI and observable services.",
  },
];

export default function About() {
  return (
    <section id="about" className="relative scroll-mt-20 py-24 sm:py-28">
      <div className="relative z-10 mx-auto max-w-6xl px-4 sm:px-6 lg:px-8">
        <SectionHeading
          eyebrow="01 — About"
          title="Engineer with product taste"
          description="I turn complex product ideas into cohesive, high-signal experiences — code that feels intentional under the cursor."
        />

        <div className="grid gap-10 lg:grid-cols-[1.1fr_0.9fr]">
          <div className="space-y-5 text-base leading-relaxed text-slate-600 sm:text-lg">
            {profile.about.map((para, i) => (
              <motion.p
                key={i}
                initial={{ opacity: 0, y: 16 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, margin: "-60px" }}
                transition={{ delay: i * 0.08 }}
              >
                {para}
              </motion.p>
            ))}
            <motion.p
              initial={{ opacity: 0 }}
              whileInView={{ opacity: 1 }}
              viewport={{ once: true }}
              className="font-mono text-sm text-accent"
            >
              Based in {profile.location} · Open to remote collaborations
            </motion.p>
          </div>

          <div className="grid gap-4 sm:grid-cols-2">
            {pillars.map((item, i) => (
              <motion.div
                key={item.title}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, margin: "-40px" }}
                transition={{ delay: 0.05 * i }}
                whileHover={{ y: -4 }}
                data-cursor="interactive"
                className="rounded-2xl border border-line bg-surface-elevated p-5 shadow-[0_12px_40px_-28px_rgba(15,23,42,0.35)] transition hover:border-accent/30 hover:shadow-[0_18px_44px_-24px_rgba(99,102,241,0.35)]"
              >
                <item.icon className="mb-3 text-accent" size={22} />
                <h3 className="mb-1.5 font-display text-lg text-ink">
                  {item.title}
                </h3>
                <p className="text-sm leading-relaxed text-ink-muted">
                  {item.text}
                </p>
              </motion.div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
