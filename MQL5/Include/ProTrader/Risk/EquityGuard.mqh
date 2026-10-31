#ifndef PROTRADER_EQUITY_GUARD_MQH
#define PROTRADER_EQUITY_GUARD_MQH

#include "../Types.mqh"
#include "../Config.mqh"
#include "../State/AccountState.mqh"
#include "../State/Journal.mqh"

class CEquityGuard
  {
private:
   PTConfig          m_cfg;
   CAccountState    *m_state;

public:
                     CEquityGuard(void) : m_state(NULL) {}

   void              Bind(const PTConfig &cfg, CAccountState &state)
     {
      m_cfg = cfg;
      m_state = &state;
     }

   GuardResult       AllowNewEntries(void)
     {
      GuardResult g;
      g.ok = false;
      g.reason = "";

      if(m_state == NULL)
        {
         g.reason = "state_null";
         return g;
        }

      AccountSnapshot snap;
      m_state.Snapshot(snap);

      if(snap.equity <= snap.equity_floor)
        {
         g.reason = StringFormat("equity_floor equity=%.2f floor=%.2f", snap.equity, snap.equity_floor);
         return g;
        }

      if(snap.cooldown_until > TimeCurrent())
        {
         g.reason = StringFormat("cooldown_until=%s", TimeToString(snap.cooldown_until, TIME_DATE|TIME_MINUTES));
         return g;
        }

      double daily_limit = MathAbs(snap.start_equity > 0 ? m_state.StartEquity() : snap.equity) * (m_cfg.daily_loss_pct / 100.0);
      // Use day start via daily_pnl: if daily_pnl <= -limit, block
      // Recompute against current equity vs implied day start
      if(snap.daily_pnl <= -daily_limit && daily_limit > 0)
        {
         g.reason = StringFormat("daily_loss_limit pnl=%.2f limit=%.2f", snap.daily_pnl, daily_limit);
         return g;
        }

      int max_pos = m_state.MaxOpenPositions(snap.equity);
      if(snap.open_positions >= max_pos)
        {
         g.reason = StringFormat("max_positions open=%d max=%d", snap.open_positions, max_pos);
         return g;
        }

      if(snap.equity > 0 && snap.margin > 0)
        {
         double usage = 100.0 * snap.margin / snap.equity;
         if(usage >= m_cfg.max_margin_usage_pct)
           {
            g.reason = StringFormat("margin_usage=%.1f%% >= %.1f%%", usage, m_cfg.max_margin_usage_pct);
            return g;
           }
        }

      if(snap.free_margin <= 0)
        {
         g.reason = "free_margin_zero";
         return g;
        }

      g.ok = true;
      g.reason = "ok";
      return g;
     }

   GuardResult       AllowSymbol(const string symbol)
     {
      GuardResult g = AllowNewEntries();
      if(!g.ok)
         return g;

      if(m_state.HasPositionOnSymbol(symbol))
        {
         g.ok = false;
         g.reason = "already_in_symbol";
         return g;
        }

      g.ok = true;
      g.reason = "ok";
      return g;
     }
  };

#endif
