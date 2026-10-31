#ifndef PROTRADER_COMPRESSION_BREAKOUT_MQH
#define PROTRADER_COMPRESSION_BREAKOUT_MQH

#include "IStrategy.mqh"

class CCompressionBreakout : public IStrategy
  {
private:
   string            m_symbol;
   PTSymbolProfile   m_profile;
   int               m_atr;

public:
                     CCompressionBreakout(void)
     {
      m_symbol = "";
      m_atr = INVALID_HANDLE;
     }

                    ~CCompressionBreakout(void) { Release(); }

   string            Name(void) const { return "CompressionBreakout"; }

   bool              Init(const string symbol, const PTSymbolProfile &profile)
     {
      Release();
      m_symbol = symbol;
      m_profile = profile;
      m_atr = iATR(symbol, profile.entry_tf, 14);
      return (m_atr != INVALID_HANDLE);
     }

   void              Release(void)
     {
      if(m_atr != INVALID_HANDLE) { IndicatorRelease(m_atr); m_atr = INVALID_HANDLE; }
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
      if(atr <= 0)
         return s;

      double atr_buf[];
      ArraySetAsSeries(atr_buf, true);
      if(CopyBuffer(m_atr, 0, 0, 30, atr_buf) < 30)
         return s;

      // Squeeze: current ATR near lowest of last 20
      double min_atr = atr_buf[1];
      for(int i=2; i<=20; i++)
         if(atr_buf[i] < min_atr) min_atr = atr_buf[i];

      bool squeeze_recent = (atr_buf[3] <= min_atr * 1.15);

      MqlRates rates[];
      ArraySetAsSeries(rates, true);
      if(CopyRates(m_symbol, m_profile.entry_tf, 0, 25, rates) < 25)
         return s;

      // Compression range from bars 3..12
      double rh = rates[3].high;
      double rl = rates[3].low;
      for(int i=4; i<=12; i++)
        {
         if(rates[i].high > rh) rh = rates[i].high;
         if(rates[i].low < rl) rl = rates[i].low;
        }

      double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
      double r_mult = (mode == PT_MODE_RECOVERY ? 1.5 : 2.5);
      double atr_mult = m_profile.min_sl_atr_mult;

      // Break + retest: bar2 breaks, bar1 retests and continues
      if(squeeze_recent && rates[2].close > rh && rates[1].low <= rh && rates[1].close > rh)
        {
         if(htf_bias == PT_DIR_SELL) return s;
         s.dir = PT_DIR_BUY;
         s.score = 30.0 + (regime == PT_REGIME_VOLATILE ? 5.0 : 10.0);
         if(htf_bias == PT_DIR_BUY) s.score += 10.0;
         s.sl_price = PT_ATR_SL(PT_DIR_BUY, ask, atr, atr_mult, rl);
         s.tp_price = PT_TP_From_R(PT_DIR_BUY, ask, s.sl_price, r_mult);
         s.reason = "squeeze_break_retest_long";
         return s;
        }

      if(squeeze_recent && rates[2].close < rl && rates[1].high >= rl && rates[1].close < rl)
        {
         if(htf_bias == PT_DIR_BUY) return s;
         s.dir = PT_DIR_SELL;
         s.score = 30.0 + (regime == PT_REGIME_VOLATILE ? 5.0 : 10.0);
         if(htf_bias == PT_DIR_SELL) s.score += 10.0;
         s.sl_price = PT_ATR_SL(PT_DIR_SELL, bid, atr, atr_mult, rh);
         s.tp_price = PT_TP_From_R(PT_DIR_SELL, bid, s.sl_price, r_mult);
         s.reason = "squeeze_break_retest_short";
         return s;
        }

      return s;
     }
  };

#endif
