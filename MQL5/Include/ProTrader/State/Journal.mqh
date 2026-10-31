#ifndef PROTRADER_JOURNAL_MQH
#define PROTRADER_JOURNAL_MQH

void PT_Log(const string module, const string msg)
  {
   PrintFormat("[ProTrader][%s] %s", module, msg);
  }

void PT_LogBlock(const string symbol, const string reason)
  {
   PrintFormat("[ProTrader][BLOCK] %s | %s", symbol, reason);
  }

void PT_LogSignal(const string symbol, const string tag, const int dir, const double score,
                  const double sl, const double tp)
  {
   PrintFormat("[ProTrader][SIGNAL] %s tag=%s dir=%d score=%.1f sl=%.5f tp=%.5f",
               symbol, tag, dir, score, sl, tp);
  }

void PT_LogTrade(const string action, const string symbol, const double lots,
                 const double price, const double sl, const double tp, const string comment)
  {
   PrintFormat("[ProTrader][TRADE] %s %s lots=%.2f price=%.5f sl=%.5f tp=%.5f | %s",
               action, symbol, lots, price, sl, tp, comment);
  }

#endif
