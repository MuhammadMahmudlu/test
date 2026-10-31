#ifndef PROTRADER_CONFIG_MQH
#define PROTRADER_CONFIG_MQH

#include "Types.mqh"

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

#endif
