#ifndef PROTRADER_TYPES_MQH
#define PROTRADER_TYPES_MQH

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

#endif
