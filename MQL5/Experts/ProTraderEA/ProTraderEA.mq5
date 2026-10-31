//+------------------------------------------------------------------+
//|                                                  ProTraderEA.mq5 |
//|                     Pro Trader brain — A+ confluence EA for MT5  |
//|           Forex majors + XAUUSD | Aggressive recovery risk model |
//+------------------------------------------------------------------+
#property copyright "ProTraderEA"
#property version   "1.00"
#property strict
#property description "A+ confluence EA: regime + manipulation filters, hard equity floor, recovery scalp / growth day-trade."

#include <ProTrader/Config.mqh>
#include <ProTrader/Types.mqh>
#include <ProTrader/State/Journal.mqh>
#include <ProTrader/State/AccountState.mqh>
#include <ProTrader/Market/SymbolProfile.mqh>
#include <ProTrader/Market/SessionFilter.mqh>
#include <ProTrader/Market/RegimeDetector.mqh>
#include <ProTrader/Market/ManipulationGuard.mqh>
#include <ProTrader/Risk/RiskEngine.mqh>
#include <ProTrader/Strategies/TrendPullback.mqh>
#include <ProTrader/Strategies/LiquiditySweepReversal.mqh>
#include <ProTrader/Strategies/CompressionBreakout.mqh>
#include <ProTrader/Strategies/MeanRevertRange.mqh>
#include <ProTrader/Confluence/SetupScorer.mqh>
#include <ProTrader/Execution/TradeManager.mqh>

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

//+------------------------------------------------------------------+
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

//+------------------------------------------------------------------+
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

//+------------------------------------------------------------------+
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

//+------------------------------------------------------------------+
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

//+------------------------------------------------------------------+
ENUM_PT_MODE ResolveMode(const AccountSnapshot &snap)
  {
   // Explicit mode switcher (equity-tier) — already in AccountState; mirrored here for clarity/logs
   return snap.mode;
  }

//+------------------------------------------------------------------+
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

//+------------------------------------------------------------------+
void OnTimer()
  {
   g_account.OnTimerDayRoll();
   g_trades.ManageOpen();

   for(int i=0; i<ArraySize(g_symbols); i++)
      EvaluateSymbol(i);
  }

//+------------------------------------------------------------------+
void OnTick()
  {
   // Keep spread EMA warm; decisions run on timer/new bar
   for(int i=0; i<ArraySize(g_symbols); i++)
      g_manip[i].OnTickUpdate(g_symbols[i]);

   g_trades.ManageOpen();
  }

//+------------------------------------------------------------------+
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

//+------------------------------------------------------------------+
