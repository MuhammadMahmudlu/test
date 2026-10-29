"use client";

import { useMemo, useState } from "react";
import { Check, Copy, Minimize2, Sparkles } from "lucide-react";

const SAMPLE = `{
  "name": "Muhammad Elshan",
  "role": "Full-Stack Developer",
  "stack": ["Next.js", "Node", "TypeScript"]
}`;

export default function JsonLabApp() {
  const [input, setInput] = useState(SAMPLE);
  const [copied, setCopied] = useState(false);

  const result = useMemo(() => {
    try {
      const parsed = JSON.parse(input);
      return { ok: true as const, parsed, error: null };
    } catch (e) {
      return {
        ok: false as const,
        parsed: null,
        error: e instanceof Error ? e.message : "Invalid JSON",
      };
    }
  }, [input]);

  const pretty = result.ok ? JSON.stringify(result.parsed, null, 2) : "";
  const minified = result.ok ? JSON.stringify(result.parsed) : "";

  const copy = async (text: string) => {
    try {
      await navigator.clipboard.writeText(text);
      setCopied(true);
      window.setTimeout(() => setCopied(false), 1400);
    } catch {
      /* ignore */
    }
  };

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap gap-2">
        <button
          type="button"
          disabled={!result.ok}
          onClick={() => setInput(pretty)}
          className="inline-flex items-center gap-1.5 bg-crimson px-3.5 py-2 text-xs font-bold text-white uppercase disabled:opacity-40"
        >
          <Sparkles size={14} /> Prettify
        </button>
        <button
          type="button"
          disabled={!result.ok}
          onClick={() => setInput(minified)}
          className="inline-flex items-center gap-1.5 border border-line px-3.5 py-2 text-xs font-bold text-ink-muted uppercase hover:text-crimson disabled:opacity-40"
        >
          <Minimize2 size={14} /> Minify
        </button>
        <button
          type="button"
          disabled={!result.ok}
          onClick={() => copy(pretty || input)}
          className="inline-flex items-center gap-1.5 border border-line px-3.5 py-2 text-xs font-bold text-ink-muted uppercase hover:text-crimson disabled:opacity-40"
        >
          {copied ? <Check size={14} /> : <Copy size={14} />}
          {copied ? "Copied" : "Copy"}
        </button>
      </div>

      <textarea
        value={input}
        onChange={(e) => setInput(e.target.value)}
        spellCheck={false}
        rows={14}
        className="w-full border border-line bg-charcoal p-4 font-mono text-sm text-ink outline-none focus:border-crimson"
      />

      <div
        className={`border px-4 py-3 text-sm ${
          result.ok
            ? "border-emerald-800 bg-emerald-950/40 text-emerald-400"
            : "border-crimson/40 bg-crimson/10 text-crimson-bright"
        }`}
      >
        {result.ok ? "Valid JSON ✓" : `Error: ${result.error}`}
      </div>
    </div>
  );
}
