# ProTraderEA — Smoke compile notes

## Install into MetaTrader 5

1. Copy repo `MQL5/Experts/ProTraderEA/` → `<MT5_DATA>/MQL5/Experts/ProTraderEA/`
2. Copy repo `MQL5/Include/ProTrader/` → `<MT5_DATA>/MQL5/Include/ProTrader/`
3. Open MetaEditor → `Experts/ProTraderEA/ProTraderEA.mq5` → Compile (F7)
4. Confirm `0 error(s)` in the Errors tab

## Quick sanity after attach

- Experts log should show: `start_equity=... floor=...`
- Mode line: `RECOVERY` when equity &lt; 100 (RecoveryAggressive)
- On blocked entries look for `[ProTrader][BLOCK]` with an explicit reason
- No order should ever open without SL (OrderRouter hard-refuses)

## Tester checklist

| Deposit | Symbol  | TF | Expectation |
|--------|---------|----|-------------|
| 20     | EURUSD  | M5 | Recovery mode, frequent skips if min-lot over risk |
| 50     | EURUSD  | M5 | Recovery scalp, equity floor respected |
| 200    | EURUSD  | M5 | Growth mode possible, higher A+ threshold |
| 50     | XAUUSD  | M5 | Stricter spread/manip filters; Asia blocked |

Use **Every tick based on real ticks** when available. Model XAUUSD spread carefully.
