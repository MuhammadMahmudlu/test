//+------------------------------------------------------------------+
//|                                              ProTraderGold.mq5   |
//|     XAUUSD-only pro-trader brain — profit-first, risk-on DD      |
//|     Copy this ONE file into MQL5/Experts/ and compile (F7)       |
//+------------------------------------------------------------------+
#property copyright "ProTraderGold"
#property version   "2.00"
#property description "XAUUSD/XAUUSDc only. Profit-focused brain: A+ gold setups, aggressive when underwater, protect when ahead."

#include <Trade/Trade.mqh>

enum ENUM_GOLD_BIAS { BIAS_NONE=0, BIAS_BUY=1, BIAS_SELL=-1 };
enum ENUM_GOLD_REGIME { REG_DEAD=0, REG_RANGE, REG_TREND, REG_VOLATILE };
enum ENUM_GOLD_MOOD { MOOD_PROTECT=0, MOOD_HUNT, MOOD_RECOVERY };

input group "=== Core ==="
input long     InpMagic            = 260231;
input int      InpSlippage         = 30;
input bool     InpAllowCentSuffix  = true;   // XAUUSDc / GOLDc OK

input group "=== Profit brain / risk ==="
input double   InpBaseRiskPct      = 2.0;    // normal hunt risk %
input double   InpRecoveryRiskPct  = 4.0;    // when underwater — take risk to recover
input double   InpProtectRiskPct   = 1.0;    // when day is green — smaller size
input double   InpEquityFloorPct   = 0.40;   // hard floor vs start equity (anti-liq)
input double   InpMinFloorMoney    = 5.0;
input double   InpMaxMarginPct     = 35.0;
input double   InpDailyLossHaltPct = 8.0;    // halt new entries after this daily loss
input int      InpMaxTradesPerDay  = 24;
input int      InpMaxOpenPos       = 1;

input group "=== Setup quality ==="
input double   InpMinScoreHunt     = 55.0;
input double   InpMinScoreRecovery = 45.0;   // accept more setups when recovering
input double   InpMinScoreProtect  = 70.0;   // picky when already green

input group "=== Gold geometry ==="
input ENUM_TIMEFRAMES InpEntryTF   = PERIOD_M5;
input double   InpSlAtrMult        = 1.4;
input double   InpTpR_Hunt         = 2.0;
input double   InpTpR_Recovery     = 1.4;    // faster scalp TP when recovering
input double   InpTpR_Protect      = 2.5;
input double   InpBE_R             = 1.0;
input double   InpTrail_R          = 1.5;
input double   InpTrailAtrMult     = 1.0;
input int      InpMaxMinutes       = 90;
input double   InpSpreadCapPoints  = 800.0;

input group "=== Sessions (server time) ==="
input bool     InpTradeLondon      = true;   // 07-12
input bool     InpTradeOverlap     = true;   // 12-16
input bool     InpTradeNY          = true;   // 16-21
input bool     InpTradeAsia        = false;  // usually skip thin gold Asia

input group "=== Aggression ==="
input bool     InpRiskOnWhenDD     = true;   // true = pro recovery brain
input double   InpDDTriggerPct     = 1.5;    // equity vs start → recovery mood
input bool     InpLockProfitBE     = true;   // when day green, BE faster

CTrade   g_trade;
double   g_start_equity = 0;
double   g_day_start_equity = 0;
int      g_day_stamp = 0;
int      g_trades_today = 0;
int      g_consec_loss = 0;
datetime g_cooldown_until = 0;
datetime g_last_bar = 0;
int      g_atr_h = INVALID_HANDLE;
int      g_adx_h = INVALID_HANDLE;
int      g_ema21 = INVALID_HANDLE;
int      g_ema55 = INVALID_HANDLE;
int      g_ema9  = INVALID_HANDLE;
int      g_rsi_h = INVALID_HANDLE;
double   g_spread_ema = 0;
bool     g_spread_init = false;

//------------------------------------------------------------------
bool IsGoldSymbol(const string s)
  {
   string u=s; StringToUpper(u);
   return (StringFind(u,"XAU")>=0 || StringFind(u,"GOLD")>=0);
  }

int DayStamp(const datetime t)
  {
   MqlDateTime d; TimeToStruct(t,d);
   return d.year*10000+d.mon*100+d.day;
  }

