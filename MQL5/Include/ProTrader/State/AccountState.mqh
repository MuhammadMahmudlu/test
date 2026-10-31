#ifndef PROTRADER_ACCOUNT_STATE_MQH
#define PROTRADER_ACCOUNT_STATE_MQH

#include "../Types.mqh"
#include "../Config.mqh"
#include "Journal.mqh"

class CAccountState
  {
private:
   PTConfig          m_cfg;
   double            m_start_equity;
   double            m_day_start_equity;
   int               m_day_stamp;          // yyyymmdd
   int               m_consecutive_losses;
   datetime          m_cooldown_until;
   long              m_magic;

public:
                     CAccountState(void)
     {
      m_start_equity = 0;
      m_day_start_equity = 0;
      m_day_stamp = 0;
      m_consecutive_losses = 0;
      m_cooldown_until = 0;
      m_magic = 0;
     }

   void              Init(const PTConfig &cfg)
     {
      m_cfg = cfg;
      m_magic = cfg.magic;
      m_start_equity = AccountInfoDouble(ACCOUNT_EQUITY);
      if(m_start_equity <= 0)
         m_start_equity = AccountInfoDouble(ACCOUNT_BALANCE);
      m_day_start_equity = m_start_equity;
      m_day_stamp = PT_DayStamp(TimeCurrent());
      m_consecutive_losses = 0;
      m_cooldown_until = 0;
      PT_Log("AccountState", StringFormat("start_equity=%.2f floor=%.2f",
             m_start_equity, EquityFloor()));
     }

   double            StartEquity(void) const { return m_start_equity; }

   double            EquityFloor(void) const
     {
      return MathMax(m_cfg.min_equity_floor_usd, m_start_equity * m_cfg.equity_floor_pct);
     }

   ENUM_PT_MODE      CurrentMode(const double equity) const
     {
      // Aggressive recovery while equity is small; growth otherwise
      if(m_cfg.risk_mode == PT_RISK_RECOVERY_AGGRESSIVE)
        {
         if(equity < 100.0)
            return PT_MODE_RECOVERY;
         return PT_MODE_GROWTH;
        }
      // Balanced: recovery only under 50
      if(equity < 50.0)
         return PT_MODE_RECOVERY;
      return PT_MODE_GROWTH;
     }

   int               MaxOpenPositions(const double equity) const
     {
      if(equity < 100.0) return 1;
      if(equity < 500.0) return 2;
      return 3;
     }

   void              OnTimerDayRoll(void)
     {
      int stamp = PT_DayStamp(TimeCurrent());
      if(stamp != m_day_stamp)
        {
         m_day_stamp = stamp;
         m_day_start_equity = AccountInfoDouble(ACCOUNT_EQUITY);
         PT_Log("AccountState", StringFormat("new day equity_start=%.2f", m_day_start_equity));
        }
     }

   void              RegisterClosedTrade(const double profit)
     {
      if(profit < 0.0)
        {
         m_consecutive_losses++;
         if(m_consecutive_losses >= m_cfg.max_consecutive_losses)
           {
            int mins = m_cfg.cooldown_min_minutes;
            // stretch cooldown with consecutive losses
            int extra = (m_consecutive_losses - m_cfg.max_consecutive_losses) * 15;
            mins = MathMin(m_cfg.cooldown_max_minutes, mins + extra);
            m_cooldown_until = TimeCurrent() + mins * 60;
            PT_Log("AccountState", StringFormat("cooldown %d min after %d losses",
                   mins, m_consecutive_losses));
           }
        }
      else if(profit > 0.0)
        {
         m_consecutive_losses = 0;
        }
     }

   void              Snapshot(AccountSnapshot &out)
     {
      OnTimerDayRoll();
      out.balance = AccountInfoDouble(ACCOUNT_BALANCE);
      out.equity = AccountInfoDouble(ACCOUNT_EQUITY);
      out.margin = AccountInfoDouble(ACCOUNT_MARGIN);
      out.free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      out.daily_pnl = out.equity - m_day_start_equity;
      out.open_positions = CountMagicPositions();
      out.consecutive_losses = m_consecutive_losses;
      out.cooldown_until = m_cooldown_until;
      out.mode = CurrentMode(out.equity);
      out.equity_floor = EquityFloor();
      out.start_equity = m_start_equity;
     }

   int               CountMagicPositions(const string symbol_filter = "")
     {
      int count = 0;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         ulong ticket = PositionGetTicket(i);
         if(ticket == 0) continue;
         if(!PositionSelectByTicket(ticket)) continue;
         if((long)PositionGetInteger(POSITION_MAGIC) != m_magic) continue;
         if(symbol_filter != "" && PositionGetString(POSITION_SYMBOL) != symbol_filter) continue;
         count++;
        }
      return count;
     }

   bool              HasPositionOnSymbol(const string symbol)
     {
      return CountMagicPositions(symbol) > 0;
     }

   static int        PT_DayStamp(const datetime t)
     {
      MqlDateTime dt;
      TimeToStruct(t, dt);
      return dt.year * 10000 + dt.mon * 100 + dt.day;
     }
  };

#endif
