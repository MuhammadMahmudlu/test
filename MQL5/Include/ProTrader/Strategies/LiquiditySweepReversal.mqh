#ifndef PROTRADER_LIQUIDITY_SWEEP_REVERSAL_MQH
#define PROTRADER_LIQUIDITY_SWEEP_REVERSAL_MQH

#include "IStrategy.mqh"
#include "../Market/ManipulationGuard.mqh"

class CLiquiditySweepReversal : public IStrategy
  {
private:
   string            m_symbol;
   PTSymbolProfile   m_profile;
   CManipulationGuard *m_manip; // non-owning

public:
                     CLiquiditySweepReversal(void) : m_manip(NULL) { m_symbol = ""; }

   void              SetManipulationGuard(CManipulationGuard &g) { m_manip = &g; }

   string            Name(void) const { return "LiqSweepReversal"; }

   bool              Init(const string symbol, const PTSymbolProfile &profile)
     {
      m_symbol = symbol;
      m_profile = profile;
      return true;
     }

   StrategySignal    Evaluate(const ENUM_PT_REGIME regime,
                              const ENUM_PT_DIR htf_bias,
                              const ENUM_PT_MODE mode,
                              const double atr)
     {
      StrategySignal s;
      PT_ClearSignal(s);
      s.tag = Name();

      if(regime == PT_REGIME_DEAD)
         return s;
      if(m_manip == NULL || atr <= 0)
         return s;

      ENUM_PT_DIR sweep_dir = PT_DIR_NONE;
      double extreme = 0;
      if(!m_manip.DetectLiquiditySweep(m_symbol, m_profile.entry_tf, sweep_dir, extreme))
         return s;

      // Optional displacement: next closed bar continues in sweep direction
      MqlRates rates[];
      ArraySetAsSeries(rates, true);
      if(CopyRates(m_symbol, m_profile.entry_tf, 0, 4, rates) < 4)
         return s;

      double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
      double r_mult = (mode == PT_MODE_RECOVERY ? 1.5 : 2.0);
      double atr_mult = m_profile.min_sl_atr_mult + 0.2;

      if(sweep_dir == PT_DIR_BUY && htf_bias != PT_DIR_SELL)
        {
         bool engulf = (rates[1].close > rates[2].high);
         bool fvg_proxy = (rates[1].low > rates[3].high); // simple displacement gap proxy
         s.dir = PT_DIR_BUY;
         s.score = 30.0 + (engulf ? 15.0 : 0.0) + (fvg_proxy ? 10.0 : 0.0);
         if(htf_bias == PT_DIR_BUY) s.score += 5.0;
         double struct_sl = (extreme > 0 ? extreme : rates[1].low);
         s.sl_price = PT_ATR_SL(PT_DIR_BUY, ask, atr, atr_mult, struct_sl - atr * 0.1);
         s.tp_price = PT_TP_From_R(PT_DIR_BUY, ask, s.sl_price, r_mult);
         s.reason = "buy_side_stop_hunt_reversal";
         return s;
        }

      if(sweep_dir == PT_DIR_SELL && htf_bias != PT_DIR_BUY)
        {
         bool engulf = (rates[1].close < rates[2].low);
         bool fvg_proxy = (rates[1].high < rates[3].low);
         s.dir = PT_DIR_SELL;
         s.score = 30.0 + (engulf ? 15.0 : 0.0) + (fvg_proxy ? 10.0 : 0.0);
         if(htf_bias == PT_DIR_SELL) s.score += 5.0;
         double struct_sl = (extreme > 0 ? extreme : rates[1].high);
         s.sl_price = PT_ATR_SL(PT_DIR_SELL, bid, atr, atr_mult, struct_sl + atr * 0.1);
         s.tp_price = PT_TP_From_R(PT_DIR_SELL, bid, s.sl_price, r_mult);
         s.reason = "sell_side_stop_hunt_reversal";
         return s;
        }

      return s;
     }
  };

#endif