void RollDay()
  {
   int st=DayStamp(TimeCurrent());
   if(st!=g_day_stamp)
     {
      g_day_stamp=st;
      g_day_start_equity=AccountInfoDouble(ACCOUNT_EQUITY);
      g_trades_today=0;
      PrintFormat("[GoldBrain] new day equity=%.2f", g_day_start_equity);
     }
  }

ENUM_GOLD_MOOD CurrentMood()
  {
   double eq=AccountInfoDouble(ACCOUNT_EQUITY);
   double day_pnl=eq-g_day_start_equity;
   double vs_start=0;
   if(g_start_equity>0) vs_start=100.0*(eq-g_start_equity)/g_start_equity;

   // Already green today → protect gains
   if(day_pnl > MathMax(1.0, g_day_start_equity*0.01))
      return MOOD_PROTECT;

   // Underwater vs start or day → recovery risk-on
   if(InpRiskOnWhenDD && (vs_start <= -InpDDTriggerPct || day_pnl < 0))
      return MOOD_RECOVERY;

   return MOOD_HUNT;
  }

double RiskPctForMood(const ENUM_GOLD_MOOD mood)
  {
   if(mood==MOOD_RECOVERY) return InpRecoveryRiskPct;
   if(mood==MOOD_PROTECT)  return InpProtectRiskPct;
   return InpBaseRiskPct;
  }

double MinScoreForMood(const ENUM_GOLD_MOOD mood)
  {
   if(mood==MOOD_RECOVERY) return InpMinScoreRecovery;
   if(mood==MOOD_PROTECT)  return InpMinScoreProtect;
   return InpMinScoreHunt;
  }

double TpRForMood(const ENUM_GOLD_MOOD mood)
  {
   if(mood==MOOD_RECOVERY) return InpTpR_Recovery;
   if(mood==MOOD_PROTECT)  return InpTpR_Protect;
   return InpTpR_Hunt;
  }

string MoodName(const ENUM_GOLD_MOOD m)
  {
   if(m==MOOD_RECOVERY) return "RECOVERY";
   if(m==MOOD_PROTECT)  return "PROTECT";
   return "HUNT";
  }

//------------------------------------------------------------------
bool SessionOK()
  {
   MqlDateTime d; TimeToStruct(TimeCurrent(),d);
   int h=d.hour;
   if(h>=0 && h<7)  return InpTradeAsia;
   if(h>=7 && h<12) return InpTradeLondon;
   if(h>=12&& h<16) return InpTradeOverlap;
   if(h>=16&& h<21) return InpTradeNY;
   return false;
  }

bool SpreadOK()
  {
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double point=SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   if(point<=0) return false;
   double sp=(ask-bid)/point;
   if(!g_spread_init){ g_spread_ema=sp; g_spread_init=true; }
   else g_spread_ema=0.9*g_spread_ema+0.1*sp;
   double lim=MathMax(InpSpreadCapPoints, g_spread_ema*2.2);
   if(sp>lim)
     {
      PrintFormat("[GoldBrain][BLOCK] spread=%.1f lim=%.1f", sp, lim);
      return false;
     }
   return true;
  }

double ATR(const int shift=1)
  {
   double b[]; ArraySetAsSeries(b,true);
   if(CopyBuffer(g_atr_h,0,shift,1,b)!=1) return 0;
   return b[0];
  }

ENUM_GOLD_REGIME DetectRegime()
  {
   double atr[], adx[], e21[], e55[];
   ArraySetAsSeries(atr,true); ArraySetAsSeries(adx,true);
   ArraySetAsSeries(e21,true); ArraySetAsSeries(e55,true);
   if(CopyBuffer(g_atr_h,0,0,40,atr)<40) return REG_DEAD;
   if(CopyBuffer(g_adx_h,0,0,3,adx)<3) return REG_DEAD;
   if(CopyBuffer(g_ema21,0,0,3,e21)<3) return REG_DEAD;
   if(CopyBuffer(g_ema55,0,0,3,e55)<3) return REG_DEAD;

   double cur=atr[0]; int below=0;
   for(int i=0;i<40;i++) if(atr[i]<=cur) below++;
   double pct=100.0*below/40.0;
   double point=SymbolInfoDouble(_Symbol,SYMBOL_POINT); if(point<=0) point=_Point;

   if(pct<12.0 && MathAbs(e21[0]-e21[2])<8*point) return REG_DEAD;
   if(pct>85.0 || adx[0]>35.0) return REG_VOLATILE;
   if(adx[0]>=20.0 && MathAbs(e21[0]-e55[0])>12*point) return REG_TREND;
   return REG_RANGE;
  }

