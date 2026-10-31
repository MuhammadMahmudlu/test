# ProTraderEA (MetaTrader 5)

A+ confluence Expert Advisor for **Forex majors + XAUUSD** with an **aggressive recovery** risk model.  
Decision flow: equity/session/manipulation guards → market regime → HTF bias → strategy votes → A+ score → hard-SL lot sizing → manage (BE / partial / trail / time-stop).

> No EA guarantees profit. Aggressive recovery on tiny accounts still has high ruin risk; this design **reduces** liquidation odds with hard floors and skip rules — it does not eliminate them.

## Install

1. Copy `MQL5/Experts/ProTraderEA/` into your terminal `MQL5/Experts/ProTraderEA/`
2. Copy `MQL5/Include/ProTrader/` into your terminal `MQL5/Include/ProTrader/`
3. Compile `ProTraderEA.mq5` in MetaEditor (F7)

See also [`MQL5/Scripts/SmokeCompileNotes.md`](MQL5/Scripts/SmokeCompileNotes.md).

## What it does

| Module | Role |
|--------|------|
| `EquityGuard` / `LotSizer` | Equity floor, margin cap, daily loss, cooldown, never force min-lot over risk |
| `RegimeDetector` | TREND / RANGE / VOLATILE / DEAD |
| `SessionFilter` | London / NY / overlap; Asia FX mean-revert only; XAU Asia blocked |
| `ManipulationGuard` | Spread spike, fake breakout, stops/freeze toxicity; liquidity-sweep detector |
| Strategies | TrendPullback, LiqSweepReversal, CompressionBreakout, MeanRevertRange |
| `SetupScorer` | Same-direction confluence; HTF bias penalty; recovery vs growth thresholds |
| `TradeManager` | SL-mandatory entries, 50% @1R, BE, ATR trail, time-stop, Friday flatten |

## Modes (auto)

With default `RecoveryAggressive`:

- Equity **&lt; $100** → **RECOVERY** scalp (A+ min score 60, TP ~1.5R, shorter time-stop)
- Equity **≥ $100** → **GROWTH** day-trade bias (A+ min 75, prefers 2+ strategy confluence)

Lot risk tiers (recovery): ~2–2.5% under $100, then taper to ~1% above $500.  
If broker `min lot` would exceed the risk budget → **skip** (no forced lot).

## Hard “no liq” rules

- Every market entry requires a stop-loss
- `equity_floor = max($5, 35% of start equity)` → no new entries at/below floor
- Max margin usage 25%
- Max positions: 1 / 2 / 3 by equity band
- Daily loss cap 4% of start equity
- 3 consecutive losses → cooldown 30–90 minutes
- No martingale / grid / averaging down

## Recommended Strategy Tester matrix

| Deposit | Symbol | TF | Settings notes |
|--------:|--------|----|----------------|
| $20 | EURUSD | M5 | `InpOnlyChartSymbol=true`, RecoveryAggressive |
| $50 | EURUSD | M5 | Watch `[BLOCK] min_lot_over_risk` vs fills |
| $200 | EURUSD | M5 | Expect GROWTH threshold behavior |
| $50 | XAUUSD | M5 | Model realistic spread; Asia entries should stay blocked |

Model: **Every tick based on real ticks** when possible. Review Journal/`Experts` log for `[ProTrader][BLOCK]` reasons.

## Key inputs

- `InpRiskMode` — RecoveryAggressive (default) or Balanced
- `InpAplusRecovery` / `InpAplusGrowth` — confluence thresholds
- `InpEquityFloorPct`, `InpDailyLossPct`, `InpMaxMarginUsagePct`
- `InpNextNewsTime` + `InpNewsBlackoutMin` — optional manual news blackout
- `InpOnlyChartSymbol` — default `true` (tester-safe); set `false` to scan enabled majors+XAU on one chart

## Layout

```
MQL5/
  Experts/ProTraderEA/ProTraderEA.mq5
  Include/ProTrader/
    Config.mqh  Types.mqh
    Risk/  Market/  Strategies/  Confluence/  Execution/  State/
  Scripts/SmokeCompileNotes.md
```
