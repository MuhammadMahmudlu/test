#ifndef PROTRADER_LOT_SIZER_MQH
#define PROTRADER_LOT_SIZER_MQH

#include "../Types.mqh"
#include "../Config.mqh"
#include "../Market/SymbolProfile.mqh"
#include "../State/Journal.mqh"

class CLotSizer
  {
private:
   PTConfig          m_cfg;

   double            RiskPctForEquity(const double equity, const ENUM_PT_MODE mode) const
     {
      if(m_cfg.risk_mode == PT_RISK_BALANCED)
        {
         if(equity < 30.0) return 1.0;
         if(equity < 100.0) return 1.25;
         if(equity < 500.0) return 1.0;
         return 0.75;
        }

      // RecoveryAggressive (default)
      if(equity < 30.0)  return (mode == PT_MODE_RECOVERY ? 2.0 : 1.5);
      if(equity < 100.0) return 2.5;
      if(equity < 500.0) return 1.5;
      return 1.0;
     }

   double            NormalizeLots(const string symbol, double lots) const
     {
      double min_lot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
      double max_lot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
      double step    = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
      if(step <= 0) step = 0.01;
      if(min_lot <= 0) min_lot = 0.01;

      lots = MathFloor(lots / step + 1e-9) * step;
      if(lots < min_lot)
         return 0.0; // signal: below min — caller must skip, not force
      if(lots > max_lot)
         lots = max_lot;

      int digits = 0;
      double tmp = step;
      while(tmp < 1.0 && digits < 8)
        {
         tmp *= 10.0;
         digits++;
        }
      return NormalizeDouble(lots, digits);
     }

public:
   void              Bind(const PTConfig &cfg) { m_cfg = cfg; }

   double            TargetRiskPct(const AccountSnapshot &snap) const
     {
      return RiskPctForEquity(snap.equity, snap.mode);
     }

   // Returns lots; 0 means skip (min lot would over-risk)
   RiskDecision      Build(const string symbol,
                           const AccountSnapshot &snap,
                           const PTSymbolProfile &profile,
                           const ENUM_PT_DIR dir,
                           const double entry_price,
                           const double sl_price,
                           const double tp_price)
     {
      RiskDecision d;
      d.allowed = false;
      d.lots = 0;
      d.risk_money = 0;
      d.risk_pct = 0;
      d.sl_price = sl_price;
      d.tp_price = tp_price;
      d.block_reason = "";

      if(dir == PT_DIR_NONE || entry_price <= 0 || sl_price <= 0)
        {
         d.block_reason = "invalid_prices_or_dir";
         return d;
        }

      // Mandatory SL distance sanity
      double sl_dist = MathAbs(entry_price - sl_price);
      if(sl_dist <= 0)
        {
         d.block_reason = "sl_distance_zero";
         return d;
        }

      double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
      double tick_size = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
      double tick_value = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
      if(point <= 0 || tick_size <= 0 || tick_value <= 0)
        {
         d.block_reason = "symbol_tick_meta_invalid";
         return d;
        }

      // Stops level
      int stops_level = (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
      double min_stop = stops_level * point;
      if(sl_dist < min_stop)
        {
         d.block_reason = StringFormat("sl_inside_stops_level need>=%.5f got=%.5f", min_stop, sl_dist);
         return d;
        }

      d.risk_pct = TargetRiskPct(snap);
      d.risk_money = snap.equity * (d.risk_pct / 100.0);
      if(d.risk_money <= 0)
        {
         d.block_reason = "risk_money_zero";
         return d;
        }

      // money risk per 1.0 lot for this SL distance
      double ticks = sl_dist / tick_size;
      double money_per_lot = ticks * tick_value;
      if(money_per_lot <= 0)
        {
         d.block_reason = "money_per_lot_zero";
         return d;
        }

      double raw_lots = d.risk_money / money_per_lot;
      double lots = NormalizeLots(symbol, raw_lots);

      if(lots <= 0.0)
        {
         // Check whether min lot would exceed risk budget — always skip (never force)
         double min_lot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
         double min_risk = min_lot * money_per_lot;
         d.block_reason = StringFormat("min_lot_over_risk min_lot=%.2f min_risk=%.2f budget=%.2f",
                                       min_lot, min_risk, d.risk_money);
         return d;
        }

      // Final check: actual risk with chosen lots must not blow daily-ish hard cap of 5% equity
      double actual_risk = lots * money_per_lot;
      double hard_cap = snap.equity * 0.05;
      if(actual_risk > hard_cap + 1e-6)
        {
         d.block_reason = StringFormat("actual_risk=%.2f > hard_cap=%.2f", actual_risk, hard_cap);
         return d;
        }

      // Margin check for the lot
      double margin_required = 0;
      ENUM_ORDER_TYPE otype = (dir == PT_DIR_BUY ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
      if(!OrderCalcMargin(otype, symbol, lots, entry_price, margin_required))
        {
         d.block_reason = "OrderCalcMargin_failed";
         return d;
        }
      if(margin_required > snap.free_margin)
        {
         d.block_reason = StringFormat("margin_required=%.2f > free=%.2f", margin_required, snap.free_margin);
         return d;
        }
      if(snap.equity > 0)
        {
         double projected_usage = 100.0 * (snap.margin + margin_required) / snap.equity;
         if(projected_usage > m_cfg.max_margin_usage_pct)
           {
            d.block_reason = StringFormat("projected_margin_usage=%.1f%%", projected_usage);
            return d;
           }
        }

      // Never allow trade that could push equity estimate below floor on full SL
      if(snap.equity - actual_risk < snap.equity_floor)
        {
         d.block_reason = StringFormat("sl_would_breach_floor eq=%.2f risk=%.2f floor=%.2f",
                                       snap.equity, actual_risk, snap.equity_floor);
         return d;
        }

      d.lots = lots;
      d.risk_money = actual_risk;
      d.allowed = true;
      d.block_reason = "ok";
      return d;
     }
  };

#endif