ENUM_GOLD_BIAS HTFBias()
  {
   int f=iMA(_Symbol,PERIOD_H1,21,0,MODE_EMA,PRICE_CLOSE);
   int s=iMA(_Symbol,PERIOD_H1,55,0,MODE_EMA,PRICE_CLOSE);
   if(f==INVALID_HANDLE || s==INVALID_HANDLE) return BIAS_NONE;
   double a[],b[]; ArraySetAsSeries(a,true); ArraySetAsSeries(b,true);
   bool ok=(CopyBuffer(f,0,0,3,a)==3 && CopyBuffer(s,0,0,3,b)==3);
   IndicatorRelease(f); IndicatorRelease(s);
   if(!ok) return BIAS_NONE;
   if(a[0]>b[0] && a[0]>=a[1]) return BIAS_BUY;
   if(a[0]<b[0] && a[0]<=a[1]) return BIAS_SELL;
   return BIAS_NONE;
  }

//------------------------------------------------------------------
struct GoldSignal
  {
   ENUM_GOLD_BIAS dir;
   double score;
   double sl;
   double tp;
   string tag;
  };

void ClearSig(GoldSignal &s){ s.dir=BIAS_NONE; s.score=0; s.sl=0; s.tp=0; s.tag=""; }

double MakeSL(const ENUM_GOLD_BIAS dir, const double entry, const double atr, const double struct_px)
  {
   double dist=atr*InpSlAtrMult;
   if(dir==BIAS_BUY)
     {
      double sl=entry-dist;
      if(struct_px>0 && struct_px<entry) sl=MathMin(sl, struct_px-atr*0.05);
      return sl;
     }
   if(dir==BIAS_SELL)
     {
      double sl=entry+dist;
      if(struct_px>0 && struct_px>entry) sl=MathMax(sl, struct_px+atr*0.05);
      return sl;
     }
   return 0;
  }

double MakeTP(const ENUM_GOLD_BIAS dir, const double entry, const double sl, const double rmul)
  {
   double r=MathAbs(entry-sl); if(r<=0) return 0;
   return (dir==BIAS_BUY)? entry+r*rmul : entry-r*rmul;
  }

GoldSignal SigTrendPullback(const ENUM_GOLD_REGIME reg, const ENUM_GOLD_BIAS bias, const double atr, const double rmul)
  {
   GoldSignal s; ClearSig(s); s.tag="TrendPB";
   if(reg==REG_DEAD || reg==REG_RANGE || atr<=0) return s;
   double e9[],e21[],e55[]; ArraySetAsSeries(e9,true); ArraySetAsSeries(e21,true); ArraySetAsSeries(e55,true);
   if(CopyBuffer(g_ema9,0,0,5,e9)<5) return s;
   if(CopyBuffer(g_ema21,0,0,5,e21)<5) return s;
   if(CopyBuffer(g_ema55,0,0,5,e55)<5) return s;
   MqlRates r[]; ArraySetAsSeries(r,true);
   if(CopyRates(_Symbol,InpEntryTF,0,5,r)<5) return s;
   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);

   if(e21[0]>e55[0] && bias!=BIAS_SELL)
     {
      if(r[1].low<=e9[1] && r[1].close>e9[1] && r[1].close>r[1].open && r[1].close>e21[1])
        {
         s.dir=BIAS_BUY; s.score=40; if(bias==BIAS_BUY) s.score+=15; if(reg==REG_TREND) s.score+=10;
         s.sl=MakeSL(BIAS_BUY,ask,atr,r[1].low); s.tp=MakeTP(BIAS_BUY,ask,s.sl,rmul);
        }
     }
   if(e21[0]<e55[0] && bias!=BIAS_BUY)
     {
      if(r[1].high>=e9[1] && r[1].close<e9[1] && r[1].close<r[1].open && r[1].close<e21[1])
        {
         s.dir=BIAS_SELL; s.score=40; if(bias==BIAS_SELL) s.score+=15; if(reg==REG_TREND) s.score+=10;
         s.sl=MakeSL(BIAS_SELL,bid,atr,r[1].high); s.tp=MakeTP(BIAS_SELL,bid,s.sl,rmul);
        }
     }
   return s;
  }

