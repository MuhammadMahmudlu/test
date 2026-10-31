#ifndef PROTRADER_ORDER_ROUTER_MQH
#define PROTRADER_ORDER_ROUTER_MQH

#include <Trade/Trade.mqh>
#include "../Types.mqh"
#include "../Config.mqh"
#include "../State/Journal.mqh"

class COrderRouter
  {
private:
   CTrade            m_trade;
   PTConfig          m_cfg;

public:
   void              Init(const PTConfig &cfg)
     {
      m_cfg = cfg;
      m_trade.SetExpertMagicNumber(cfg.magic);
      m_trade.SetDeviationInPoints(cfg.slippage_points);
      m_trade.SetTypeFillingBySymbol(_Symbol);
      m_trade.LogLevel(LOG_LEVEL_ERRORS);
     }

   void              PrepareSymbol(const string symbol)
     {
      m_trade.SetExpertMagicNumber(m_cfg.magic);
      m_trade.SetDeviationInPoints(m_cfg.slippage_points);
      m_trade.SetTypeFillingBySymbol(symbol);
     }

   bool              OpenMarket(const string symbol,
                                const ENUM_PT_DIR dir,
                                const double lots,
                                const double sl,
                                const double tp,
                                const string comment,
                                ulong &ticket_out)
     {
      ticket_out = 0;
      if(sl <= 0)
        {
         PT_Log("OrderRouter", "REFUSE open without SL");
         return false;
        }

      PrepareSymbol(symbol);
      bool ok = false;
      if(dir == PT_DIR_BUY)
         ok = m_trade.Buy(lots, symbol, 0.0, sl, tp, comment);
      else if(dir == PT_DIR_SELL)
         ok = m_trade.Sell(lots, symbol, 0.0, sl, tp, comment);
      else
         return false;

      if(!ok)
        {
         PT_Log("OrderRouter", StringFormat("open_failed ret=%d %s",
                m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription()));
         return false;
        }

      ticket_out = m_trade.ResultOrder();
      // Prefer position ticket if available
      if(m_trade.ResultDeal() > 0)
        {
         // resolve position by symbol+magic shortly after
         for(int i=PositionsTotal()-1; i>=0; i--)
           {
            ulong t = PositionGetTicket(i);
            if(!PositionSelectByTicket(t)) continue;
            if(PositionGetString(POSITION_SYMBOL) == symbol &&
               (long)PositionGetInteger(POSITION_MAGIC) == m_cfg.magic)
              {
               ticket_out = t;
               break;
              }
           }
        }

      PT_LogTrade("OPEN", symbol, lots, m_trade.ResultPrice(), sl, tp, comment);
      return true;
     }

   bool              ModifySLTP(const ulong ticket, const double sl, const double tp)
     {
      if(!PositionSelectByTicket(ticket))
         return false;
      string symbol = PositionGetString(POSITION_SYMBOL);
      PrepareSymbol(symbol);
      bool ok = m_trade.PositionModify(ticket, sl, tp);
      if(!ok)
         PT_Log("OrderRouter", StringFormat("modify_failed ticket=%s ret=%d",
                IntegerToString((long)ticket), m_trade.ResultRetcode()));
      return ok;
     }

   bool              ClosePartial(const ulong ticket, const double lots)
     {
      if(!PositionSelectByTicket(ticket))
         return false;
      string symbol = PositionGetString(POSITION_SYMBOL);
      PrepareSymbol(symbol);
      bool ok = m_trade.PositionClosePartial(ticket, lots);
      if(!ok)
         PT_Log("OrderRouter", StringFormat("partial_close_failed ticket=%s", IntegerToString((long)ticket)));
      return ok;
     }

   bool              CloseFull(const ulong ticket)
     {
      if(!PositionSelectByTicket(ticket))
         return false;
      string symbol = PositionGetString(POSITION_SYMBOL);
      double vol = PositionGetDouble(POSITION_VOLUME);
      PrepareSymbol(symbol);
      bool ok = m_trade.PositionClose(ticket);
      if(!ok)
         PT_Log("OrderRouter", StringFormat("close_failed ticket=%s", IntegerToString((long)ticket)));
      else
         PT_LogTrade("CLOSE", symbol, vol,
                     SymbolInfoDouble(symbol, SYMBOL_BID), 0, 0, "manual_or_time");
      return ok;
     }

   CTrade           *Trade(void) { return &m_trade; }
  };

#endif
