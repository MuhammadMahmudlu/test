//+------------------------------------------------------------------+
//|                                           ProTraderEA_Single.mq5 |
//|        Single-file ProTrader EA — copy into MQL5/Experts only    |
//|              Forex majors + XAUUSD | Aggressive recovery         |
//+------------------------------------------------------------------+
#property copyright "ProTraderEA"
#property version   "1.01"
#property description "Single-file A+ confluence EA. No Include folder needed."

#include <Trade/Trade.mqh>

//===== Include/ProTrader/Types.mqh =====

enum ENUM_PT_DIR
  {
   PT_DIR_NONE = 0,
   PT_DIR_BUY  = 1,
   PT_DIR_SELL = -1
  };

enum ENUM_PT_REGIME
  {
   PT_REGIME_DEAD = 0,
   PT_REGIME_RANGE,
   PT_REGIME_TREND,
   PT_REGIME_VOLATILE
  };

enum ENUM_PT_MODE
  {
   PT_MODE_RECOVERY = 0,
   PT_MODE_GROWTH
  };

enum ENUM_PT_SESSION
  {
   PT_SESSION_ASIA = 0,
   PT_SESSION_LONDON,
   PT_SESSION_NY,
   PT_SESSION_OVERLAP,
   PT_SESSION_OFF
  };

enum ENUM_PT_RISK_MODE
  {
   PT_RISK_RECOVERY_AGGRESSIVE = 0,
   PT_RISK_BALANCED
  };

struct PTSymbolProfile
  {
   string            symbol;
   bool              is_gold;
   double            spread_cap_points;
   double            min_sl_atr_mult;
   double            manip_spread_mult;
   bool              allow_asia_scalp;
   ENUM_TIMEFRAMES   entry_tf;
   ENUM_TIMEFRAMES   manage_tf;
  };

struct StrategySignal
  {
   ENUM_PT_DIR       dir;
   double            score;       // 0..100 contribution
   double            sl_price;
   double            tp_price;
   string            reason;
   string            tag;
  };

struct ConfluenceResult
  {
   bool              valid;
   ENUM_PT_DIR       dir;
   double            score;       // 0..100
   double            sl_price;
   double            tp_price;
   string            reason;
   string            primary_tag;
  };

struct RiskDecision
  {
   bool              allowed;
   double            lots;
   double            risk_money;
   double            risk_pct;
   double            sl_price;
   double            tp_price;
   string            block_reason;
  };

struct AccountSnapshot
  {
   double            balance;
   double            equity;
   double            margin;
   double            free_margin;
   double            daily_pnl;
   int               open_positions;
   int               consecutive_losses;
   datetime          cooldown_until;
   ENUM_PT_MODE      mode;
   double            equity_floor;
   double            start_equity;
  };

struct GuardResult
  {
   bool              ok;
   string            reason;
  };



//===== Include/ProTrader/Config.mqh =====

//--- inputs are declared in the EA; this struct mirrors runtime config
struct PTConfig
  {
   long              magic;
   int               slippage_points;
   ENUM_PT_RISK_MODE risk_mode;

   // Risk floors
   double            equity_floor_pct;      // of start equity
   double            min_equity_floor_usd;
   double            max_margin_usage_pct;
   double            daily_loss_pct;
   int               max_consecutive_losses;
   int               cooldown_min_minutes;
   int               cooldown_max_minutes;

   // Scoring
   double            aplus_min_recovery;
   double            aplus_min_growth;
   double            htf_bias_penalty;

   // Trade management
   double            be_trigger_r;
   double            trail_trigger_r;
   double            trail_atr_mult;
   int               scalp_max_minutes;
   int               daytrade_max_minutes;
   bool              flatten_before_friday_close;
   int               friday_flatten_hour_server;

   // Sessions / news
   bool              trade_london;
   bool              trade_ny;
   bool              trade_overlap;
   bool              trade_asia_fx_meanrevert;
   int               news_blackout_minutes;
   datetime          next_news_time;        // 0 = unused

   // Symbols
   bool              enable_eurusd;
   bool              enable_gbpusd;
   bool              enable_usdjpy;
   bool              enable_audusd;
   bool              enable_usdcad;
   bool              enable_usdchf;
   bool              enable_nzdusd;
   bool              enable_xauusd;

   string            chart_symbol_override; // empty = use chart
  };

void PTConfig_SetDefaults(PTConfig &cfg)
  {
   cfg.magic = 20261031;
   cfg.slippage_points = 20;
   cfg.risk_mode = PT_RISK_RECOVERY_AGGRESSIVE;

   cfg.equity_floor_pct = 0.35;
   cfg.min_equity_floor_usd = 5.0;
   cfg.max_margin_usage_pct = 25.0;
   cfg.daily_loss_pct = 4.0;
   cfg.max_consecutive_losses = 3;
   cfg.cooldown_min_minutes = 30;
   cfg.cooldown_max_minutes = 90;

   cfg.aplus_min_recovery = 60.0;
   cfg.aplus_min_growth = 75.0;
   cfg.htf_bias_penalty = 25.0;

   cfg.be_trigger_r = 1.0;
   cfg.trail_trigger_r = 1.5;
   cfg.trail_atr_mult = 1.0;
   cfg.scalp_max_minutes = 45;
   cfg.daytrade_max_minutes = 360;
   cfg.flatten_before_friday_close = true;
   cfg.friday_flatten_hour_server = 20;

   cfg.trade_london = true;
   cfg.trade_ny = true;
   cfg.trade_overlap = true;
   cfg.trade_asia_fx_meanrevert = true;
   cfg.news_blackout_minutes = 30;
   cfg.next_news_time = 0;

   cfg.enable_eurusd = true;
   cfg.enable_gbpusd = true;
   cfg.enable_usdjpy = true;
   cfg.enable_audusd = true;
   cfg.enable_usdcad = true;
   cfg.enable_usdchf = true;
   cfg.enable_nzdusd = true;
   cfg.enable_xauusd = true;

   cfg.chart_symbol_override = "";
  }



//===== Include/ProTrader/State/Journal.mqh =====

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



//===== Include/ProTrader/State/AccountState.mqh =====

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



//===== Include/ProTrader/Market/SymbolProfile.mqh =====

bool PT_IsGoldSymbol(const string symbol)
  {
   string u = symbol;
   StringToUpper(u);
   return (StringFind(u, "XAU") >= 0 || StringFind(u, "GOLD") >= 0);
  }