GoldSignal SigLiquiditySweep(const ENUM_GOLD_BIAS bias, const double atr, const double rmul)
  {
   GoldSignal s; ClearSig(s); s.tag="LiqSweep";
   if(atr<=0) return s;
   MqlRates r[]; ArraySetAsSeries(r,true);
   if(CopyRates(_Symbol,InpEntryTF,0,20,r)<20) return s;
   double ph=r[2].high, pl=r[2].low;
   for(int i=3;i<=7;i++){ if(r[i].high>ph) ph=r[i].high; if(r[i].low<pl) pl=r[i].low; }
   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);

   // buy-side stop hunt → long
   if(r[1].high>ph && r[1].close<ph && r[1].close>r[1].open && bias!=BIAS_SELL)
     {
      s.dir=BIAS_BUY; s.score=45;
      if(r[1].close>r[2].high) s.score+=15;
      if(bias==BIAS_BUY) s.score+=10;
      s.sl=MakeSL(BIAS_BUY,ask,atr,r[1].low); s.tp=MakeTP(BIAS_BUY,ask,s.sl,rmul);
      return s;
     }
   // sell-side stop hunt → short
   if(r[1].low<pl && r[1].close>pl && r[1].close<r[1].open && bias!=BIAS_BUY)
     {
      s.dir=BIAS_SELL; s.score=45;
      if(r[1].close<r[2].low) s.score+=15;
      if(bias==BIAS_SELL) s.score+=10;
      s.sl=MakeSL(BIAS_SELL,bid,atr,r[1].high); s.tp=MakeTP(BIAS_SELL,bid,s.sl,rmul);
      return s;
     }
   return s;
  }

GoldSignal SigCompressionBreak(const ENUM_GOLD_BIAS bias, const double atr, const double rmul)
  {
   GoldSignal s; ClearSig(s); s.tag="SqueezeBO";
   if(atr<=0) return s;
   double atrb[]; ArraySetAsSeries(atrb,true);
   if(CopyBuffer(g_atr_h,0,0,25,atrb)<25) return s;
   double mn=atrb[1]; for(int i=2;i<=20;i++) if(atrb[i]<mn) mn=atrb[i];
   bool squeeze=(atrb[3]<=mn*1.15);
   MqlRates r[]; ArraySetAsSeries(r,true);
   if(CopyRates(_Symbol,InpEntryTF,0,20,r)<20) return s;
   double rh=r[3].high, rl=r[3].low;
   for(int i=4;i<=12;i++){ if(r[i].high>rh) rh=r[i].high; if(r[i].low<rl) rl=r[i].low; }
   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);

   if(squeeze && r[2].close>rh && r[1].low<=rh && r[1].close>rh && bias!=BIAS_SELL)
     {
      s.dir=BIAS_BUY; s.score=42; if(bias==BIAS_BUY) s.score+=12;
      s.sl=MakeSL(BIAS_BUY,ask,atr,rl); s.tp=MakeTP(BIAS_BUY,ask,s.sl,rmul); return s;
     }
   if(squeeze && r[2].close<rl && r[1].high>=rl && r[1].close<rl && bias!=BIAS_BUY)
     {
      s.dir=BIAS_SELL; s.score=42; if(bias==BIAS_SELL) s.score+=12;
      s.sl=MakeSL(BIAS_SELL,bid,atr,rh); s.tp=MakeTP(BIAS_SELL,bid,s.sl,rmul); return s;
     }
   return s;
  }

