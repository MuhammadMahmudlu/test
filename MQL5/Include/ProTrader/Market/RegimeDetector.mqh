#ifndef PROTRADER_REGIME_DETECTOR_MQH
#define PROTRADER_REGIME_DETECTOR_MQH

#include "../Types.mqh"
#include "../State/Journal.mqh"

class CRegimeDetector
  {
private:
   int               m_atr_handle;
   int               m_adx_handle;
   int               m_ema_fast_handle;
   int               m_ema_slow_handle;
   string            m_symbol;
   ENUM_TIMEFRAMES   m_tf;

   bool              CopyBuf(const int handle, const int buf, const int count, double &out[])
     {
      ArraySetAsSeries(out, true);
      if(handle == INVALID_HANDLE)
         return false;
      return (CopyBuffer(handle, buf, 0, count, out) == count);
     }

public:
                     CRegimeDetector(void)
     {
      m_atr_handle = INVALID_HANDLE;
      m_adx_handle = INVALID_HANDLE;
      m_ema_fast_handle = INVALID_HANDLE;
      m_ema_slow_handle = INVALID_HANDLE;
      m_symbol = "";
      m_tf = PERIOD_M15;
     }

                    ~CRegimeDetector(void) { Release(); }

   void              Release(void)
     {
      if(m_atr_handle != INVALID_HANDLE) { IndicatorRelease(m_atr_handle); m_atr_handle = INVALID_HANDLE; }
      if(m_adx_handle != INVALID_HANDLE) { IndicatorRelease(m_adx_handle); m_adx_handle = INVALID_HANDLE; }
      if(m_ema_fast_handle != INVALID_HANDLE) { IndicatorRelease(m_ema_fast_handle); m_ema_fast_handle = INVALID_HANDLE; }
      if(m_ema_slow_handle != INVALID_HANDLE) { IndicatorRelease(m_ema_slow_handle); m_ema_slow_handle = INVALID_HANDLE; }
     }

   bool              Init(const string symbol, const ENUM_TIMEFRAMES tf = PERIOD_M15)
     {
      Release();
      m_symbol = symbol;
      m_tf = tf;
      m_atr_handle = iATR(symbol, tf, 14);
      m_adx_handle = iADX(symbol, tf, 14);
      m_ema_fast_handle = iMA(symbol, tf, 21, 0, MODE_EMA, PRICE_CLOSE);
      m_ema_slow_handle = iMA(symbol, tf, 55, 0, MODE_EMA, PRICE_CLOSE);
      return (m_atr_handle != INVALID_HANDLE && m_adx_handle != INVALID_HANDLE &&
              m_ema_fast_handle != INVALID_HANDLE && m_ema_slow_handle != INVALID_HANDLE);
     }

   ENUM_PT_REGIME    Detect(void)
     {
      double atr[], adx[], ema_f[], ema_s[];
      if(!CopyBuf(m_atr_handle, 0, 50, atr)) return PT_REGIME_DEAD;
      if(!CopyBuf(m_adx_handle, 0, 5, adx)) return PT_REGIME_DEAD;
      if(!CopyBuf(m_ema_fast_handle, 0, 5, ema_f)) return PT_REGIME_DEAD;
      if(!CopyBuf(m_ema_slow_handle, 0, 5, ema_s)) return PT_REGIME_DEAD;

      // ATR percentile vs last 50
      double cur = atr[0];
      int below = 0;
      for(int i=0; i<50; i++)
         if(atr[i] <= cur) below++;
      double pct = 100.0 * below / 50.0;

      double adx_now = adx[0];
      double slope = ema_f[0] - ema_f[2];
      double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
      if(point <= 0) point = _Point;

      bool dead = (pct < 15.0 && MathAbs(slope) < 5.0 * point);
      if(dead)
         return PT_REGIME_DEAD;

      if(pct > 85.0 || adx_now > 35.0)
         return PT_REGIME_VOLATILE;

      if(adx_now >= 22.0 && MathAbs(ema_f[0] - ema_s[0]) > 10.0 * point)
         return PT_REGIME_TREND;

      return PT_REGIME_RANGE;
     }

   ENUM_PT_DIR       HTFBias(const ENUM_TIMEFRAMES htf = PERIOD_H1)
     {
      int ema_f = iMA(m_symbol, htf, 21, 0, MODE_EMA, PRICE_CLOSE);
      int ema_s = iMA(m_symbol, htf, 55, 0, MODE_EMA, PRICE_CLOSE);
      if(ema_f == INVALID_HANDLE || ema_s == INVALID_HANDLE)
         return PT_DIR_NONE;

      double f[], s[];
      ArraySetAsSeries(f, true);
      ArraySetAsSeries(s, true);
      bool ok = (CopyBuffer(ema_f, 0, 0, 3, f) == 3 && CopyBuffer(ema_s, 0, 0, 3, s) == 3);
      IndicatorRelease(ema_f);
      IndicatorRelease(ema_s);
      if(!ok) return PT_DIR_NONE;

      if(f[0] > s[0] && f[0] >= f[1]) return PT_DIR_BUY;
      if(f[0] < s[0] && f[0] <= f[1]) return PT_DIR_SELL;
      return PT_DIR_NONE;
     }

   double            ATR(const int shift = 0)
     {
      double atr[];
      if(!CopyBuf(m_atr_handle, 0, shift + 1, atr))
         return 0;
      return atr[shift];
     }
  };

#endif