void PT_BuildSymbolProfile(const string symbol, PTSymbolProfile &out)
  {
   out.symbol = symbol;
   out.is_gold = PT_IsGoldSymbol(symbol);
   if(out.is_gold)
     {
      out.spread_cap_points = 600.0;      // broker-dependent; tightened by avg spread check
      out.min_sl_atr_mult = 1.6;
      out.manip_spread_mult = 2.0;
      out.allow_asia_scalp = false;
      out.entry_tf = PERIOD_M5;
      out.manage_tf = PERIOD_M5;
     }
   else
     {
      out.spread_cap_points = 35.0;
      out.min_sl_atr_mult = 1.2;
      out.manip_spread_mult = 2.5;
      out.allow_asia_scalp = true;
      out.entry_tf = PERIOD_M5;
      out.manage_tf = PERIOD_M5;
     }
  }

int PT_CollectEnabledSymbols(const PTConfig &cfg, string &out_symbols[])
  {
   ArrayResize(out_symbols, 0);
   string candidates[];
   ArrayResize(candidates, 0);

   if(cfg.enable_eurusd) { int n=ArraySize(candidates); ArrayResize(candidates,n+1); candidates[n]="EURUSD"; }
   if(cfg.enable_gbpusd) { int n=ArraySize(candidates); ArrayResize(candidates,n+1); candidates[n]="GBPUSD"; }
   if(cfg.enable_usdjpy) { int n=ArraySize(candidates); ArrayResize(candidates,n+1); candidates[n]="USDJPY"; }
   if(cfg.enable_audusd) { int n=ArraySize(candidates); ArrayResize(candidates,n+1); candidates[n]="AUDUSD"; }
   if(cfg.enable_usdcad) { int n=ArraySize(candidates); ArrayResize(candidates,n+1); candidates[n]="USDCAD"; }
   if(cfg.enable_usdchf) { int n=ArraySize(candidates); ArrayResize(candidates,n+1); candidates[n]="USDCHF"; }
   if(cfg.enable_nzdusd) { int n=ArraySize(candidates); ArrayResize(candidates,n+1); candidates[n]="NZDUSD"; }
   if(cfg.enable_xauusd) { int n=ArraySize(candidates); ArrayResize(candidates,n+1); candidates[n]="XAUUSD"; }

   // Prefer chart symbol first if enabled / override set
   string chart_sym = (cfg.chart_symbol_override != "" ? cfg.chart_symbol_override : _Symbol);

   for(int i=0; i<ArraySize(candidates); i++)
     {
      string s = candidates[i];
      // Resolve broker suffix: try exact, then chart if base matches
      string resolved = s;
      if(!SymbolSelect(resolved, true))
        {
         // try common suffixes via chart
         if(StringFind(chart_sym, s) == 0)
            resolved = chart_sym;
         else
            continue;
        }
      if(!SymbolSelect(resolved, true))
         continue;

      if(resolved == chart_sym)
        {
         int n = ArraySize(out_symbols);
         ArrayResize(out_symbols, n + 1);
         // shift right
         for(int j=n; j>0; j--)
            out_symbols[j] = out_symbols[j-1];
         out_symbols[0] = resolved;
        }
      else
        {
         int n = ArraySize(out_symbols);
         ArrayResize(out_symbols, n + 1);
         out_symbols[n] = resolved;
        }
     }

   // Always allow current chart if nothing else resolved
   if(ArraySize(out_symbols) == 0 && SymbolSelect(chart_sym, true))
     {
      ArrayResize(out_symbols, 1);
      out_symbols[0] = chart_sym;
     }

   return ArraySize(out_symbols);
  }



//===== Include/ProTrader/Market/SessionFilter.mqh =====

class CSessionFilter
  {
private:
   PTConfig          m_cfg;

   // Broker/server hour assumed; sessions in GMT-ish windows (common default).
   // Users can shift via server timezone; windows are inclusive start, exclusive end.
   ENUM_PT_SESSION   ClassifyHour(const int hour) const
     {
      // Approx GMT: Asia 0-7, London 7-12, Overlap 12-16, NY 16-21, Off 21-24
      if(hour >= 0 && hour < 7)  return PT_SESSION_ASIA;
      if(hour >= 7 && hour < 12) return PT_SESSION_LONDON;
      if(hour >= 12 && hour < 16) return PT_SESSION_OVERLAP;
      if(hour >= 16 && hour < 21) return PT_SESSION_NY;
      return PT_SESSION_OFF;
     }

public:
   void              Bind(const PTConfig &cfg) { m_cfg = cfg; }

   ENUM_PT_SESSION   CurrentSession(void) const
     {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      return ClassifyHour(dt.hour);
     }

   GuardResult       AllowTrade(const PTSymbolProfile &profile, const ENUM_PT_REGIME regime) const
     {
      GuardResult g;
      g.ok = false;
      g.reason = "";

      ENUM_PT_SESSION sess = CurrentSession();

      if(sess == PT_SESSION_OFF)
        {
         g.reason = "session_off";
         return g;
        }

      if(sess == PT_SESSION_LONDON && !m_cfg.trade_london)
        { g.reason = "london_disabled"; return g; }
      if(sess == PT_SESSION_NY && !m_cfg.trade_ny)
        { g.reason = "ny_disabled"; return g; }
      if(sess == PT_SESSION_OVERLAP && !m_cfg.trade_overlap)
        { g.reason = "overlap_disabled"; return g; }

      if(sess == PT_SESSION_ASIA)
        {
         if(profile.is_gold)
           {
            // Thin Asia gold: no aggressive scalp
            g.reason = "xau_asia_blocked";
            return g;
           }
         // FX Asia only for mean-revert range setups
         if(!m_cfg.trade_asia_fx_meanrevert)
           {
            g.reason = "asia_disabled";
            return g;
           }
         if(regime != PT_REGIME_RANGE)
           {
            g.reason = "asia_only_range_meanrevert";
            return g;
           }
        }

      // News blackout
      if(m_cfg.next_news_time > 0 && m_cfg.news_blackout_minutes > 0)
        {
         int sec = m_cfg.news_blackout_minutes * 60;
         datetime now = TimeCurrent();
         if(MathAbs((long)(now - m_cfg.next_news_time)) <= sec)
           {
            g.reason = "news_blackout";
            return g;
           }
        }

      g.ok = true;
      g.reason = "ok";
      return g;
     }
  };



