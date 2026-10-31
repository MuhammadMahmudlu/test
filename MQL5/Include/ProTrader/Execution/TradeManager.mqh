#ifndef PROTRADER_TRADE_MANAGER_MQH
#define PROTRADER_TRADE_MANAGER_MQH

#include "OrderRouter.mqh"
#include "../Config.mqh"
#include "../Types.mqh"
#include "../Market/SymbolProfile.mqh"
#include "../State/AccountState.mqh"
#include "../State/Journal.mqh"

struct PTManagedPosition
  {
   ulong             ticket;
   string            symbol;
   ENUM_PT_DIR       dir;
   double            open_price;
   double            volume;
   double            sl;
   double            tp;
   double            initial_r;
   datetime          open_time;
   bool              be_done;
   bool              partial_done;
   ENUM_PT_MODE      mode_at_entry;
  };

class CTradeManager
  {
private:
   PTConfig          m_cfg;
   COrderRouter      m_router;
   CAccountState    *m_state;
   PTManagedPosition m_pos[];
   int               m_last_deal_count;

   int               FindLocal(const ulong ticket)
     {
      for(int i=0; i<ArraySize(m_pos); i++)
         if(m_pos[i].ticket == ticket)
            return i;
      return -1;
     }

   void              SyncFromTerminal(void)
     {
      // Add new positions
      for(int i=PositionsTotal()-1; i>=0; i--)
        {
         ulong ticket = PositionGetTicket(i);
         if(ticket == 0) continue;
         if(!PositionSelectByTicket(ticket)) continue;
         if((long)PositionGetInteger(POSITION_MAGIC) != m_cfg.magic) continue;
         if(FindLocal(ticket) >= 0) continue;

         int n = ArraySize(m_pos);
         ArrayResize(m_pos, n + 1);
         m_pos[n].ticket = ticket;
         m_pos[n].symbol = PositionGetString(POSITION_SYMBOL);
         long type = PositionGetInteger(POSITION_TYPE);
         m_pos[n].dir = (type == POSITION_TYPE_BUY ? PT_DIR_BUY : PT_DIR_SELL);
         m_pos[n].open_price = PositionGetDouble(POSITION_PRICE_OPEN);
         m_pos[n].volume = PositionGetDouble(POSITION_VOLUME);
         m_pos[n].sl = PositionGetDouble(POSITION_SL);
         m_pos[n].tp = PositionGetDouble(POSITION_TP);
         m_pos[n].open_time = (datetime)PositionGetInteger(POSITION_TIME);
         m_pos[n].be_done = false;
         m_pos[n].partial_done = false;
         m_pos[n].mode_at_entry = PT_MODE_RECOVERY;
         double sl = m_pos[n].sl;
         m_pos[n].initial_r = MathAbs(m_pos[n].open_price - sl);
         if(m_state != NULL)
           {
            AccountSnapshot snap;
            m_state.Snapshot(snap);
            m_pos[n].mode_at_entry = snap.mode;
           }
        }

      // Drop closed
      for(int i=ArraySize(m_pos)-1; i>=0; i--)
        {
         if(!PositionSelectByTicket(m_pos[i].ticket))
            RemoveAt(i);
        }
     }

   void              RemoveAt(const int idx)
     {
      int n = ArraySize(m_pos);
      if(idx < 0 || idx >= n) return;
      for(int j=idx; j<n-1; j++)
         m_pos[j] = m_pos[j+1];
      ArrayResize(m_pos, n - 1);
     }

   void              HarvestClosedPnL(void)
     {
      // Scan recent history for magic deals to update consecutive losses
      datetime from = TimeCurrent() - 86400;
      if(!HistorySelect(from, TimeCurrent()))
         return;

      int deals = HistoryDealsTotal();
      for(int i=deals-1; i>=0; i--)
        {
         ulong deal = HistoryDealGetTicket(i);
         if(deal == 0) continue;
         if((long)HistoryDealGetInteger(deal, DEAL_MAGIC) != m_cfg.magic) continue;
         long entry = HistoryDealGetInteger(deal, DEAL_ENTRY);
         if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_OUT_BY)
            continue;
         // Use deal comment marker via time uniqueness — store last processed in comment field not available
         // Simple approach: check DEAL_TIME vs last processed using static set is hard; use POSITION_ID profit aggregation once
        }
      // Fallback handled in OnTradeTransaction from EA
     }

