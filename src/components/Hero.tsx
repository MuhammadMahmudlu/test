"use client";

import { motion } from "framer-motion";
import { ArrowDown } from "lucide-react";
import { profile } from "@/data/portfolio";

export default function Hero() {
  return (
    <section
      id="top"
      className="relative flex min-h-[100svh] items-end overflow-hidden pt-24 pb-12 sm:items-center sm:pb-16"
    >
      {/* Massive editorial background type */}
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 z-0 flex items-center justify-center overflow-hidden"
      >
        <motion.p
          initial={{ opacity: 0, scale: 1.04 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 1.1 }}
          className="font-display editorial-outline select-none text-[clamp(4.5rem,22vw,18rem)] leading-[0.8] tracking-tight whitespace-nowrap"
        >
          MUHAMMAD
          <br />
          ELSHAN
        </motion.p>
      </div>

      <div
        aria-hidden
        className="pointer-events-none absolute top-1/3 right-0 h-[50%] w-[45%] bg-[radial-gradient(ellipse_at_center,rgba(220,38,38,0.22),transparent_70%)] blur-2xl"
      />

      <div className="relative z-10 mx-auto grid w-full max-w-6xl gap-10 px-4 sm:px-6 lg:grid-cols-[1.2fr_0.8fr] lg:items-end lg:gap-8 lg:px-8">
        <div>
          <motion.p
            initial={{ opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            className="mb-4 font-mono text-[11px] tracking-[0.28em] text-crimson uppercase"
          >
            {profile.title}
          </motion.p>

          <motion.h1
            initial={{ opacity: 0, y: 28 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.08, duration: 0.65 }}
            className="font-display text-[clamp(3.2rem,10vw,6.5rem)] leading-[0.88] text-ink"
          >
            Muhammad
            <br />
            <span className="text-crimson">Elshan</span>
          </motion.h1>

          <motion.p
            initial={{ opacity: 0, y: 18 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.18 }}
            className="mt-5 max-w-md text-base leading-relaxed text-ink-muted sm:text-lg"
          >
            {profile.tagline}
          </motion.p>

          <motion.div
            initial={{ opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.28 }}
            className="mt-8 flex flex-wrap gap-3"
          >
            <a
              href="#projects"
              className="group inline-flex items-center gap-2 bg-crimson px-5 py-3 text-sm font-bold tracking-wide text-white uppercase transition hover:bg-crimson-bright"
            >
              View work
              <ArrowDown size={16} className="transition group-hover:translate-y-0.5" />
            </a>
            <a
              href="#contact"
              className="inline-flex items-center border border-line px-5 py-3 text-sm font-bold tracking-wide text-ink uppercase transition hover:border-crimson hover:text-crimson"
            >
              Contact
            </a>
          </motion.div>
        </div>

        <motion.aside
          initial={{ opacity: 0, x: 24 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.25 }}
          className="relative border border-line bg-charcoal/80 p-5 backdrop-blur-sm sm:p-6"
        >
          {/* Portrait cutout placeholder framed by type */}
          <div className="relative mb-6 overflow-hidden border border-line bg-elevated">
            <div className="aspect-[4/5] w-full bg-[linear-gradient(160deg,#141414_0%,#0a0a0a_45%,#1a0505_100%)]">
              <div className="absolute inset-0 flex items-end justify-center">
                <div className="relative h-[88%] w-[70%]">
                  <div className="absolute inset-x-[18%] top-[8%] h-[28%] rounded-full bg-gradient-to-b from-neutral-500 to-neutral-700" />
                  <div className="absolute inset-x-[8%] top-[32%] h-[70%] rounded-t-[42%] bg-gradient-to-b from-neutral-600 via-neutral-800 to-[#1a0808]" />
                  <div className="absolute inset-0 bg-[linear-gradient(to_top,rgba(5,5,5,0.85),transparent_45%)]" />
                </div>
              </div>
              <p className="absolute bottom-3 left-3 font-mono text-[10px] tracking-[0.2em] text-crimson uppercase">
                Portrait · Placeholder
              </p>
            </div>
          </div>

          <ul className="grid grid-cols-2 gap-4">
            {profile.stats.map((stat, i) => (
              <motion.li
                key={stat.label}
                initial={{ opacity: 0, y: 12 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.35 + i * 0.06 }}
                className="border-t border-line pt-3"
              >
                <p className="font-display text-3xl text-crimson sm:text-4xl">
                  {stat.value}
                </p>
                <p className="mt-1 font-mono text-[10px] tracking-[0.16em] text-ink-muted uppercase">
                  {stat.label}
                </p>
              </motion.li>
            ))}
          </ul>
        </motion.aside>
      </div>
    </section>
  );
}
