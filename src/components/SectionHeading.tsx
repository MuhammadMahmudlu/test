"use client";

import { motion } from "framer-motion";

type Props = {
  eyebrow: string;
  title: string;
  description?: string;
};

export default function SectionHeading({ eyebrow, title, description }: Props) {
  return (
    <div className="mb-12 max-w-3xl">
      <motion.p
        initial={{ opacity: 0, y: 12 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true, margin: "-80px" }}
        className="mb-3 font-mono text-xs tracking-[0.3em] text-crimson uppercase"
      >
        {eyebrow}
      </motion.p>
      <motion.h2
        initial={{ opacity: 0, y: 18 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true, margin: "-80px" }}
        className="font-display text-5xl leading-[0.9] text-ink sm:text-6xl md:text-7xl"
      >
        {title}
        <span className="text-crimson">.</span>
      </motion.h2>
      {description && (
        <motion.p
          initial={{ opacity: 0, y: 14 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-80px" }}
          transition={{ delay: 0.08 }}
          className="mt-4 max-w-xl text-base leading-relaxed text-ink-muted sm:text-lg"
        >
          {description}
        </motion.p>
      )}
    </div>
  );
}
