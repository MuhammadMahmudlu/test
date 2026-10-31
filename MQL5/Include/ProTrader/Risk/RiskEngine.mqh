#ifndef PROTRADER_RISK_ENGINE_MQH
#define PROTRADER_RISK_ENGINE_MQH

#include "EquityGuard.mqh"
#include "LotSizer.mqh"
#include "../Market/SymbolProfile.mqh"
#include "../State/AccountState.mqh"
#include "../State/Journal.mqh"

class CRiskEngine
  {
private:
   PTConfig          m_cfg;
   CEquityGuard      m_guard;
   CLotSizer         m_lots;
   CAccountState    *m_state;

public:
                     CRiskEngine(void) : m_state(NULL) {}

   void              Init(const PTConfig &cfg, CAccountState &state)
     {
      m_cfg = cfg;
      m_state = &state;
      m_guard.Bind(cfg, state);
      m_lots.Bind(cfg);
     }

   CEquityGuard     *Guard(void) { return &m_guard; }
   CLotSizer        *Lots(void)  { return &m_lots; }

   RiskDecision      EvaluateEntry(const string symbol,
                                   const PTSymbolProfile &profile,
                                   const ConfluenceResult &setup,
                                   const double entry_price)
     {
      RiskDecision d;
      d.allowed = false;
      d.lots = 0;
      d.block_reason = "";

      GuardResult g = m_guard.AllowSymbol(symbol);
      if(!g.ok)
        {
         d.block_reason = g.reason;
         return d;
        }

      if(!setup.valid || setup.dir == PT_DIR_NONE)
        {
         d.block_reason = "setup_invalid";
         return d;
        }

      if(setup.sl_price <= 0)
        {
         d.block_reason = "sl_mandatory_missing";
         return d;
        }

      AccountSnapshot snap;
      m_state.Snapshot(snap);

      // Recovery mode: prefer tighter scalp R; Growth: allow wider
      double sl = setup.sl_price;
      double tp = setup.tp_price;

      // Ensure SL on correct side
      if(setup.dir == PT_DIR_BUY && sl >= entry_price)
        {
         d.block_reason = "buy_sl_not_below_entry";
         return d;
        }
      if(setup.dir == PT_DIR_SELL && sl <= entry_price)
        {
         d.block_reason = "sell_sl_not_above_entry";
         return d;
        }

      // If TP missing, synthesize from mode R-multiple
      if(tp <= 0)
        {
         double r = MathAbs(entry_price - sl);
         double mult = (snap.mode == PT_MODE_RECOVERY ? 1.5 : 2.5);
         tp = (setup.dir == PT_DIR_BUY) ? entry_price + mult * r : entry_price - mult * r;
        }

      d = m_lots.Build(symbol, snap, profile, setup.dir, entry_price, sl, tp);
      return d;
     }
  };

#endif
