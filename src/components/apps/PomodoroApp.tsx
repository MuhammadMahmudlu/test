"use client";

import { useCallback, useEffect, useState } from "react";
import { Pause, Play, RotateCcw } from "lucide-react";

const PRESETS = {
  focus: 25 * 60,
  short: 5 * 60,
  long: 15 * 60,
} as const;

type Mode = keyof typeof PRESETS;

function format(seconds: number) {
  const m = Math.floor(seconds / 60)
    .toString()
    .padStart(2, "0");
  const s = (seconds % 60).toString().padStart(2, "0");
  return `${m}:${s}`;
}

export default function PomodoroApp() {
  const [mode, setMode] = useState<Mode>("focus");
  const [remaining, setRemaining] = useState(PRESETS.focus);
  const [running, setRunning] = useState(false);
  const [sessions, setSessions] = useState(0);

  const total = PRESETS[mode];
  const progress = 1 - remaining / total;

  const reset = useCallback(
    (next: Mode = mode) => {
      setMode(next);
      setRemaining(PRESETS[next]);
      setRunning(false);
    },
    [mode],
  );

  useEffect(() => {
    if (!running) return;
    const id = window.setInterval(() => {
      setRemaining((r) => {
        if (r <= 1) {
          window.clearInterval(id);
          setRunning(false);
          if (mode === "focus") setSessions((n) => n + 1);
          return 0;
        }
        return r - 1;
      });
    }, 1000);
    return () => window.clearInterval(id);
  }, [running, mode]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.code === "Space") {
        e.preventDefault();
        setRunning((v) => !v);
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);

  const r = 54;
  const c = 2 * Math.PI * r;
  const offset = c * (1 - progress);

  return (
    <div className="border border-line bg-charcoal p-6 sm:p-8">
      <div className="mb-6 flex flex-wrap gap-2">
        {(Object.keys(PRESETS) as Mode[]).map((m) => (
          <button
            key={m}
            type="button"
            onClick={() => reset(m)}
            className={`px-3.5 py-1.5 text-xs font-bold tracking-wide uppercase transition ${
              mode === m
                ? "bg-crimson text-white"
                : "border border-line text-ink-muted hover:border-crimson hover:text-crimson"
            }`}
          >
            {m === "short" ? "Short break" : m === "long" ? "Long break" : "Focus"}
          </button>
        ))}
      </div>

      <div className="relative mx-auto mb-6 flex h-56 w-56 items-center justify-center">
        <svg className="-rotate-90" width="220" height="220" viewBox="0 0 120 120">
          <circle cx="60" cy="60" r={r} fill="none" stroke="#1f1f1f" strokeWidth="8" />
          <circle
            cx="60"
            cy="60"
            r={r}
            fill="none"
            stroke="#dc2626"
            strokeWidth="8"
            strokeLinecap="round"
            strokeDasharray={c}
            strokeDashoffset={offset}
            className="transition-[stroke-dashoffset] duration-1000 ease-linear"
          />
        </svg>
        <div className="absolute text-center">
          <p className="font-display text-5xl tabular-nums text-ink">
            {format(remaining)}
          </p>
          <p className="mt-1 font-mono text-[10px] tracking-wider text-ink-muted uppercase">
            Sessions {sessions}
          </p>
        </div>
      </div>

      <div className="flex items-center justify-center gap-3">
        <button
          type="button"
          onClick={() => setRunning((v) => !v)}
          className="inline-flex items-center gap-2 bg-crimson px-5 py-2.5 text-sm font-bold text-white uppercase hover:bg-crimson-bright"
        >
          {running ? <Pause size={16} /> : <Play size={16} />}
          {running ? "Pause" : "Start"}
        </button>
        <button
          type="button"
          onClick={() => reset(mode)}
          className="inline-flex items-center gap-2 border border-line px-4 py-2.5 text-sm font-bold text-ink-muted uppercase hover:border-crimson hover:text-crimson"
        >
          <RotateCcw size={16} /> Reset
        </button>
      </div>
    </div>
  );
}