GoldSignal SigSessionImpulse(const ENUM_GOLD_BIAS bias, const double atr, const double rmul)
  {
   // London/NY open displacement continuation — classic gold pro setup
   GoldSignal s; ClearSig(s); s.tag="SessionImpulse";
   if(atr<=0) return s;
   MqlDateTime d; TimeToStruct(TimeCurrent(),d);
   bool killzone=((d.hour==7||d.hour==8||d.hour==12||d.hour==13||d.hour==16||d.hour==17));
   if(!killzone) return s;
   MqlRates r[]; ArraySetAsSeries(r,true);
   if(CopyRates(_Symbol,InpEntryTF,0,6,r)<6) return s;
   double body=MathAbs(r[1].close-r[1].open);
   if(body < atr*0.8) return s;
   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);

   if(r[1].close>r[1].open && r[1].close>r[2].high && bias!=BIAS_SELL)
     {
      s.dir=BIAS_BUY; s.score=38; if(bias==BIAS_BUY) s.score+=12;
      s.sl=MakeSL(BIAS_BUY,ask,atr,r[1].low); s.tp=MakeTP(BIAS_BUY,ask,s.sl,rmul); return s;
     }
   if(r[1].close<r[1].open && r[1].close<r[2].low && bias!=BIAS_BUY)
     {
      s.dir=BIAS_SELL; s.score=38; if(bias==BIAS_SELL) s.score+=12;
      s.sl=MakeSL(BIAS_SELL,bid,atr,r[1].high); s.tp=MakeTP(BIAS_SELL,bid,s.sl,rmul); return s;
     }
   return s;
  }

//------------------------------------------------------------------
bool Confluence(GoldSignal &votes[], const int n, const ENUM_GOLD_BIAS bias,
                const ENUM_GOLD_MOOD mood, GoldSignal &out)
  {
   ClearSig(out);
   double buy=0, sell=0, buy_sl=0, sell_sl=0, buy_tp=0, sell_tp=0, bestb=-1, bests=-1;
   string btag="", stag="";
   int bn=0, sn=0;
   for(int i=0;i<n;i++)
     {
      if(votes[i].dir==BIAS_BUY && votes[i].score>0)
        {
         buy+=votes[i].score; bn++;
         if(buy_sl==0 || votes[i].sl<buy_sl) buy_sl=votes[i].sl;
         if(votes[i].tp>buy_tp) buy_tp=votes[i].tp;
         if(votes[i].score>bestb){ bestb=votes[i].score; btag=votes[i].tag; }
        }
      else if(votes[i].dir==BIAS_SELL && votes[i].score>0)
        {
         sell+=votes[i].score; sn++;
         if(sell_sl==0 || votes[i].sl>sell_sl) sell_sl=votes[i].sl;
         if(sell_tp==0 || votes[i].tp<sell_tp) sell_tp=votes[i].tp;
         if(votes[i].score>bests){ bests=votes[i].score; stag=votes[i].tag; }
        }
     }
   buy=MathMin(100.0,buy); sell=MathMin(100.0,sell);
   // HTF soft veto
   if(bias==BIAS_BUY)  sell=MathMax(0.0, sell-20.0);
   if(bias==BIAS_SELL) buy =MathMax(0.0, buy-20.0);

   double thr=MinScoreForMood(mood);
   if(buy>sell && buy>=thr)
     {
      out.dir=BIAS_BUY; out.score=buy; out.sl=buy_sl; out.tp=buy_tp; out.tag=btag;
      // recovery: single strong vote OK; protect: prefer 2+
      if(mood==MOOD_PROTECT && bn<2 && buy<thr+10) { ClearSig(out); return false; }
      return (out.sl>0);
     }
   if(sell>buy && sell>=thr)
     {
      out.dir=BIAS_SELL; out.score=sell; out.sl=sell_sl; out.tp=sell_tp; out.tag=stag;
      if(mood==MOOD_PROTECT && sn<2 && sell<thr+10) { ClearSig(out); return false; }
      return (out.sl>0);
     }
   return false;
  }

//------------------------------------------------------------------
int CountOurPositions()
  {
   int c=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong t=PositionGetTicket(i); if(t==0) continue;
      if(!PositionSelectByTicket(t)) continue;
      if((long)PositionGetInteger(POSITION_MAGIC)!=InpMagic) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      c++;
     }
   return c;
  }

double NormalizeLots(double lots)
  {
   double mn=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double mx=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   double st=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   if(st<=0) st=0.01; if(mn<=0) mn=0.01;
   lots=MathFloor(lots/st+1e-9)*st;
   if(lots<mn) return 0;
   if(lots>mx) lots=mx;
   return NormalizeDouble(lots,2);
  }

