#ifndef PROTRADER_ISTRATEGY_MQH
#define PROTRADER_ISTRATEGY_MQH

#include "../Types.mqh"
#include "../Market/SymbolProfile.mqh"

void PT_ClearSignal(StrategySignal &s)
  {
   s.dir = PT_DIR_NONE;
   s.score = 0;
   s.sl_price = 0;
   s.tp_price = 0;
   s.reason = "";
   s.tag = "";
  }

double PT_ATR_SL(const ENUM_PT_DIR dir, const double entry, const double atr,
                 const double atr_mult, const double structure_price)
  {
   double dist = atr * atr_mult;
   if(dir == PT_DIR_BUY)
     {
      double sl = entry - dist;
      if(structure_price > 0 && structure_price < entry)
         sl = MathMin(sl, structure_price);
      return sl;
     }
   if(dir == PT_DIR_SELL)
     {
      double sl = entry + dist;
      if(structure_price > 0 && structure_price > entry)
         sl = MathMax(sl, structure_price);
      return sl;
     }
   return 0;
  }

double PT_TP_From_R(const ENUM_PT_DIR dir, const double entry, const double sl, const double r_mult)
  {
   double r = MathAbs(entry - sl);
   if(r <= 0) return 0;
   if(dir == PT_DIR_BUY)  return entry + r * r_mult;
   if(dir == PT_DIR_SELL) return entry - r * r_mult;
   return 0;
  }

// Base strategy interface (concrete defaults for MQL5 compatibility)
class IStrategy
  {
public:
   virtual          ~IStrategy(void) {}
   virtual string    Name(void) const { return "IStrategy"; }
   virtual bool      Init(const string symbol, const PTSymbolProfile &profile) { return true; }
   virtual void      Release(void) {}
   virtual StrategySignal Evaluate(const ENUM_PT_REGIME regime,
                                   const ENUM_PT_DIR htf_bias,
                                   const ENUM_PT_MODE mode,
                                   const double atr)
     {
      StrategySignal s;
      PT_ClearSignal(s);
      return s;
     }
  };

#endif
