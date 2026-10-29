"use client";

import { useMemo, useState } from "react";
import { Check, Copy, RefreshCw } from "lucide-react";

function hslToHex(h: number, s: number, l: number) {
  s /= 100;
  l /= 100;
  const k = (n: number) => (n + h / 30) % 12;
  const a = s * Math.min(l, 1 - l);
  const f = (n: number) =>
    l - a * Math.max(-1, Math.min(k(n) - 3, Math.min(9 - k(n), 1)));
  const toHex = (x: number) =>
    Math.round(x * 255)
      .toString(16)
      .padStart(2, "0");
  return `#${toHex(f(0))}${toHex(f(8))}${toHex(f(4))}`;
}

const STOPS = [
  { name: "50", l: 96, s: 90 },
  { name: "100", l: 90, s: 85 },
  { name: "200", l: 80, s: 78 },
  { name: "400", l: 65, s: 72 },
  { name: "500", l: 55, s: 70 },
  { name: "700", l: 40, s: 65 },
  { name: "900", l: 22, s: 55 },
];

export default function PaletteApp() {
  const [hue, setHue] = useState(0);
  const [copied, setCopied] = useState<string | null>(null);

  const swatches = useMemo(
    () => STOPS.map((stop) => ({ ...stop, hex: hslToHex(hue, stop.s, stop.l) })),
    [hue],
  );

  const cssVars = swatches
    .map((s) => `  --brand-${s.name}: ${s.hex};`)
    .join("\n");

  const copy = async (text: string, key: string) => {
    try {
      await navigator.clipboard.writeText(text);
      setCopied(key);
      window.setTimeout(() => setCopied(null), 1400);
    } catch {
      /* ignore */
    }
  };

  return (
    <div className="space-y-5">
      <div className="border border-line bg-charcoal p-5 sm:p-6">
        <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
          <label className="flex flex-1 flex-col gap-2 text-sm font-medium text-ink">
            Base hue · {hue}°
            <input
              type="range"
              min={0}
              max={360}
              value={hue}
              onChange={(e) => setHue(Number(e.target.value))}
              className="w-full accent-crimson"
            />
          </label>
          <button
            type="button"
            onClick={() => setHue(Math.floor(Math.random() * 360))}
            className="inline-flex items-center gap-2 border border-line px-3 py-2 text-xs font-bold text-ink-muted uppercase hover:border-crimson hover:text-crimson"
          >
            <RefreshCw size={14} /> Random
          </button>
        </div>

        <div className="grid grid-cols-2 gap-3 sm:grid-cols-4 lg:grid-cols-7">
          {swatches.map((s) => (
            <button
              key={s.name}
              type="button"
              onClick={() => copy(s.hex, s.hex)}
              className="group overflow-hidden border border-line text-left transition hover:-translate-y-0.5"
            >
              <div className="h-16" style={{ background: s.hex }} />
              <div className="bg-elevated px-2.5 py-2">
                <p className="font-mono text-[10px] text-ink-muted">{s.name}</p>
                <p className="font-mono text-xs font-semibold text-ink">
                  {copied === s.hex ? "Copied" : s.hex}
                </p>
              </div>
            </button>
          ))}
        </div>
      </div>

      <div className="border border-line bg-void p-4">
        <div className="mb-2 flex items-center justify-between">
          <p className="font-mono text-[10px] tracking-wider text-ink-muted uppercase">
            CSS variables
          </p>
          <button
            type="button"
            onClick={() => copy(`:root {\n${cssVars}\n}`, "css")}
            className="inline-flex items-center gap-1.5 border border-line px-2.5 py-1 text-[11px] font-bold text-ink uppercase hover:border-crimson hover:text-crimson"
          >
            {copied === "css" ? <Check size={12} /> : <Copy size={12} />}
            {copied === "css" ? "Copied" : "Copy"}
          </button>
        </div>
        <pre className="overflow-x-auto font-mono text-xs leading-relaxed text-crimson-bright">
          {`:root {\n${cssVars}\n}`}
        </pre>
      </div>
    </div>
  );
}