bool CalcLots(const ENUM_GOLD_BIAS dir, const double entry, const double sl,
              const double risk_pct, double &lots_out, string &why)
  {
   lots_out=0; why="";
   double eq=AccountInfoDouble(ACCOUNT_EQUITY);
   double floor=MathMax(InpMinFloorMoney, g_start_equity*InpEquityFloorPct);
   if(eq<=floor){ why="equity_floor"; return false; }

   double sl_dist=MathAbs(entry-sl);
   if(sl_dist<=0){ why="bad_sl"; return false; }
   double tick_size=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   double tick_value=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   if(tick_size<=0 || tick_value<=0){ why="tick_meta"; return false; }

   double risk_money=eq*(risk_pct/100.0);
   double money_per_lot=(sl_dist/tick_size)*tick_value;
   if(money_per_lot<=0){ why="mpl_zero"; return false; }

   double lots=NormalizeLots(risk_money/money_per_lot);
   if(lots<=0)
     {
      double min_lot=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
      why=StringFormat("min_lot_over_risk need=%.2f budget=%.2f", min_lot*money_per_lot, risk_money);
      return false;
     }

   double actual=lots*money_per_lot;
   if(eq-actual < floor){ why="sl_breaches_floor"; return false; }

   double margin=0;
   ENUM_ORDER_TYPE ot=(dir==BIAS_BUY?ORDER_TYPE_BUY:ORDER_TYPE_SELL);
   if(!OrderCalcMargin(ot,_Symbol,lots,entry,margin)){ why="margin_calc"; return false; }
   double free=AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   if(margin>free){ why="no_free_margin"; return false; }
   double usage=100.0*(AccountInfoDouble(ACCOUNT_MARGIN)+margin)/MathMax(eq,1.0);
   if(usage>InpMaxMarginPct){ why="margin_cap"; return false; }

   lots_out=lots; why="ok"; return true;
  }

bool OpenTrade(const GoldSignal &sig, const ENUM_GOLD_MOOD mood)
  {
   if(sig.dir==BIAS_NONE || sig.sl<=0) return false;
   double entry=(sig.dir==BIAS_BUY)? SymbolInfoDouble(_Symbol,SYMBOL_ASK):SymbolInfoDouble(_Symbol,SYMBOL_BID);
   if(sig.dir==BIAS_BUY && sig.sl>=entry) return false;
   if(sig.dir==BIAS_SELL && sig.sl<=entry) return false;

   double lots; string why;
   if(!CalcLots(sig.dir, entry, sig.sl, RiskPctForMood(mood), lots, why))
     {
      PrintFormat("[GoldBrain][BLOCK] lot %s", why);
      return false;
     }

   double tp=sig.tp;
   if(tp<=0) tp=MakeTP(sig.dir, entry, sig.sl, TpRForMood(mood));

   string cmt=StringFormat("G|%s|%.0f|%s", sig.tag, sig.score, MoodName(mood));
   g_trade.SetExpertMagicNumber(InpMagic);
   g_trade.SetDeviationInPoints(InpSlippage);
   g_trade.SetTypeFillingBySymbol(_Symbol);

   bool ok=false;
   if(sig.dir==BIAS_BUY) ok=g_trade.Buy(lots,_Symbol,0,sig.sl,tp,cmt);
   else ok=g_trade.Sell(lots,_Symbol,0,sig.sl,tp,cmt);

   if(!ok)
     {
      PrintFormat("[GoldBrain] open fail %d %s", g_trade.ResultRetcode(), g_trade.ResultRetcodeDescription());
      return false;
     }
   g_trades_today++;
   PrintFormat("[GoldBrain] OPEN %s lots=%.2f score=%.1f mood=%s tag=%s",
               (sig.dir==BIAS_BUY?"BUY":"SELL"), lots, sig.score, MoodName(mood), sig.tag);
   return true;
  }

