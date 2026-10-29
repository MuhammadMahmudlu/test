"use client";

import { useMemo, useState } from "react";

export default function TipSplitApp() {
  const [bill, setBill] = useState("86.50");
  const [tip, setTip] = useState(15);
  const [people, setPeople] = useState(3);

  const calc = useMemo(() => {
    const amount = Number.parseFloat(bill) || 0;
    const tipAmount = amount * (tip / 100);
    const total = amount + tipAmount;
    const perPerson = people > 0 ? total / people : 0;
    return { tipAmount, total, perPerson };
  }, [bill, tip, people]);

  const money = (n: number) =>
    n.toLocaleString(undefined, { style: "currency", currency: "USD" });

  return (
    <div className="grid gap-5 sm:grid-cols-[1.1fr_0.9fr]">
      <div className="space-y-4 border border-line bg-charcoal p-5 sm:p-6">
        <label className="block text-sm font-medium text-ink">
          Bill amount
          <input
            type="number"
            min={0}
            step="0.01"
            value={bill}
            onChange={(e) => setBill(e.target.value)}
            className="mt-1.5 w-full border border-line bg-void px-3 py-2.5 text-ink outline-none focus:border-crimson"
          />
        </label>

        <label className="block text-sm font-medium text-ink">
          Tip · {tip}%
          <input
            type="range"
            min={0}
            max={40}
            value={tip}
            onChange={(e) => setTip(Number(e.target.value))}
            className="mt-2 w-full accent-crimson"
          />
          <div className="mt-2 flex flex-wrap gap-2">
            {[10, 15, 18, 20].map((p) => (
              <button
                key={p}
                type="button"
                onClick={() => setTip(p)}
                className={`px-3 py-1 text-xs font-bold ${
                  tip === p
                    ? "bg-crimson text-white"
                    : "border border-line text-ink-muted"
                }`}
              >
                {p}%
              </button>
            ))}
          </div>
        </label>

        <label className="block text-sm font-medium text-ink">
          People
          <input
            type="number"
            min={1}
            value={people}
            onChange={(e) =>
              setPeople(Math.max(1, Number(e.target.value) || 1))
            }
            className="mt-1.5 w-full border border-line bg-void px-3 py-2.5 text-ink outline-none focus:border-crimson"
          />
        </label>
      </div>

      <div className="border border-crimson/40 bg-gradient-to-br from-crimson-deep to-crimson p-6 text-white">
        <p className="text-sm text-red-100">Tip amount</p>
        <p className="font-display text-4xl">{money(calc.tipAmount)}</p>
        <div className="my-5 h-px bg-white/20" />
        <p className="text-sm text-red-100">Total</p>
        <p className="font-display text-4xl">{money(calc.total)}</p>
        <div className="my-5 h-px bg-white/20" />
        <p className="text-sm text-red-100">Per person</p>
        <p className="font-display text-5xl">{money(calc.perPerson)}</p>
      </div>
    </div>
  );
}
