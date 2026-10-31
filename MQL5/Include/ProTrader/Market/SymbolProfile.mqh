#ifndef PROTRADER_SYMBOL_PROFILE_MQH
#define PROTRADER_SYMBOL_PROFILE_MQH

#include "../Types.mqh"
#include "../Config.mqh"

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

#endif
