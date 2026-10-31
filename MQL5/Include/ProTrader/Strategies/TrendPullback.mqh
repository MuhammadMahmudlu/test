#ifndef PROTRADER_TREND_PULLBACK_MQH
#define PROTRADER_TREND_PULLBACK_MQH

#include "IStrategy.mqh"

class CTrendPullback : public IStrategy
  {
private:
   string            m_symbol;
   PTSymbolProfile   m_profile;
   int               m_ema_fast;
   int               m_ema_slow;
   int               m_ema_pull;

public:
                     CTrendPullback(void)
     {
      m_symbol = "";
      m_ema_fast = INVALID_HANDLE;
      m_ema_slow = INVALID_HANDLE;
      m_ema_pull = INVALID_HANDLE;
     }

                    ~CTrendPullback(void) { Release(); }

   string            Name(void) const { return "TrendPullback"; }

   bool              Init(const string symbol, const PTSymbolProfile &profile)
     {
      Release();
      m_symbol = symbol;
      m_profile = profile;
      ENUM_TIMEFRAMES tf = profile.entry_tf;
      m_ema_fast = iMA(symbol, tf, 21, 0, MODE_EMA, PRICE_CLOSE);
      m_ema_slow = iMA(symbol, tf, 55, 0, MODE_EMA, PRICE_CLOSE);
      m_ema_pull = iMA(symbol, tf, 9, 0, MODE_EMA, PRICE_CLOSE);
      return (m_ema_fast != INVALID_HANDLE && m_ema_slow != INVALID_HANDLE && m_ema_pull != INVALID_HANDLE);
     }

   void              Release(void)
     {
      if(m_ema_fast != INVALID_HANDLE) { IndicatorRelease(m_ema_fast); m_ema_fast = INVALID_HANDLE; }
      if(m_ema_slow != INVALID_HANDLE) { IndicatorRelease(m_ema_slow); m_ema_slow = INVALID_HANDLE; }
      if(m_ema_pull != INVALID_HANDLE) { IndicatorRelease(m_ema_pull); m_ema_pull = INVALID_HANDLE; }
     }

   StrategySignal    Evaluate(const ENUM_PT_REGIME regime,
                              const ENUM_PT_DIR htf_bias,
                              const ENUM_PT_MODE mode,
                              const double atr)
     {
      StrategySignal s;
      PT_ClearSignal(s);
      s.tag = Name();

      if(regime == PT_REGIME_DEAD || regime == PT_REGIME_RANGE)
         return s;
      if(atr <= 0)
         return s;

      double f[], slow[], pull[];
      ArraySetAsSeries(f, true);
      ArraySetAsSeries(slow, true);
      ArraySetAsSeries(pull, true);
      if(CopyBuffer(m_ema_fast, 0, 0, 5, f) < 5) return s;
      if(CopyBuffer(m_ema_slow, 0, 0, 5, slow) < 5) return s;
      if(CopyBuffer(m_ema_pull, 0, 0, 5, pull) < 5) return s;

      MqlRates rates[];
      ArraySetAsSeries(rates, true);
      if(CopyRates(m_symbol, m_profile.entry_tf, 0, 5, rates) < 5)
         return s;

      double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
      double r_mult = (mode == PT_MODE_RECOVERY ? 1.5 : 2.5);
      double atr_mult = m_profile.min_sl_atr_mult;

      // Bullish trend pullback
      if(f[0] > slow[0] && htf_bias != PT_DIR_SELL)
        {
         bool touched = (rates[1].low <= pull[1] && rates[1].close > pull[1]);
         bool confirm = (rates[1].close > rates[1].open && rates[1].close > f[1]);
         if(touched && confirm)
           {
            s.dir = PT_DIR_BUY;
            s.score = 35.0 + (regime == PT_REGIME_TREND ? 10.0 : 0.0);
            if(htf_bias == PT_DIR_BUY) s.score += 10.0;
            s.sl_price = PT_ATR_SL(PT_DIR_BUY, ask, atr, atr_mult, rates[1].low);
            s.tp_price = PT_TP_From_R(PT_DIR_BUY, ask, s.sl_price, r_mult);
            s.reason = "ema_pullback_long";
            return s;
           }
        }

      // Bearish trend pullback
      if(f[0] < slow[0] && htf_bias != PT_DIR_BUY)
        {
         bool touched = (rates[1].high >= pull[1] && rates[1].close < pull[1]);
         bool confirm = (rates[1].close < rates[1].open && rates[1].close < f[1]);
         if(touched && confirm)
           {
            s.dir = PT_DIR_SELL;
            s.score = 35.0 + (regime == PT_REGIME_TREND ? 10.0 : 0.0);
            if(htf_bias == PT_DIR_SELL) s.score += 10.0;
            s.sl_price = PT_ATR_SL(PT_DIR_SELL, bid, atr, atr_mult, rates[1].high);
            s.tp_price = PT_TP_From_R(PT_DIR_SELL, bid, s.sl_price, r_mult);
            s.reason = "ema_pullback_short";
            return s;
           }
        }

      return s;
     }
  };

#endif
