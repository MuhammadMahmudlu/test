#ifndef PROTRADER_MEAN_REVERT_RANGE_MQH
#define PROTRADER_MEAN_REVERT_RANGE_MQH

#include "IStrategy.mqh"

class CMeanRevertRange : public IStrategy
  {
private:
   string            m_symbol;
   PTSymbolProfile   m_profile;
   int               m_rsi;
   int               m_bb;

public:
                     CMeanRevertRange(void)
     {
      m_symbol = "";
      m_rsi = INVALID_HANDLE;
      m_bb = INVALID_HANDLE;
     }

                    ~CMeanRevertRange(void) { Release(); }

   string            Name(void) const { return "MeanRevertRange"; }

   bool              Init(const string symbol, const PTSymbolProfile &profile)
     {
      Release();
      m_symbol = symbol;
      m_profile = profile;
      m_rsi = iRSI(symbol, profile.entry_tf, 14, PRICE_CLOSE);
      m_bb  = iBands(symbol, profile.entry_tf, 20, 0, 2.0, PRICE_CLOSE);
      return (m_rsi != INVALID_HANDLE && m_bb != INVALID_HANDLE);
     }

   void              Release(void)
     {
      if(m_rsi != INVALID_HANDLE) { IndicatorRelease(m_rsi); m_rsi = INVALID_HANDLE; }
      if(m_bb != INVALID_HANDLE) { IndicatorRelease(m_bb); m_bb = INVALID_HANDLE; }
     }

   StrategySignal    Evaluate(const ENUM_PT_REGIME regime,
                              const ENUM_PT_DIR htf_bias,
                              const ENUM_PT_MODE mode,
                              const double atr)
     {
      StrategySignal s;
      PT_ClearSignal(s);
      s.tag = Name();

      // Only in RANGE
      if(regime != PT_REGIME_RANGE)
         return s;
      if(atr <= 0)
         return s;

      double rsi[], upper[], mid[], lower[];
      ArraySetAsSeries(rsi, true);
      ArraySetAsSeries(upper, true);
      ArraySetAsSeries(mid, true);
      ArraySetAsSeries(lower, true);

      if(CopyBuffer(m_rsi, 0, 0, 3, rsi) < 3) return s;
      if(CopyBuffer(m_bb, 1, 0, 3, upper) < 3) return s; // upper
      if(CopyBuffer(m_bb, 0, 0, 3, mid) < 3) return s;   // base/middle
      if(CopyBuffer(m_bb, 2, 0, 3, lower) < 3) return s; // lower

      MqlRates rates[];
      ArraySetAsSeries(rates, true);
      if(CopyRates(m_symbol, m_profile.entry_tf, 0, 3, rates) < 3)
         return s;

      double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
      double r_mult = (mode == PT_MODE_RECOVERY ? 1.2 : 1.5);
      double atr_mult = m_profile.min_sl_atr_mult;

      // Oversold bounce
      if(rsi[1] < 30.0 && rates[1].low <= lower[1] && rates[1].close > lower[1])
        {
         if(htf_bias == PT_DIR_SELL) return s; // soft veto already via scorer; skip hard conflict
         s.dir = PT_DIR_BUY;
         s.score = 25.0 + (rsi[1] < 25.0 ? 10.0 : 0.0);
         s.sl_price = PT_ATR_SL(PT_DIR_BUY, ask, atr, atr_mult, rates[1].low);
         // TP toward mid band preferentially
         double tp_r = PT_TP_From_R(PT_DIR_BUY, ask, s.sl_price, r_mult);
         s.tp_price = (mid[0] > ask ? MathMin(mid[0], tp_r) : tp_r);
         s.reason = "rsi_bb_oversold";
         return s;
        }

      // Overbought fade
      if(rsi[1] > 70.0 && rates[1].high >= upper[1] && rates[1].close < upper[1])
        {
         if(htf_bias == PT_DIR_BUY) return s;
         s.dir = PT_DIR_SELL;
         s.score = 25.0 + (rsi[1] > 75.0 ? 10.0 : 0.0);
         s.sl_price = PT_ATR_SL(PT_DIR_SELL, bid, atr, atr_mult, rates[1].high);
         double tp_r = PT_TP_From_R(PT_DIR_SELL, bid, s.sl_price, r_mult);
         s.tp_price = (mid[0] < bid ? MathMax(mid[0], tp_r) : tp_r);
         s.reason = "rsi_bb_overbought";
         return s;
        }

      return s;
     }
  };

#endif
