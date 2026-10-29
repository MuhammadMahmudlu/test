"use client";

import { useEffect, useState } from "react";
import { motion } from "framer-motion";

const LINES = [
  { prefix: "$", text: "whoami" },
  { prefix: ">", text: "Muhammad Elshan — Full-Stack Developer" },
  { prefix: "$", text: "cat ./stack.json" },
  {
    prefix: ">",
    text: '{ "frontend": "Next.js", "backend": "Node", "craft": "high" }',
  },
  { prefix: "$", text: 'echo "Building polished products"' },
  { prefix: ">", text: "Building polished products" },
  { prefix: "$", text: "ready --hire" },
  { prefix: ">", text: "Status: ONLINE  ●" },
];

export default function TerminalIntro() {
  const [lineIdx, setLineIdx] = useState(0);
  const [charIdx, setCharIdx] = useState(0);
  const [done, setDone] = useState(false);

  useEffect(() => {
    if (lineIdx >= LINES.length) {
      setDone(true);
      return;
    }
    const current = LINES[lineIdx].text;
    if (charIdx <= current.length) {
      const t = window.setTimeout(
        () => setCharIdx((c) => c + 1),
        18 + Math.random() * 28,
      );
      return () => clearTimeout(t);
    }
    const t = window.setTimeout(() => {
      setLineIdx((i) => i + 1);
      setCharIdx(0);
    }, 380);
    return () => clearTimeout(t);
  }, [lineIdx, charIdx]);

  return (
    <motion.div
      initial={{ opacity: 0, y: 24 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: 0.35, duration: 0.6 }}
      className="w-full max-w-xl overflow-hidden rounded-2xl border border-line bg-surface-elevated font-mono shadow-[0_20px_50px_-24px_rgba(15,23,42,0.25)]"
      data-cursor="interactive"
    >
      <div className="flex items-center gap-2 border-b border-line bg-slate-50 px-4 py-2.5">
        <span className="h-2.5 w-2.5 rounded-full bg-[#ff5f57]" />
        <span className="h-2.5 w-2.5 rounded-full bg-[#febc2e]" />
        <span className="h-2.5 w-2.5 rounded-full bg-[#28c840]" />
        <span className="ml-3 text-[11px] tracking-wider text-ink-muted">
          elshan@portfolio — zsh
        </span>
      </div>
      <div className="space-y-1.5 p-4 text-[12px] leading-relaxed text-slate-700 sm:text-[13px]">
        {LINES.slice(0, lineIdx + 1).map((line, i) => {
          const isActive = i === lineIdx && !done;
          const shown = isActive ? line.text.slice(0, charIdx) : line.text;
          return (
            <p key={`${line.prefix}-${i}`} className="flex gap-2">
              <span
                className={
                  line.prefix === "$" ? "text-accent font-medium" : "text-slate-400"
                }
              >
                {line.prefix}
              </span>
              <span
                className={
                  line.text.includes("ONLINE") ? "text-emerald-600" : undefined
                }
              >
                {shown}
                {isActive && (
                  <span className="ml-0.5 inline-block h-3.5 w-1.5 animate-pulse bg-accent align-middle" />
                )}
              </span>
            </p>
          );
        })}
      </div>
    </motion.div>
  );
}