public:
                     CTradeManager(void) : m_state(NULL), m_last_deal_count(0)
     {
      ArrayResize(m_pos, 0);
     }

   void              Init(const PTConfig &cfg, CAccountState &state)
     {
      m_cfg = cfg;
      m_state = &state;
      m_router.Init(cfg);
      ArrayResize(m_pos, 0);
      SyncFromTerminal();
     }

   COrderRouter     *Router(void) { return &m_router; }

   bool              ExecuteSetup(const string symbol,
                                  const PTSymbolProfile &profile,
                                  const ConfluenceResult &setup,
                                  const RiskDecision &risk,
                                  const ENUM_PT_MODE mode)
     {
      if(!setup.valid || !risk.allowed)
         return false;
      if(risk.sl_price <= 0)
        {
         PT_Log("TradeManager", "hard_refuse_no_sl");
         return false;
        }

      double entry = (setup.dir == PT_DIR_BUY)
                     ? SymbolInfoDouble(symbol, SYMBOL_ASK)
                     : SymbolInfoDouble(symbol, SYMBOL_BID);

      string comment = StringFormat("PT|%s|%.0f|%s",
                                    setup.primary_tag,
                                    setup.score,
                                    (mode == PT_MODE_RECOVERY ? "R" : "G"));

      ulong ticket = 0;
      if(!m_router.OpenMarket(symbol, setup.dir, risk.lots, risk.sl_price, risk.tp_price, comment, ticket))
         return false;

      SyncFromTerminal();
      int idx = FindLocal(ticket);
      if(idx >= 0)
         m_pos[idx].mode_at_entry = mode;

      PT_LogSignal(symbol, setup.primary_tag, (int)setup.dir, setup.score, risk.sl_price, risk.tp_price);
      return true;
     }

   void              ManageOpen(void)
     {
      SyncFromTerminal();

      for(int i=ArraySize(m_pos)-1; i>=0; i--)
        {
         if(!PositionSelectByTicket(m_pos[i].ticket))
           {
            RemoveAt(i);
            continue;
           }

         string symbol = m_pos[i].symbol;
         double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
         double volume = PositionGetDouble(POSITION_VOLUME);
         double sl = PositionGetDouble(POSITION_SL);
         double tp = PositionGetDouble(POSITION_TP);
         datetime open_time = (datetime)PositionGetInteger(POSITION_TIME);
         long type = PositionGetInteger(POSITION_TYPE);
         ENUM_PT_DIR dir = (type == POSITION_TYPE_BUY ? PT_DIR_BUY : PT_DIR_SELL);

         double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
         double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
         double price = (dir == PT_DIR_BUY ? bid : ask);

         double initial_r = m_pos[i].initial_r;
         if(initial_r <= 0 && sl > 0)
            initial_r = MathAbs(open_price - sl);
         if(initial_r <= 0)
            continue;

         double favor = (dir == PT_DIR_BUY ? (price - open_price) : (open_price - price));
         double r_now = favor / initial_r;

         // Partial 50% at 1R
         if(!m_pos[i].partial_done && r_now >= 1.0 && volume > SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN))
           {
            double step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
            double half = MathFloor((volume * 0.5) / step) * step;
            double min_lot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
            if(half >= min_lot && volume - half >= min_lot - 1e-8)
              {
               if(m_router.ClosePartial(m_pos[i].ticket, half))
                 {
                  m_pos[i].partial_done = true;
                  PT_Log("TradeManager", StringFormat("partial_1R ticket=%s", IntegerToString((long)m_pos[i].ticket)));
                 }
              }
            else
               m_pos[i].partial_done = true; // can't partial — mark done
           }

         // Break-even after trigger R
         if(!m_pos[i].be_done && r_now >= m_cfg.be_trigger_r)
           {
            double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
            int stops = (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
            double be = open_price;
            if(dir == PT_DIR_BUY)
               be = open_price + MathMax(stops, 2) * point;
            else
               be = open_price - MathMax(stops, 2) * point;

            bool improve = (dir == PT_DIR_BUY && (sl < be || sl == 0)) ||
                           (dir == PT_DIR_SELL && (sl > be || sl == 0));
            if(improve)
              {
               if(m_router.ModifySLTP(m_pos[i].ticket, be, tp))
                 {
                  m_pos[i].be_done = true;
                  m_pos[i].sl = be;
                  PT_Log("TradeManager", StringFormat("BE ticket=%s", IntegerToString((long)m_pos[i].ticket)));
                 }
              }
            else
               m_pos[i].be_done = true;
           }

         // ATR trail after trail_trigger_r
         if(r_now >= m_cfg.trail_trigger_r)
           {
            int atr_h = iATR(symbol, PERIOD_M5, 14);
            double atr_buf[];
            ArraySetAsSeries(atr_buf, true);
            double atr = 0;
            if(atr_h != INVALID_HANDLE && CopyBuffer(atr_h, 0, 0, 2, atr_buf) >= 2)
               atr = atr_buf[0];
            if(atr_h != INVALID_HANDLE)
               IndicatorRelease(atr_h);

            if(atr > 0)
              {
               double trail = atr * m_cfg.trail_atr_mult;
               double new_sl = sl;
               if(dir == PT_DIR_BUY)
                 {
                  new_sl = price - trail;
                  if(new_sl > sl && new_sl < price)
                    {
                     if(m_router.ModifySLTP(m_pos[i].ticket, new_sl, tp))
                        m_pos[i].sl = new_sl;
                    }
                 }
               else
                 {
                  new_sl = price + trail;
                  if((sl == 0 || new_sl < sl) && new_sl > price)
                    {
                     if(m_router.ModifySLTP(m_pos[i].ticket, new_sl, tp))
                        m_pos[i].sl = new_sl;
                    }
                 }
              }
           }

         // Time stop
         int max_min = (m_pos[i].mode_at_entry == PT_MODE_RECOVERY)
                       ? m_cfg.scalp_max_minutes
                       : m_cfg.daytrade_max_minutes;
         if(max_min > 0 && (TimeCurrent() - open_time) >= max_min * 60)
           {
            PT_Log("TradeManager", StringFormat("time_stop ticket=%s age_min=%d",
                   IntegerToString((long)m_pos[i].ticket), (int)((TimeCurrent() - open_time) / 60)));
            m_router.CloseFull(m_pos[i].ticket);
            continue;
           }

         // Friday flatten
         if(m_cfg.flatten_before_friday_close)
           {
            MqlDateTime dt;
            TimeToStruct(TimeCurrent(), dt);
            if(dt.day_of_week == 5 && dt.hour >= m_cfg.friday_flatten_hour_server)
              {
               PT_Log("TradeManager", "friday_flatten");
               m_router.CloseFull(m_pos[i].ticket);
              }
           }
        }
     }

   void              OnClosedDealProfit(const double profit)
     {
      if(m_state != NULL)
         m_state.RegisterClosedTrade(profit);
     }
  };

#endif