//------------------------------------------------------------------
void ManageOpen()
  {
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong ticket=PositionGetTicket(i); if(ticket==0) continue;
      if(!PositionSelectByTicket(ticket)) continue;
      if((long)PositionGetInteger(POSITION_MAGIC)!=InpMagic) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;

      double open=PositionGetDouble(POSITION_PRICE_OPEN);
      double sl=PositionGetDouble(POSITION_SL);
      double tp=PositionGetDouble(POSITION_TP);
      double vol=PositionGetDouble(POSITION_VOLUME);
      datetime ot=(datetime)PositionGetInteger(POSITION_TIME);
      long type=PositionGetInteger(POSITION_TYPE);
      bool is_buy=(type==POSITION_TYPE_BUY);
      double price=is_buy? SymbolInfoDouble(_Symbol,SYMBOL_BID):SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      double r0=MathAbs(open-sl); if(r0<=0) continue;
      double favor=is_buy? (price-open):(open-price);
      double rn=favor/r0;

      ENUM_GOLD_MOOD mood=CurrentMood();
      double be_trig=InpBE_R;
      if(InpLockProfitBE && mood==MOOD_PROTECT) be_trig=0.7;

      // partial 50% @1R
      if(rn>=1.0)
        {
         double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
         double minl=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
         double half=MathFloor((vol*0.5)/step)*step;
         static ulong last_partial=0;
         if(half>=minl && vol-half>=minl-1e-8 && ticket!=last_partial)
           {
            if(g_trade.PositionClosePartial(ticket,half))
               last_partial=ticket;
           }
        }

      // BE
      if(rn>=be_trig)
        {
         double point=SymbolInfoDouble(_Symbol,SYMBOL_POINT);
         int stops=(int)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);
         double be=is_buy? open+MathMax(stops,2)*point : open-MathMax(stops,2)*point;
         bool better=is_buy? (sl<be||sl==0) : (sl>be||sl==0);
         if(better) g_trade.PositionModify(ticket,be,tp);
        }

      // trail
      if(rn>=InpTrail_R)
        {
         double atr=ATR(0); if(atr<=0) atr=ATR(1);
         if(atr>0)
           {
            double nsl=is_buy? price-atr*InpTrailAtrMult : price+atr*InpTrailAtrMult;
            if(is_buy && nsl>sl && nsl<price) g_trade.PositionModify(ticket,nsl,tp);
            if(!is_buy && (sl==0||nsl<sl) && nsl>price) g_trade.PositionModify(ticket,nsl,tp);
           }
        }

      if(InpMaxMinutes>0 && (TimeCurrent()-ot)>=InpMaxMinutes*60)
         g_trade.PositionClose(ticket);
     }
  }

//------------------------------------------------------------------
bool GuardsAllowEntry(const ENUM_GOLD_MOOD mood)
  {
   RollDay();
   if(TimeCurrent()<g_cooldown_until) return false;
   if(!IsGoldSymbol(_Symbol))
     {
      Print("[GoldBrain][BLOCK] chart is not XAU/GOLD");
      return false;
     }
   if(!SessionOK()) return false;
   if(!SpreadOK()) return false;

   double eq=AccountInfoDouble(ACCOUNT_EQUITY);
   double floor=MathMax(InpMinFloorMoney, g_start_equity*InpEquityFloorPct);
   if(eq<=floor){ Print("[GoldBrain][BLOCK] equity_floor"); return false; }

   double day_pnl=eq-g_day_start_equity;
   double halt=g_day_start_equity*(InpDailyLossHaltPct/100.0);
   if(day_pnl <= -halt){ Print("[GoldBrain][BLOCK] daily_halt"); return false; }

   if(g_trades_today>=InpMaxTradesPerDay) return false;
   if(CountOurPositions()>=InpMaxOpenPos) return false;
   return true;
  }

void ThinkAndTrade()
  {
   datetime bar=iTime(_Symbol,InpEntryTF,0);
   if(bar==0 || bar==g_last_bar) return;
   g_last_bar=bar;

   ENUM_GOLD_MOOD mood=CurrentMood();
   if(!GuardsAllowEntry(mood)) return;

   ENUM_GOLD_REGIME reg=DetectRegime();
   if(reg==REG_DEAD)
     {
      // Recovery mood: still allow sweep/session if not dead-dead; skip only true dead
      if(mood!=MOOD_RECOVERY){ Print("[GoldBrain][BLOCK] regime_DEAD"); return; }
     }

   double atr=ATR(1); if(atr<=0) atr=ATR(0);
   if(atr<=0) return;
   ENUM_GOLD_BIAS bias=HTFBias();
   double rmul=TpRForMood(mood);

   GoldSignal votes[4];
   votes[0]=SigTrendPullback(reg,bias,atr,rmul);
   votes[1]=SigLiquiditySweep(bias,atr,rmul);
   votes[2]=SigCompressionBreak(bias,atr,rmul);
   votes[3]=SigSessionImpulse(bias,atr,rmul);

   GoldSignal setup;
   if(!Confluence(votes,4,bias,mood,setup))
     {
      // optional log only when any vote existed
      return;
     }

   PrintFormat("[GoldBrain] mood=%s score=%.1f tag=%s bias=%d reg=%d",
               MoodName(mood), setup.score, setup.tag, (int)bias, (int)reg);
   OpenTrade(setup, mood);
  }

