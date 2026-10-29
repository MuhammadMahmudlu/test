"use client";

import { motion } from "framer-motion";
import { useState } from "react";
import { processSteps } from "@/data/portfolio";
import { cn } from "@/lib/utils";
import SectionHeading from "./SectionHeading";

export default function Process() {
  const [active, setActive] = useState(0);

  return (
    <section id="process" className="relative scroll-mt-20 py-24 sm:py-28">
      <div className="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8">
        <SectionHeading
          eyebrow="03 — Method"
          title="Work Process"
          description="An interactive workflow from discovery through deployment — click a step to focus."
        />

        <div className="mb-8 flex flex-wrap gap-2">
          {processSteps.map((step, i) => (
            <button
              key={step.id}
              type="button"
              onClick={() => setActive(i)}
              className={cn(
                "border px-3 py-2 font-mono text-[11px] tracking-[0.14em] uppercase transition",
                active === i
                  ? "border-crimson bg-crimson text-white"
                  : "border-line text-ink-muted hover:border-crimson hover:text-crimson",
              )}
            >
              {step.id} {step.title}
            </button>
          ))}
        </div>

        <div className="relative">
          <div
            aria-hidden
            className="absolute top-5 right-0 left-0 hidden h-px bg-line md:block"
          />
          <ol className="grid gap-4 md:grid-cols-5">
            {processSteps.map((step, i) => (
              <motion.li
                key={step.id}
                initial={{ opacity: 0, y: 16 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.05 }}
              >
                <button
                  type="button"
                  onClick={() => setActive(i)}
                  data-cursor="interactive"
                  className={cn(
                    "relative w-full border p-4 text-left transition md:pt-10",
                    active === i
                      ? "border-crimson bg-crimson/10 shadow-[0_0_30px_rgba(220,38,38,0.2)]"
                      : "border-line bg-charcoal hover:border-crimson/40",
                  )}
                >
                  <span
                    aria-hidden
                    className={cn(
                      "absolute -top-2 left-4 hidden h-4 w-4 rounded-full border-2 md:block",
                      active === i
                        ? "border-crimson bg-crimson"
                        : "border-line bg-void",
                    )}
                  />
                  <p className="font-display text-4xl text-crimson">{step.id}</p>
                  <h3 className="mt-1 font-display text-2xl text-ink">
                    {step.title}
                  </h3>
                  <p className="mt-2 text-xs leading-relaxed text-ink-muted sm:text-sm">
                    {step.text}
                  </p>
                </button>
              </motion.li>
            ))}
          </ol>
        </div>

        <motion.div
          key={active}
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          className="mt-8 border-l-2 border-crimson bg-elevated px-5 py-4"
        >
          <p className="font-mono text-[10px] tracking-[0.2em] text-crimson uppercase">
            Active stage
          </p>
          <p className="mt-1 font-display text-3xl text-ink">
            {processSteps[active].title}
          </p>
          <p className="mt-2 max-w-2xl text-sm text-ink-muted">
            {processSteps[active].text}
          </p>
        </motion.div>
      </div>
    </section>
  );
}
