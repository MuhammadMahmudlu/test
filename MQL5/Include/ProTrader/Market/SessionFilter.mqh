#ifndef PROTRADER_SESSION_FILTER_MQH
#define PROTRADER_SESSION_FILTER_MQH

#include "../Types.mqh"
#include "../Config.mqh"
#include "SymbolProfile.mqh"

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

#endif