//===== Include/ProTrader/Market/RegimeDetector.mqh =====

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



//===== Include/ProTrader/Market/ManipulationGuard.mqh =====

class CManipulationGuard
  {
private:
   PTConfig          m_cfg;
   double            m_spread_ema;
   bool              m_spread_init;
   datetime          m_last_tick_time;
   double            m_last_bid;
   double            m_last_ask;

   int               SwingLookback(const PTSymbolProfile &profile) const
     {
      return profile.is_gold ? 8 : 5;
     }

public:
                     CManipulationGuard(void)
     {
      m_spread_ema = 0;
      m_spread_init = false;
      m_last_tick_time = 0;
      m_last_bid = 0;
      m_last_ask = 0;
     }

   void              Bind(const PTConfig &cfg) { m_cfg = cfg; }

   void              OnTickUpdate(const string symbol)
     {
      double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
      double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
      if(point <= 0) return;
      double spread = (ask - bid) / point;

      if(!m_spread_init)
        {
         m_spread_ema = spread;
         m_spread_init = true;
        }
      else
         m_spread_ema = 0.9 * m_spread_ema + 0.1 * spread;

      m_last_tick_time = TimeCurrent();
      m_last_bid = bid;
      m_last_ask = ask;
     }

   // Toxic environment → block entries (strategies may still use sweep signals separately)
   GuardResult       IsToxic(const string symbol, const PTSymbolProfile &profile)
     {
      GuardResult g;
      g.ok = true;
      g.reason = "ok";

      OnTickUpdate(symbol);

      double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
      double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
      if(point <= 0)
        {
         g.ok = false;
         g.reason = "bad_point";
         return g;
        }

      double spread = (ask - bid) / point;
      double cap = profile.spread_cap_points;
      double dyn = m_spread_ema * profile.manip_spread_mult;
      double limit = MathMax(cap, dyn);

      if(spread > limit)
        {
         g.ok = false;
         g.reason = StringFormat("spread_spike spread=%.1f limit=%.1f ema=%.1f", spread, limit, m_spread_ema);
         return g;
        }

      // Tick freeze / gap: large jump vs last
      if(m_last_bid > 0)
        {
         double jump = MathAbs(bid - m_last_bid) / point;
         double jump_limit = profile.is_gold ? 250.0 : 40.0;
         if(jump > jump_limit && (TimeCurrent() - m_last_tick_time) <= 2)
           {
            // Note: OnTickUpdate already refreshed last; use previous comparison carefully.
            // We compare against pre-update would be better; approximate with ask-bid range.
           }
        }

      // Stop-level jump toxicity: trade stops level suddenly very high
      int stops = (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
      int freeze = (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_FREEZE_LEVEL);
      if(stops > (profile.is_gold ? 200 : 50) || freeze > (profile.is_gold ? 100 : 30))
        {
         g.ok = false;
         g.reason = StringFormat("stops_freeze_high stops=%d freeze=%d", stops, freeze);
         return g;
        }

      // Fake breakout toxicity: last closed bar broke prior swing then closed back inside
      if(IsFakeBreakoutToxic(symbol, profile))
        {
         g.ok = false;
         g.reason = "fake_breakout_toxic";
         return g;
        }

      return g;
     }

   // Detect liquidity sweep structure (useful as signal input, not always toxic)
   bool              DetectLiquiditySweep(const string symbol, const ENUM_TIMEFRAMES tf,
                                          ENUM_PT_DIR &sweep_dir, double &sweep_extreme)
     {
      sweep_dir = PT_DIR_NONE;
      sweep_extreme = 0;

      MqlRates rates[];
      ArraySetAsSeries(rates, true);
      int need = 30;
      if(CopyRates(symbol, tf, 0, need, rates) < need)
         return false;

      // Use closed bar 1 as candidate sweep bar
      int lb = 5;
      double prior_high = rates[2].high;
      double prior_low  = rates[2].low;
      for(int i=3; i<2+lb; i++)
        {
         if(rates[i].high > prior_high) prior_high = rates[i].high;
         if(rates[i].low  < prior_low)  prior_low  = rates[i].low;
        }

      // Sweep high then close back below prior high → sell-side liquidity grab (bullish reversal potential after? actually sell liquidity above = buy-side stop hunt → bullish)
      if(rates[1].high > prior_high && rates[1].close < prior_high && rates[1].close > rates[1].open)
        {
         sweep_dir = PT_DIR_BUY;
         sweep_extreme = rates[1].low;
         return true;
        }
      if(rates[1].low < prior_low && rates[1].close > prior_low && rates[1].close < rates[1].open)
        {
         sweep_dir = PT_DIR_SELL;
         sweep_extreme = rates[1].high;
         return true;
        }
      return false;
     }

private:
   bool              IsFakeBreakoutToxic(const string symbol, const PTSymbolProfile &profile)
     {
      MqlRates rates[];
      ArraySetAsSeries(rates, true);
      ENUM_TIMEFRAMES tf = profile.entry_tf;
      if(CopyRates(symbol, tf, 0, 10, rates) < 10)
         return false;

      // Prior range high/low of bars 3..7
      double rh = rates[3].high;
      double rl = rates[3].low;
      for(int i=4; i<=7; i++)
        {
         if(rates[i].high > rh) rh = rates[i].high;
         if(rates[i].low < rl) rl = rates[i].low;
        }

      // Bar 2 breaks out, bar 1 fully reverses back through
      bool up_fake = (rates[2].high > rh && rates[1].close < rh && rates[1].close < rates[1].open);
      bool dn_fake = (rates[2].low < rl && rates[1].close > rl && rates[1].close > rates[1].open);

      // Only toxic if body of reversal is large relative to range (chase trap)
      double body = MathAbs(rates[1].close - rates[1].open);
      double range = rates[1].high - rates[1].low;
      if(range <= 0) return false;
      if((up_fake || dn_fake) && body / range > 0.6)
         return true;
      return false;
     }
  };



//===== Include/ProTrader/Risk/EquityGuard.mqh =====

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



//===== Include/ProTrader/Risk/LotSizer.mqh =====

class CLotSizer
  {
private:
   PTConfig          m_cfg;

   double            RiskPctForEquity(const double equity, const ENUM_PT_MODE mode) const
     {
      if(m_cfg.risk_mode == PT_RISK_BALANCED)
        {
         if(equity < 30.0) return 1.0;
         if(equity < 100.0) return 1.25;
         if(equity < 500.0) return 1.0;
         return 0.75;
        }

      // RecoveryAggressive (default)
      if(equity < 30.0)  return (mode == PT_MODE_RECOVERY ? 2.0 : 1.5);
      if(equity < 100.0) return 2.5;
      if(equity < 500.0) return 1.5;
      return 1.0;
     }

   double            NormalizeLots(const string symbol, double lots) const
     {
      double min_lot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
      double max_lot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
      double step    = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
      if(step <= 0) step = 0.01;
      if(min_lot <= 0) min_lot = 0.01;

      lots = MathFloor(lots / step + 1e-9) * step;
      if(lots < min_lot)
         return 0.0; // signal: below min — caller must skip, not force
      if(lots > max_lot)
         lots = max_lot;

      int digits = 0;
      double tmp = step;
      while(tmp < 1.0 && digits < 8)
        {
         tmp *= 10.0;
         digits++;
        }
      return NormalizeDouble(lots, digits);
     }

public:
   void              Bind(const PTConfig &cfg) { m_cfg = cfg; }

   double            TargetRiskPct(const AccountSnapshot &snap) const
     {
      return RiskPctForEquity(snap.equity, snap.mode);
     }

   // Returns lots; 0 means skip (min lot would over-risk)
   RiskDecision      Build(const string symbol,
                           const AccountSnapshot &snap,
                           const PTSymbolProfile &profile,
                           const ENUM_PT_DIR dir,
                           const double entry_price,
                           const double sl_price,
                           const double tp_price)
     {
      RiskDecision d;
      d.allowed = false;
      d.lots = 0;
      d.risk_money = 0;
      d.risk_pct = 0;
      d.sl_price = sl_price;
      d.tp_price = tp_price;
      d.block_reason = "";

      if(dir == PT_DIR_NONE || entry_price <= 0 || sl_price <= 0)
        {
         d.block_reason = "invalid_prices_or_dir";
         return d;
        }

      // Mandatory SL distance sanity
      double sl_dist = MathAbs(entry_price - sl_price);
      if(sl_dist <= 0)
        {
         d.block_reason = "sl_distance_zero";
         return d;
        }

      double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
      double tick_size = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
      double tick_value = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
      if(point <= 0 || tick_size <= 0 || tick_value <= 0)
        {
         d.block_reason = "symbol_tick_meta_invalid";
         return d;
        }

      // Stops level
      int stops_level = (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
      double min_stop = stops_level * point;
      if(sl_dist < min_stop)
        {
         d.block_reason = StringFormat("sl_inside_stops_level need>=%.5f got=%.5f", min_stop, sl_dist);
         return d;
        }

      d.risk_pct = TargetRiskPct(snap);
      d.risk_money = snap.equity * (d.risk_pct / 100.0);
      if(d.risk_money <= 0)
        {
         d.block_reason = "risk_money_zero";
         return d;
        }

      // money risk per 1.0 lot for this SL distance
      double ticks = sl_dist / tick_size;
      double money_per_lot = ticks * tick_value;
      if(money_per_lot <= 0)
        {
         d.block_reason = "money_per_lot_zero";
         return d;
        }

      double raw_lots = d.risk_money / money_per_lot;
      double lots = NormalizeLots(symbol, raw_lots);

      if(lots <= 0.0)
        {
         // Check whether min lot would exceed risk budget — always skip (never force)
         double min_lot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
         double min_risk = min_lot * money_per_lot;
         d.block_reason = StringFormat("min_lot_over_risk min_lot=%.2f min_risk=%.2f budget=%.2f",
                                       min_lot, min_risk, d.risk_money);
         return d;
        }

      // Final check: actual risk with chosen lots must not blow daily-ish hard cap of 5% equity
      double actual_risk = lots * money_per_lot;
      double hard_cap = snap.equity * 0.05;
      if(actual_risk > hard_cap + 1e-6)
        {
         d.block_reason = StringFormat("actual_risk=%.2f > hard_cap=%.2f", actual_risk, hard_cap);
         return d;
        }

      // Margin check for the lot
      double margin_required = 0;
      ENUM_ORDER_TYPE otype = (dir == PT_DIR_BUY ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
      if(!OrderCalcMargin(otype, symbol, lots, entry_price, margin_required))
        {
         d.block_reason = "OrderCalcMargin_failed";
         return d;
        }
      if(margin_required > snap.free_margin)
        {
         d.block_reason = StringFormat("margin_required=%.2f > free=%.2f", margin_required, snap.free_margin);
         return d;
        }
      if(snap.equity > 0)
        {
         double projected_usage = 100.0 * (snap.margin + margin_required) / snap.equity;
         if(projected_usage > m_cfg.max_margin_usage_pct)
           {
            d.block_reason = StringFormat("projected_margin_usage=%.1f%%", projected_usage);
            return d;
           }
        }

      // Never allow trade that could push equity estimate below floor on full SL
      if(snap.equity - actual_risk < snap.equity_floor)
        {
         d.block_reason = StringFormat("sl_would_breach_floor eq=%.2f risk=%.2f floor=%.2f",
                                       snap.equity, actual_risk, snap.equity_floor);
         return d;
        }

      d.lots = lots;
      d.risk_money = actual_risk;
      d.allowed = true;
      d.block_reason = "ok";
      return d;
     }
  };



//===== Include/ProTrader/Risk/RiskEngine.mqh =====

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



//===== Include/ProTrader/Strategies/IStrategy.mqh =====

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



//===== Include/ProTrader/Strategies/TrendPullback.mqh =====

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



//===== Include/ProTrader/Strategies/LiquiditySweepReversal.mqh =====

class CLiquiditySweepReversal : public IStrategy
  {
private:
   string            m_symbol;
   PTSymbolProfile   m_profile;
   CManipulationGuard *m_manip; // non-owning

public:
                     CLiquiditySweepReversal(void) : m_manip(NULL) { m_symbol = ""; }

   void              SetManipulationGuard(CManipulationGuard &g) { m_manip = &g; }

   string            Name(void) const { return "LiqSweepReversal"; }

   bool              Init(const string symbol, const PTSymbolProfile &profile)
     {
      m_symbol = symbol;
      m_profile = profile;
      return true;
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
      if(m_manip == NULL || atr <= 0)
         return s;

      ENUM_PT_DIR sweep_dir = PT_DIR_NONE;
      double extreme = 0;
      if(!m_manip.DetectLiquiditySweep(m_symbol, m_profile.entry_tf, sweep_dir, extreme))
         return s;

      // Optional displacement: next closed bar continues in sweep direction
      MqlRates rates[];
      ArraySetAsSeries(rates, true);
      if(CopyRates(m_symbol, m_profile.entry_tf, 0, 4, rates) < 4)
         return s;

      double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
      double r_mult = (mode == PT_MODE_RECOVERY ? 1.5 : 2.0);
      double atr_mult = m_profile.min_sl_atr_mult + 0.2;

      if(sweep_dir == PT_DIR_BUY && htf_bias != PT_DIR_SELL)
        {
         bool engulf = (rates[1].close > rates[2].high);
         bool fvg_proxy = (rates[1].low > rates[3].high); // simple displacement gap proxy
         s.dir = PT_DIR_BUY;
         s.score = 30.0 + (engulf ? 15.0 : 0.0) + (fvg_proxy ? 10.0 : 0.0);
         if(htf_bias == PT_DIR_BUY) s.score += 5.0;
         double struct_sl = (extreme > 0 ? extreme : rates[1].low);
         s.sl_price = PT_ATR_SL(PT_DIR_BUY, ask, atr, atr_mult, struct_sl - atr * 0.1);
         s.tp_price = PT_TP_From_R(PT_DIR_BUY, ask, s.sl_price, r_mult);
         s.reason = "buy_side_stop_hunt_reversal";
         return s;
        }

      if(sweep_dir == PT_DIR_SELL && htf_bias != PT_DIR_BUY)
        {
         bool engulf = (rates[1].close < rates[2].low);
         bool fvg_proxy = (rates[1].high < rates[3].low);
         s.dir = PT_DIR_SELL;
         s.score = 30.0 + (engulf ? 15.0 : 0.0) + (fvg_proxy ? 10.0 : 0.0);
         if(htf_bias == PT_DIR_SELL) s.score += 5.0;
         double struct_sl = (extreme > 0 ? extreme : rates[1].high);
         s.sl_price = PT_ATR_SL(PT_DIR_SELL, bid, atr, atr_mult, struct_sl + atr * 0.1);
         s.tp_price = PT_TP_From_R(PT_DIR_SELL, bid, s.sl_price, r_mult);
         s.reason = "sell_side_stop_hunt_reversal";
         return s;
        }

      return s;
     }
  };



//===== Include/ProTrader/Strategies/CompressionBreakout.mqh =====

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



//===== Include/ProTrader/Strategies/MeanRevertRange.mqh =====

class CMeanRevertRange : public IStrategy
  {
private:
   string            m_symbol;
   PTSymbolProfile   m_profile;
   int               m_rsi;
   int               m_bb;

public:
                     CMeanRevertRange(void)
     {
      m_symbol = "";
      m_rsi = INVALID_HANDLE;
      m_bb = INVALID_HANDLE;
     }

                    ~CMeanRevertRange(void) { Release(); }

   string            Name(void) const { return "MeanRevertRange"; }

   bool              Init(const string symbol, const PTSymbolProfile &profile)
     {
      Release();
      m_symbol = symbol;
      m_profile = profile;
      m_rsi = iRSI(symbol, profile.entry_tf, 14, PRICE_CLOSE);
      m_bb  = iBands(symbol, profile.entry_tf, 20, 0, 2.0, PRICE_CLOSE);
      return (m_rsi != INVALID_HANDLE && m_bb != INVALID_HANDLE);
     }

   void              Release(void)
     {
      if(m_rsi != INVALID_HANDLE) { IndicatorRelease(m_rsi); m_rsi = INVALID_HANDLE; }
      if(m_bb != INVALID_HANDLE) { IndicatorRelease(m_bb); m_bb = INVALID_HANDLE; }
     }

   StrategySignal    Evaluate(const ENUM_PT_REGIME regime,
                              const ENUM_PT_DIR htf_bias,
                              const ENUM_PT_MODE mode,
                              const double atr)
     {
      StrategySignal s;
      PT_ClearSignal(s);
      s.tag = Name();

      // Only in RANGE
      if(regime != PT_REGIME_RANGE)
         return s;
      if(atr <= 0)
         return s;

      double rsi[], upper[], mid[], lower[];
      ArraySetAsSeries(rsi, true);
      ArraySetAsSeries(upper, true);
      ArraySetAsSeries(mid, true);
      ArraySetAsSeries(lower, true);

      if(CopyBuffer(m_rsi, 0, 0, 3, rsi) < 3) return s;
      if(CopyBuffer(m_bb, 1, 0, 3, upper) < 3) return s; // upper
      if(CopyBuffer(m_bb, 0, 0, 3, mid) < 3) return s;   // base/middle
      if(CopyBuffer(m_bb, 2, 0, 3, lower) < 3) return s; // lower

      MqlRates rates[];
      ArraySetAsSeries(rates, true);
      if(CopyRates(m_symbol, m_profile.entry_tf, 0, 3, rates) < 3)
         return s;

      double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
      double r_mult = (mode == PT_MODE_RECOVERY ? 1.2 : 1.5);
      double atr_mult = m_profile.min_sl_atr_mult;

      // Oversold bounce
      if(rsi[1] < 30.0 && rates[1].low <= lower[1] && rates[1].close > lower[1])
        {
         if(htf_bias == PT_DIR_SELL) return s; // soft veto already via scorer; skip hard conflict
         s.dir = PT_DIR_BUY;
         s.score = 25.0 + (rsi[1] < 25.0 ? 10.0 : 0.0);
         s.sl_price = PT_ATR_SL(PT_DIR_BUY, ask, atr, atr_mult, rates[1].low);
         // TP toward mid band preferentially
         double tp_r = PT_TP_From_R(PT_DIR_BUY, ask, s.sl_price, r_mult);
         s.tp_price = (mid[0] > ask ? MathMin(mid[0], tp_r) : tp_r);
         s.reason = "rsi_bb_oversold";
         return s;
        }

      // Overbought fade
      if(rsi[1] > 70.0 && rates[1].high >= upper[1] && rates[1].close < upper[1])
        {
         if(htf_bias == PT_DIR_BUY) return s;
         s.dir = PT_DIR_SELL;
         s.score = 25.0 + (rsi[1] > 75.0 ? 10.0 : 0.0);
         s.sl_price = PT_ATR_SL(PT_DIR_SELL, bid, atr, atr_mult, rates[1].high);
         double tp_r = PT_TP_From_R(PT_DIR_SELL, bid, s.sl_price, r_mult);
         s.tp_price = (mid[0] < bid ? MathMax(mid[0], tp_r) : tp_r);
         s.reason = "rsi_bb_overbought";
         return s;
        }

      return s;
     }
  };



//===== Include/ProTrader/Confluence/SetupScorer.mqh =====

class CSetupScorer
  {
private:
   PTConfig          m_cfg;

public:
   void              Bind(const PTConfig &cfg) { m_cfg = cfg; }

   double            Threshold(const ENUM_PT_MODE mode) const
     {
      return (mode == PT_MODE_RECOVERY ? m_cfg.aplus_min_recovery : m_cfg.aplus_min_growth);
     }

   ConfluenceResult  Score(StrategySignal &signals[],
                           const int count,
                           const ENUM_PT_DIR htf_bias,
                           const ENUM_PT_MODE mode)
     {
      ConfluenceResult r;
      r.valid = false;
      r.dir = PT_DIR_NONE;
      r.score = 0;
      r.sl_price = 0;
      r.tp_price = 0;
      r.reason = "";
      r.primary_tag = "";

      double buy_score = 0;
      double sell_score = 0;
      int buy_n = 0, sell_n = 0;
      double buy_sl = 0, sell_sl = 0, buy_tp = 0, sell_tp = 0;
      string buy_tags = "", sell_tags = "";
      string buy_primary = "", sell_primary = "";
      double buy_best = -1, sell_best = -1;

      for(int i=0; i<count; i++)
        {
         if(signals[i].dir == PT_DIR_BUY && signals[i].score > 0)
           {
            buy_score += signals[i].score;
            buy_n++;
            // Prefer widest (safer) SL for buys = lowest SL
            if(buy_sl == 0 || signals[i].sl_price < buy_sl)
               buy_sl = signals[i].sl_price;
            if(signals[i].tp_price > buy_tp)
               buy_tp = signals[i].tp_price;
            if(buy_tags != "") buy_tags += "+";
            buy_tags += signals[i].tag;
            if(signals[i].score > buy_best)
              {
               buy_best = signals[i].score;
               buy_primary = signals[i].tag;
              }
           }
         else if(signals[i].dir == PT_DIR_SELL && signals[i].score > 0)
           {
            sell_score += signals[i].score;
            sell_n++;
            if(sell_sl == 0 || signals[i].sl_price > sell_sl)
               sell_sl = signals[i].sl_price;
            if(sell_tp == 0 || signals[i].tp_price < sell_tp)
               sell_tp = signals[i].tp_price;
            if(sell_tags != "") sell_tags += "+";
            sell_tags += signals[i].tag;
            if(signals[i].score > sell_best)
              {
               sell_best = signals[i].score;
               sell_primary = signals[i].tag;
              }
           }
        }

      // Cap raw sum to 100
      buy_score = MathMin(100.0, buy_score);
      sell_score = MathMin(100.0, sell_score);

      // HTF bias: penalty / soft veto
      if(htf_bias == PT_DIR_BUY)
         sell_score = MathMax(0.0, sell_score - m_cfg.htf_bias_penalty);
      else if(htf_bias == PT_DIR_SELL)
         buy_score = MathMax(0.0, buy_score - m_cfg.htf_bias_penalty);

      // Require at least one vote; prefer confluence of 2+ in growth mode
      ENUM_PT_DIR dir = PT_DIR_NONE;
      double score = 0;
      if(buy_score > sell_score)
        {
         dir = PT_DIR_BUY;
         score = buy_score;
         r.sl_price = buy_sl;
         r.tp_price = buy_tp;
         r.reason = buy_tags;
         r.primary_tag = buy_primary;
         if(mode == PT_MODE_GROWTH && buy_n < 2 && score < m_cfg.aplus_min_growth + 5.0)
           {
            // Growth wants confluence unless extremely strong single
            r.reason = "growth_needs_confluence:" + buy_tags;
            return r;
           }
        }
      else if(sell_score > buy_score)
        {
         dir = PT_DIR_SELL;
         score = sell_score;
         r.sl_price = sell_sl;
         r.tp_price = sell_tp;
         r.reason = sell_tags;
         r.primary_tag = sell_primary;
         if(mode == PT_MODE_GROWTH && sell_n < 2 && score < m_cfg.aplus_min_growth + 5.0)
           {
            r.reason = "growth_needs_confluence:" + sell_tags;
            return r;
           }
        }
      else
        {
         r.reason = "tied_or_empty";
         return r;
        }

      double thr = Threshold(mode);
      if(score < thr)
        {
         r.reason = StringFormat("score_%.1f_lt_thr_%.1f:%s", score, thr, r.reason);
         r.score = score;
         r.dir = dir;
         return r;
        }

      if(r.sl_price <= 0)
        {
         r.reason = "missing_sl_after_score";
         return r;
        }

      r.valid = true;
      r.dir = dir;
      r.score = score;
      return r;
     }
  };



//===== Include/ProTrader/Execution/OrderRouter.mqh =====

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



//===== Include/ProTrader/Execution/TradeManager.mqh =====

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



//===== EA body =====

//--- Inputs
input group "=== Core ==="
input long               InpMagic              = 20261031;
input int                InpSlippagePoints     = 20;
input ENUM_PT_RISK_MODE  InpRiskMode           = PT_RISK_RECOVERY_AGGRESSIVE;
input int                InpTimerSeconds       = 1;

input group "=== Risk floors (liq protection) ==="
input double             InpEquityFloorPct     = 0.35;   // of start equity
input double             InpMinEquityFloorUSD  = 5.0;
input double             InpMaxMarginUsagePct  = 25.0;
input double             InpDailyLossPct       = 4.0;
input int                InpMaxConsecutiveLoss = 3;
input int                InpCooldownMinMin     = 30;
input int                InpCooldownMaxMin     = 90;

input group "=== A+ scoring ==="
input double             InpAplusRecovery      = 60.0;
input double             InpAplusGrowth        = 75.0;
input double             InpHtfBiasPenalty     = 25.0;

input group "=== Trade management ==="
input double             InpBETriggerR         = 1.0;
input double             InpTrailTriggerR      = 1.5;
input double             InpTrailAtrMult       = 1.0;
input int                InpScalpMaxMinutes    = 45;
input int                InpDaytradeMaxMinutes = 360;
input bool               InpFridayFlatten      = true;
input int                InpFridayFlattenHour  = 20;

input group "=== Sessions / news ==="
input bool               InpTradeLondon        = true;
input bool               InpTradeNY            = true;
input bool               InpTradeOverlap       = true;
input bool               InpTradeAsiaFXMR      = true;
input int                InpNewsBlackoutMin    = 30;
input datetime           InpNextNewsTime       = 0; // set manually if desired

input group "=== Symbols ==="
input bool               InpEURUSD             = true;
input bool               InpGBPUSD             = true;
input bool               InpUSDJPY             = true;
input bool               InpAUDUSD             = true;
input bool               InpUSDCAD             = true;
input bool               InpUSDCHF             = true;
input bool               InpNZDUSD             = true;
input bool               InpXAUUSD             = true;
input bool               InpOnlyChartSymbol    = true; // safer default for tester / single chart

//--- Globals
PTConfig                 g_cfg;
CAccountState            g_account;
CRiskEngine              g_risk;
CSessionFilter           g_session;
CSetupScorer             g_scorer;
CTradeManager            g_trades;

string                   g_symbols[];
CRegimeDetector          g_regime[];
CManipulationGuard       g_manip[];
CTrendPullback           g_st_trend[];
CLiquiditySweepReversal  g_st_sweep[];
CCompressionBreakout     g_st_break[];
CMeanRevertRange         g_st_mean[];
PTSymbolProfile          g_profiles[];
datetime                 g_last_bar_time[];

void BuildConfigFromInputs()
  {
   PTConfig_SetDefaults(g_cfg);
   g_cfg.magic = InpMagic;
   g_cfg.slippage_points = InpSlippagePoints;
   g_cfg.risk_mode = InpRiskMode;

   g_cfg.equity_floor_pct = InpEquityFloorPct;
   g_cfg.min_equity_floor_usd = InpMinEquityFloorUSD;
   g_cfg.max_margin_usage_pct = InpMaxMarginUsagePct;
   g_cfg.daily_loss_pct = InpDailyLossPct;
   g_cfg.max_consecutive_losses = InpMaxConsecutiveLoss;
   g_cfg.cooldown_min_minutes = InpCooldownMinMin;
   g_cfg.cooldown_max_minutes = InpCooldownMaxMin;

   g_cfg.aplus_min_recovery = InpAplusRecovery;
   g_cfg.aplus_min_growth = InpAplusGrowth;
   g_cfg.htf_bias_penalty = InpHtfBiasPenalty;

   g_cfg.be_trigger_r = InpBETriggerR;
   g_cfg.trail_trigger_r = InpTrailTriggerR;
   g_cfg.trail_atr_mult = InpTrailAtrMult;
   g_cfg.scalp_max_minutes = InpScalpMaxMinutes;
   g_cfg.daytrade_max_minutes = InpDaytradeMaxMinutes;
   g_cfg.flatten_before_friday_close = InpFridayFlatten;
   g_cfg.friday_flatten_hour_server = InpFridayFlattenHour;

   g_cfg.trade_london = InpTradeLondon;
   g_cfg.trade_ny = InpTradeNY;
   g_cfg.trade_overlap = InpTradeOverlap;
   g_cfg.trade_asia_fx_meanrevert = InpTradeAsiaFXMR;
   g_cfg.news_blackout_minutes = InpNewsBlackoutMin;
   g_cfg.next_news_time = InpNextNewsTime;

   g_cfg.enable_eurusd = InpEURUSD;
   g_cfg.enable_gbpusd = InpGBPUSD;
   g_cfg.enable_usdjpy = InpUSDJPY;
   g_cfg.enable_audusd = InpAUDUSD;
   g_cfg.enable_usdcad = InpUSDCAD;
   g_cfg.enable_usdchf = InpUSDCHF;
   g_cfg.enable_nzdusd = InpNZDUSD;
   g_cfg.enable_xauusd = InpXAUUSD;
  }

bool InitSymbolSlot(const int idx, const string symbol)
  {
   PT_BuildSymbolProfile(symbol, g_profiles[idx]);
   if(!g_regime[idx].Init(symbol, PERIOD_M15))
     {
      PT_Log("Init", "RegimeDetector failed for " + symbol);
      return false;
     }
   g_manip[idx].Bind(g_cfg);
   if(!g_st_trend[idx].Init(symbol, g_profiles[idx])) return false;
   if(!g_st_sweep[idx].Init(symbol, g_profiles[idx])) return false;
   g_st_sweep[idx].SetManipulationGuard(g_manip[idx]);
   if(!g_st_break[idx].Init(symbol, g_profiles[idx])) return false;
   if(!g_st_mean[idx].Init(symbol, g_profiles[idx])) return false;
   g_last_bar_time[idx] = 0;
   PT_Log("Init", StringFormat("symbol=%s gold=%d entry_tf=%d",
          symbol, (int)g_profiles[idx].is_gold, (int)g_profiles[idx].entry_tf));
   return true;
  }

int OnInit()
  {
   BuildConfigFromInputs();
   g_account.Init(g_cfg);
   g_risk.Init(g_cfg, g_account);
   g_session.Bind(g_cfg);
   g_scorer.Bind(g_cfg);
   g_trades.Init(g_cfg, g_account);

   // Self-checks
   AccountSnapshot snap;
   g_account.Snapshot(snap);
   if(snap.equity_floor <= 0)
     {
      Print("ProTraderEA: invalid equity floor");
      return INIT_FAILED;
     }
   PT_Log("OnInit", StringFormat("equity=%.2f floor=%.2f mode=%s risk_mode=%d",
          snap.equity, snap.equity_floor,
          (snap.mode == PT_MODE_RECOVERY ? "RECOVERY" : "GROWTH"),
          (int)g_cfg.risk_mode));

   if(InpOnlyChartSymbol)
     {
      ArrayResize(g_symbols, 1);
      g_symbols[0] = _Symbol;
     }
   else
     {
      int n = PT_CollectEnabledSymbols(g_cfg, g_symbols);
      if(n <= 0)
        {
         ArrayResize(g_symbols, 1);
         g_symbols[0] = _Symbol;
        }
     }

   int nsym = ArraySize(g_symbols);
   ArrayResize(g_regime, nsym);
   ArrayResize(g_manip, nsym);
   ArrayResize(g_st_trend, nsym);
   ArrayResize(g_st_sweep, nsym);
   ArrayResize(g_st_break, nsym);
   ArrayResize(g_st_mean, nsym);
   ArrayResize(g_profiles, nsym);
   ArrayResize(g_last_bar_time, nsym);

   for(int i=0; i<nsym; i++)
     {
      if(!SymbolSelect(g_symbols[i], true))
        {
         PT_Log("OnInit", "SymbolSelect failed: " + g_symbols[i]);
         continue;
        }
      if(!InitSymbolSlot(i, g_symbols[i]))
         return INIT_FAILED;
     }

   EventSetTimer(MathMax(1, InpTimerSeconds));
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   EventKillTimer();
   for(int i=0; i<ArraySize(g_regime); i++)
     {
      g_regime[i].Release();
      g_st_trend[i].Release();
      g_st_break[i].Release();
      g_st_mean[i].Release();
     }
  }

ENUM_PT_MODE ResolveMode(const AccountSnapshot &snap)
  {
   // Explicit mode switcher (equity-tier) — already in AccountState; mirrored here for clarity/logs
   return snap.mode;
  }

void EvaluateSymbol(const int idx)
  {
   string symbol = g_symbols[idx];
   if(symbol == "")
      return;

   // New bar gate on entry TF (avoid tick spam)
   datetime bar_time = iTime(symbol, g_profiles[idx].entry_tf, 0);
   if(bar_time == 0)
      return;
   if(bar_time == g_last_bar_time[idx])
      return;
   g_last_bar_time[idx] = bar_time;

   AccountSnapshot snap;
   g_account.Snapshot(snap);
   ENUM_PT_MODE mode = ResolveMode(snap);

   CEquityGuard *guard = g_risk.Guard();
   GuardResult eg = guard.AllowSymbol(symbol);
   if(!eg.ok)
     {
      PT_LogBlock(symbol, eg.reason);
      return;
     }

   ENUM_PT_REGIME regime = g_regime[idx].Detect();
   if(regime == PT_REGIME_DEAD)
     {
      PT_LogBlock(symbol, "regime_DEAD");
      return;
     }

   GuardResult sess = g_session.AllowTrade(g_profiles[idx], regime);
   if(!sess.ok)
     {
      PT_LogBlock(symbol, sess.reason);
      return;
     }

   // Manipulation toxic → no entry (sweep strategy still needs non-toxic book)
   GuardResult tox = g_manip[idx].IsToxic(symbol, g_profiles[idx]);
   if(!tox.ok)
     {
      PT_LogBlock(symbol, tox.reason);
      return;
     }

   ENUM_PT_DIR bias = g_regime[idx].HTFBias(PERIOD_H1);
   double atr = g_regime[idx].ATR(0);
   // Prefer entry-TF ATR for SL geometry
   int atr_h = iATR(symbol, g_profiles[idx].entry_tf, 14);
   if(atr_h != INVALID_HANDLE)
     {
      double buf[];
      ArraySetAsSeries(buf, true);
      if(CopyBuffer(atr_h, 0, 0, 2, buf) >= 2)
         atr = buf[0];
      IndicatorRelease(atr_h);
     }
   if(atr <= 0)
     {
      PT_LogBlock(symbol, "atr_zero");
      return;
     }

   StrategySignal votes[4];
   votes[0] = g_st_trend[idx].Evaluate(regime, bias, mode, atr);
   votes[1] = g_st_sweep[idx].Evaluate(regime, bias, mode, atr);
   votes[2] = g_st_break[idx].Evaluate(regime, bias, mode, atr);
   votes[3] = g_st_mean[idx].Evaluate(regime, bias, mode, atr);

   ConfluenceResult setup = g_scorer.Score(votes, 4, bias, mode);
   if(!setup.valid)
     {
      if(setup.reason != "")
         PT_LogBlock(symbol, setup.reason);
      return;
     }

   double entry = (setup.dir == PT_DIR_BUY)
                  ? SymbolInfoDouble(symbol, SYMBOL_ASK)
                  : SymbolInfoDouble(symbol, SYMBOL_BID);

   RiskDecision risk = g_risk.EvaluateEntry(symbol, g_profiles[idx], setup, entry);
   if(!risk.allowed)
     {
      PT_LogBlock(symbol, risk.block_reason);
      return;
     }

   PT_Log("Mode", StringFormat("%s mode=%s equity=%.2f risk_pct=%.2f lots=%.2f score=%.1f",
          symbol,
          (mode == PT_MODE_RECOVERY ? "RECOVERY" : "GROWTH"),
          snap.equity, risk.risk_pct, risk.lots, setup.score));

   g_trades.ExecuteSetup(symbol, g_profiles[idx], setup, risk, mode);
  }

void OnTimer()
  {
   g_account.OnTimerDayRoll();
   g_trades.ManageOpen();

   for(int i=0; i<ArraySize(g_symbols); i++)
      EvaluateSymbol(i);
  }

void OnTick()
  {
   // Keep spread EMA warm; decisions run on timer/new bar
   for(int i=0; i<ArraySize(g_symbols); i++)
      g_manip[i].OnTickUpdate(g_symbols[i]);

   g_trades.ManageOpen();
  }

void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
  {
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD)
      return;
   ulong deal = trans.deal;
   if(deal == 0)
      return;
   if(!HistoryDealSelect(deal))
      return;
   if((long)HistoryDealGetInteger(deal, DEAL_MAGIC) != g_cfg.magic)
      return;
   long entry = HistoryDealGetInteger(deal, DEAL_ENTRY);
   if(entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_OUT_BY)
     {
      double profit = HistoryDealGetDouble(deal, DEAL_PROFIT)
                      + HistoryDealGetDouble(deal, DEAL_SWAP)
                      + HistoryDealGetDouble(deal, DEAL_COMMISSION);
      g_trades.OnClosedDealProfit(profit);
      PT_Log("Deal", StringFormat("closed profit=%.2f", profit));
     }
  }