//------------------------------------------------------------------
int OnInit()
  {
   if(!IsGoldSymbol(_Symbol))
     {
      Alert("ProTraderGold: yalnız XAUUSD / XAUUSDc / GOLD chartında işləyir. İndi: ", _Symbol);
      return INIT_FAILED;
     }

   g_start_equity=AccountInfoDouble(ACCOUNT_EQUITY);
   if(g_start_equity<=0) g_start_equity=AccountInfoDouble(ACCOUNT_BALANCE);
   g_day_start_equity=g_start_equity;
   g_day_stamp=DayStamp(TimeCurrent());

   g_atr_h=iATR(_Symbol,InpEntryTF,14);
   g_adx_h=iADX(_Symbol,InpEntryTF,14);
   g_ema21=iMA(_Symbol,InpEntryTF,21,0,MODE_EMA,PRICE_CLOSE);
   g_ema55=iMA(_Symbol,InpEntryTF,55,0,MODE_EMA,PRICE_CLOSE);
   g_ema9 =iMA(_Symbol,InpEntryTF,9,0,MODE_EMA,PRICE_CLOSE);
   g_rsi_h=iRSI(_Symbol,InpEntryTF,14,PRICE_CLOSE);
   if(g_atr_h==INVALID_HANDLE || g_adx_h==INVALID_HANDLE || g_ema21==INVALID_HANDLE ||
      g_ema55==INVALID_HANDLE || g_ema9==INVALID_HANDLE)
      return INIT_FAILED;

   g_trade.SetExpertMagicNumber(InpMagic);
   g_trade.SetDeviationInPoints(InpSlippage);
   g_trade.SetTypeFillingBySymbol(_Symbol);
   EventSetTimer(1);

   PrintFormat("[GoldBrain] init %s start_eq=%.2f floor=%.2f entryTF=%d",
               _Symbol, g_start_equity, MathMax(InpMinFloorMoney,g_start_equity*InpEquityFloorPct), (int)InpEntryTF);
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   EventKillTimer();
   if(g_atr_h!=INVALID_HANDLE) IndicatorRelease(g_atr_h);
   if(g_adx_h!=INVALID_HANDLE) IndicatorRelease(g_adx_h);
   if(g_ema21!=INVALID_HANDLE) IndicatorRelease(g_ema21);
   if(g_ema55!=INVALID_HANDLE) IndicatorRelease(g_ema55);
   if(g_ema9!=INVALID_HANDLE) IndicatorRelease(g_ema9);
   if(g_rsi_h!=INVALID_HANDLE) IndicatorRelease(g_rsi_h);
  }

void OnTimer()
  {
   ManageOpen();
   ThinkAndTrade();
  }

void OnTick()
  {
   // warm spread + manage
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double point=SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   if(point>0)
     {
      double sp=(ask-bid)/point;
      if(!g_spread_init){ g_spread_ema=sp; g_spread_init=true; }
      else g_spread_ema=0.9*g_spread_ema+0.1*sp;
     }
   ManageOpen();
  }

void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
   if(trans.type!=TRADE_TRANSACTION_DEAL_ADD) return;
   ulong deal=trans.deal; if(deal==0) return;
   if(!HistoryDealSelect(deal)) return;
   if((long)HistoryDealGetInteger(deal,DEAL_MAGIC)!=InpMagic) return;
   long entry=HistoryDealGetInteger(deal,DEAL_ENTRY);
   if(entry==DEAL_ENTRY_OUT || entry==DEAL_ENTRY_OUT_BY)
     {
      double profit=HistoryDealGetDouble(deal,DEAL_PROFIT)
                   +HistoryDealGetDouble(deal,DEAL_SWAP)
                   +HistoryDealGetDouble(deal,DEAL_COMMISSION);
      if(profit<0)
        {
         g_consec_loss++;
         if(g_consec_loss>=3)
           {
            int mins=(CurrentMood()==MOOD_RECOVERY? 15:45);
            g_cooldown_until=TimeCurrent()+mins*60;
            PrintFormat("[GoldBrain] cooldown %d min after losses", mins);
           }
        }
      else if(profit>0) g_consec_loss=0;
     }
  }
//+------------------------------------------------------------------+
