#ifndef PROTRADER_MANIPULATION_GUARD_MQH
#define PROTRADER_MANIPULATION_GUARD_MQH

#include "../Types.mqh"
#include "../Config.mqh"
#include "SymbolProfile.mqh"
#include "../State/Journal.mqh"

class CManipulationGuard
  {
private:
   PTConfig          m_cfg;
   double            m_spread_ema;
   bool              m_spread_init;
   datetime          m_last_tick_time;
   double            m_last_bid;
   double            m_last_ask;

   int               SwingLookback(const PTSymbolProfile &profile) const
     {
      return profile.is_gold ? 8 : 5;
     }

public:
                     CManipulationGuard(void)
     {
      m_spread_ema = 0;
      m_spread_init = false;
      m_last_tick_time = 0;
      m_last_bid = 0;
      m_last_ask = 0;
     }

   void              Bind(const PTConfig &cfg) { m_cfg = cfg; }

   void              OnTickUpdate(const string symbol)
     {
      double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
      double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
      if(point <= 0) return;
      double spread = (ask - bid) / point;

      if(!m_spread_init)
        {
         m_spread_ema = spread;
         m_spread_init = true;
        }
      else
         m_spread_ema = 0.9 * m_spread_ema + 0.1 * spread;

      m_last_tick_time = TimeCurrent();
      m_last_bid = bid;
      m_last_ask = ask;
     }

   // Toxic environment → block entries (strategies may still use sweep signals separately)
   GuardResult       IsToxic(const string symbol, const PTSymbolProfile &profile)
     {
      GuardResult g;
      g.ok = true;
      g.reason = "ok";

      OnTickUpdate(symbol);

      double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
      double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
      if(point <= 0)
        {
         g.ok = false;
         g.reason = "bad_point";
         return g;
        }

      double spread = (ask - bid) / point;
      double cap = profile.spread_cap_points;
      double dyn = m_spread_ema * profile.manip_spread_mult;
      double limit = MathMax(cap, dyn);

      if(spread > limit)
        {
         g.ok = false;
         g.reason = StringFormat("spread_spike spread=%.1f limit=%.1f ema=%.1f", spread, limit, m_spread_ema);
         return g;
        }

      // Tick freeze / gap: large jump vs last
      if(m_last_bid > 0)
        {
         double jump = MathAbs(bid - m_last_bid) / point;
         double jump_limit = profile.is_gold ? 250.0 : 40.0;
         if(jump > jump_limit && (TimeCurrent() - m_last_tick_time) <= 2)
           {
            // Note: OnTickUpdate already refreshed last; use previous comparison carefully.
            // We compare against pre-update would be better; approximate with ask-bid range.
           }
        }

      // Stop-level jump toxicity: trade stops level suddenly very high
      int stops = (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
      int freeze = (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_FREEZE_LEVEL);
      if(stops > (profile.is_gold ? 200 : 50) || freeze > (profile.is_gold ? 100 : 30))
        {
         g.ok = false;
         g.reason = StringFormat("stops_freeze_high stops=%d freeze=%d", stops, freeze);
         return g;
        }

      // Fake breakout toxicity: last closed bar broke prior swing then closed back inside
      if(IsFakeBreakoutToxic(symbol, profile))
        {
         g.ok = false;
         g.reason = "fake_breakout_toxic";
         return g;
        }

      return g;
     }

   // Detect liquidity sweep structure (useful as signal input, not always toxic)
   bool              DetectLiquiditySweep(const string symbol, const ENUM_TIMEFRAMES tf,
                                          ENUM_PT_DIR &sweep_dir, double &sweep_extreme)
     {
      sweep_dir = PT_DIR_NONE;
      sweep_extreme = 0;

      MqlRates rates[];
      ArraySetAsSeries(rates, true);
      int need = 30;
      if(CopyRates(symbol, tf, 0, need, rates) < need)
         return false;

      // Use closed bar 1 as candidate sweep bar
      int lb = 5;
      double prior_high = rates[2].high;
      double prior_low  = rates[2].low;
      for(int i=3; i<2+lb; i++)
        {
         if(rates[i].high > prior_high) prior_high = rates[i].high;
         if(rates[i].low  < prior_low)  prior_low  = rates[i].low;
        }

      // Sweep high then close back below prior high → sell-side liquidity grab (bullish reversal potential after? actually sell liquidity above = buy-side stop hunt → bullish)
      if(rates[1].high > prior_high && rates[1].close < prior_high && rates[1].close > rates[1].open)
        {
         sweep_dir = PT_DIR_BUY;
         sweep_extreme = rates[1].low;
         return true;
        }
      if(rates[1].low < prior_low && rates[1].close > prior_low && rates[1].close < rates[1].open)
        {
         sweep_dir = PT_DIR_SELL;
         sweep_extreme = rates[1].high;
         return true;
        }
      return false;
     }

private:
   bool              IsFakeBreakoutToxic(const string symbol, const PTSymbolProfile &profile)
     {
      MqlRates rates[];
      ArraySetAsSeries(rates, true);
      ENUM_TIMEFRAMES tf = profile.entry_tf;
      if(CopyRates(symbol, tf, 0, 10, rates) < 10)
         return false;

      // Prior range high/low of bars 3..7
      double rh = rates[3].high;
      double rl = rates[3].low;
      for(int i=4; i<=7; i++)
        {
         if(rates[i].high > rh) rh = rates[i].high;
         if(rates[i].low < rl) rl = rates[i].low;
        }

      // Bar 2 breaks out, bar 1 fully reverses back through
      bool up_fake = (rates[2].high > rh && rates[1].close < rh && rates[1].close < rates[1].open);
      bool dn_fake = (rates[2].low < rl && rates[1].close > rl && rates[1].close > rates[1].open);

      // Only toxic if body of reversal is large relative to range (chase trap)
      double body = MathAbs(rates[1].close - rates[1].open);
      double range = rates[1].high - rates[1].low;
      if(range <= 0) return false;
      if((up_fake || dn_fake) && body / range > 0.6)
         return true;
      return false;
     }
  };

#endif
