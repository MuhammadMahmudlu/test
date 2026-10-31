#ifndef PROTRADER_SETUP_SCORER_MQH
#define PROTRADER_SETUP_SCORER_MQH

#include "../Types.mqh"
#include "../Config.mqh"
#include "../Strategies/IStrategy.mqh"
#include "../State/Journal.mqh"

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

#endif
