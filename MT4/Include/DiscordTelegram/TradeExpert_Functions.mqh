//+------------------------------------------------------------------+
//|                                        TradeExpert_Functions.mqh |
//|                         Copyright 2022, nguemechieu noel martial |
//|                       https://github.com/nguemechieu/TradeExpert |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, nguemechieu noel martial"
#property link      "https://github.com/nguemechieu/TradeExpert"
#property strict
#include <DiscordTelegram/TRADEEXPERT_INPUTS_PARAMETRES.mqh>


CEngine engine;
CTradeObj trades[2000];

           int NomNews=100;
int NumOfSymbols=StringSplit(InpUsedSymbols,',',Symbols);
string _split=InpUsedSymbols;
//+------------------------------------------------------------------+
//|                      SignalFilter                                            |
//+------------------------------------------------------------------+

int signalFilter(int buySignal,int sellSignal){
 
    bool alignx=InpAlign;
  ;int signalx=0;
  string commentx1,commentx;
   int buyx=buySignal;
  
  int sellx=sellSignal;
  
   if(alignx)
     {
      if(buyx== 1 && sellx==-1)
        {
         signalx= 1;commentx="BUY SIGNAL";
        }
        else
      if(buyx == -1 && sellx==1)
        {
       signalx= -1;commentx1="SELL SIGNAL";
        }
     }
   else
     {
  
     
      if(buyx == 1)
        {
         signalx= 1;commentx1="BUY SIGNAL";
        }
      if(sellx == -1)
        {
        signalx= -1;
        
        commentx="SELL SIGNAL";}
        }
   
return signalx;
}
    

 int signalList[10];

 //+------------------------------------------------------------------+
 //|                       TradeSignal2                                           |
 //+------------------------------------------------------------------+

ENUM_ORDER_TYPE TradeSignal2(int i) //Get    trades signals
  {
  
  if(i==option)  return 0;
      string sigList[10];
      
      sigList[0]=inpInd0;
         sigList[1]=inpInd1;
            sigList[2]=inpInd2;  
             sigList[3]=inpInd3;
                sigList[4]=inpInd0Ex;
                   sigList[5]=inpInd1Ex;
                      sigList[6]=inpInd2Ex;
                      
                         sigList[7]=inpInd3Ex;
 
        //----------Exit sell and open Buy signals 
    signalList[0]=(int)iCustom(Symbols[i],inpTF0,sigList[0],0,inpShift0); 
         signalList[1]=(int)iCustom(Symbols[i],inpTF1,sigList[1],0,inpShift1);     
           signalList[2]=  (int)iCustom(Symbols[i],inpTF2,sigList[2],0,inpShift2);   
            signalList[3]= (int)iCustom(Symbols[i],inpTF3,sigList[3],0,inpShift3);
               
        //----------Exit buy and open sell signal
          signalList[4]=   (int)iCustom(Symbols[i],inpTF0Ex,sigList[4],1,inpShift0Ex);
           signalList[5]=  (int)iCustom(Symbols[i],inpTF1Ex,sigList[5],1,inpShift1Ex);
            signalList[6]=  (int)iCustom(Symbols[i],inpTF2Ex,sigList[6],1,inpShift2Ex);
          signalList[7]=   (int)iCustom(Symbols[i],inpTF3Ex,sigList[7],1,inpShift3Ex);
            //FILTERED 4 SIGNALS
    
         int s0=       signalFilter(  signalList[0],  signalList[4]);
         
           int s1=       signalFilter(  signalList[1],  signalList[5]);
         
           int s2=       signalFilter(  signalList[2],  signalList[6]);
         
           int s3=       signalFilter(  signalList[3],  signalList[7]);
         
         
    //GET ALL FILTERED SIGNALS
    int signalFinalList[4];
    signalFinalList[0]=s0;
      signalFinalList[1]=s1; 
       signalFinalList[2]=s2;
         signalFinalList[3]=s3;
         
  printf(  StringFormat("%s ||Master %s ||Slave1 %s||Slave2 %s ||Slave3 %s \n===  Exits === \n||MasterExit %s ||Slave1Exit %s||Slave2Exit %s ||Slave3Exit %s",
    (string)Symbols[i],
   (string) signalList[0], 
    (string)      signalList[1],
        (string)    signalList[2]  ,
            (string) signalList[3],
               
        //----------Exit buy and open sell signal
          (string) signalList[4],
          (string)  signalList[5],
           (string)  signalList[6],
          (string) signalList[7] 
 )); 
     
      
    
    
    
    
    
    
    
    
    

 
 
 //===================JOINT STRATEGY ===========================
 
 if(inpOpenTradeStrategy ==joint)
 
{ 
 
 
 
 
 for(int h=0;h<4;h++){
 
 if(signalFinalList[h]==1&& h==3){
 return OP_BUY;
 }else  if(signalFinalList[h]==-1&&h==3){
 return OP_SELL;}
 
 }
 
 
    

return 0;

}else //===================SEPARATE STRATEGY ===========================
  if(inpOpenTradeStrategy ==separate)
        {





        }

 
 return 0;
 }
 
bool inTimeInterval(datetime t, int From_Hour, int From_Min, int To_Hour, int To_Min)
  {
  
  if(UseTime==No)return true;
   string TOD = TimeToString(t, TIME_MINUTES);
   string TOD_From = StringFormat("%02d", From_Hour)+":"+StringFormat("%02d", From_Min);
   string TOD_To = StringFormat("%02d", To_Hour)+":"+StringFormat("%02d", To_Min);
   
 
   
   
   return((StringCompare(TOD, TOD_From) >= 0 && StringCompare(TOD, TOD_To) <= 0)
     || (StringCompare(TOD_From, TOD_To) > 0
       && ((StringCompare(TOD, TOD_From) >= 0 && StringCompare(TOD, "23:59") <= 0)
         || (StringCompare(TOD, "00:00") >= 0 && StringCompare(TOD, TOD_To) <= 0))));
  }




void  DisPlaySiGnal(){

   int i; 
   string obj_name="SIGNAL_PANEL"; 
   long current_chart_id=ChartID(); 
//--- creating label object (it does not have time/price coordinates) 
   if(!ObjectCreate(current_chart_id,obj_name,OBJ_RECTANGLE_LABEL,0,0,0)) 
     { 
      Print("Error: can't create label! code #",GetLastError()); 
   
     } 
//--- set color to Red 
   ObjectSetInteger(current_chart_id,obj_name,OBJPROP_COLOR,clrChocolate); 
//--- move object down and change its text 
   for(i=0; i<NumOfSymbols; i++) 
     { 
      //--- set text property 
      ObjectSetString(current_chart_id,obj_name,OBJPROP_TEXT,StringFormat("Simple Label at y= %d",i)); 
      //--- set distance property 
      ObjectSet(obj_name,OBJPROP_YDISTANCE,i); 
      //--- forced chart redraw 
      ChartRedraw(current_chart_id); 
      Sleep(10); 
     } 
//--- set color to Blue 
   ObjectSetInteger(current_chart_id,obj_name,OBJPROP_COLOR,clrBlue); 
//--- move object up and change its text 
   for(i=NumOfSymbols-1; i>0; i--) 
     { 
      //--- set text property 
      ObjectSetString(current_chart_id,obj_name,OBJPROP_TEXT,StringFormat("Simple Label at y= %d",i)); 
      //--- set distance property 
      ObjectSet(obj_name,OBJPROP_YDISTANCE,i); 
      //--- forced chart redraw 
      ChartRedraw(current_chart_id); 
      Sleep(10); 
     } 
//--- delete object 
   ObjectDelete(obj_name); 
  

}









void CloseByDuration(int sec) //close trades opened longer than sec seconds
  {
   if(!IsTradeAllowed()) return;
   bool success = false;
   int err = 0;
   int total = OrdersTotal();
   int orderList[][2];
   int orderCount = 0;
   int i;
   for(i = 0; i < total; i++)
     {
      while(IsTradeContextBusy()) Sleep(100);
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderMagicNumber() != MagicNumber || OrderSymbol() != _Symbol || OrderType() > 1 || OrderOpenTime() + sec > TimeCurrent()) continue;
      orderCount++;
      ArrayResize(orderList, orderCount);
      orderList[orderCount - 1][0] = (int)OrderOpenTime();
      orderList[orderCount - 1][1] = OrderTicket();
     }
   if(orderCount > 0)
      ArraySort(orderList, WHOLE_ARRAY, 0, MODE_ASCEND);
   for(i = 0; i < orderCount; i++)
     {
      if(!OrderSelect(orderList[i][1], SELECT_BY_POS, MODE_TRADES)&&OrderSymbol()!=_Symbol) continue;
      while(IsTradeContextBusy()) Sleep(100);
      RefreshRates();
    double price = Bid;
      if(OrderType() == OP_SELL)
         price = Ask();
      success = OrderClose(i, NormalizeDouble(OrderLots(), LotDigits), NormalizeDouble(price, Digits()), MaxSlippage, clrWhite);
      if(!success)
        {
         err = GetLastError();
         myAlert("error", "OrderClose failed; error #"+IntegerToString(err)+" "+ErrorDescription(err));
        }
     }
   if(success) myAlert("order", "Orders closed by duration: "+Symbol()+" Magic #"+IntegerToString(MagicNumber));
  }

void DeleteByDuration(int sec) //delete pending order after time since placing the order
  {
   if(!IsTradeAllowed()) return;
   bool success = false;
   int err = 0;
   int total = OrdersTotal();
   int orderList[][2];
   int orderCount = 0;
   int i;
   for(i = 0; i < total; i++)
     {
      while(IsTradeContextBusy()) Sleep(100);
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderMagicNumber() != MagicNumber || OrderSymbol() != Symbol() || OrderType() <= 1 || OrderOpenTime() + sec > TimeCurrent()) continue;
      orderCount++;
      ArrayResize(orderList, orderCount);
      orderList[orderCount - 1][0] = (int)OrderOpenTime();
      orderList[orderCount - 1][1] = OrderTicket();
     }
   if(orderCount > 0)
      ArraySort(orderList, WHOLE_ARRAY, 0, MODE_ASCEND);
   for(i = 0; i < orderCount; i++)
     {
      if(!OrderSelect(orderList[i][1], SELECT_BY_TICKET, MODE_TRADES)) continue;
      while(IsTradeContextBusy()) Sleep(100);
      RefreshRates();
      success = OrderDelete(OrderTicket());
      if(!success)
        {
         err = GetLastError();
         myAlert("error", "OrderDelete failed; error #"+IntegerToString(err)+" "+ErrorDescription(err));
        }
     }
   if(success) myAlert("order", "Orders deleted by duration: "+Symbol()+" Magic #"+IntegerToString(MagicNumber));
  }

void DeleteByDistance(double distance) //delete pending order if price went too far from it
  {
   if(!IsTradeAllowed()) return;
   bool success = false;
   int err = 0;
   int total = OrdersTotal();
   int orderList[][2];
   int orderCount = 0;
   int i;
   for(i = 0; i < total; i++)
     {
      while(IsTradeContextBusy()) Sleep(100);
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderMagicNumber() != MagicNumber || OrderSymbol() != Symbol() || OrderType() <= 1) continue;
      orderCount++;
      ArrayResize(orderList, orderCount);
      orderList[orderCount - 1][0] = (int)OrderOpenTime();
      orderList[orderCount - 1][1] = OrderTicket();
     }
   if(orderCount > 0)
      ArraySort(orderList, WHOLE_ARRAY, 0, MODE_ASCEND);
   for(i = 0; i < orderCount; i++)
     {
      if(!OrderSelect(orderList[i][1], SELECT_BY_TICKET, MODE_TRADES)) continue;
      while(IsTradeContextBusy()) Sleep(100);
      RefreshRates();
     double price = (OrderType() % 2 == 1) ? Ask : Bid;
      if(MathAbs(OrderOpenPrice() - price) <= distance) continue;
      success = OrderDelete(OrderTicket());
      if(!success)
        {
         err = GetLastError();
         myAlert("error", "OrderDelete failed; error #"+IntegerToString(err)+" "+ErrorDescription(err));
        }
     }
   if(success) myAlert("order", "Orders deleted by distance: "+Symbol()+" Magic #"+IntegerToString(MagicNumber));
  }

double MM_Size() //martingale / anti-martingale
  {
   double lots = MM_Martingale_Start;
   double MaxLot = MarketInfo(Symbol(), MODE_MAXLOT);
   double MinLot = MarketInfo(Symbol(), MODE_MINLOT);
   if(SelectLastHistoryTrade())
     {
      double orderprofit = OrderProfit();
      double orderlots = OrderLots();
      double boprofit = BOProfit(OrderTicket());
      if(orderprofit + boprofit > 0 && !MM_Martingale_RestartProfit)
         lots = orderlots * MM_Martingale_ProfitFactor;
      else if(orderprofit + boprofit < 0 && !MM_Martingale_RestartLoss)
         lots = orderlots * MM_Martingale_LossFactor;
      else if(orderprofit + boprofit == 0)
         lots = orderlots;
     }
   if(ConsecutivePL(false, MM_Martingale_RestartLosses))
      lots = MM_Martingale_Start;
   if(ConsecutivePL(true, MM_Martingale_RestartProfits))
      lots = MM_Martingale_Start;
   if(lots > MaxLot) lots = MaxLot;
   if(lots < MinLot) lots = MinLot;
   return(lots);
  }

bool TradeDayOfWeek()
  {
   int day = DayOfWeek();
   return((TradeMonday && day == 1)
   || (TradeTuesday && day == 2)
   || (TradeWednesday && day == 3)
   || (TradeThursday && day == 4)
   || (TradeFriday && day == 5)
   || (TradeSaturday && day == 6)
   || (TradeSunday && day == 0));
  }

void CloseTradesAtPL(double PL) //close all trades if total P/L >= profit (positive) or total P/L <= loss (negative)
  {
   double totalPL = TotalOpenProfit(0);
   if((PL > 0 && totalPL >= PL) || (PL < 0 && totalPL <= PL))
     {
      myOrderClose(OP_BUY, 100, "");
      myOrderClose(OP_SELL, 100, "");
     }
  }

void myAlert(string type, string message1)
  {
   if(type == "print")
      Print(message);
   else if(type == "error")
     {
      Print(type+" | TradeExpertPro @ "+Symbol()+","+IntegerToString(Period())+" | "+message1);
     }
   else if(type == "order")
     {
     }
   else if(type == "modify")
     {
     }
  }

int TradesCount(int type) //returns # of open trades for order type, current symbol and magic number
  {
   int result = 0;
   int total = OrdersTotal();
   for(int i = 0; i < total; i++)
     {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) continue;
      if(OrderMagicNumber() != MagicNumber || OrderSymbol() != Symbol() || OrderType() != type) continue;
      result++;
     }
   return(result);
  }

bool SelectLastHistoryTrade()
  {
   int lastOrder = -1;
   int total = OrdersHistoryTotal();
   for(int i = total-1; i >= 0; i--)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) continue;
      if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
        {
         lastOrder = i;
         break;
        }
     } 
   return(lastOrder >= 0);
  }

double BOProfit(int ticket) //Binary Options profit
  {
   int total = OrdersHistoryTotal();
   for(int i = total-1; i >= 0; i--)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) continue;
      if(StringSubstr(OrderComment(), 0, 2) == "BO" && StringFind(OrderComment(), "#"+IntegerToString(ticket)+" ") >= 0)
         return OrderProfit();
     }
   return 0;
  }

bool ConsecutivePL(bool profits, int n)
  {
   int count = 0;
   int total = OrdersHistoryTotal();
   for(int i = 0; i<NumOfSymbols; i++)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) continue;
      if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
        {
         double orderprofit = OrderProfit();
         double boprofit = BOProfit(OrderTicket());
         if((!profits && orderprofit + boprofit >= 0) || (profits && orderprofit + boprofit <= 0))
            break;
         count++;
        }
     }
   return(count >= n);
  }

double TotalOpenProfit(int direction)
  {
   double result = 0;
   int total = OrdersTotal();
   for(int i = 0; i < total; i++)   
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber) continue;
      if((direction < 0 && OrderType() == OP_BUY) || (direction > 0 && OrderType() == OP_SELL)) continue;
      result += OrderProfit();
     }
   return(result);
  }

datetime LastCloseTime()
  {
   if(SelectLastHistoryTrade())
     {
      return(OrderCloseTime());
     }
   return(0);
  }

int myOrderModify(int ticket, double SL, double TP) //modify SL and TP (absolute price), zero targets do not modify
  { 
   if(!IsTradeAllowed()) return(-1);
   bool success = false;
   int err = 0;
   SL = NormalizeDouble(SL, Digits());
   TP = NormalizeDouble(TP, Digits());
   if(SL < 0) SL = 0;
   if(TP < 0) TP = 0;
   //prepare to select order
   while(IsTradeContextBusy()) Sleep(100);
   if(!OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
     {
      err = GetLastError();
      myAlert("error", "OrderSelect failed; error #"+IntegerToString(err)+" "+ErrorDescription(err));
      return(-1);
     }
   //prepare to modify order
   while(IsTradeContextBusy()) Sleep(100);
   RefreshRates();
   //adjust targets for market order if too close to the market price
   double MinDistance = PriceTooClose * myPoint;
   if(OrderType() == OP_BUY)
     {
      if(NormalizeDouble(SL, Digits()) != 0 && Ask() - SL < MinDistance)
         SL = Ask() - MinDistance;
      if(NormalizeDouble(TP, Digits()) != 0 && TP - Ask() < MinDistance)
         TP = Ask() + MinDistance;
     }
   else if(OrderType() == OP_SELL)
     {
      if(NormalizeDouble(SL, Digits()) != 0 && SL - Bid() < MinDistance)
         SL = Bid() + MinDistance;
      if(NormalizeDouble(TP, Digits()) != 0 && Bid() - TP < MinDistance)
         TP = Bid() - MinDistance;
     }
   if(CompareDoubles(SL, 0)) SL = OrderStopLoss(); //not to modify
   if(CompareDoubles(TP, 0)) TP = OrderTakeProfit(); //not to modify
   if(CompareDoubles(SL, OrderStopLoss()) && CompareDoubles(TP, OrderTakeProfit())) return(0); //nothing to do
   while(!success && retries < OrderRetry+1)
     {
      success = OrderModify(ticket, NormalizeDouble(OrderOpenPrice(), Digits()), NormalizeDouble(SL, Digits()), NormalizeDouble(TP, Digits()), OrderExpiration(), CLR_NONE);
      if(!success)
        {
         err = GetLastError();
         myAlert("print", "OrderModify error #"+IntegerToString(err)+" "+ErrorDescription(err));
         Sleep(OrderWait*1000);
        }
      retries++;
     }
   if(!success)
     {
      myAlert("error", "OrderModify failed "+IntegerToString(OrderRetry+1)+" times; error #"+IntegerToString(err)+" "+ErrorDescription(err));
      return(-1);
     }
   string alertstr = "Order modified: ticket="+IntegerToString(ticket);
   if(!CompareDoubles(SL, 0)) alertstr = alertstr+" SL="+DoubleToString(SL);
   if(!CompareDoubles(TP, 0)) alertstr = alertstr+" TP="+DoubleToString(TP);
   myAlert("modify", alertstr);
   return(0);
  }

int myOrderModifyRel(int ticket, double SL, double TP) //modify SL and TP (relative to open price), zero targets do not modify
  {
   if(!IsTradeAllowed()) return(-1);
   bool success = false;
  

   SL = NormalizeDouble(SL, Digits());
   TP = NormalizeDouble(TP, Digits());
   if(SL < 0) SL = 0;
   if(TP < 0) TP = 0;
   //prepare to select order
   while(IsTradeContextBusy()) Sleep(100);
   if(!OrderSelect(ticket, SELECT_BY_POS, MODE_TRADES))
     {
      int err = GetLastError();
      myAlert("error", "OrderSelect failed; error #"+IntegerToString(err)+" "+ErrorDescription(err));
      return(-1);
     }
   //prepare to modify order
   while(IsTradeContextBusy()) Sleep(100);
   RefreshRates();
   //convert relative to absolute
   if(OrderType() % 2 == 0) //buy
     {
      if(NormalizeDouble(SL, Digits()) != 0)
         SL = OrderOpenPrice() - SL;
      if(NormalizeDouble(TP, Digits()) != 0)
         TP = OrderOpenPrice() + TP;
     }
   else //sell
     {
      if(NormalizeDouble(SL, Digits()) != 0)
         SL = OrderOpenPrice() + SL;
      if(NormalizeDouble(TP, Digits()) != 0)
         TP = OrderOpenPrice() - TP;
     }
   //adjust targets for market order if too close to the market price
   double MinDistance = PriceTooClose * myPoint;
   if(OrderType() == OP_BUY)
     {
      if(NormalizeDouble(SL, Digits()) != 0 && Ask() - SL < MinDistance)
         SL = Ask()- MinDistance;
      if(NormalizeDouble(TP, Digits()) != 0 && TP - Ask() < MinDistance)
         TP = Ask() + MinDistance;
     }
   else if(OrderType() == OP_SELL)
     {
      if(NormalizeDouble(SL, Digits()) != 0 && SL - Bid() < MinDistance)
         SL = Bid() + MinDistance;
      if(NormalizeDouble(TP, Digits()) != 0 && Bid() - TP < MinDistance)
         TP = Bid() - MinDistance;
     }int err=0;
  
   if(CompareDoubles(SL, 0)) SL = OrderStopLoss(); //not to modify
   if(CompareDoubles(TP, 0)) TP = OrderTakeProfit(); //not to modify
   if(CompareDoubles(SL, OrderStopLoss()) && CompareDoubles(TP, OrderTakeProfit())) return(0); //nothing to do
   while(!success && retries < OrderRetry+1)
     {
      success = OrderModify(ticket, NormalizeDouble(OrderOpenPrice(), Digits()), NormalizeDouble(SL, Digits()), NormalizeDouble(TP, Digits()), OrderExpiration(), CLR_NONE);
      if(!success)
        {
        err = GetLastError();
         myAlert("print", "OrderModify error #"+IntegerToString(err)+" "+ErrorDescription(err));
         Sleep(OrderWait*1000);
        }
      retries++;
     }
   if(!success)
     {
      myAlert("error", "OrderModify failed "+IntegerToString(OrderRetry+1)+" times; error #"+IntegerToString(err)+" "+ErrorDescription(err));
      return(-1);
     }
   string alertstr = "Order modified: ticket="+IntegerToString(ticket);
   if(!CompareDoubles(SL, 0)) alertstr = alertstr+" SL="+DoubleToString(SL);
   if(!CompareDoubles(TP, 0)) alertstr = alertstr+" TP="+DoubleToString(TP);
   myAlert("modify", alertstr);
   return(0);
  }

void myOrderClose(int type, double volumepercent, string ordername) //close open orders for current symbol, magic number and "type" (OP_BUY or OP_SELL)
  {
   if(!IsTradeAllowed()) return;
   if (type > 1)
     {
      myAlert("error", "Invalid type in myOrderClose");
      return;
     }
   bool success = false;
   int err = 0;
   string ordername_ = ordername;
   if(ordername != "")
      ordername_ = "("+ordername+")";
   int total = OrdersTotal();
   int orderList[][2];
   int orderCount = 0;
   int i;
   for(i = 0; i < total; i++)
     {
      while(IsTradeContextBusy()) Sleep(100);
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderMagicNumber() != MagicNumber || OrderSymbol() != Symbol() || OrderType() != type) continue;
      orderCount++;
      ArrayResize(orderList, orderCount);
      orderList[orderCount - 1][0] = (int)OrderOpenTime();
      orderList[orderCount - 1][1] = OrderTicket();
     }
   if(orderCount > 0)
      ArraySort(orderList, WHOLE_ARRAY, 0, MODE_ASCEND);
   for(i = 0; i < orderCount; i++)
     {
      if(!OrderSelect(orderList[i][1], SELECT_BY_POS, MODE_TRADES)) continue;
      while(IsTradeContextBusy()) Sleep(100);
      RefreshRates();
  double price = (type == OP_SELL) ? Ask() : Bid();
      double volume = NormalizeDouble(OrderLots()*volumepercent * 1.0 / 100, LotDigits);
      if (NormalizeDouble(volume, LotDigits) == 0) continue;
      success = OrderClose(OrderTicket(), volume, NormalizeDouble(price, Digits()), MaxSlippage, clrWhite);
      if(!success)
        {
         err = GetLastError();
         myAlert("error", "OrderClose"+ordername_+" failed; error #"+IntegerToString(err)+" "+ErrorDescription(err));
        }
     }
   string typestr[6] = {"Buy", "Sell", "Buy Limit", "Sell Limit", "Buy Stop", "Sell Stop"};
   if(success) myAlert("order", "Orders closed"+ordername_+": "+typestr[type]+" "+Symbol()+" Magic #"+IntegerToString(MagicNumber));
  }

void DrawLine(string objname, double price, int count, int start_index) //creates or modifies existing object if necessary
  {
   if((price < 0) && ObjectFind(objname) >= 0)
     {
      ObjectDelete(objname);
     }
   else if(ObjectFind(objname) >= 0 && ObjectType(objname) == OBJ_TREND)
     {
      ObjectSet(objname, OBJPROP_TIME1, Time[start_index]);
      ObjectSet(objname, OBJPROP_PRICE1, price);
      ObjectSet(objname, OBJPROP_TIME2, Time[start_index+count-1]);
      ObjectSet(objname, OBJPROP_PRICE2, price);
     }
   else
     {
      ObjectCreate(objname, OBJ_TREND, 0, Time[start_index], price, Time[start_index+count-1], price);
      ObjectSet(objname, OBJPROP_RAY, false);
      ObjectSet(objname, OBJPROP_COLOR, C'0x00,0x00,0xFF');
      ObjectSet(objname, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSet(objname, OBJPROP_WIDTH, 2);
     }
  }

double Support(int time_interval, bool fixed_tod, int hh, int mm, bool draw, int shift)
  {int   start_index=0;
   int count = time_interval / 60 / Period();
   if(fixed_tod)
     {
      datetime start_time;
      if(shift == 0)
	     start_time = TimeCurrent();
      else
         start_time = Time[shift-1];
      datetime dt = StringToTime(StringConcatenate(TimeToString(start_time, TIME_DATE)," ",hh,":",mm)); //closest time hh:mm
      if (dt > start_time)
         dt -= 86400; //go 24 hours back
      int dt_index = iBarShift(NULL, 0, dt, true);
      datetime dt2 = dt;
      while(dt_index < 0 && dt > Time[Bars-1-count]) //bar not found => look a few days back
        {
         dt -= 86400; //go 24 hours back
         dt_index = iBarShift(NULL, 0, dt, true);
        }
      if (dt_index < 0) //still not found => find nearest bar
         dt_index = iBarShift(NULL, 0, dt2, false);
      start_index = dt_index + 1; //bar after S/R opens at dt
     }
   double ret = Low[iLowest(NULL, 0, MODE_LOW, count, start_index)];
   if (draw) DrawLine("Support", ret, count, start_index);
   return(ret);
  }

double Resistance(int time_interval, bool fixed_tod, int hh, int mm, bool draw, int shift)
  {
 int   start_index=0;
   int count = time_interval / 60 / Period();
   if(fixed_tod)
     {
      datetime start_time;
      if(shift == 0)
	     start_time = TimeCurrent();
      else
         start_time = Time[shift-1];
      datetime dt = StringToTime(StringConcatenate(TimeToString(start_time, TIME_DATE)," ",hh,":",mm)); //closest time hh:mm
      if (dt > start_time)
         dt -= 86400; //go 24 hours back
      int dt_index = iBarShift(NULL, 0, dt, true);
      datetime dt2 = dt;
      while(dt_index < 0 && dt > Time[Bars-1-count]) //bar not found => look a few days back
        {
         dt -= 86400; //go 24 hours back
         dt_index = iBarShift(NULL, 0, dt, true);
        }
      if (dt_index < 0) //still not found => find nearest bar
         dt_index = iBarShift(NULL, 0, dt2, false);
      start_index = dt_index + 1; //bar after S/R opens at dt
     }
   double ret = High[iHighest(NULL, 0, MODE_HIGH, count, start_index)];
   if (draw) DrawLine("Resistance", ret, count, start_index);
   return(ret);
  }

void TrailingStopBE(int type, double profit, double add) //set Stop Loss to open price if in profit
  {
   int total = OrdersTotal();
   profit = NormalizeDouble(profit, Digits());
   for(int i = total-1; i >= 0; i--)
     {
      while(IsTradeContextBusy()) Sleep(100);
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderMagicNumber() != MagicNumber || OrderSymbol() != Symbol() || OrderType() != type) continue;
      RefreshRates();
      if((type == OP_BUY && Bid() > OrderOpenPrice() + profit && (NormalizeDouble(OrderStopLoss(), Digits()) <= 0 || OrderOpenPrice() > OrderStopLoss()))
      || (type == OP_SELL && Ask() < OrderOpenPrice() - profit && (NormalizeDouble(OrderStopLoss(), Digits()) <= 0 || OrderOpenPrice() < OrderStopLoss())))
         myOrderModify(OrderTicket(), OrderOpenPrice() + add, 0);
     }
  }
 


string ValStr;
datetime TimeNews[300];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
void OnnInit()
  {
//---
   string v1=StringSubstr(_Symbol,0,3);
   string v2=StringSubstr(_Symbol,3,3);
   ValStr=v1+","+v2;
//---

  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnNDeinit(const int reason)
  {
//---
   Comment("");
   del("NS_");
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+


int del(string name) // Спец. ф-ия deinit()
  {
   for(int n=ObjectsTotal()-1; n>=0; n--)
     {
      string Obj_Name=ObjectName(n);
      if(StringFind(Obj_Name,name,0)!=-1)
        {
         ObjectDelete(Obj_Name);
        }
     }
   return 0;                                      // Выход из deinit()
  }

//+------------------------------------------------------------------+
//|                    LabelCreate                                              |
//+------------------------------------------------------------------+
bool LabelCreate2(const string text="Label",const color clr=clrRed)
  {
   long x_distance;
   long y_distance;
   long chart_ID=0;
   string name="NS_Label";
   int sub_window=0;
   ENUM_BASE_CORNER  corner=CORNER_LEFT_UPPER;
   string font="Arial";
   int font_size=28;
   double angle=0.0;
   ENUM_ANCHOR_POINT anchor1=ANCHOR_LEFT_UPPER;
   bool back=false;
   bool selection=false;
   bool hidden=true;
   long z_order=0;
//--- определим размеры окна
   ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0,x_distance);
   ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0,y_distance);
   ResetLastError();
   if(!ObjectCreate(chart_ID,name,OBJ_LABEL,sub_window,0,0))
     {
      Print(__FUNCTION__,
            ": failed to create text label! Error code = ",GetLastError());
      return(false);
     }
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,(int)(x_distance/2.7));
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,(int)(y_distance/1.5));
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner);
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
   ObjectSetDouble(chart_ID,name,OBJPROP_ANGLE,angle);
   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor1);
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
   return(true);
  }

//////////////////////////////////////////////////////////////////////////////////

//+------------------------------------------------------------------+
//|                      CHECK TRAILING                              |
//+------------------------------------------------------------------+
void  checkTrail(bool usetrailing)
  {
   int count=OrdersTotal();
   double ts=0;
   if(usetrailing==false)
     {
      printf("trailling stop status:OFF");
      return;
     }
   else

      while(count>0)
        {
         int os=OrderSelect(count-1,MODE_TRADES);

         if(OrderMagicNumber()==MagicNumber)
           {
            //--- symbol variables
            double pip=SymbolInfoDouble(OrderSymbol(),SYMBOL_POINT);
            if(SymbolInfoInteger(OrderSymbol(),SYMBOL_DIGITS)==5 || SymbolInfoInteger(OrderSymbol(),SYMBOL_DIGITS)==3)
               pip*=10;
            int digits = (int)SymbolInfoInteger(OrderSymbol(),SYMBOL_DIGITS);

            switch(OrderType())
              {
               default:
                  break;
               case ORDER_TYPE_BUY:
                 {
                  switch(TrailingUnit)
                    {
                     default:
                     case InDollars:
                       {
                        double profit_distance = OrderProfit();
                        bool is_activated = profit_distance > TrailingStart;
                        if(is_activated)
                          {
                           double steps = MathFloor((profit_distance - TrailingStart)/TrailingStep);
                           if(steps>0)
                             {
                              //--- calculate stop loss distance
                              double stop_distance = GetDistanceInPoints(OrderSymbol(),TrailingUnit,TrailingStop*steps,1,OrderLots()); //--- pip value forced to 1 because TrailingStop*steps already in points
                              double stop_price = NormalizeDouble(OrderOpenPrice()+stop_distance,digits);
                              //--- move stop if needed
                              if((OrderStopLoss()==0)||(stop_price > OrderStopLoss()))
                                {
                                 if(DebugTrailingStop)
                                   {
                                    Print("TS[Start:$"+DoubleToString(TrailingStart,2)
                                          +",Step:$"+DoubleToString(TrailingStep,2)
                                          +",Stop:$"+DoubleToString(TrailingStop,2)+"]"
                                          +" p:$"+DoubleToString(profit_distance,digits)
                                          +" s:$"+DoubleToString(steps,digits)
                                          +" sd:"+DoubleToString(stop_distance,digits)
                                          +" sp:"+DoubleToString(stop_price,digits));
                                   }
                                 if(!OrderModify(OrderTicket(),OrderOpenPrice(),stop_price,OrderTakeProfit(),0,clrGold))
                                   {
                                    Print("Failed to modify trailing stop. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError()));

                                    message="Failed to modify trailing stop. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError());


                                    smartBot.SendMessage(InpChatID2,message,smartBot.ReplyKeyboardMarkup(KEYB_MAIN,FALSE,FALSE),false,false);


                                   }
                                }
                             }
                          }
                        break;
                       }
                     case InPips:
                       {
                        double profit_distance = SymbolInfoDouble(OrderSymbol(),SYMBOL_BID) - OrderOpenPrice();
                        bool is_activated = profit_distance > TrailingStart*pip;
                        if(is_activated)    //--- get trailing steps
                          {
                           double steps = MathFloor((profit_distance - TrailingStart*pip)/(TrailingStep*pip));
                           if(steps>0)
                             {
                              //--- calculate stop loss distance
                              double stop_distance = TrailingStop*pip*steps;
                              double stop_price = NormalizeDouble(OrderOpenPrice()+stop_distance,digits);
                              //--- move stop if needed
                              if((OrderStopLoss()==0)||(stop_price > OrderStopLoss()))
                                {
                                 if(DebugTrailingStop)
                                   {
                                    Print("TS[Start:"+DoubleToString(TrailingStart)
                                          +",Step:"+DoubleToString(TrailingStep)
                                          +",Stop:"+DoubleToString(TrailingStop)+"]"
                                          +" p:"+DoubleToString(profit_distance,digits)
                                          +" s:"+DoubleToString(steps)
                                          +" sd:"+DoubleToString(stop_distance,digits)
                                          +" sp:"+DoubleToString(stop_price,digits));
                                   }
                                 if(!OrderModify(OrderTicket(),OrderOpenPrice(),stop_price,OrderTakeProfit(),0,clrGold))
                                   {
                                    Print("Failed to modify trailing stop. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError()));

                                    message="Failed to modify trailing stop. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError());


                                    smartBot.SendMessage(InpChatID2,message,smartBot.ReplyKeyboardMarkup(KEYB_MAIN,FALSE,FALSE),false,false);
                                   }
                                }
                             }
                          }
                        break;
                       }
                    }
                  break;
                 }
               case ORDER_TYPE_SELL:
                 {
                  switch(TrailingUnit)
                    {
                     default:
                     case InDollars:
                       {
                        double profit_distance = OrderProfit();
                        bool is_activated = profit_distance > TrailingStart;
                        if(is_activated)
                          {
                           double steps = MathFloor((profit_distance - TrailingStart)/TrailingStep);
                           if(steps>0)
                             {
                              //--- calculate stop loss distance
                              double stop_distance = GetDistanceInPoints(OrderSymbol(),TrailingUnit,TrailingStop*steps,1,OrderLots());//--- pip value forced to 1 because TrailingStop*steps already in points
                              double stop_price = NormalizeDouble(OrderOpenPrice()-stop_distance,digits);
                              //--- move stop if needed
                              if((OrderStopLoss()==0)||(stop_price < OrderStopLoss()))
                                {
                                 if(DebugTrailingStop)
                                   {
                                    Print("TS[Start:$"+DoubleToString(TrailingStart,2)
                                          +",Step:$"+DoubleToString(TrailingStep,2)
                                          +",Stop:$"+DoubleToString(TrailingStop,2)+"]"
                                          +" p:$"+DoubleToString(profit_distance,digits)
                                          +" s:$"+DoubleToString(steps,digits)
                                          +" sd:"+DoubleToString(stop_distance,digits)
                                          +" sp:"+DoubleToString(stop_price,digits));
                                   }
                                 if(!OrderModify(OrderTicket(),OrderOpenPrice(),stop_price,OrderTakeProfit(),0,clrGold))
                                   {
                                    Print("Failed to modify trailing stop. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError()));
                                    if(UseBot)
                                       message="Failed to modify trailing stop. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError());
                                    smartBot.SendMessage(InpChatID2,message,smartBot.ReplyKeyboardMarkup(KEYB_MAIN,FALSE,FALSE),false,false);
                                   }
                                }
                             }
                          }
                        break;
                       }
                     case InPips:
                       {
                        double profit_distance = OrderOpenPrice() - SymbolInfoDouble(OrderSymbol(),SYMBOL_ASK);
                        bool is_activated = profit_distance > TrailingStart*pip;
                        if(is_activated)    //--- get trailing steps
                          {
                           double steps = MathFloor((profit_distance - TrailingStart*pip)/(TrailingStep*pip));
                           if(steps>0)
                             {
                              //--- calculate stop loss distance
                              double stop_distance = TrailingStop*pip*steps;
                              double stop_price = NormalizeDouble(OrderOpenPrice()-stop_distance,digits);
                              //--- move stop if needed
                              if((OrderStopLoss()==0) || (stop_price < OrderStopLoss()))
                                {
                                 if(DebugTrailingStop)
                                   {
                                    Print("TS[Start:"+DoubleToString(TrailingStart)
                                          +",Step:"+DoubleToString(TrailingStep)
                                          +",Stop:"+DoubleToString(TrailingStop)+"]"
                                          +" p:"+DoubleToString(profit_distance,digits)
                                          +" s:"+DoubleToString(steps)
                                          +" sd:"+DoubleToString(stop_distance,digits)
                                          +" sp:"+DoubleToString(stop_price,digits));
                                    message="TS[Start:"+DoubleToString(TrailingStart)
                                            +",Step:"+DoubleToString(TrailingStep)
                                            +",Stop:"+DoubleToString(TrailingStop)+"]"
                                            +" p:"+DoubleToString(profit_distance,digits)
                                            +" s:"+DoubleToString(steps)
                                            +" sd:"+DoubleToString(stop_distance,digits)
                                            +" sp:"+DoubleToString(stop_price,digits);
                                   }
                                 if(!OrderModify(OrderTicket(),OrderOpenPrice(),stop_price,OrderTakeProfit(),0,clrGold))
                                   {
                                    Print("Failed to modify trailing stop. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError()));
                                    if(UseBot)
                                       message="Failed to modify trailing stop. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError());
                                   }
                                 smartBot.SendMessage(InpChatID2,message,smartBot.ReplyKeyboardMarkup(KEYB_MAIN,FALSE,FALSE),false,false);
                                }
                             }
                          }
                        break;
                       }
                    }
                  break;
                 }
              }
           }
         count--;
        }
  }



//+------------------------------------------------------------------+
//|                       GetDistanceInPoints                                       |
//+------------------------------------------------------------------+
double GetDistanceInPoints(const string symbols,ENUM_UNIT unit,double value,double pip_value,double volume)
  {
   switch(unit)
     {
      default:
         PrintFormat("Unhandled unit %s, returning -1",EnumToString(unit));
         break;
      case InPips:
        {
         double distance = value;

         if(IsTesting()&&DebugUnit)
            PrintFormat("%s:%.2f dist: %.5f",EnumToString(unit),value,distance);

         return value;
        }
      case InDollars:
        {
         double tickSize        = SymbolInfoDouble(symbols,SYMBOL_TRADE_TICK_SIZE);
         double tickValue       = SymbolInfoDouble(symbols,SYMBOL_TRADE_TICK_VALUE);
         double dVpL            = tickValue / tickSize;
         double distance        = (value /(volume * dVpL))/pip_value;

         if(IsTesting()&&DebugUnit)
            PrintFormat("%s:%s:%.2f dist: %.5f volume:%.2f dVpL:%.5f pip:%.5f",symbols,EnumToString(unit),value,distance,volume,dVpL,pip_value);

         return distance;
        }
     }
   return -1;
  }
//+------------------------------------------------------------------+
//|                   _funcBE                                                |
//+------------------------------------------------------------------+
void  _funcBE(bool usebreakeaven=false)
  {
   if(usebreakeaven==false)
      return;
   int count=OrdersTotal();
   double ts=0;
   while(count>0)
     {
      int os=OrderSelect(count-1,MODE_TRADES);

      if(OrderMagicNumber()==MagicNumber)
        {
         //--- symbol variables
         double pip=SymbolInfoDouble(OrderSymbol(),SYMBOL_POINT);
         if(SymbolInfoInteger(OrderSymbol(),SYMBOL_DIGITS)==5 || SymbolInfoInteger(OrderSymbol(),SYMBOL_DIGITS)==3)
            pip*=10;
       int  digits = (int)SymbolInfoInteger(OrderSymbol(),SYMBOL_DIGITS);

         switch(OrderType())
           {
            default:
               break;
            case ORDER_TYPE_BUY:
              {
               switch(BreakEvenUnit)
                 {
                  default:
                  case InDollars:
                    {
                     double profit_distance = OrderProfit();
                     bool is_activated = profit_distance > BreakEvenTrigger;
                     if(is_activated)
                       {
                        double steps = MathFloor(profit_distance / BreakEvenTrigger);
                        if(steps>0)
                          {
                           //--- check current step count is within limit
                           if(steps <= MaxNoBreakEven)
                             {
                              //--- calculate stop loss distance
                              double stop_distance   = GetDistanceInPoints(OrderSymbol(),BreakEvenUnit,BreakEvenProfit*steps,1,OrderLots()); //--- pip value forced to 1 because BreakEvenProfit*steps already in points
                              double stop_price      = NormalizeDouble(OrderOpenPrice()+stop_distance,digits);
                              //--- move stop if needed
                              if((OrderStopLoss()==0)||(stop_price > OrderStopLoss()))
                                {
                                 if(DebugBreakEven)
                                   {
                                    Print("BE[Trigger:$"+DoubleToString(BreakEvenTrigger,2)
                                          +",Profit:$"+DoubleToString(BreakEvenProfit,2)
                                          +",Max:"+DoubleToString(MaxNoBreakEven,2)+"]"
                                          +" p:$"+DoubleToString(profit_distance,digits)
                                          +" s:$"+DoubleToString(steps,digits)
                                          +" sd:"+DoubleToString(stop_distance,digits)
                                          +" sp:"+DoubleToString(stop_price,digits));

                                    message="BE[Trigger:$"+DoubleToString(BreakEvenTrigger,2)
                                            +",Profit:$"+DoubleToString(BreakEvenProfit,2)
                                            +",Max:"+DoubleToString(MaxNoBreakEven,2)+"]"
                                            +" p:$"+DoubleToString(profit_distance,digits)
                                            +" s:$"+DoubleToString(steps,digits)
                                            +" sd:"+DoubleToString(stop_distance,digits)
                                            +" sp:"+DoubleToString(stop_price,digits);
                                   }
                                 if(!OrderModify(OrderTicket(),OrderOpenPrice(),stop_price,OrderTakeProfit(),0,clrGold))
                                   {
                                    Print("Failed to modify break even. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError()));
                                    if(UseBot)
                                       message="Failed to modify break even. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError());
                                   }
                                 smartBot.SendMessage(InpChatID2,message,smartBot.ReplyKeyboardMarkup(KEYB_MAIN,FALSE,FALSE),false,false);

                                }
                             }
                          }
                       }
                     break;
                    }
                  case InPips:
                    {
                     double profit_distance = SymbolInfoDouble(OrderSymbol(),SYMBOL_BID) - OrderOpenPrice();
                     bool is_activated = profit_distance > BreakEvenTrigger*pip;
                     if(is_activated)
                       {
                        double steps = MathFloor(profit_distance / BreakEvenTrigger*pip);
                        if(steps>0)
                          {
                           //--- check current step count is within limit
                           if(steps <= MaxNoBreakEven)
                             {
                              double stop_distance = BreakEvenProfit*pip*steps;
                              double stop_price = NormalizeDouble(OrderOpenPrice()+stop_distance,digits);
                              //--- move stop if needed
                              if((OrderStopLoss()==0)||(stop_price > OrderStopLoss()))
                                {
                                 if(DebugBreakEven)
                                   {
                                    Print("BE[Trigger:"+DoubleToString(BreakEvenTrigger)
                                          +",Profit:"+DoubleToString(BreakEvenProfit)
                                          +",Max:"+IntegerToString(MaxNoBreakEven)+"]"
                                          +" p:"+DoubleToString(profit_distance,digits)
                                          +" s:"+DoubleToString(steps)
                                          +" sd:"+DoubleToString(stop_distance,digits)
                                          +" sp:"+DoubleToString(stop_price,digits));
                                    messages="BE[Trigger:"+DoubleToString(BreakEvenTrigger)
                                             +",Profit:"+DoubleToString(BreakEvenProfit)
                                             +",Max:"+IntegerToString(MaxNoBreakEven)+"]"
                                             +" p:"+DoubleToString(profit_distance,digits)
                                             +" s:"+DoubleToString(steps)
                                             +" sd:"+DoubleToString(stop_distance,digits)
                                             +" sp:"+DoubleToString(stop_price,digits);

                                   }
                                 smartBot.SendMessage(InpChatID2,messages,smartBot.ReplyKeyboardMarkup(KEYB_MAIN,FALSE,FALSE),false,false);


                                 if(!OrderModify(OrderTicket(),OrderOpenPrice(),stop_price,OrderTakeProfit(),0,clrGold))
                                   {
                                    Print("Failed to modify break even. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError()));
                                    if(UseBot)
                                       message="Failed to modify Break Even. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError());




                                    smartBot.SendMessage(InpChatID2,message,smartBot.ReplyKeyboardMarkup(KEYB_MAIN,FALSE,FALSE),false,false);


                                   }
                                }
                             }
                          }
                       }
                     break;
                    }
                 }
               break;
              }
            case ORDER_TYPE_SELL:
              {
               switch(BreakEvenUnit)
                 {
                  default:
                  case InDollars:
                    {
                     double profit_distance = OrderProfit();
                     bool is_activated = profit_distance > BreakEvenTrigger;
                     if(is_activated)
                       {
                        double steps = MathFloor(profit_distance / BreakEvenTrigger);
                        if(steps>0)
                          {
                           //--- check current step count is within limit
                           if(steps <= MaxNoBreakEven)
                             {
                              //--- calculate stop loss distance
                              double stop_distance = GetDistanceInPoints(OrderSymbol(),BreakEvenUnit,BreakEvenProfit*steps,1,OrderLots());
                              double stop_price    = NormalizeDouble(OrderOpenPrice()-stop_distance,digits);
                              //--- move stop if needed
                              if((OrderStopLoss()==0)||(stop_price < OrderStopLoss()))
                                {
                                 if(DebugBreakEven)
                                   {
                                    Print("BE[Trigger:$"+DoubleToString(BreakEvenTrigger,2)
                                          +",Profit:$"+DoubleToString(BreakEvenProfit,2)
                                          +",Max:"+IntegerToString(MaxNoBreakEven)+"]"
                                          +" p:$"+DoubleToString(profit_distance,digits)
                                          +" s:$"+DoubleToString(steps,digits)
                                          +" sd:"+DoubleToString(stop_distance,digits)
                                          +" sp:"+DoubleToString(stop_price,digits));
                                    message="BE[Trigger:$"+DoubleToString(BreakEvenTrigger,2)
                                            +",Profit:$"+DoubleToString(BreakEvenProfit,2)
                                            +",Max:"+IntegerToString(MaxNoBreakEven)+"]"
                                            +" p:$"+DoubleToString(profit_distance,digits)
                                            +" s:$"+DoubleToString(steps,digits)
                                            +" sd:"+DoubleToString(stop_distance,digits)
                                            +" sp:"+DoubleToString(stop_price,digits);

                                    smartBot.SendMessage(InpChatID2,message,smartBot.ReplyKeyboardMarkup(KEYB_MAIN,FALSE,FALSE),false,false);

                                   }
                                 if(!OrderModify(OrderTicket(),OrderOpenPrice(),stop_price,OrderTakeProfit(),0,clrGold))
                                   {
                                    Print("Failed to modify break even. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError()));
                                    if(UseBot)
                                       message="Failed to modify Break Even. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError());

                                    smartBot.SendMessage(InpChatID2,message,smartBot.ReplyKeyboardMarkup(KEYB_MAIN,FALSE,FALSE),false,false);


                                   }
                                }
                             }
                          }
                       }
                     break;
                    }
                  case InPips:
                    {
                     double profit_distance = OrderOpenPrice() - SymbolInfoDouble(OrderSymbol(),SYMBOL_ASK);
                     bool is_activated = profit_distance > BreakEvenTrigger*pip;
                     if(is_activated)
                       {
                        double steps = MathFloor(profit_distance / BreakEvenTrigger*pip);
                        if(steps>0)
                          {
                           //--- check current step count is within limit
                           if(steps <= MaxNoBreakEven)
                             {
                              double stop_distance = BreakEvenProfit*pip*steps;
                              double stop_price    = NormalizeDouble(OrderOpenPrice()-stop_distance,digits);
                              //--- move stop if needed
                              if((OrderStopLoss()==0)||(stop_price < OrderStopLoss()))
                                {
                                 if(DebugBreakEven)
                                   {
                                    Print("BE[Trigger:"+DoubleToString(BreakEvenTrigger)
                                          +",Profit:"+DoubleToString(BreakEvenProfit)
                                          +",Max:"+IntegerToString(MaxNoBreakEven)+"]"
                                          +" p:"+DoubleToString(profit_distance,digits)
                                          +" s:"+DoubleToString(steps)
                                          +" sd:"+DoubleToString(stop_distance,digits)
                                          +" sp:"+DoubleToString(stop_price,digits));

                                    message=   "BE[Trigger:"+DoubleToString(BreakEvenTrigger)
                                               +",Profit:"+DoubleToString(BreakEvenProfit)
                                               +",Max:"+IntegerToString(MaxNoBreakEven)+"]"
                                               +" p:"+DoubleToString(profit_distance,digits)
                                               +" s:"+DoubleToString(steps)
                                               +" sd:"+DoubleToString(stop_distance,digits)
                                               +" sp:"+DoubleToString(stop_price,digits);
                                    smartBot.SendMessage(InpChatID2,message,smartBot.ReplyKeyboardMarkup(KEYB_MAIN,FALSE,FALSE),false,false);

                                   }
                                 if(!OrderModify(OrderTicket(),OrderOpenPrice(),stop_price,OrderTakeProfit(),0,clrGold))
                                   {
                                    Print("Failed to modify break even. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError()));

                                    message="Failed to modify Break Even. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError());

                                    smartBot.SendMessage(InpChatID2,message,smartBot.ReplyKeyboardMarkup(KEYB_MAIN,FALSE,FALSE),false,false);


                                   }
                                }
                             }
                          }
                       }
                     break;
                    }
                 }
               break;
              }
           }

        }
      count--;
     }
  }

//+------------------------------------------------------------------+
//|                 CHECK PARTIAL CLOSE                              |
//+------------------------------------------------------------------+
void CheckPartialClose(bool   checkPartialClose =false)
  {
   if(!checkPartialClose)
      return;
   int count=OrdersTotal();
   double ts=0;
   while(count>0)
     {
      int os=OrderSelect(count-1,MODE_TRADES);

      if(OrderMagicNumber()==MagicNumber)
        {
         //--- symbol variables
         double pip=SymbolInfoDouble(OrderSymbol(),SYMBOL_POINT);
         if(SymbolInfoInteger(OrderSymbol(),SYMBOL_DIGITS)==5 || SymbolInfoInteger(OrderSymbol(),SYMBOL_DIGITS)==3)
            pip*=10;
        int digits = (int)SymbolInfoInteger(OrderSymbol(),SYMBOL_DIGITS);

         switch(OrderType())
           {
            default:
               break;
            case ORDER_TYPE_BUY:
              {
               switch(PartialCloseUnit)
                 {
                  default:
                  case InDollars:
                    {
                     double profit_distance = OrderProfit();
                     bool is_activated = profit_distance > PartialCloseTrigger;
                     if(is_activated)
                       {
                        double steps = MathFloor(profit_distance / PartialCloseTrigger);
                        if(steps>0)
                          {
                           //--- check current step count is within limit
                           if(steps <= MaxNoPartialClose)
                             {
                              //--- calculate new lot size
                              int lot_digits = (int)(MathLog(SymbolInfoDouble(OrderSymbol(),SYMBOL_VOLUME_STEP))/MathLog(0.1));
                              double lots = NormalizeDouble(OrderLots() * PartialClosePercent,lot_digits);
                              if(lots < SymbolInfoDouble(OrderSymbol(),SYMBOL_VOLUME_MIN))    //--- close all
                                {
                                 lots = OrderLots();
                                }
                              if(OrderClose(OrderTicket(),lots,SymbolInfoDouble(OrderSymbol(),SYMBOL_BID),MaxSlippage,clrYellow))
                                {

                                 if(DebugPartialClose)
                                   {
                                    Print("PC[Trigger:$"+DoubleToString(PartialCloseTrigger,2)
                                          +",Percent:"+DoubleToString(PartialClosePercent,2)
                                          +",Max:"+IntegerToString(MaxNoPartialClose)+"]"
                                          +" p:$"+DoubleToString(profit_distance,digits)
                                          +" s:"+DoubleToString(steps,digits)
                                          +" l:"+DoubleToString(lots,lot_digits));

                                    messages= "PC[Trigger:$"+DoubleToString(PartialCloseTrigger,2)
                                              +",Percent:"+DoubleToString(PartialClosePercent,2)
                                              +",Max:"+IntegerToString(MaxNoPartialClose)+"]"
                                              +" p:$"+DoubleToString(profit_distance,digits)
                                              +" s:"+DoubleToString(steps,digits)
                                              +" l:"+DoubleToString(lots,lot_digits) ;

                                    smartBot.SendMessage(InpChatID,messages,smartBot.ReplyKeyboardMarkup(KEYB_MAIN,FALSE,FALSE),false,false);

                                   }
                                }
                              else
                                {
                                 Print("Failed to partial close. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError()));

                                 messages=   "Failed to partial close. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError());


                                 smartBot.SendMessage(InpChatID,messages,smartBot.ReplyKeyboardMarkup(KEYB_MAIN,FALSE,FALSE),false,false);

                                }
                             }
                          }
                       }
                     break;
                    }
                  case InPips:
                    {
                     double profit_distance = SymbolInfoDouble(OrderSymbol(),SYMBOL_BID) - OrderOpenPrice();
                     bool is_activated = profit_distance > PartialCloseTrigger*pip;
                     if(is_activated)
                       {
                        double steps = MathFloor(profit_distance / PartialCloseTrigger*pip);
                        if(steps>0)
                          {
                           //--- check current step count is within limit
                           if(steps <= MaxNoPartialClose)
                             {
                              //--- calculate new lot size
                              int lot_digits = (int)(MathLog(SymbolInfoDouble(OrderSymbol(),SYMBOL_VOLUME_STEP))/MathLog(0.1));
                              double lots = NormalizeDouble(OrderLots() * PartialClosePercent,lot_digits);
                              if(lots < SymbolInfoDouble(OrderSymbol(),SYMBOL_VOLUME_MIN))    //--- close all
                                {
                                 lots = OrderLots();
                                }
                              if(OrderClose(OrderTicket(),lots,SymbolInfoDouble(OrderSymbol(),SYMBOL_BID),MaxSlippage,clrYellow))
                                {
                                 if(DebugPartialClose)
                                   {
                                    Print("PC[Trigger:"+DoubleToString(PartialCloseTrigger,2)
                                          +",Percent:"+DoubleToString(PartialClosePercent,2)
                                          +",Max:"+IntegerToString(MaxNoPartialClose)+"]"
                                          +" p:"+DoubleToString(profit_distance,digits)
                                          +" s:"+DoubleToString(steps,digits)
                                          +" l:"+DoubleToString(lots,lot_digits));
                                    message=           "PC[Trigger:"+DoubleToString(PartialCloseTrigger,2)
                                                       +",Percent:"+DoubleToString(PartialClosePercent,2)
                                                       +",Max:"+IntegerToString(MaxNoPartialClose)+"]"
                                                       +" p:"+DoubleToString(profit_distance,digits)
                                                       +" s:"+DoubleToString(steps,digits)
                                                       +" l:"+DoubleToString(lots,lot_digits);
                                    smartBot.SendMessage(InpChatID2,message,smartBot.ReplyKeyboardMarkup(KEYB_MAIN,FALSE,FALSE),false,false);


                                   }
                                }
                              else
                                {
                                 Print("Failed to partial close. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError()));
                                 messages="Failed to partial close. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError());



                                 smartBot.SendMessage(InpChatID2,messages,smartBot.ReplyKeyboardMarkup(KEYB_MAIN,FALSE,FALSE),false,false);

                                }
                             }
                          }
                       }
                     break;
                    }
                 }
               break;
              }
            case ORDER_TYPE_SELL:
              {
               switch(PartialCloseUnit)
                 {
                  default:
                  case InDollars:
                    {
                     double profit_distance = OrderProfit();
                     bool is_activated = profit_distance > PartialCloseTrigger;
                     if(is_activated)
                       {
                        double steps = MathFloor(profit_distance / PartialCloseTrigger);
                        if(steps>0)
                          {
                           //--- check current step count is within limit
                           if(steps <= MaxNoPartialClose)
                             {
                              //--- calculate new lot size
                              int lot_digits = (int)(MathLog(SymbolInfoDouble(OrderSymbol(),SYMBOL_VOLUME_STEP))/MathLog(0.1));
                              double lots = NormalizeDouble(OrderLots() * PartialClosePercent,lot_digits);
                              if(lots < SymbolInfoDouble(OrderSymbol(),SYMBOL_VOLUME_MIN))    //--- close all
                                {
                                 lots = OrderLots();
                                }
                              if(OrderClose(OrderTicket(),lots,SymbolInfoDouble(OrderSymbol(),SYMBOL_ASK),MaxSlippage,clrYellow))
                                {

                                 if(DebugPartialClose)
                                   {
                                    Print("PC[Trigger:$"+DoubleToString(PartialCloseTrigger,2)
                                          +",Percent:"+DoubleToString(PartialClosePercent,2)
                                          +",Max:"+IntegerToString(MaxNoPartialClose)+"]"
                                          +" p:$"+DoubleToString(profit_distance,digits)
                                          +" s:"+DoubleToString(steps,digits)
                                          +" l:"+DoubleToString(lots,lot_digits));
                                    message="PC[Trigger:$"+DoubleToString(PartialCloseTrigger,2)
                                            +",Percent:"+DoubleToString(PartialClosePercent,2)
                                            +",Max:"+IntegerToString(MaxNoPartialClose)+"]"
                                            +" p:$"+DoubleToString(profit_distance,digits)
                                            +" s:"+DoubleToString(steps,digits)
                                            +" l:"+DoubleToString(lots,lot_digits);
                                    smartBot.SendMessage(InpChatID2,message,smartBot.ReplyKeyboardMarkup(KEYB_MAIN,FALSE,FALSE),false,false);


                                   }
                                }
                              else
                                {
                                 Print("Failed to partial close. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError()));

                                 message="Failed to partial close. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError());

                                 smartBot.SendMessage(InpChatID2,message,smartBot.ReplyKeyboardMarkup(KEYB_MAIN,FALSE,FALSE),false,false);


                                }
                             }
                          }
                       }
                     break;
                    }
                  case InPips:
                    {
                     double profit_distance = OrderOpenPrice() - SymbolInfoDouble(OrderSymbol(),SYMBOL_ASK);
                     bool is_activated = profit_distance > PartialCloseTrigger*pip;
                     if(is_activated)
                       {
                        double steps = MathFloor(profit_distance / PartialCloseTrigger*pip);
                        if(steps>0)
                          {
                           //--- check current step count is within limit
                           if(steps <= MaxNoPartialClose)
                             {
                              //--- calculate new lot size
                              int lot_digits = (int)(MathLog(SymbolInfoDouble(OrderSymbol(),SYMBOL_VOLUME_STEP))/MathLog(0.1));
                              double lots = NormalizeDouble(OrderLots() * PartialClosePercent,lot_digits);
                              if(lots < SymbolInfoDouble(OrderSymbol(),SYMBOL_VOLUME_MIN))    //--- close all
                                {
                                 lots = OrderLots();
                                }
                              if(OrderClose(OrderTicket(),lots,SymbolInfoDouble(OrderSymbol(),SYMBOL_ASK),MaxSlippage,clrYellow))
                                {

                                 if(DebugPartialClose)
                                   {
                                    Print("PC[Trigger:"+DoubleToString(PartialCloseTrigger,2)
                                          +",Percent:"+DoubleToString(PartialClosePercent,2)
                                          +",Max:"+IntegerToString(MaxNoPartialClose)+"]"
                                          +" p:"+DoubleToString(profit_distance,digits)
                                          +" s:"+DoubleToString(steps,digits)
                                          +" l:"+DoubleToString(lots,lot_digits));
                                    messages=      "PC[Trigger:"+DoubleToString(PartialCloseTrigger,2)
                                                   +",Percent:"+DoubleToString(PartialClosePercent,2)
                                                   +",Max:"+IntegerToString(MaxNoPartialClose)+"]"
                                                   +" p:"+DoubleToString(profit_distance,digits)
                                                   +" s:"+DoubleToString(steps,digits)
                                                   +" l:"+DoubleToString(lots,lot_digits);

                                    smartBot.SendMessage(InpChatID,message,smartBot.ReplyKeyboardMarkup(KEYB_MAIN,FALSE,FALSE),false,false);

                                   }
                   }
                             }
                           else
                             {
                              Print("Failed to partial close. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError()));
                              messages="Failed to partial close. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError());


                              smartBot.SendMessage(InpChatID,message,smartBot.ReplyKeyboardMarkup(KEYB_MAIN,FALSE,FALSE),false,false);

                             }
                          }
                       }
                    }
                  break;
                 }
              }
            break;
           }
        }
      break;
     }
   count--;

  }



void  checkTrail()
  {
   int count=OrdersTotal();
   double ts=0;
   while(count>0)
     {
      int os=OrderSelect(count-1,MODE_TRADES);
      
      if (OrderMagicNumber()==MagicNumber) {
         //--- symbol variables                     
         double pip=SymbolInfoDouble(OrderSymbol(),SYMBOL_POINT);
         if(SymbolInfoInteger(OrderSymbol(),SYMBOL_DIGITS)==5 || SymbolInfoInteger(OrderSymbol(),SYMBOL_DIGITS)==3)
            pip*=10;
       int digits = (int)SymbolInfoInteger(OrderSymbol(),SYMBOL_DIGITS);
         
         switch(OrderType()) {
            default:
               break;
            case ORDER_TYPE_BUY: {
               switch(TrailingUnit) {
                  default:
                  case InDollars: {
                     double profit_distance = OrderProfit();
                     bool is_activated = profit_distance > TrailingStart;
                     if (is_activated) {
                        double steps = MathFloor((profit_distance - TrailingStart)/TrailingStep);
                        if (steps>0) {
                           //--- calculate stop loss distance                          
                           double stop_distance = GetDistanceInPoints(OrderSymbol(),TrailingUnit,TrailingStop*steps,1,OrderLots()); //--- pip value forced to 1 because TrailingStop*steps already in points
                           double stop_price = NormalizeDouble(OrderOpenPrice()+stop_distance,digits);
                           //--- move stop if needed
                           if ((OrderStopLoss()==0)||(stop_price > OrderStopLoss())) {
                              if (DebugTrailingStop) {
                                 Print("TS[Start:$"+DoubleToString(TrailingStart,2)
                                    +",Step:$"+DoubleToString(TrailingStep,2)
                                    +",Stop:$"+DoubleToString(TrailingStop,2)+"]"
                                    +" p:$"+DoubleToString(profit_distance,digits)
                                    +" s:$"+DoubleToString(steps,digits)
                                    +" sd:"+DoubleToString(stop_distance,digits)
                                    +" sp:"+DoubleToString(stop_price,digits));
                              }
                              if (!OrderModify(OrderTicket(),OrderOpenPrice(),stop_price,OrderTakeProfit(),0,clrGold)) {
                                 Print("Failed to modify trailing stop. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError()));
                              }
                           }
                        }                        
                     } 
                     break;
                  }
                  case InPips: {
                     double profit_distance = SymbolInfoDouble(OrderSymbol(),SYMBOL_BID) - OrderOpenPrice();
                     bool is_activated = profit_distance > TrailingStart*pip;
                     if (is_activated) { //--- get trailing steps
                        double steps = MathFloor((profit_distance - TrailingStart*pip)/(TrailingStep*pip));
                        if (steps>0) {
                           //--- calculate stop loss distance
                           double stop_distance = TrailingStop*pip*steps;
                           double stop_price = NormalizeDouble(OrderOpenPrice()+stop_distance,digits);
                           //--- move stop if needed
                           if ((OrderStopLoss()==0)||(stop_price > OrderStopLoss())) {
                              if (DebugTrailingStop) {
                                 Print("TS[Start:"+DoubleToString(TrailingStart)
                                    +",Step:"+DoubleToString(TrailingStep)
                                    +",Stop:"+DoubleToString(TrailingStop)+"]"
                                    +" p:"+DoubleToString(profit_distance,digits)
                                    +" s:"+DoubleToString(steps)
                                    +" sd:"+DoubleToString(stop_distance,digits)
                                    +" sp:"+DoubleToString(stop_price,digits));
                              }
                              if (!OrderModify(OrderTicket(),OrderOpenPrice(),stop_price,OrderTakeProfit(),0,clrGold)) {
                                 Print("Failed to modify trailing stop. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError()));
                              }
                           }
                        }
                     }
                     break;
                  }
               }
               break;
            }
            case ORDER_TYPE_SELL: {
               switch(TrailingUnit) {
                  default:
                  case InDollars: {
                     double profit_distance = OrderProfit();
                     bool is_activated = profit_distance > TrailingStart;
                     if (is_activated) {
                        double steps = MathFloor((profit_distance - TrailingStart)/TrailingStep);
                        if (steps>0) {
                           //--- calculate stop loss distance                        
                           double stop_distance = GetDistanceInPoints(OrderSymbol(),TrailingUnit,TrailingStop*steps,1,OrderLots());//--- pip value forced to 1 because TrailingStop*steps already in points
                           double stop_price = NormalizeDouble(OrderOpenPrice()-stop_distance,digits);
                           //--- move stop if needed
                           if ((OrderStopLoss()==0)||(stop_price < OrderStopLoss())) {
                              if (DebugTrailingStop) {
                                 Print("TS[Start:$"+DoubleToString(TrailingStart,2)
                                    +",Step:$"+DoubleToString(TrailingStep,2)
                                    +",Stop:$"+DoubleToString(TrailingStop,2)+"]"
                                    +" p:$"+DoubleToString(profit_distance,digits)
                                    +" s:$"+DoubleToString(steps,digits)
                                    +" sd:"+DoubleToString(stop_distance,digits)
                                    +" sp:"+DoubleToString(stop_price,digits));
                              }
                              if (!OrderModify(OrderTicket(),OrderOpenPrice(),stop_price,OrderTakeProfit(),0,clrGold)) {
                                 Print("Failed to modify trailing stop. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError()));
                              }
                           }
                        }                        
                     } 
                     break;
                  }
                  case InPips: {            
                     double profit_distance = OrderOpenPrice() - SymbolInfoDouble(OrderSymbol(),SYMBOL_ASK); 
                     bool is_activated = profit_distance > TrailingStart*pip;
                     if (is_activated) { //--- get trailing steps
                        double steps = MathFloor((profit_distance - TrailingStart*pip)/(TrailingStep*pip));
                        if (steps>0) {
                           //--- calculate stop loss distance
                           double stop_distance = TrailingStop*pip*steps;
                           double stop_price = NormalizeDouble(OrderOpenPrice()-stop_distance,digits);
                           //--- move stop if needed
                           if ((OrderStopLoss()==0) || (stop_price < OrderStopLoss())) {
                              if (DebugTrailingStop) {
                                 Print("TS[Start:"+DoubleToString(TrailingStart)
                                    +",Step:"+DoubleToString(TrailingStep)
                                    +",Stop:"+DoubleToString(TrailingStop)+"]"
                                    +" p:"+DoubleToString(profit_distance,digits)
                                    +" s:"+DoubleToString(steps)
                                    +" sd:"+DoubleToString(stop_distance,digits)
                                    +" sp:"+DoubleToString(stop_price,digits));                  
                              }
                              if (!OrderModify(OrderTicket(),OrderOpenPrice(),stop_price,OrderTakeProfit(),0,clrGold)) {
                                 Print("Failed to modify trailing stop. Order " + IntegerToString(OrderTicket()) + ", error: " + IntegerToString(GetLastError()));
                              }
                           }  
                        }                 
                     }
                     break;
                  }
               }
               break;
            }
         }
      }
      count--;
     }
  }

//+------------------------------------------------------------------+
//|                               ClOSEAll                                    |
//+------------------------------------------------------------------+
void CloseAll()
  {
   int totalOP  = OrdersTotal(),tiket=0;
   for(int cnt = totalOP-1 ; cnt >= 0 ; cnt--)
     {
      Os=OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderType()==OP_BUY && OrderMagicNumber() == MagicNumber)
        {
         Oc=OrderClose(OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_BID), MaxSlippage, clrViolet);


         Sleep(300);
         continue;
        }
      if(OrderType()==OP_SELL && OrderMagicNumber() == MagicNumber)
        {
         Oc=OrderClose(OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_ASK), MaxSlippage, clrYellow);
         Sleep(300);
        }
     }
  }
//+------------------------------------------------------------------+
//|                     DYp                                              |
//+------------------------------------------------------------------+
double DYp(datetime start_)
  {

   double total = 0;
   for(int i = OrdersHistoryTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
        {
         if(OrderMagicNumber() == MagicNumber  &&OrderCloseTime()>=start_)
           {
            total+=(OrderProfit()+OrderSwap()+OrderCommission());
           }
        }
     }
   return(total);
  }

//+------------------------------------------------------------------+
//|                       timelockaction                                           |
//+------------------------------------------------------------------+
void timelockaction(string symbol )
  {



   double stoplevel=0,proffit=OrderProfit(),newsl=0;

  ;
   int sy_digits=0;
   double sy_points=0;
   bool ans=false;
   bool next=false;
   int otype=-1;
   int kk=0;

   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
         continue;
      if(OrderMagicNumber()!=MagicNumber)
         continue;
      next=false;
      ans=false;
      string sy=OrderSymbol();
    
      sy_points=myPoint;
      stoplevel=MarketInfo(sy, MODE_STOPLEVEL)*sy_points;
      otype=OrderType();
      kk=0;
      proffit=OrderProfit()+OrderSwap()+OrderCommission();
      newsl=OrderOpenPrice();

      switch(EA_TIME_LOCK_ACTION)
        {
         case closeall:
            if(otype>1)
              {
               while(kk<5 && !OrderDelete(OrderTicket()))
                 {
                  kk++;

                  break;
                 }
              }
            else
              {
            double price=(otype==OP_BUY)?Bid():Ask();
               while(kk<5 && !OrderClose(OrderTicket(),OrderLots(),price,10))
                 {
                  kk++;
                  price=(otype==OP_BUY)?SymbolInfoDouble(sy,SYMBOL_BID):SymbolInfoDouble(sy,SYMBOL_ASK);
                  break;
                 }
              }
            break;
         case closeprofit:
            if(proffit<=0)
               break;
            else
              {
         double price=(otype==OP_BUY)?Bid():Ask();
               while(otype<2 && kk<5 && !OrderClose(OrderTicket(),OrderLots(),Ask(),10))
                 {
                  kk++;
                  price=(otype==OP_BUY)?SymbolInfoDouble(sy,SYMBOL_BID):SymbolInfoDouble(sy,SYMBOL_ASK);
                  break;
                 }
              }
            break;
            
            
         case breakevenprofit:
            if(proffit<=0)
               break;
            else
              {
             double price=(otype==OP_BUY)?Bid():Ask();
               while(otype<2 && kk<5 && MathAbs(price-newsl)>=stoplevel && !OrderModify(OrderTicket(),newsl,newsl,OrderTakeProfit(),OrderExpiration()))
                 {
                  kk++;
                  price=(otype==OP_BUY)?SymbolInfoDouble(sy,SYMBOL_BID):SymbolInfoDouble(sy,SYMBOL_ASK);
                  break;
                 }
              }
            break;

        }
      continue;
     }

  }


//+------------------------------------------------------------------+
//|                         SymbolNumOfSymbol                                         |
//+------------------------------------------------------------------+
int SymbolNumOfSymbol(string symbols)
  {
   for(int i = 0; i < NumOfSymbols; i++)
     {
      if(symbols==TradeScheduleSymbol(i,InpSelectPairs_By_Basket_Schedule))
         return(i);
     }
   return(-1);
  }
//+------------------------------------------------------------------+
//|                          ClosetradePairs                                         |
//+------------------------------------------------------------------+
void ClosetradePairs(string Pair)
  {
   if(closetype != opposite)
      return;
   int SymbolNum = SymbolNumOfSymbol(Pair);
   if(SymbolNum < 0)
      return;

   if(exitSell[0] ==true)
     {
      Print("Opposite Close Sell ",Pair);
      myOrderClose(OP_SELL,OrderLots(),"");
     }
   else
      if(exitBuy[0]==true)
        {
         Print("Opposite Close Buy ",Pair);

      myOrderClose(OP_BUY,OrderLots(),"");
        }

  }



input string Comment_ea="";


//+------------------------------------------------------------------+
//|                        RectLabelCreate                                          |
//+------------------------------------------------------------------+
bool RectLabelCreate(const long             chart_ID=0,               // chart's ID
                     const string           name="RectLabel",         // label name
                     const int              sub_window=3,             // subwindow index
                     const int              x=80,                      // X coordinate
                     const int              y=120,                      // Y coordinate
                     const int              width=50,                 // width
                     const int              height=18,                // height
                     const color            back_clr=C'236,233,216',  // background color
                     const ENUM_BORDER_TYPE border=BORDER_SUNKEN,     // border type
                     const ENUM_BASE_CORNER corner=CORNER_LEFT_UPPER, // chart corner for anchoring
                     const color            clr=clrRed,               // flat border color (Flat)
                     const ENUM_LINE_STYLE  style=STYLE_SOLID,        // flat border style
                     const int              line_width=1,             // flat border width
                     const bool             back=true,               // in the background
                     const bool             selection=false,          // highlight to move
                     const bool             hidden=true,              // hidden in the object list
                     const long             z_order=0
                    )                // priority for mouse click
  {
//--- reset the error value
   ObjectDelete(chart_ID,name);
   ResetLastError();
//--- create a rectangle label
   if(!ObjectCreate(chart_ID,name,OBJ_RECTANGLE_LABEL,sub_window,0,0))
     {
      Print(__FUNCTION__,
            ": failed to create a rectangle label! Error code = ",GetLastError());
      return(false);
     }
//--- set label coordinates
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
//--- set label size
   ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width);
   ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height);
//--- set background color
   ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,back_clr);
//--- set border type
   ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_TYPE,border);
//--- set the chart's corner, relative to which point coordinates are defined
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner);
//--- set flat border color (in Flat mode)
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- set flat border line style
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- set flat border width
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,line_width);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the label by mouse
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Move rectangle label                                             |
//+------------------------------------------------------------------+
bool RectLabelMove(const long   chart_ID=0,       // chart's ID
                   const string name="RectLabel", // label name
                   const int    x=5,              // X coordinate
                   const int    y=7)              // Y coordinate
  {
//--- reset the error value
   ResetLastError();
//--- move the rectangle label
   if(!ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x))
     {
      Print(__FUNCTION__,
            ": failed to move X coordinate of the label! Error code = ",GetLastError());
      return(false);
     }
   if(!ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y))
     {
      Print(__FUNCTION__,
            ": failed to move Y coordinate of the label! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution
   return(true);
  }


//+------------------------------------------------------------------+
//|                          LabelCreate                                        |
//+------------------------------------------------------------------+
bool LabelCreate(const long              chart_ID=0,               // chart's ID
                 const string            name="Label",             // label name
                 const int               sub_window=0,             // subwindow index
                 const int               x=0,                      // X coordinate
                 const int               y=0,                      // Y coordinate
                 const ENUM_BASE_CORNER  corner=CORNER_LEFT_UPPER, // chart corner for anchoring
                 const string            text="Label",             // text
                 const string            font="Arial",             // font
                 const int               font_size=10,             // font size
                 const color             clr=C'183,28,28',// color
                 const double            angle=0.0,                // text slope
                 const ENUM_ANCHOR_POINT anchor2=ANCHOR_LEFT_UPPER, // anchor type
                 const bool              back=false,               // in the background
                 const bool              selection=false,          // highlight to move
                 const bool              hidden=true,              // hidden in the object list
                 const long              z_order=0)                // priority for mouse click
  {
//--- reset the error value
   ObjectDelete(chart_ID,name);

   ResetLastError();
//--- create a text label
   if(!ObjectCreate(chart_ID,name,OBJ_LABEL,sub_window,0,0))
     {
      Print(__FUNCTION__,
            ": failed to create text label! Error code = ",GetLastError());
      return(false);
     }
//--- set label coordinates
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
//--- set the chart's corner, relative to which point coordinates are defined
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner);
//--- set the text
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
//--- set text font
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
//--- set font size
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
//--- set the slope angle of the text
   ObjectSetDouble(chart_ID,name,OBJPROP_ANGLE,angle);
//--- set anchor type
   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor2);
//--- set color
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the label by mouse
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Move the text label                                              |
//+------------------------------------------------------------------+
bool LabelMove(const long   chart_ID=0,   // chart's ID
               const string name="Label", // label name
               const int    x=0,          // X coordinate
               const int    y=0)          // Y coordinate
  {
//--- reset the error value
   ResetLastError();
//--- move the text label
   if(!ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x))
     {
      Print(__FUNCTION__,
            ": failed to move X coordinate of the label! Error code = ",GetLastError());
      return(false);
     }
   if(!ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y))
     {
      Print(__FUNCTION__,
            ": failed to move Y coordinate of the label! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution
   return(true);
  }






//+------------------------------------------------------------------+
//|             ButtonCreate                                         |
//+------------------------------------------------------------------+
bool ButtonCreate(const long              chart_ID=0,               // chart's ID
                  const string            name="Button",            // button name
                  const int               sub_window=0,             // subwindow index
                  const int               x=0,                      // X coordinate
                  const int               y=0,                      // Y coordinate
                  const int               width=50,                 // button width
                  const int               height=18,                // button height
                  const ENUM_BASE_CORNER  corner=CORNER_LEFT_UPPER, // chart corner for anchoring
                  const string            text="Button",            // text
                  const string            font="Arial",             // font
                  const int               font_size=10,             // font size
                  const color             clr=clrBlack,             // text color
                  const color             back_clr=C'236,233,216',  // background color
                  const color             border_clr=clrNONE,       // border color
                  const bool              state=false,              // pressed/released
                  const bool              back=false,               // in the background
                  const bool              selection=false,          // highlight to move
                  const bool              hidden=true,              // hidden in the object list
                  const long              z_order=0)                // priority for mouse click
  {
   ObjectDelete(chart_ID,name);
//--- reset the error value
   ResetLastError();
//--- create the button
   if(!ObjectCreate(chart_ID,name,OBJ_BUTTON,sub_window,0,0))
     {
      Print(__FUNCTION__,
            ": failed to create the button! Error code = ",GetLastError());
      return(false);
     }
//--- set button coordinates
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
//--- set button size
   ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width);
   ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height);
//--- set the chart's corner, relative to which point coordinates are defined
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner);
//--- set the text
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
//--- set text font
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
//--- set font size
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
//--- set text color
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- set background color
   ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,back_clr);
//--- set border color
   ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_COLOR,border_clr);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- set button state
   ObjectSetInteger(chart_ID,name,OBJPROP_STATE,state);
//--- enable (true) or disable (false) the mode of moving the button by mouse
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Move the button                                                  |
//+------------------------------------------------------------------+
bool ButtonMove(const long   chart_ID=0,    // chart's ID
                const string name="Button", // button name
                const int    x=0,           // X coordinate
                const int    y=0)           // Y coordinate
  {
//--- reset the error value
   ResetLastError();
//--- move the button
   if(!ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x))
     {
      Print(__FUNCTION__,
            ": failed to move X coordinate of the button! Error code = ",GetLastError());
      return(false);
     }
   if(!ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y))
     {
      Print(__FUNCTION__,
            ": failed to move Y coordinate of the button! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution
   return(true);
  }



//+------------------------------------------------------------------+
//|                         EditCreate                                         |
//+------------------------------------------------------------------+
bool EditCreate(const long             chart_ID=0,               // chart's ID
                const string           name="Edit",              // object name
                const int              sub_window=0,             // subwindow index
                const int              x=0,                      // X coordinate
                const int              y=0,                      // Y coordinate
                const int              width=50,                 // width
                const int              height=18,                // height
                const string           text="Text",              // text
                const string           font="Arial",             // font
                const int              font_size=10,             // font size
                const ENUM_ALIGN_MODE  align=ALIGN_CENTER,       // alignment type
                const bool             read_only=false,          // ability to edit
                const ENUM_BASE_CORNER corner=CORNER_LEFT_UPPER, // chart corner for anchoring
                const color            clr=clrBlack,             // text color
                const color            back_clr=clrWhite,        // background color
                const color            border_clr=clrNONE,       // border color
                const bool             back=false,               // in the background
                const bool             selection=false,          // highlight to move
                const bool             hidden=true,              // hidden in the object list
                const long             z_order=0)                // priority for mouse click
  {
   ObjectDelete(chart_ID,name);
//--- reset the error value
   ResetLastError();
//--- create edit field
   if(!ObjectCreate(chart_ID,name,OBJ_EDIT,sub_window,0,0))
     {
      Print(__FUNCTION__,
            ": failed to create \"Edit\" object! Error code = ",GetLastError());
      return(false);
     }
//--- set object coordinates
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
//--- set object size
   ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width);
   ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height);
//--- set the text
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
//--- set text font
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
//--- set font size
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
//--- set the type of text alignment in the object
   ObjectSetInteger(chart_ID,name,OBJPROP_ALIGN,align);
//--- enable (true) or cancel (false) read-only mode
   ObjectSetInteger(chart_ID,name,OBJPROP_READONLY,read_only);
//--- set the chart's corner, relative to which object coordinates are defined
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner);
//--- set text color
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- set background color
   ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,back_clr);
//--- set border color
   ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_COLOR,border_clr);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the label by mouse
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution
   return(true);
  }
  

//+------------------------------------------------------------------+
//|                  CreateSymbolPanel                                 |
//+------------------------------------------------------------------+
void CreateSymbolPanel(bool   showSymbolPanel, int option)
  {
   if(showSymbolPanel==false) return;
   int x =0;
   int y =0;color clr=clrNONE;
   for(int j=0; j<option; j++)
     {
      ArrayResize(_isBuy,option,0);
      ArrayResize(_isSell,option,0);
      //--- Initialization of buy/sell state arrays
      if(TradeSignal2(j)==1)_isBuy[j] = true;clr=clrGreen;
       if(TradeSignal2(j)==-1)_isBuy[j] = true; _isSell[j] = true;clr=clrRed;
     
       comments.SetText(2,EnumToString(TradeSignal2(j)),clr);
      //--- Creation of GUI buttons
      ButtonCreate(0,OBJPFX+"SGGS"+(string)j,0,startx_symbolpanel+x,starty_symbolpanel+y+5,panelwidth/5,buttonheight,CORNER_LEFT_UPPER,Symbols[j],"Calibri",TradedSymbolsFontSize, clrWhite,j==0?clrGreen:clrRed,clrNONE,j==SymbolButtonSelected?true:false,false,false,true,0);
      
     
      x+=(panelwidth/5);
      if(x>=panelwidth)
        {
         x=0;
         y+= buttonheight;
        }
        
           }
  }


 
//+------------------------------------------------------------------+
//| Move Edit object                                                 |
//+------------------------------------------------------------------+
bool EditMove(const long   chart_ID=0,  // chart's ID
              const string name="Edit", // object name
              const int    x=0,         // X coordinate
              const int    y=0)         // Y coordinate
  {
//--- reset the error value
   ResetLastError();
//--- move the object
   if(!ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x))
     {
      Print(__FUNCTION__,
            ": failed to move X coordinate of the object! Error code = ",GetLastError());
      return(false);
     }
   if(!ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y))
     {
      Print(__FUNCTION__,
            ": failed to move Y coordinate of the object! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution
   return(true);
  }
  

int Per_k=0;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string  TradeScheduleSymbol(int symbolindex, Answer selectByBasket)  //execute trade base on schedule symbols
  {

   ArrayResize(array_used_symbols,NumOfSymbols+1000,0);
      

   if(selectByBasket==Yes)
     {



      int schedulselect=0;
      if(TimeCurrent()<start1 &&TimeCurrent()<stop1)
        {

         schedulselect=1;

        }
      else
         if(TimeCurrent()<start2 &&TimeCurrent()<stop2)
           {


            schedulselect=2;

           }
         else
            if(TimeCurrent()<start3 &&TimeCurrent()<stop3)
              {

               schedulselect=3;
              }


      if(InpUsedSymbols==(string)EMPTY)
         printf("symbol list 0 is empty");

      if(symbolList1==(string)EMPTY)
         printf("symbol list 1 is empty");

      if(symbolList2==(string)EMPTY)
         printf("symbol list 2 is empty");

      if(symbolList3==(string)EMPTY)
         printf("symbol list 3 is empty");

      if(schedulselect==1&&symbolList1!=NULL) //time interval 1
        {
         string symbolList11[];
         _split=symbolList1;

         ushort _u_sep=StringGetCharacter(_sep,0);
    Per_k=StringSplit(_split,_u_sep,symbolList11);

         //--- Set the number of symbols in SymbolArraySize
         NumOfSymbols = Per_k;


         return symbolList11[symbolindex];

        }
      else
         if(schedulselect==2&&symbolList2!=NULL) //time interval 2
           {
            string symbolList22[];

            _split=symbolList2;

            ushort _u_sep=StringGetCharacter(_sep,0);
             Per_k=StringSplit(_split,_u_sep,symbolList22);

            //--- Set the number of symbols in SymbolArraySize
            NumOfSymbols = Per_k;


            return symbolList22[symbolindex];
           }
         else
            if(schedulselect==3&&symbolList3!=NULL) //time interval 3
              {
               string symbolList33[];
               _split=symbolList3;

                ushort _u_sep=StringGetCharacter(_sep,0);
                Per_k=StringSplit(_split,_u_sep,symbolList33);

               //---r Set the number of symbols in SymbolArraySize
               NumOfSymbols =Per_k;


               return symbolList33[symbolindex];

              }

     }

   else
     {   ushort _u_sep=StringGetCharacter(_sep,0);
                Per_k=StringSplit(_split,_u_sep,array_used_symbols);

               //---r Set the number of symbols in SymbolArraySize
               NumOfSymbols =Per_k;

      if(symbolindex<Per_k)
         return  array_used_symbols[symbolindex];
      //Go back to normal Trading time

     };
   if(InpUsedSymbols==(string)EMPTY_VALUE)
      printf("symbol list is empty");



   return NULL ;


  }


 
double Ask(){

return tick.ask;};
double Bid(){return tick.bid;};string messages="";

double SetPoint=Point,sls=0,tpx=0;




double TradeSize(MONEYMANAGEMENT moneymanagement)
  {
   

   double TradingLots=0.1;
   double MaxLot = MarketInfo(_Symbol, MODE_MAXLOT);
   double MinLot = MarketInfo(_Symbol, MODE_MINLOT);

   switch(moneymanagement)
     {
      case Market_Volume_Risk:
         TradingLots=1/(((double)Volume[0])*100);
         break;
      case FIXED_SIZE:
         TradingLots= Fixed_size;
         break;
      case Risk_Percent_Per_Trade:
         TradingLots=Riskpertrade(stoploss,_Symbol);
         break;
      case POSITION_SIZE:
         TradingLots= PositionSize(_Symbol);
         break;
      case MARTINGALE_OR_ANTI_MATINGALE:
         TradingLots= Martingale_Size();
         break;
      case LOT_OPTIMIZE:
         TradingLots= LotsOptimized(_Symbol);
         if(TradesCount(OP_BUY)>0)
           {
            TradingLots=SubLots;
           };
           if(TradesCount(OP_SELL)<0)
           {
            TradingLots=SubLots;
           };
         if(TradingLots>MaxLot)
           {
            TradingLots=MaxLot;
           }
         if(TradingLots<MinLot)
           {
            TradingLots=MinLot;
           }

         break;
      default :
         TradingLots=Fixed_size;
         break;
     }

printf("lot "+(string)TradingLots);

   return TradingLots;
  }


//+------------------------------------------------------------------+
//|                    LotsOptimized                                              |
//+------------------------------------------------------------------+
double LotsOptimized(const string symbols)
  {
 
   int    orders=HistoryTotal();     // history orders total
   int    losses=0;                  // number of losses orders without a break
//--- select lot size
   lot=NormalizeDouble(AccountFreeMargin()*MaximumRisk/1000.0,1);
//--- calcuulate number of losses orders without a break
   if(DecreaseFactor>0)
     {
      for(int i=orders-1; i>=0; i--)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false)
           {
            Print("Error in history!");
            break;
           }
         if(OrderSymbol()!=symbols || OrderType()>OP_SELL)
            continue;
         //---
         if(OrderProfit()>0)
            break;
         if(OrderProfit()<0)
            losses++;
        }
      if(losses>1)
         lot=NormalizeDouble(lot-lot*losses/DecreaseFactor,1);
     }
//--- return lot size
   if(lot<0.01)
      lot=0.01;
   return(lot);
  }
//+------------------------------------------------------------------+
//|                     LicenseControl                                             |
//+------------------------------------------------------------------+
bool LicenseControl()
  {

   if(License=="none")
     {


      return true;

     }else if(LicenseMode==LICENSE_FULL){
     if(License=="Noel307##457g"){
     
     return true
     ;
     
     };
     }
     
     else if(LicenseMode==LICENSE_FREE){
     if(License=="Noel307##45W7g"){
     
     return true
     ;
     
     };
     }else if(LicenseMode==LICENSE_TIME){
     if(License=="Noel307#" &&Year()<2023){
     
     return true;
     ;
     
     };
     }else if(LicenseMode==LICENSE_DEMO){
     if(License=="demo"&& Year()<2023 && Month()<=12-Month()){
     
     return true
     ;
     
     };
     
     }
   return false;

  }

//+------------------------------------------------------------------+
//|                     ControlTrade                                             |
//+------------------------------------------------------------------+
void ControlTrade(double resitance,double support,double previousdayhigh, string symbol1,bool controltrade=false)
  {

   if(controltrade)
     {
      datetime uninterrupted_trading_time=0;
      string datafeed=NULL;
      string trend=NULL;

      double moneyatrisk=0;
      double  previousdaylow;
      double openprice[100];
      double closeprice[100];


      int  lot_unit[];
      string tp_sl_mode=NULL;
      double price_average=0;
      double pair_winrate[7];
      double riskpercentage[8];
      double fibonnacci=0;
      string indicatorname=NULL;
      double lotsize=0;
      datetime timelimit=0;
      double percentagegoal=0;
      string pair=symbol1;
      string text=NULL;



double S3x=0,R3x=0;

  R3x=resitance;
      double S1x=support;
      lotsize=OrderLots();

      double losses[],profit[];
      double LotEq_To_Risk =0;
      double size1=(double)Volume[0];
      LotEq_To_Risk=((1/size1)*100);
      yesterday_high = MathMax(yesterday_high,day_high);
      yesterday_low = MathMin(yesterday_low,day_low);
      string symbolst[];
      string message1 ="Do not trade this pair =>> "+pair;
      int h=MathRand()%(OrdersHistoryTotal()+1);
      if(h <OrdersHistoryTotal())
        {

         ArrayResize(riskpercentage,OrdersHistoryTotal(),0);
         

         ArrayResize(pair_winrate,OrdersHistoryTotal(),0);


         ArrayResize(losses,OrdersHistoryTotal(),0);

         ArrayResize(profit,OrdersHistoryTotal()+h,0);
        
         ArrayResize( closeprice,OrdersHistoryTotal()+1,0);
       ArrayResize(openprice,OrdersHistoryTotal()+1,0);
       ArrayResize(closeprice,OrdersHistoryTotal()+1,0);
       ArrayResize(symbolst,OrdersHistoryTotal()+h,0);
         symbolst[h]=symbol1;

         if(OrderSelect(h,SELECT_BY_POS,MODE_HISTORY)&&symbolst[h]==OrderSymbol()&& OrderMagicNumber()==MagicNumber)
           {


            if(OrderProfit()>0)
              {
               profit[h]+=OrderProfit();

              }
            if(OrderProfit()<0)
              {
               losses[h]+=OrderProfit();

              }
          
      closeprice[h]=OrderClosePrice();
      openprice[h]=OrderOpenPrice();
      closeprice[h]=OrderClosePrice();
      previousdayhigh=yesterday_high;
      previousdaylow=yesterday_low;
            text="Trade Allowed for this pair!";


            pair_winrate[h]=losses[h]/(1+profit[h]);
            if(pair_winrate[h]<(0.7))
              {


               text="Do not trade this pair "+symbolst[h];
               printf("Do not trade this pair  "+symbolst[h]);
               if(text=="Do not trade this pair "+symbolst[h])
                 {
                  riskpercentage[h]=(100)*pair_winrate[h];

                 }

              }
            else
               if(pair_winrate[h]>=0.7 &&pair_winrate[h]<=0.79)
                 {

                  riskpercentage[h]=0.5;
                  takeprofit=stoploss/2;
                  printf(StringFormat("%s ,Risk %2.4f,takeprofit %2.4f ",pair,riskpercentage[h],takeprofit));
                  message=StringFormat("%s ,Risk %2.4f,takeprofit %2.4f ",pair,riskpercentage[h],takeprofit);
                  smartBot.SendMessageToChannel(InpChannel,message);

                 }
               else
                  if(pair_winrate[h]>=0.8 &&pair_winrate[h]<=0.83)
                    {

                     riskpercentage[h]=1;
                     takeprofit=stoploss/3;
                     printf(StringFormat("%s ,Risk %2.4f,takeprofit %2.4f ",pair,riskpercentage[h],takeprofit));


                    }
                  else
                     if(pair_winrate[h]>=0.84 &&pair_winrate[h]<=0.86)
                       {

                        riskpercentage[h]=2;
                        takeprofit=stoploss/4;
                        printf(StringFormat("%s ,Risk %2.4f,takeprofit %2.4f ",pair,riskpercentage[h],takeprofit));

                       }
                     else
                        if(pair_winrate[h]>=0.87 &&pair_winrate[h]<=0.89)
                          {
                           printf(StringFormat("%s ,Risk %2.4f,takeprofit %2.4f ",pair,riskpercentage[h],takeprofit));

                           riskpercentage[h]=3;
                           takeprofit=stoploss/5;


                          }
                        else
                           if(pair_winrate[h]>=0.7 && pair_winrate[h]<=0.79)
                             {
                              printf(StringFormat("%s ,Risk %2.4f,takeprofit %2.4f ",pair,riskpercentage[h],takeprofit));

                              riskpercentage[h]=0.5;
                              takeprofit=stoploss/2;
                              printf(StringFormat("%s ,Risk %2.4f,takeprofit %2.4f ",pair,riskpercentage[h],takeprofit));

                             }
                           else
                              if(pair_winrate[h]>=0.90)
                                {

                                 riskpercentage[h]=4;
                                 takeprofit=stoploss/5;
                                 printf(StringFormat("%s ,Risk %2.4f,takeprofit %2.4f ",pair,riskpercentage[h],takeprofit));


                                }

            messages=StringFormat("%s \nPrice %2.4f \nTP  %2.4f \nSL %2.4f \nWinrate %2.4f, \nSupport %2.4f \nResistance %2.4f \nRisk To allocate %2.4f \nAdvise:%s\n", symbolst[h],  tick.ask,  takeprofit,   stoploss,   pair_winrate[h],   support,    resitance,  riskpercentage[h],text);
            smartBot.SendMessageToChannel(InpChannel,messages);


    double R2x=0;


            if(day_high>0 &&today_open>0&&day_low>0)
              {
               message =    StringFormat("%s\nVolume: %2.4f \nLotToRisk for this pair %2.4f\nYesterday high %2.4f\nDay High %2.4f \nDiff  %2.4f \nYesterday close %2.4f\nDay Open %2.4f\nDiff %2.4f\n,Yesterday low %2.4f\n,Day low %2.4f\n,%2.4f\nDiff %2.4f\nCurrent Price %2.4f\nSupport %2.4f\n Resistance %2.4f %2. \n",

                                         symbolst[h],size1,LotEq_To_Risk, yesterday_high,day_high,
                                         ((yesterday_high+1/(day_high))),
                                         yesterday_close,today_open,
                                         ((yesterday_close+1/(today_open))),
                                         yesterday_low,day_low,

                                         ((yesterday_low+1/(day_low))),
                                         tick.ask,S1x,R2x,R3x);
              }
              
              
              
                         bool report=  FileOpen(InpDirectoryName+"\\"+"TradeAdviser.csv",FILE_READ|FILE_WRITE|FILE_CSV|InpEncodingType);
                         
                          if(!report){
                         
                         
                         printf("Error Unable to open  file!TradeAdviser.csv" );
                         
                         }
              
                         FileSeek(report,offset,SEEK_END);
                         
                       bool checkwrite=  FileWrite(report, symbol1   ,tick.ask    ,tick.bid   ,riskpercentage[h]        ,losses[h]     ,profit[h]              );
                         
                          
                         if(!checkwrite){
                         
                         
                         printf("Error Unable to write report on file!TradeAdviser.csv" );
                         
                         }
              
                         FileClose(report);
                        
              
              
              
              
              

           }

        }
     }





  }




//+------------------------------------------------------------------+
//|                             Riskpertrade                                      |
//+------------------------------------------------------------------+
double Riskpertrade(double sl1,string symbol) //Risk % per trade, SL = relative Stop Loss to calculate risk
  {
  
   double MaxLot = MarketInfo(symbol, MODE_MAXLOT);
   double MinLot = MarketInfo(symbol, MODE_MINLOT);
   double tickvalue = MarketInfo(symbol, MODE_TICKVALUE);
   double ticksize = MarketInfo(symbol, MODE_TICKSIZE);
   double lots = (Risk_Percentage )*AccountFreeMargin()/1000000;
   if(lots > MaxLot)
      lots = MaxLot;
   if(lots < MinLot)
      lots = MinLot;
   return(lots);
  }
//+------------------------------------------------------------------+
//|                         NewBar                                          |
//+------------------------------------------------------------------+
bool NewBar()
  {
   static datetime LastTime = 0;
   bool ret = Time[0] > LastTime && LastTime > 0;
   LastTime = Time[0];
   return(ret);
  }





//+------------------------------------------------------------------+
//|                    MARTINGALE                                             |
//+------------------------------------------------------------------+
double Martingale_Size() //martingale / anti-martingale
  {

   double lots = MM_Martingale_Start;
   double MaxLot = MarketInfo(Symbol(), MODE_MAXLOT);
   double MinLot = MarketInfo(Symbol(), MODE_MINLOT);
   if(SelectLastHistoryTrade())
     {
      double orderprofit = OrderProfit();
      double orderlots = OrderLots();
      double boprofit = BOProfit(OrderTicket());
      if(orderprofit + boprofit > 0 && !MM_Martingale_RestartProfit)
         lots = orderlots * MM_Martingale_ProfitFactor;
      else
         if(orderprofit + boprofit < 0 && !MM_Martingale_RestartLoss)
            lots = orderlots * MM_Martingale_LossFactor;
         else
            if(orderprofit + boprofit == 0)
               lots = orderlots;
     }
   if(ConsecutivePL(false, MM_Martingale_RestartLosses))
      lots = MM_Martingale_Start;
   if(ConsecutivePL(true, MM_Martingale_RestartProfits))
      lots = MM_Martingale_Start;
   if(lots > MaxLot)
      lots = MaxLot;
   if(lots < MinLot)
      lots = MinLot;
   return(lots);
  }
//+------------------------------------------------------------------+
//|                      POSITION SIZE                              |
//+------------------------------------------------------------------+
double PositionSize(string symbol) //position sizing
  {


   double MaxLot = MarketInfo(symbol, MODE_MAXLOT);
   double MinLot = MarketInfo(symbol, MODE_MINLOT);
   double lots = AccountBalance() / Position_size;
   if(lots > MaxLot)
      lots = MaxLot;
   if(lots < MinLot)
      lots = MinLot;
   return(lots);
  }
  
//+------------------------------------------------------------------+
//|                 Check Demo Period                                |
//+------------------------------------------------------------------+
bool CheckDemoPeriod(int day,int month,int year)
  {
   if(


      (TimeDay(TimeCurrent())>=day && TimeMonth(TimeCurrent())==month && TimeYear(TimeCurrent())==year) ||
      (TimeMonth(TimeCurrent())>month && TimeYear(TimeCurrent())==year) ||
      (TimeYear(TimeCurrent())>year)
   )
     {
      Print("@TradeExpert: EA"+EnumToString(LicenseMode)+" version expired..!");
      MessageBox("TradeExpert EA "+EnumToString(LicenseMode)+" version expired..!|Contact Seller: NGUEMECHIEU@LIVE.COM","Error:");
      //  EABlocked=true;
      return false;
     }
   else
      return(true);

  }
  

//+------------------------------------------------------------------+
//| dString                                                          |
//+------------------------------------------------------------------+
string dString(string text)
  {
//---
   uchar in[],
         out[],
         key[];
//---
   StringToCharArray("H+#eF_He", key);
//---
   StringToCharArray(text, in, 0, StringLen(text));
//---
   HexToArray(text, in);
//---
   CryptDecode(CRYPT_DES, in, key, out);
//---
   string result = CharArrayToString(out);
//---
   return(result);
  }
//+------------------------------------------------------------------+
//| HexToArray                                                       |
//+------------------------------------------------------------------+
bool HexToArray(string str, uchar &arr[])
  {
//--- By Andrew Sumner & Alain Verleyen
//--- https://www.mql5.com/en/forum/157839/page3
#define HEXCHAR_TO_DECCHAR(h) (h<=57?(h-48):(h-55))
//---
   int strcount = StringLen(str);
   int arrcount = ArraySize(arr);
   if(arrcount < strcount / 2)
      return false;
//---
   uchar tc[];
   StringToCharArray(str, tc);
//---
   int i = 0,
       j = 0;
//---
   for(i = 0; i < strcount; i += 2)
     {
      //---
      uchar tmpchr = (HEXCHAR_TO_DECCHAR(tc[i])<<4)+HEXCHAR_TO_DECCHAR(tc[i+1]);
      //---
      arr[j] = tmpchr;
      j++;
     }
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| ArrayToHex                                                       |
//+------------------------------------------------------------------+
//--- By Andrew Sumner & Alain Verleyen
//--- https://www.mql5.com/en/forum/157839/page3
string ArrayToHex(uchar &arr[], int count = -1)
  {
   string res = "";
//---
   if(count < 0 || count > ArraySize(arr))
      count = ArraySize(arr);
//---
   for(int i = 0; i < count; i++)
      res += StringFormat("%.2X", arr[i]);
//---
   return(res);
  }

//---
void snrfibo(bool showfibolines)
  {
   if(!showfibolines)
      return;
   int counted_bars = IndicatorCounted();
   double day_highx = 0;
   double day_lowx = 0;
   double yesterday_highx = 0;
   double yesterday_openx = 0;
   double yesterday_lowx = 0;
   double yesterday_closex = 0;
   double today_openx = 0;
   double P = 0, S = 0, R = 0, S1 = 0, R1 = 0, S2 = 0, R2 = 0, S3 = 0, R3 = 0;
   int cnt = 720;
   double cur_dayx = 0;
   double prev_dayx = 0;
   double rates_d1x[2][6];
//---- exit if period is greater than daily charts
   if(Period() > 1440)
     {
      Print("Error - Chart period is greater than 1 day.");
      return; // then exit
     }
   cur_dayx = TimeDay(datetime(Time[0] - (gmtoffset()*3600)));
   yesterday_closex = iClose(NULL,snrperiod,1);
   today_openx = iOpen(NULL,snrperiod,0);
   yesterday_highx = iHigh(NULL,snrperiod,1);//day_high;
   yesterday_lowx = iLow(NULL,snrperiod,1);//day_low;
   day_highx = iHigh(NULL,snrperiod,1);
   day_lowx  = iLow(NULL,snrperiod,1);
   prev_dayx = cur_dayx;

   yesterday_highx = MathMax(yesterday_highx,day_highx);
   yesterday_lowx = MathMin(yesterday_lowx,day_lowx);
// messages="Yesterday High : "+ yesterday_high + ", Yesterday Low : " + yesterday_low + ", Yesterday Close : " + yesterday_close ;

//------ Pivot Points ------
   R = (yesterday_highx - yesterday_lowx);
   P = (yesterday_highx + yesterday_lowx + yesterday_closex)/3; //Pivot
   R1 = P + (R * 0.382);
   R2 = P + (R * 0.618);
   R3 = P + (R * 1);
   S1 = P - (R * 0.382);
   S2 = P - (R * 0.618);
   S3 = P - (R * 1);
//---- Set line labels on chart window
   drawLine(R3, "R3", clrLime, 0);
   drawLabel("Resistance 3", R3, clrLime);
   drawLine(R2, "R2", clrGreen, 0);
   drawLabel("Resistance 2", R2, clrGreen);
   drawLine(R1, "R1", clrDarkGreen, 0);
   drawLabel("Resistance 1", R1, clrDarkGreen);
   drawLine(P, "PIVIOT", clrBlue, 1);
   drawLabel("Piviot level", P, clrBlue);
   drawLine(S1, "S1", clrMaroon, 0);
   drawLabel("Support 1", S1, clrMaroon);
   drawLine(S2, "S2", clrCrimson, 0);
   drawLabel("Support 2", S2, clrCrimson);
   drawLine(S3, "S3", clrRed, 0);
   drawLabel("Support 3", S3, clrRed);
   return;
//----
  }

TOOLS tools [100];

void snr (int i)
  {
  string sym=Symbols[i];
   string cc0;
   if(Show_Support_Resistance==false)return;
   int counted_bars = IndicatorCounted();
   double day_highx = 0;
   double day_lowx = 0;
   double yesterday_highx = 0;
   double yesterday_openx = 0;
   double yesterday_lowx = 0;
   double yesterday_closex = 0;
   double today_openx = 0;

   int cnt = 720;
   double cur_dayx = 0;
   double prev_dayx = 0;
   double rates_d1x[2][6];
//---- exit if period is greater than daily charts
   if(Period() > 1440)
     {
      Print("Error - Chart period is greater than 1 day.");
      return; // then exit
     }
   cur_dayx = TimeDay(datetime(Time[0] - (gmtoffset()*3600)));
   yesterday_closex = iClose(Symbols[i],snrperiod,1);
   today_openx = iOpen(Symbols[i],snrperiod,1);
   yesterday_highx = iHigh(Symbols[i],snrperiod,1);//day_high;
   yesterday_lowx = iLow(Symbols[i],snrperiod,1);//day_low;
   day_highx = iHigh(Symbols[i],snrperiod,1);
   day_lowx  = iLow(Symbols[i],snrperiod,1);
   prev_dayx = cur_dayx;

   yesterday_highx = MathMax(yesterday_highx,day_highx);
   yesterday_lowx = MathMin(yesterday_lowx,day_lowx);
   comments.Destroy();
   
   double R3[100],S3[100],S2[100],S1[100];
            
             double R1[100],R2[100];
             ArrayResize(S3,NumOfSymbols,0);
             
             ArrayResize(R1,NumOfSymbols,0);
             ArrayResize(S1,NumOfSymbols,0);
             ArrayResize(R2,NumOfSymbols,0);
             ArrayResize(S2,NumOfSymbols,0);
             
             ArrayResize(R3,NumOfSymbols,0);
             
             ArrayResize(S3,NumOfSymbols,0);
//------ Pivot Points ------
   double R = (yesterday_highx - yesterday_lowx);
 double   P = (yesterday_highx + yesterday_lowx + yesterday_closex)/3;//Pivot
  R1[i] = P + (R * 0.382);
   R2[i] = P + (R * 0.618);
   R3[i] = P + (R * 1);
   S1 [i]= P - (R * 0.382);
   S2[i] = P - (R * 0.618);
  S3[i] = P - (R * 1);
  ControlTrade(R3[i],S3[i],yesterday_highx,sym,sendcontroltrade);
  
  
     comments.SetText(2,"Yesterday High : "+(string) yesterday_high + ", Yesterday Low : " +(string) yesterday_low + ", Yesterday Close : " + (string)yesterday_close,clrBlueViolet);

   if(sendsupportandResisitance)
     {
      if(tools[i].Bid()>R1[i]&&tools[i].Bid()<R1[i]+3*tools[i].Pip()&&tools[i].Bid()<R2[i]&&lastResistance[i]!=R1[i])
        {
         lastResistance[i]=R1[i];
         cc0=sym+ " Reached Resistant Zone @ "+ DoubleToString(R1[i],(int)tools[i].Digits())+" Timeframe: "+Get_Timeframe(Period())+" "+ TimeToString(TimeCurrent(),TIME_DATE)+" - "+TimeToString(TimeCurrent(),TIME_MINUTES);
         smartBot.SendMessage(InpChannelChatID,cc0);
        }
      if(tools[i].Bid()>R2[i]&&tools[i].Bid()<R2[i]+3*tools[i].Pip()&&tools[i].Bid()<R3[i]&&lastResistance[i]!=R2[i])
        {
         lastResistance[i]=R2[i];
         cc0=sym+ " Reached Resistant Zone @ "+ DoubleToString(R2[i],(int)tools[i].Digits())+" Timeframe: "+Get_Timeframe(Period())+" "+ TimeToString(TimeCurrent(),TIME_DATE)+" - "+TimeToString(TimeCurrent(),TIME_MINUTES);
         smartBot.SendMessage(InpChannelChatID,cc0);
        }
      if(tools[i].Bid()>=R3[i]&&tools[i].Bid()<R3[i]+3*tools[i].Pip()&&lastResistance[i]!=R3[i])
        {
         lastResistance[i]=R3[i];
         cc0=sym+ " Reached Resistant Zone @ "+ DoubleToString(R3[i],(int)tools[i].Digits())+" Timeframe: "+Get_Timeframe(Period())+" "+TimeToString(TimeCurrent(),TIME_DATE)+" - "+TimeToString(TimeCurrent(),TIME_MINUTES);
         smartBot.SendMessage(InpChannelChatID,cc0);
        }
      if(tools[i].Bid()<S1[i]&&tools[i].Bid()>S1[i]-3*tools[i].Pip()&&tools[i].Bid()>S2[i]&&lastResistance[i]!=S1[i])
        {
         lastResistance[i]=S1[i];
         cc0=sym+ " Reached Support Zone @ "+ DoubleToString(S1[i],(int)tools[i].Digits())+" Timeframe: "+Get_Timeframe(Period())+" "+ TimeToString(TimeCurrent(),TIME_DATE)+" - "+TimeToString(TimeCurrent(),TIME_MINUTES);
         smartBot.SendMessage(InpChannelChatID,cc0);
        }
      if(tools[i].Bid()<S2[i]&&tools[i].Bid()>(S2[i]-3*tools[i].Pip())&&tools[i].Bid()>S3[i]&&lastResistance[i]!=S2[i])
        {
         lastResistance[i]=S2[i];

         cc0=sym+ " Reached Support Zone @ "+ DoubleToString(S2[i],(int)tools[i].Digits())+" Timeframe: "+Get_Timeframe(Period())+" "+ TimeToString(TimeCurrent(),TIME_DATE)+" - "+TimeToString(TimeCurrent(),TIME_MINUTES);
         smartBot.SendMessage(InpChannelChatID,cc0);
        }
      if(tools[i].Bid()<=S3[i]&&tools[i].Bid()>R3[i]-3*tools[i].Pip()&&lastResistance[i]!=S3[i])
        {
         lastResistance[i]=S3[i];
         cc0=sym+ " Reached Support Zone @ "+ DoubleToString(S3[i],(int)tools[i].Digits())+" Timeframe: "+Get_Timeframe(Period())+" "+ TimeToString(TimeCurrent(),TIME_DATE)+" - "+TimeToString(TimeCurrent(),TIME_MINUTES);

         smartBot.SendMessage(InpChannelChatID,cc0);
        }
     }
  


   return;
//----
  }
  void drawLabel(string Ln, string Lt, int th, string ts, color Lc, int cr, int xp1, int yp1)
  {
   ObjectCreate(Ln, OBJ_LABEL, 0, 0, 0);
   ObjectSetText(Ln, Lt, th, ts, Lc);
   ObjectSet(Ln, OBJPROP_CORNER, cr);
   ObjectSet(Ln, OBJPROP_XDISTANCE, xp1);
   ObjectSet(Ln, OBJPROP_YDISTANCE, yp1);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void drawLabel(string A_name_0, double A_price_8, color A_color_16)
  {
   if(ObjectFind(A_name_0) != 0)
     {
      ObjectCreate(A_name_0, OBJ_TEXT, 0, Time[10], A_price_8);
      ObjectSetText(A_name_0, A_name_0, 8, "Arial", CLR_NONE);
      ObjectSet(A_name_0, OBJPROP_COLOR, A_color_16);
      return;
     }
   ObjectMove(A_name_0, 0, Time[10], A_price_8);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void drawLine(double A_price_0, string A_name_8, color A_color_16, int Ai_20)
  {
   if(ObjectFind(A_name_8) != 0)
     {
      ObjectCreate(A_name_8, OBJ_HLINE, 0, Time[0], A_price_0, Time[0], A_price_0);
      if(Ai_20 == 1)
         ObjectSet(A_name_8, OBJPROP_STYLE, STYLE_SOLID);
      else
         ObjectSet(A_name_8, OBJPROP_STYLE, STYLE_DOT);
      ObjectSet(A_name_8, OBJPROP_COLOR, A_color_16);
      ObjectSet(A_name_8, OBJPROP_WIDTH, 1);
      return;
     }
   ObjectDelete(A_name_8);
   ObjectCreate(A_name_8, OBJ_HLINE, 0, Time[0], A_price_0, Time[0], A_price_0);
   if(Ai_20 == 1)
      ObjectSet(A_name_8, OBJPROP_STYLE, STYLE_SOLID);
   else
      ObjectSet(A_name_8, OBJPROP_STYLE, STYLE_DOT);
   ObjectSet(A_name_8, OBJPROP_COLOR, A_color_16);
   ObjectSet(A_name_8, OBJPROP_WIDTH, 1);
  }




//-------- Debit/Credit total -------------------
bool StopTarget()
  {
   if((Risk_Percentage/AccountBalance()) *100 >= ProfitValue)
     {
      return (true);
     }
   return (false);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int gmtoffset()
  {
   int gmthour;
   int gmtminute;
   datetime timegmt; // Gmt time
   datetime timecurrent; // Current time
   int gmtoffset=offset;
   timegmt=TimeGMT();
   timecurrent=TimeCurrent();
   gmthour=(int)StringToInteger(StringSubstr(TimeToStr(timegmt),11,2));
   gmtminute=(int)StringToInteger(StringSubstr(TimeToStr(timegmt),14,2));
   gmtoffset=TimeHour(timecurrent)-gmthour;
   if(gmtoffset<0)
      gmtoffset=24+gmtoffset;
   return(gmtoffset);
  }


//--- HUD Rectangle
void HUD()
  {
   ObjectCreate(ChartID(), "HUD", OBJ_RECTANGLE_LABEL, 0, 0, 0);
//--- set label coordinates
   ObjectSetInteger(ChartID(), "HUD", OBJPROP_XDISTANCE, Xordinate+0);
   ObjectSetInteger(ChartID(), "HUD", OBJPROP_YDISTANCE, Yordinate+20);
//--- set label size
   ObjectSetInteger(ChartID(), "HUD", OBJPROP_XSIZE, 220);
   ObjectSetInteger(ChartID(), "HUD", OBJPROP_YSIZE, 75);
//--- set background color
   ObjectSetInteger(ChartID(), "HUD", OBJPROP_BGCOLOR, color5);
//--- set border type
   ObjectSetInteger(ChartID(), "HUD", OBJPROP_BORDER_TYPE, BORDER_FLAT);
//--- set the chart's corner, relative to which point coordinates are defined
   ObjectSetInteger(ChartID(), "HUD", OBJPROP_CORNER, 4);
//--- set flat border color (in Flat mode)
   ObjectSetInteger(ChartID(), "HUD", OBJPROP_COLOR, clrWhite);
//--- set flat border line style
   ObjectSetInteger(ChartID(), "HUD", OBJPROP_STYLE, STYLE_SOLID);
//--- set flat border width
   ObjectSetInteger(ChartID(), "HUD", OBJPROP_WIDTH, 1);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(ChartID(), "HUD", OBJPROP_BACK, false);
//--- enable (true) or disable (false) the mode of moving the label by mouse
   ObjectSetInteger(ChartID(), "HUD", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(ChartID(), "HUD", OBJPROP_SELECTED, false);
//--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(ChartID(), "HUD", OBJPROP_HIDDEN, false);
//--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(ChartID(), "HUD", OBJPROP_ZORDER, 0);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void HUD2()
  {
   EA_name() ;
   ObjectCreate(ChartID(), "HUD2", OBJ_RECTANGLE_LABEL, 0, 0, 0);
//--- set label coordinates
   ObjectSetInteger(ChartID(), "HUD2", OBJPROP_XDISTANCE, Xordinate+0);
   ObjectSetInteger(ChartID(), "HUD2", OBJPROP_YDISTANCE, Yordinate+75);
//--- set label size
   ObjectSetInteger(ChartID(), "HUD2", OBJPROP_XSIZE, 220);
   ObjectSetInteger(ChartID(), "HUD2", OBJPROP_YSIZE, 200);
//--- set background color
   ObjectSetInteger(ChartID(), "HUD2", OBJPROP_BGCOLOR, color6);
//--- set border type
   ObjectSetInteger(ChartID(), "HUD2", OBJPROP_BORDER_TYPE, BORDER_FLAT);
//--- set the chart's corner, relative to which point coordinates are defined
   ObjectSetInteger(ChartID(), "HUD2", OBJPROP_CORNER, 4);
//--- set flat border color (in Flat mode)
   ObjectSetInteger(ChartID(), "HUD2", OBJPROP_COLOR, clrWhite);
//--- set flat border line style
   ObjectSetInteger(ChartID(), "HUD2", OBJPROP_STYLE, STYLE_SOLID);
//--- set flat border width
   ObjectSetInteger(ChartID(), "HUD2", OBJPROP_WIDTH, 1);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(ChartID(), "HUD2", OBJPROP_BACK, false);
//--- enable (true) or disable (false) the mode of moving the label by mouse
   ObjectSetInteger(ChartID(), "HUD2", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(ChartID(), "HUD2", OBJPROP_SELECTED, false);
//--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(ChartID(), "HUD2", OBJPROP_HIDDEN, false);
//--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(ChartID(), "HUD2", OBJPROP_ZORDER, 0);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void EA_name()
  {
   string txt2 ="BOT_NAME: " +smartBot.Name()+ "20";
   if(ObjectFind(txt2) == -1)
     {
      ObjectCreate(txt2, OBJ_LABEL, 0, 0, 0);
      ObjectSet(txt2, OBJPROP_CORNER, 0);
      ObjectSet(txt2, OBJPROP_XDISTANCE, Xordinate+15);
      ObjectSet(txt2, OBJPROP_YDISTANCE, Yordinate+17);
     }
   ObjectSetText(txt2, "", 10, "Century Gothic", color1);


   txt2 = "reel" + "22";
   if(ObjectFind(txt2) == -1)
     {
      ObjectCreate(txt2, OBJ_LABEL, 1, 1, 1);
      ObjectSet(txt2, OBJPROP_CORNER, 0);
      ObjectSet(txt2, OBJPROP_XDISTANCE, Xordinate+10);
      ObjectSet(txt2, OBJPROP_YDISTANCE, Yordinate+55);
     }
   ObjectSetText(txt2, "_______________________", 11, "Arial", Gold);




  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void GUI()
  {    
  
   string symbol=Symbol();
           
  int digits=(int)MarketInfo(symbol,MODE_DIGITS);
 
 




   string matauang = "none";

   if(AccountCurrency() == "USD")
      matauang = "$";
   if(AccountCurrency() == "JPY")
      matauang = "¥";
   if(AccountCurrency() == "EUR")
      matauang = "€";
   if(AccountCurrency() == "GBP")
      matauang = "£";
   if(AccountCurrency() == "CHF")
      matauang = "CHF";
   if(AccountCurrency() == "AUD")
      matauang = "A$";
   if(AccountCurrency() == "CAD")
      matauang = "C$";
   if(AccountCurrency() == "RUB")
      matauang = "руб";

   if(matauang == "none")
      matauang = AccountCurrency();

//--- Equity / balance / floating

   string txt2, content;
   int content_len = StringLen(content);
   ObjectSetText(txt2, "[Time: "+TimeToStr(TimeCurrent(),TIME_DATE|TIME_MINUTES)+"]", 6, "Arial", clrBrown);

   string txt1 = "tatino" + "100";
   if(AccountEquity() >= AccountBalance())
     {
      if(ObjectFind(txt1) == -1)
        {
         ObjectCreate(txt1, OBJ_LABEL,0, 1, 0);
         ObjectSet(txt1, OBJPROP_CORNER, 4);
         ObjectSet(txt1, OBJPROP_XDISTANCE, Xordinate +20);
         ObjectSet(txt1, OBJPROP_YDISTANCE, Yordinate +80);
        }

      if(AccountEquity() == AccountBalance())
         ObjectSetText(txt1, "Equity : " + DoubleToStr(AccountEquity(), 2) + matauang, 16, "Century Gothic", color3);
      if(AccountEquity() != AccountBalance())
         ObjectSetText(txt1, "Equity : " + DoubleToStr(AccountEquity(), 2) + matauang, 11, "Century Gothic", color3);
     }
   if(AccountEquity() < AccountBalance())
     {
      if(ObjectFind(txt1) == -1)
        {
         ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
         ObjectSet(txt1, OBJPROP_CORNER, 4);
         ObjectSet(txt1, OBJPROP_XDISTANCE, Xordinate +30);
         ObjectSet(txt1, OBJPROP_YDISTANCE, Yordinate +100);
        }
      if(AccountEquity() == AccountBalance())
         ObjectSetText(txt1, "Equity : " + DoubleToStr(AccountEquity(), 2) + matauang, 17, "Century Gothic", color4);
      if(AccountEquity() != AccountBalance())
         ObjectSetText(txt1, "Equity : " + DoubleToStr(AccountEquity(), 2) + matauang, 14, "Century Gothic", color4);
     }

   txt1 = "tatino" + "101";
   if(AccountEquity() - AccountBalance() > 0)
     {
      if(ObjectFind(txt1) == -1)
        {
         ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
         ObjectSet(txt1, OBJPROP_CORNER, 4);
         ObjectSet(txt1, OBJPROP_XDISTANCE, Xordinate +25);
         ObjectSet(txt1, OBJPROP_YDISTANCE, Yordinate +125);
        }
      ObjectSetText(txt1, "Floating PnL : +" + DoubleToStr(AccountEquity() - AccountBalance(), 2) + matauang, 9, "Century Gothic", color3);
     }
   if(AccountEquity() - AccountBalance() < 0)
     {
      if(ObjectFind(txt1) == -1)
        {
         ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
         ObjectSet(txt1, OBJPROP_CORNER, 4);
         ObjectSet(txt1, OBJPROP_XDISTANCE, Xordinate +25);
         ObjectSet(txt1, OBJPROP_YDISTANCE, Yordinate +125);
        }
      ObjectSetText(txt1, "Floating PnL : " + DoubleToStr(AccountEquity() - AccountBalance(), 2) + matauang, 9, "Century Gothic", color4);
 



     }

   txt1 = "tatino" + "102";
   if(ObjectFind(txt1) == -1)
     {
      ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
      ObjectSet(txt1, OBJPROP_CORNER, 4);
      ObjectSet(txt1, OBJPROP_XDISTANCE, Xordinate +25);
      ObjectSet(txt1, OBJPROP_YDISTANCE, Yordinate +140);
     }
   if(OrdersTotal() != 0)
      ObjectSetText(txt1, "Balance      : " + DoubleToStr(AccountBalance(), 2) + matauang, 9, "Century Gothic", color2);
   if(OrdersTotal() == 0)
      ObjectSetText(txt1, "Balance      : " + DoubleToStr(AccountBalance(), 2) + matauang, 9, "Century Gothic", color2);

   txt1 = "tatino" + "103";
   if(ObjectFind(txt1) == -1)
     {
      ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
      ObjectSet(txt1, OBJPROP_CORNER, 4);
      ObjectSet(txt1, OBJPROP_XDISTANCE, Xordinate +25);
      ObjectSet(txt1, OBJPROP_YDISTANCE, Yordinate +155);
     }
   ObjectSetText(txt1, "AcNumber: " + string(AccountNumber()), 9, "Century Gothic", color2);

   txt1 = "tatino" + "104";
   if(ObjectFind(txt1) == -1)
     {
      ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
      ObjectSet(txt1, OBJPROP_CORNER, 4);
      ObjectSet(txt1, OBJPROP_XDISTANCE, Xordinate +25);
      ObjectSet(txt1, OBJPROP_YDISTANCE, Yordinate +235);
     }
   ObjectSetText(txt1, "NewsInfo : " + jamberita, 9, "Century Gothic", color3);







   txt1 = "tatino" + "105";
   if(ObjectFind(txt1) == -1)
     {
      ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
      ObjectSet(txt1, OBJPROP_CORNER, 4);
      ObjectSet(txt1, OBJPROP_XDISTANCE, Xordinate +25);
      ObjectSet(txt1, OBJPROP_YDISTANCE, Yordinate +250);
     }
   ObjectSetText(txt1, infoberita, 9, "Century Gothic", color3);

   txt1 = "tatino" + "106";
   if(ObjectFind(txt1) == -1)
     {
      ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
      ObjectSet(txt1, OBJPROP_CORNER, 4);
      ObjectSet(txt1, OBJPROP_XDISTANCE, Xordinate +25);
      ObjectSet(txt1, OBJPROP_YDISTANCE, Yordinate +170);
     }
   if(P1 >= 0)
      ObjectSetText(txt1, "Day Profit    : " + DoubleToStr(P1, 2) + matauang, 9, "Century Gothic", color3);
   if(P1 < 0)
      ObjectSetText(txt1, "Day Profit    : " + DoubleToStr(P1, 2) + matauang, 9, "Century Gothic", color4);

   txt1 = "tati" + "106w";
   if(ObjectFind(txt1) == -1)
     {
      ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
      ObjectSet(txt1, OBJPROP_CORNER, 4);
      ObjectSet(txt1, OBJPROP_XDISTANCE, Xordinate +25);
      ObjectSet(txt1, OBJPROP_YDISTANCE, Yordinate +185);
     }
   if(Wp1 >= 0)
      ObjectSetText(txt1, "WeekProfit : " + DoubleToStr(Wp1, 2) + matauang, 9, "Century Gothic", color3);
   if(Wp1 < 0)
      ObjectSetText(txt1, "WeekProfit : " + DoubleToStr(Wp1, 2) + matauang, 9, "Century Gothic", color4);

   txt1 = "tatino" + "107";
   if(ObjectFind(txt1) == -1)
     {
      ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
      ObjectSet(txt1, OBJPROP_CORNER, 4);
      ObjectSet(txt1, OBJPROP_XDISTANCE, Xordinate +100);
      ObjectSet(txt1, OBJPROP_YDISTANCE, Yordinate +210);
     }
   ObjectSetText(txt1, "Spread : " + DoubleToStr(MarketInfo(symbol,MODE_SPREAD)*0.1, 1) + " Pips", 9, "Century Gothic", color3);

   txt1 = "tato" + "108";
   if(ObjectFind(txt1) == -1)
     {
      ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
      ObjectSet(txt1, OBJPROP_CORNER, 4);
      ObjectSet(txt1, OBJPROP_XDISTANCE, Xordinate +25);
      ObjectSet(txt1, OBJPROP_YDISTANCE, Yordinate +210);
     }
   if(harga > lastprice)
      ObjectSetText(txt1,  DoubleToStr(harga, digits), 14, "Century Gothic", Lime);
   if(harga < lastprice)
      ObjectSetText(txt1,  DoubleToStr(harga, digits), 14, "Century Gothic", Red);
   lastprice = harga;

  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void QnDeleteObject()
  {
   for(int i=ObjectsTotal()-1; i>=0; i--)
     {
      string oName = ObjectName(i);
      ObjectDelete(oName);
     }
  }
//+------------------------------------------------------------------+
//|                           rata_price                                       |
//+------------------------------------------------------------------+
double rata_price(int tipe, string Pair)
  {
   double total_lot=0;
   double total_kali=0;
   double rata_price=0;
   for(int cnt=0; cnt<OrdersTotal(); cnt++)
     {
      int xx=OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderSymbol()==Pair && (OrderType()==tipe) && OrderMagicNumber()==MagicNumber)
        {
         total_lot  = total_lot + OrderLots();
         total_kali = total_kali + (OrderLots() * OrderOpenPrice());
        }
     }
   if(total_lot!=0)
     {
      rata_price = total_kali / total_lot;
     }
   else
     {
      rata_price = 0;
     }
   return (rata_price);
  }





//+------------------------------------------------------------------+
//|                          TextPos                                         |
//+------------------------------------------------------------------+
void TextPosB(string nama, string isi, int ukuran, int x, int y, color warna, int pojok)
  {
   if(ObjectFind(nama)<0)
     {
      ObjectCreate(nama,OBJ_LABEL,0,0,0,0,0);
     }
   ObjectSet(nama,OBJPROP_CORNER,pojok);
   ObjectSet(nama,OBJPROP_XDISTANCE,x);
   ObjectSet(nama,OBJPROP_YDISTANCE,y);
   ObjectSetText(nama,isi,ukuran,"Arial bold",warna);

  }

//===========
void SET(int baris, string label2, color col)
  {
   int x,y1;
   y1=12;
   for(int t=0; t<100; t++)
     {
      if(baris==t)
        {
         y1=t*y1;
         break;
        }
     }


   x=63;
   y1=y1+10;
   string bar=DoubleToStr(baris,0);
   string kk=" : ";
   TextPos("SN"+bar, label2, 8, x, y1, col,Info_Corner);

  }
//+------------------------------------------------------------------+
//|                       TextPos                                           |
//+------------------------------------------------------------------+
void TextPos(string nama, string isi, int ukuran, int x, int y1, color warna, int pojok)
  {
   if(ObjectFind(nama)<0)
     {
      ObjectCreate(nama,OBJ_LABEL,0,0,0,0,0);
     }
   ObjectSet(nama,OBJPROP_CORNER,pojok);
   ObjectSet(nama,OBJPROP_XDISTANCE,x);
   ObjectSet(nama,OBJPROP_YDISTANCE,y1);
   ObjectSetText(nama,isi,ukuran,"Arial",warna);
  }



//===========
void SET2(int baris3, string label3, color col3)
  {
   int x3,y3;
   y3=12;
   for(int t3=0; t3<100; t3++)
     {
      if(baris3==t3)
        {
         y3=t3*y3;
         break;
        }
     }


   x3=170;
   y3=y3+10;
   string bar3=DoubleToStr(baris3,0);
   string kk3=" : ";
   TextPos3("SN3"+bar3, label3, 8, x3, y3, col3,Info_Corner);

  }

//+------------------------------------------------------------------+
//|                      TextPos3                                            |
//+------------------------------------------------------------------+
void TextPos3(string nama3, string isi3, int ukuran3, int x3, int y3, color warna3, int pojok3)
  {
   if(ObjectFind(nama3)<0)
     {
      ObjectCreate(nama3,OBJ_LABEL,0,0,0,0,0);
     }
   ObjectSet(nama3,OBJPROP_CORNER,pojok3);
   ObjectSet(nama3,OBJPROP_XDISTANCE,x3);
   ObjectSet(nama3,OBJPROP_YDISTANCE,y3);
   ObjectSetText(nama3,isi3,ukuran3,"Arial",warna3);
  }



//+------------------------------------------------------------------+
//|                          CloseAllm                                        |
//+------------------------------------------------------------------+
void CloseAllm(int gg=0)
  {

   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      Os=OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      if(OrderType()==OP_BUY&& ((gg==1 && OrderProfit()>0)||gg==0))
        {
         Oc=OrderClose(i, OrderLots(), MarketInfo(OrderSymbol(), MODE_BID), 3, CLR_NONE);


         continue;
        }
      if(OrderType()==OP_SELL&& ((gg==1 && OrderProfit()>0)||gg==0))
        {
         Oc=OrderClose(i, OrderLots(), MarketInfo(OrderSymbol(), MODE_ASK), 3, CLR_NONE);

        }


     }
  }


//Function: check indicators signalbfr buffer value
bool signalbfr(double value)
  {
   if(value != 0 && value != EMPTY_VALUE)
      return true;
   else
      return false;
  }


//+------------------------------------------------------------------+
//|                               tradeResponse                                    |
//+------------------------------------------------------------------+
void tradeResponse(string symbol1)
  {

string symbol=symbol1;
   if(UseBot)
      return;
   if(sendorder == Yes)
     {

      int total=OrdersTotal();
      datetime max_time = 0;

      for(int pos=0; pos<total; pos++) // Current orders -----------------------
        {
         if(OrderSelect(pos,SELECT_BY_POS)==false&& OrderSymbol()!=symbol&& OrderMagicNumber()!=MagicNumber)
            continue;
         if(OrderOpenTime() <= _opened_last_time)
            continue;
         message = StringFormat(
                      "\n----TRADE_EXPERT\n OPEN ORDER----\r\n%s %s lots \r\n%s @ %s \r\nSL - %s\r\nTP - %s\r\n----------------------\r\n\n",
                      order_type(),
                      DoubleToStr(OrderLots(),2),
                      OrderSymbol(),
                      DoubleToStr(OrderOpenPrice(),(int)MarketInfo(symbol,MODE_DIGITS)),
                      DoubleToStr(OrderStopLoss(),(int)MarketInfo(symbol,MODE_DIGITS)),
                      DoubleToStr(OrderTakeProfit(),(int)MarketInfo(symbol,MODE_DIGITS))
                   );


         smartBot.SendMessage(InpChatID2,message,smartBot.ReplyKeyboardMarkup(KEYB_MAIN,FALSE,FALSE),false,false);


         if(StringLen(message) > 0)
           {
            smartBot.SendMessage(InpChatID2,message,smartBot.ReplyKeyboardMarkup(KEYB_MAIN,FALSE,FALSE),false,false);
           }
         max_time = MathMax(max_time,OrderOpenTime());

        }

      _opened_last_time = MathMax(max_time,_opened_last_time);

     }

   if(sendclose == Yes)
     {
      datetime max_time = 0;
      double day_profit = 0;

      bool is_closed = false;
      int total = OrdersHistoryTotal();
      for(int pos=0; pos<total; pos++)  // History orders-----------------------
        {

         if(TimeDay(TimeCurrent()) == TimeDay(OrderCloseTime()) && OrderCloseTime() > iTime(NULL,1440,0))
           {
            day_profit += order_pips();
           }

         if(OrderSelect(pos,SELECT_BY_POS,MODE_HISTORY)==false)
            continue;
         if(OrderCloseTime() <= _closed_last_time)
            continue;

         printf(TimeToStr(OrderCloseTime()));
         is_closed = true;
         message = StringFormat("\n"+smartBot.Name() +"CLOSE PROFIT----\r\n%s %s lots\r\n%s @ %s\r\nSL - %s \r\nTP - %s \r\nProfit: %s PIPS \r\n--------------------------------\r\n\n",
                                order_type(),
                                DoubleToStr(OrderLots(),2),
                                OrderSymbol(),
                                DoubleToStr(OrderOpenPrice(),(int)MarketInfo(symbol,MODE_DIGITS)),
                                DoubleToStr(OrderClosePrice(),(int)MarketInfo(symbol,MODE_DIGITS)),
                                DoubleToStr(OrderTakeProfit(),(int)MarketInfo(symbol,MODE_DIGITS)),
                                DoubleToStr(order_pips()/10,1)
                               );

         if(is_closed)

            smartBot.SendMessage(InpChatID2,message,smartBot.ReplyKeyboardMarkup(KEYB_MAIN,FALSE,FALSE),false,false);


         if(StringLen(message) > 0)
           {
            if(is_closed)
               message += StringFormat("Total Profit for today : %s PIPS",DoubleToStr(day_profit/10,1));
            printf(message);

            smartBot.SendMessage(InpChatID2,message,smartBot.ReplyKeyboardMarkup(KEYB_MAIN,FALSE,FALSE),false,false);
            }

         max_time = MathMax(max_time,OrderCloseTime());

        }
      _closed_last_time = MathMax(max_time,_closed_last_time);

     }


  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double order_pips()
  {
   if(OrderType() == OP_BUY)
     {
      return (OrderClosePrice()-OrderOpenPrice())/(MathMax(MarketInfo(OrderSymbol(),MODE_POINT),0.00000001));
     }
   else
     {
      return (OrderOpenPrice()-OrderClosePrice())/(MathMax(MarketInfo(OrderSymbol(),MODE_POINT),0.00000001));
     }
  }
//+------------------------------------------------------------------+
//|                    Order_type                                               |
//+------------------------------------------------------------------+
string order_type()
  {

   if(OrderType() == OP_BUY)
      return "BUY";
   if(OrderType() == OP_SELL)
      return "SELL";
   if(OrderType() == OP_BUYLIMIT)
      return "BUYLIMIT";
   if(OrderType() == OP_SELLLIMIT)
      return "SELLLIMIT";
   if(OrderType() == OP_BUYSTOP)
      return "BUYSTOP";
   if(OrderType() == OP_SELLSTOP)
      return "SELLSTOP";

   return "";
  }

datetime _tms_last_time_messaged;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string Get_Timeframe(int tf)
  {
   string txt="";

   switch(tf)
     {
      case     1:
         txt ="M1";
         break;
      case     5:
         txt ="M5";
         break;
      case    15:
         txt ="M15";
         break;
      case    30:
         txt ="M30";
         break;
      case    60:
         txt ="H1";
         break;
      case   240:
         txt ="H4";
         break;
      case  1440:
         txt ="D1";
         break;
      case 10080:
         txt ="W1";
         break;
      case 43200:
         txt ="MN1";
         break;
     }
   return txt;
  }



//------------------------------------------------------------------------------------------------------------
//--------------------------------------------- INTERNAL VARIABLE --------------------------------------------
//--- Vars and arrays


//--- Alert
bool FirstAlert=false;
bool SecondAlert=false;
datetime AlertTime=0;
//--- Buffers

//--- time
datetime xmlModifed;
int TimeOfDay=Hour();
datetime Midnight=0;
//+------------------------------------------------------------------+
//|                          TimeNewsFunck                                        |
//+------------------------------------------------------------------+

datetime TimeNewsFunck(int nomf)//RETURN CORRECT NEWS TIME FORMAT
  {
   string s=(string)mynews[nomf].getDate();
   string time=StringConcatenate(StringSubstr(s,0,4),".",StringSubstr(s,5,2),".",StringSubstr(s,8,2)," ",StringSubstr(s,11,2),":",StringSubstr(s,14,5));
   string hour=StringSubstr(s,5,2);
   mynews[nomf].setHours((int)hour);
   string seconde=StringSubstr(s,14,5);
   mynews[nomf].setSecondes((int)seconde);
   return ((datetime)StringToTime(time) +offset*3600);
  }
  


//+------------------------------------------------------------------+
//|                              ReadWEB                                 |
//+------------------------------------------------------------------+
string ReadWEB()
  {
const string google_urls="https://www.forexfactory.com/calendar?day";
string params="[]";
   int timeout=5000;

   char data[];
   int data_size=StringLen(params);
   uchar result[];
   string result_headers;
int   start_index=0;
//--- application/x-www-form-urlencoded
   int res=WebRequest("GET","https://nfs.faireconomy.media/ff_calendar_thisweek.json?version=da47050b0660a5aea5aa1984e9554046",0,params,5000,data,0,result,result_headers);
     string  out;out=CharArrayToString(result,0,WHOLE_ARRAY);
     
     printf(out);
 
   if(res==200)//OK
     {
      //--- delete BOM
 
      int size= ArraySize(result);
     
      //---
     CJAVal  js(NULL,out);
      js.Deserialize(result);

      int total=ArraySize(js[""].m_e);
      printf("json array size"+ (string)total);
      
    
      NomNews=total;

    
           ArrayResize(  mynews ,total,0);

      for( int i=0;i<total;i++)
        {
         //Getting jason data'
      
         
         CJAVal item=js.m_e[i];
         
         
         //looping troughout each arrays to get data
         mynews[i].setDate(item["date"].ToStr());
         mynews[i].setTitle(item["title"].ToStr());
         mynews[i].setSourceUrl(google_urls);
         mynews[i].setCountry(item["country"].ToStr());
         mynews[i].setImpact(item["impact"].ToStr());
         mynews[i].setForecast(item["forecast"].ToDbl());
         mynews[i].setPrevious(item["previous"].ToDbl());

         mynews[i].setMinutes((int)(-TimeNewsFunck(i) + TimeCurrent()));  
         
         
        }

      for(int i=0; i<total; i++)
        {
         bool handle=FileOpen("News.csv"+"\\"+InpFileName, FILE_READ|FILE_CSV|FILE_WRITE|InpEncodingType);
         if(!handle)
           {  printf("Error Can't open file"+InpFileName +" to store news events! \nIf open please close it while bot is running.");
           }
         else
           {message=mynews[i].toString();
            FileSeek(handle,offset,SEEK_END);
            FileWrite(handle,message);
            FileClose(handle);
            printf(mynews[i].toString());
           }


        }
     }


   else
     {
      if(res==-1)
        {
       printf((string)(_LastError));
        }
      else
        {
         //--- HTTP errors
         if(res>=100 && res<=511)
           {
          out=CharArrayToString(result,0,WHOLE_ARRAY,CP_UTF8);
            Print(out);
            printf((string)(ERR_HTTP_ERROR_FIRST+res));
           }
         printf(((string)res));
        }
     }

  printf(out);
  return(out);

  }

  
  //+------------------------------------------------------------------+
  //|                            newsUpdate()                                       |
  //+------------------------------------------------------------------+
  
void newsUpdate()//UPDATE NEWS DATA
  {
//--- do not download on saturday
   if(TimeDayOfWeek(Midnight)==6)
      return;
   else
     {
      Print(" check for updates...");
      Print("Delete old file"+ InpFileName);
      FileDelete(InpFileName);

     ReadWEB();
    
      xmlModifed=(datetime)FileGetInteger(InpFileName,FILE_MODIFY_DATE,false);
      PrintFormat("Updated successfully! last modified: %s",InpFileName);
     }
  }
//+------------------------------------------------------------------+
//|               NEWSTRADE                                                   |
//+------------------------------------------------------------------+
bool newsTrade()//RETURN TRUE IF TRADE IS ALLOWED
  {

   offset = gmtoffset();
   double CheckNews=0;
   if(MinAfter>0)
     {
      if(TimeCurrent()-LastUpd>=Upd)
        {
         Comment("News Loading...");
         Print("News Loading...");
         newsUpdate();//update news
         LastUpd=TimeCurrent();
         Comment("");
         smartBot.SendMessageToChannel(InpChannel,"News Loading ...\n");

        }
      WindowRedraw();
      //---Draw a line on the chart news--------------------------------------------
      if(DrawLines)
        {
         for(int i=0; i<NomNews; i++)
           { 

            string Name=StringSubstr(TimeToStr(mynews[i].getMinutes(),TIME_MINUTES)+"_"+mynews[i].getImpact()+"_"+mynews[i].getTitle(),0,63);

            if(TimeNewsFunck(i)<TimeCurrent() && Next) continue;

            color clrf = clrNONE;
            if(Vhigh &&  StringFind(mynews[i].getTitle(),judulnews)>=0 )   clrf=clrRed;
                 
           if(Vhigh && mynews[i].getImpact()=="High")
                  clrf=clrRed;
            if(Vmedium &&mynews[i].getImpact()=="Medium")
               clrf=clrYellow;
            if(Vlow &&   mynews[i].getImpact()=="Low")
               clrf=clrGreen;

            if(clrf==clrNONE)
               continue;

            if(mynews[i].getTitle()!="")
              {
               ObjectCreate(0,Name,OBJ_VLINE,0,TimeNewsFunck(i),Bid);
               ObjectSet(Name,OBJPROP_COLOR,clrf);
               ObjectSet(Name,OBJPROP_STYLE,Style);
               ObjectSetInteger(0,Name,OBJPROP_BACK,true);
              }
           }
        }
      //---------------event Processing------------------------------------
      int i;
      CheckNews=0; int power =0;

      for(i=0; i<NomNews; i++)
        {  google_urlx="https://www.forexfactory.com/calendar?day";
        
      
       
         if(Vhigh && StringFind(mynews[i].getTitle(),judulnews)>=0)
            power=1;

         if(Vhigh && mynews[i].getImpact()=="High")
            power=1;
         if(Vmedium &&  mynews[i].getImpact()=="Medium")
            power=2;
         if(Vlow &&  mynews[i].getImpact()=="Low")
            power=3;
         if(power==0){continue;}
         if(TimeCurrent()+ BeforeNewsStop> TimeNewsFunck(i) && TimeCurrent()-60*AfterNewsStop< TimeNewsFunck(i)&&mynews[i].getTitle()!="")
           {
            jamberita= "==>Within "+(string)mynews[i].getMinutes()+" minutes\n"+mynews[i].toString();
            
            CheckNews=1;
               
         string ms;
           ms  =message=mynews[i].toString();//get message data with format
             
            if(ms!=message){
            ms=message;
             smartBot.SendMessageToChannel(InpChannel,jamberita);
            
            }else{
                 }
      
           }
         else{
            CheckNews=0;

         }
         if((CheckNews==1 && i!=Now && Signal)||(CheckNews==1 && i!=Now && sendnews==Yes))
           {
           
            message=mynews[i].toString();
             smartBot.SendMessageToChannel(InpChannel,message);

                     ;
            Now=i;
      
       
        }
      if(CheckNews>0 && NewsFilter)
         trade=false;
      if(CheckNews>0)
        {
       
         if(!StopTarget()&& !NewsFilter) {infoberita=" we are in the framework of the news\nAttention!! News Time \n!";
       

         
              
             /////  We are doing here if we are in the framework of the news
        
         if( mynews[i].getMinutes()==AfterNewsStop-1&& !FirstAlert&&(CheckNews==1 && i==Now && sendnews == Yes))
          {

            FirstAlert=true;
            smartBot.SendMessageToChannel(InpChannel,"-->>First Alert\n "+message);


           }
         //--- second alert
         if( mynews[i].getMinutes()==BeforeNewsStop-1 && !SecondAlert&&(CheckNews==1 && i==Now && sendnews == Yes))
           {
            smartBot.SendMessageToChannel(InpChannel,">>Second Alert\n "+message);
            SecondAlert=true;

           }
           
           
           
           
           
           
           }
        }
      else{
      
        if(NewsFilter)
            trade=true;
         // We are out of scope of the news release (No News)
         if(!StopTarget()&& mynews[i].getMinutes()==BeforeNewsStop-1 && !SecondAlert&&(CheckNews==1 && i==Now && sendnews == Yes))
           {
            jamberita= " We are out of scope of the news release\n (No News)\n";   
  
            infoberita = "Waiting......";
            
       smartBot.SendMessageToChannel(InpChannel,jamberita+infoberita);
         
              
           }
          
        }
                    
       
     }
     
   return trade;
   }
      return trade;
  }


  
void createFibo()
  {string symbol=Symbol();
   int bar = WindowFirstVisibleBar();
   int shiftLowest  = iLowest(Symbol(), 0, MODE_LOW, bar - 1, 1);
   int shiftHighest = iHighest(Symbol(), 0, MODE_HIGH, bar - 1, 1);

   current_low=iLow(Symbol(),PERIOD_CURRENT,shiftLowest);
   current_high=iHigh(Symbol(),PERIOD_CURRENT,shiftHighest);
   price_delta=current_high-current_low;

   bool   isDownTrend = shiftHighest > shiftLowest;
   string fiboObjectId1 = headerString + "1";
   string fiboObjectHigh = headerString + "High";
   string fiboObjectLow = headerString + "Low";
   string unretracedZoneObject = headerString + "UnretracedZone";
   int shiftMostRetraced;

   if(isDownTrend == true)
     {

      ObjectCreate(fiboObjectId1, OBJ_FIBO,0, Time[shiftHighest], High[shiftHighest], Time[shiftLowest], Low[shiftLowest]);
      ObjectSet(fiboObjectId1, OBJPROP_LEVELWIDTH, fiboWidth);
      ObjectSet(fiboObjectId1, OBJPROP_LEVELSTYLE, fiboStyle);

      if(showUnretracedZone == true)
        {
         if(shiftLowest > 0)
           {
            shiftMostRetraced = iHighest(NULL, 0, MODE_HIGH, shiftLowest - 1, 0);
            ObjectCreate(unretracedZoneObject, OBJ_RECTANGLE, 0, Time[shiftMostRetraced], High[shiftHighest], Time[0], High[shiftMostRetraced]);
            ObjectSet(unretracedZoneObject, OBJPROP_COLOR, unretracedZoneColor);
           }
        }
     }

   else
     {

      ObjectCreate(fiboObjectId1, OBJ_FIBO, 0, Time[shiftLowest], Low[shiftLowest], Time[shiftHighest], High[shiftHighest]);
      ObjectSet(fiboObjectId1, OBJPROP_LEVELWIDTH, fiboWidth);
      ObjectSet(fiboObjectId1, OBJPROP_LEVELSTYLE, fiboStyle);
      if(showUnretracedZone == true)
        {
         if(shiftHighest > 0)
           {
            shiftMostRetraced = iLowest(NULL, 0, MODE_LOW, shiftHighest - 1, 0);
            ObjectCreate(unretracedZoneObject, OBJ_RECTANGLE, 0, Time[shiftMostRetraced], Low[shiftLowest], Time[0], Low[shiftMostRetraced]);
            ObjectSet(unretracedZoneObject, OBJPROP_COLOR, unretracedZoneColor);
           }
        }


     }
//__________________________________________________________________________________________________________________________________________________
//
   ObjectSet(fiboObjectId1, OBJPROP_LEVELCOLOR, fiboColor);
   ObjectSet(fiboObjectId1, OBJPROP_LEVELSTYLE, fiboStyle);
   ObjectSet(fiboObjectId1, OBJPROP_LEVELWIDTH, fiboWidth);
   ObjectSet(fiboObjectId1, OBJPROP_FIBOLEVELS, 11);

   ObjectSet(fiboObjectId1, OBJPROP_FIRSTLEVEL + 0, FIBO_LEVEL_0);
   ObjectSetFiboDescription(fiboObjectId1, 0, DoubleToString(FIBO_LEVEL_0*100,1)+"  - %$");
   ObjectSet(fiboObjectId1, OBJPROP_FIRSTLEVEL + 1, FIBO_LEVEL_1);
   ObjectSetFiboDescription(fiboObjectId1, 1, DoubleToString(FIBO_LEVEL_1*100,1)+"  - %$");
   ObjectSet(fiboObjectId1, OBJPROP_FIRSTLEVEL + 2, FIBO_LEVEL_2);
   ObjectSetFiboDescription(fiboObjectId1, 2, DoubleToString(FIBO_LEVEL_2*100,1)+"  - %$");
   ObjectSet(fiboObjectId1, OBJPROP_FIRSTLEVEL + 3, FIBO_LEVEL_3);
   ObjectSetFiboDescription(fiboObjectId1, 3, DoubleToString(FIBO_LEVEL_3*100,1)+"  - %$");
   ObjectSet(fiboObjectId1, OBJPROP_FIRSTLEVEL + 4, FIBO_LEVEL_4);
   ObjectSetFiboDescription(fiboObjectId1, 4, DoubleToString(FIBO_LEVEL_4*100,1)+"  - %$");
   ObjectSet(fiboObjectId1, OBJPROP_FIRSTLEVEL + 5, FIBO_LEVEL_5);
   ObjectSetFiboDescription(fiboObjectId1, 5, DoubleToString(FIBO_LEVEL_5*100,1)+"  - %$");
   ObjectSet(fiboObjectId1, OBJPROP_FIRSTLEVEL + 6, FIBO_LEVEL_6);
   ObjectSetFiboDescription(fiboObjectId1, 6, DoubleToString(FIBO_LEVEL_6*100,1)+"  - %$");
   ObjectSet(fiboObjectId1, OBJPROP_FIRSTLEVEL + 7, FIBO_LEVEL_7);
   ObjectSetFiboDescription(fiboObjectId1, 7, DoubleToString(FIBO_LEVEL_7*100,1)+"  - %$");
   ObjectSet(fiboObjectId1, OBJPROP_FIRSTLEVEL + 8, FIBO_LEVEL_8);
   ObjectSetFiboDescription(fiboObjectId1, 8, DoubleToString(FIBO_LEVEL_8*100,1)+"  - %$");
   ObjectSet(fiboObjectId1, OBJPROP_FIRSTLEVEL + 9, FIBO_LEVEL_9);
   ObjectSetFiboDescription(fiboObjectId1, 9, DoubleToString(FIBO_LEVEL_9*100,1)+"  - %$");
   ObjectSet(fiboObjectId1, OBJPROP_FIRSTLEVEL + 10,FIBO_LEVEL_10);
   ObjectSetFiboDescription(fiboObjectId1, 10, DoubleToString(FIBO_LEVEL_10*100,1)+"  - %$");

   if(previous_trend!=isDownTrend)
      RESET_ALARMS();

   previous_trend=isDownTrend;
//__________________________________________________________________________________________________________________________________________________
//
// FIBO MESSAGES ON LEVEL CROSSING UP
//__________________________________________________________________________________________________________________________________________________
//
   if(SymbolInfoDouble(symbol,SYMBOL_BID)<=current_high-FIBO_LEVEL_1*price_delta&&alarm_fibo_level_1==false&&ALERT_ACTIVE_FIBO_LEVEL_1==true&&isDownTrend==false)
     {

      alarm_fibo_level_1=true;

      if(ALERT_MODE == E_MAIL_AND_MOBILE)
        {
         SendMail("FIBO MT4 NOTIFICATION",symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_1,1)+" "+" PRICE "+" "+DoubleToStr(SymbolInfoDouble(symbol,SYMBOL_BID),5));

         SendNotification(symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_1,1)+" "+" PRICE "+" "+DoubleToStr(SymbolInfoDouble(symbol,SYMBOL_BID),5));
        }

      if(ALERT_MODE==E_MAIL)
         SendMail("FIBO MT4 NOTIFICATION",symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_1,1)+" "+" PRICE "+" "+DoubleToStr(SymbolInfoDouble(symbol,SYMBOL_BID),5));
      if(ALERT_MODE==MOBILE)
         SendNotification(symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_1,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
     }


   if(SymbolInfoDouble(symbol,SYMBOL_BID)<=current_high-FIBO_LEVEL_2*price_delta&&alarm_fibo_level_2==false&&ALERT_ACTIVE_FIBO_LEVEL_2==true&&isDownTrend==false)
     {
      alarm_fibo_level_2=true;

      if(ALERT_MODE==E_MAIL_AND_MOBILE)
        {
         SendMail("FIBO MT4 NOTIFICATION",symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_2,1)+" "+" PRICE "+" "+DoubleToStr(SymbolInfoDouble(symbol,SYMBOL_BID),5));

         SendNotification(symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_2,1)+" "+" PRICE "+" "+DoubleToStr(SymbolInfoDouble(symbol,SYMBOL_BID),5));
        }

      if(ALERT_MODE==E_MAIL)
         SendMail("FIBO MT4 NOTIFICATION",symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_2,1)+" "+" PRICE "+" "+DoubleToStr(SymbolInfoDouble(symbol,SYMBOL_BID),5));
      if(ALERT_MODE==MOBILE)
         SendNotification(symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_2,1)+" "+" PRICE "+" "+DoubleToStr(SymbolInfoDouble(symbol,SYMBOL_BID),5));
     }

   if(SymbolInfoDouble(symbol,SYMBOL_BID)<=current_high-FIBO_LEVEL_3*price_delta&&alarm_fibo_level_3==false&&ALERT_ACTIVE_FIBO_LEVEL_3==true&&isDownTrend==false)
     {
      alarm_fibo_level_3=true;

      if(ALERT_MODE==E_MAIL_AND_MOBILE)
        {
         SendMail("FIBO MT4 NOTIFICATION",symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_3,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));

         SendNotification(symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_3,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
        }

      if(ALERT_MODE==E_MAIL)
         SendMail("FIBO MT4 NOTIFICATION",symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_3,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
      if(ALERT_MODE==MOBILE)
         SendNotification(symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_3,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
     }

   if(SymbolInfoDouble(symbol,SYMBOL_BID)<=current_high-FIBO_LEVEL_4*price_delta&&alarm_fibo_level_4==false&&ALERT_ACTIVE_FIBO_LEVEL_4==true&&isDownTrend==false)
     {
      alarm_fibo_level_4=true;

      if(ALERT_MODE==E_MAIL_AND_MOBILE)
        {
         SendMail("FIBO MT4 NOTIFICATION",symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_4,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));

         SendNotification(symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_4,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
        }

      if(ALERT_MODE==E_MAIL)
         SendMail("FIBO MT4 NOTIFICATION",symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_4,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
      if(ALERT_MODE==MOBILE)
         SendNotification(symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_4,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
     }

   if(SymbolInfoDouble(symbol,SYMBOL_BID)<=current_high-FIBO_LEVEL_5*price_delta&&alarm_fibo_level_5==false&&ALERT_ACTIVE_FIBO_LEVEL_5==true&&isDownTrend==false)
     {
      alarm_fibo_level_5=true;

      if(ALERT_MODE==E_MAIL_AND_MOBILE)
        {
         SendMail("FIBO MT4 NOTIFICATION",symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_5,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));

         SendNotification(symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_5,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
        }

      if(ALERT_MODE==E_MAIL)
         SendMail("FIBO MT4 NOTIFICATION",symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_5,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
      if(ALERT_MODE==MOBILE)
         SendNotification(symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_5,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
     }

   if(SymbolInfoDouble(symbol,SYMBOL_BID)<=current_high-FIBO_LEVEL_6*price_delta&&alarm_fibo_level_6==false&&ALERT_ACTIVE_FIBO_LEVEL_6==true&&isDownTrend==false)
     {
      alarm_fibo_level_6=true;

      if(ALERT_MODE==E_MAIL_AND_MOBILE)
        {
         SendMail("FIBO MT4 NOTIFICATION",Symbol()+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_6,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));

         SendNotification(symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_6,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
        }

      if(ALERT_MODE==E_MAIL)
         SendMail("FIBO MT4 NOTIFICATION",symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_6,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
      if(ALERT_MODE == MOBILE)
         SendNotification(symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_6,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
     }


   if(SymbolInfoDouble(symbol,SYMBOL_BID)<=current_high-FIBO_LEVEL_7*price_delta&&alarm_fibo_level_7==false&&ALERT_ACTIVE_FIBO_LEVEL_7==true&&isDownTrend==false)
     {
      alarm_fibo_level_7=true;

      if(ALERT_MODE==E_MAIL_AND_MOBILE)
        {
         SendMail("FIBO MT4 NOTIFICATION",Symbol()+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_7,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));

         SendNotification(symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_7,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
        }

      if(ALERT_MODE==E_MAIL)
         SendMail("FIBO MT4 NOTIFICATION",Symbol()+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_7,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
      if(ALERT_MODE==MOBILE)
         SendNotification(Symbol()+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_7,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
     }



   if(SymbolInfoDouble(symbol,SYMBOL_BID)<=current_high-FIBO_LEVEL_8*price_delta&&alarm_fibo_level_8==false&&ALERT_ACTIVE_FIBO_LEVEL_8==true&&isDownTrend==false)
     {
      alarm_fibo_level_8=true;

      if(ALERT_MODE==E_MAIL_AND_MOBILE)
        {
         SendMail("FIBO MT4 NOTIFICATION",symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_8,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));

         SendNotification(symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_8,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
        }

      if(ALERT_MODE==E_MAIL)
         SendMail("FIBO MT4 NOTIFICATION",Symbol()+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_8,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
      if(ALERT_MODE==MOBILE)
         SendNotification(Symbol()+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_8,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
     }


   if(SymbolInfoDouble(symbol,SYMBOL_BID)<=current_high-FIBO_LEVEL_9*price_delta&&alarm_fibo_level_9==false&&ALERT_ACTIVE_FIBO_LEVEL_9==true&&isDownTrend==false)
     {
      alarm_fibo_level_9=true;

      if(ALERT_MODE==E_MAIL_AND_MOBILE)
        {
         SendMail("FIBO MT4 NOTIFICATION",Symbol()+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_9,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));

         SendNotification(symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_9,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
        }

      if(ALERT_MODE==E_MAIL)
         SendMail("FIBO MT4 NOTIFICATION",symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_9,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
      if(ALERT_MODE==MOBILE)
         SendNotification(symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_9,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
     }


   if(SymbolInfoDouble(symbol,SYMBOL_BID)<=current_high-FIBO_LEVEL_10*price_delta&&alarm_fibo_level_10==false&&ALERT_ACTIVE_FIBO_LEVEL_10==true&&isDownTrend==false)
     {
      alarm_fibo_level_10=true;

      if(ALERT_MODE==E_MAIL_AND_MOBILE)
        {
         SendMail("FIBO MT4 NOTIFICATION",symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_10,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));

         SendNotification(symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_10,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
        }

      if(ALERT_MODE==E_MAIL)
         SendMail("FIBO MT4 NOTIFICATION",symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_10,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
      if(ALERT_MODE==MOBILE)
         SendNotification(symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_10,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
     }


//__________________________________________________________________________________________________________________________________________________
//
// FIBO MESSAGES ON LEVEL CROSSING DOWN
//__________________________________________________________________________________________________________________________________________________
//

   if(SymbolInfoDouble(symbol,SYMBOL_BID)>=current_low+FIBO_LEVEL_1*price_delta&&alarm_fibo_level_1==false&&ALERT_ACTIVE_FIBO_LEVEL_1==true&&isDownTrend==true)
     {
      alarm_fibo_level_1=true;

      if(ALERT_MODE==E_MAIL_AND_MOBILE)
        {
         SendMail("FIBO MT4 NOTIFICATION",symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_1,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));

         SendNotification(symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_1,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
        }

      if(ALERT_MODE==E_MAIL)
         SendMail("FIBO MT4 NOTIFICATION",Symbol()+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_1,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
      if(ALERT_MODE==MOBILE)
         SendNotification(Symbol()+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_1,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
     }


   if(SymbolInfoDouble(symbol,SYMBOL_BID)>=current_low+FIBO_LEVEL_2*price_delta&&alarm_fibo_level_2==false&&ALERT_ACTIVE_FIBO_LEVEL_2==true&&isDownTrend==true)
     {
      alarm_fibo_level_2=true;

      if(ALERT_MODE==E_MAIL_AND_MOBILE)
        {
         SendMail("FIBO MT4 NOTIFICATION",Symbol()+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_2,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));

         SendNotification(Symbol()+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_2,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
        }

      if(ALERT_MODE==E_MAIL)
         SendMail("FIBO MT4 NOTIFICATION",Symbol()+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_2,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
      if(ALERT_MODE==MOBILE)
         SendNotification(Symbol()+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_2,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
     }


   if(SymbolInfoDouble(symbol,SYMBOL_BID)>=current_low+FIBO_LEVEL_3*price_delta&&alarm_fibo_level_3==false&&ALERT_ACTIVE_FIBO_LEVEL_3==true&&isDownTrend==true)
     {
      alarm_fibo_level_3=true;

      if(ALERT_MODE==E_MAIL_AND_MOBILE)
        {
         SendMail("FIBO MT4 NOTIFICATION",symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_3,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));

         SendNotification(Symbol()+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_3,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
        }

      if(ALERT_MODE==E_MAIL)
         SendMail("FIBO MT4 NOTIFICATION",Symbol()+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_3,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
      if(ALERT_MODE==MOBILE)
         SendNotification(Symbol()+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_3,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
     }

   if(SymbolInfoDouble(symbol,SYMBOL_BID)>=current_low+FIBO_LEVEL_4*price_delta&&alarm_fibo_level_4==false&&ALERT_ACTIVE_FIBO_LEVEL_4==true&&isDownTrend==true)
     {
      alarm_fibo_level_4=true;

      if(ALERT_MODE==E_MAIL_AND_MOBILE)
        {
         SendMail("FIBO MT4 NOTIFICATION",Symbol()+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_4,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));

         SendNotification(Symbol()+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_4,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
        }

      if(ALERT_MODE==E_MAIL)
         SendMail("FIBO MT4 NOTIFICATION",Symbol()+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_4,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
      if(ALERT_MODE==MOBILE)
         SendNotification(Symbol()+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_4,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
     }



   if(SymbolInfoDouble(symbol,SYMBOL_BID)>=current_low+FIBO_LEVEL_5*price_delta&&alarm_fibo_level_5==false&&ALERT_ACTIVE_FIBO_LEVEL_5==true&&isDownTrend==true)
     {
      alarm_fibo_level_5=true;

      if(ALERT_MODE==E_MAIL_AND_MOBILE)
        {
         SendMail("FIBO MT4 NOTIFICATION",Symbol()+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_5,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));

         SendNotification(symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_5,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
        }

      if(ALERT_MODE==E_MAIL)
         SendMail("FIBO MT4 NOTIFICATION",symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_5,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
      if(ALERT_MODE==MOBILE)
         SendNotification(symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_5,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
     }


   if(SymbolInfoDouble(symbol,SYMBOL_BID)>=current_low+FIBO_LEVEL_6*price_delta&&alarm_fibo_level_6==false&&ALERT_ACTIVE_FIBO_LEVEL_6==true&&isDownTrend==true)
     {
      alarm_fibo_level_6=true;

      if(ALERT_MODE==E_MAIL_AND_MOBILE)
        {
         SendMail("FIBO MT4 NOTIFICATION",symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_6,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));

         SendNotification(Symbol()+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_6,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
        }

      if(ALERT_MODE==E_MAIL)
         SendMail("FIBO MT4 NOTIFICATION",symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_6,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
      if(ALERT_MODE==MOBILE)
         SendNotification(symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_6,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
     }


   if(SymbolInfoDouble(symbol,SYMBOL_BID)>=current_low+FIBO_LEVEL_7*price_delta&&alarm_fibo_level_7==false&&ALERT_ACTIVE_FIBO_LEVEL_7==true&&isDownTrend==true)
     {
      alarm_fibo_level_7=true;

      if(ALERT_MODE==E_MAIL_AND_MOBILE)
        {
         SendMail("FIBO MT4 NOTIFICATION",symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_7,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));

         SendNotification(Symbol()+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_7,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
        }

      if(ALERT_MODE==E_MAIL)
         SendMail("FIBO MT4 NOTIFICATION",symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_7,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
      if(ALERT_MODE==MOBILE)
         SendNotification(symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_7,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
     }




   if(SymbolInfoDouble(symbol,SYMBOL_BID)>=current_low+FIBO_LEVEL_8*price_delta&&alarm_fibo_level_8==false&&ALERT_ACTIVE_FIBO_LEVEL_8==true&&isDownTrend==true)
     {
      alarm_fibo_level_8=true;

      if(ALERT_MODE==E_MAIL_AND_MOBILE)
        {
         SendMail("FIBO MT4 NOTIFICATION",Symbol()+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_8,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));

         SendNotification(Symbol()+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_8,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
        }

      if(ALERT_MODE==E_MAIL)
         SendMail("FIBO MT4 NOTIFICATION",Symbol()+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_8,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
      if(ALERT_MODE==MOBILE)
         SendNotification(Symbol()+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_8,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
     }


   if(SymbolInfoDouble(symbol,SYMBOL_BID)>=current_low+FIBO_LEVEL_9*price_delta&&alarm_fibo_level_9==false&&ALERT_ACTIVE_FIBO_LEVEL_9==true&&isDownTrend==true)
     {
      alarm_fibo_level_9=true;

      if(ALERT_MODE==E_MAIL_AND_MOBILE)
        {
         SendMail("FIBO MT4 NOTIFICATION",symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_9,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));

         SendNotification(symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_9,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
        }

      if(ALERT_MODE ==E_MAIL)
         SendMail("FIBO MT4 NOTIFICATION",symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_9,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
      if(ALERT_MODE == MOBILE)
         SendNotification(Symbol()+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_9,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
     }


   if(SymbolInfoDouble(symbol,SYMBOL_BID)>=current_low+FIBO_LEVEL_10*price_delta&&alarm_fibo_level_10==false&&ALERT_ACTIVE_FIBO_LEVEL_10==true&&isDownTrend==true)
     {
      alarm_fibo_level_10=true;

      if(ALERT_MODE == E_MAIL_AND_MOBILE)
        {
         SendMail("FIBO MT4 NOTIFICATION",Symbol()+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_10,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));

         SendNotification(symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_10,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
        }

      if(ALERT_MODE==E_MAIL)
         SendMail("FIBO MT4 NOTIFICATION",Symbol()+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_10,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
      if(ALERT_MODE==MOBILE)
         SendNotification(symbol+" "+TimeToString(TimeCurrent())+" "+"CROSSING FIBO LEVEL "+" "+DoubleToString(100*FIBO_LEVEL_10,1)+" "+" PRICE "+" "+DoubleToStr(Bid,5));
     }


  }
STRUCT_SYMBOL_SIGNAL symbolSignal;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double TrendlinePriceUpper(int shift) //returns current price on the highest horizontal line or trendline found in the chart
  {
   int obj_total = ObjectsTotal(); double price=0;
   double maxprice = -1;
   for(int i = obj_total - 1; i >= 0; i--)
     {
      string name = ObjectName(i);
      
      if(ObjectType(name) == OBJ_HLINE && StringFind(name, "#", 0) < 0
         && (price = ObjectGet(name, OBJPROP_PRICE1)) > maxprice
         && price > 0)
         maxprice = price;
      else
         if(ObjectType(name) == OBJ_TREND && StringFind(name, "#", 0) < 0
            && (price = ObjectGetValueByShift(name, shift)) > maxprice
            && price > 0)
            maxprice = price;
     }
   return(maxprice); //not found => -1
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double TrendlinePriceLower(int shift) //returns current price on the lowest horizontal line or trendline found in the chart
  {
  double price=0;
   int obj_total = ObjectsTotal();
   double minprice = MathPow(10, 308);
   for(int i = obj_total - 1; i >= 0; i--)
     {
      string name = ObjectName(i);

      if(ObjectType(name) == OBJ_HLINE && StringFind(name, "#", 0) < 0
         && (price = ObjectGet(name, OBJPROP_PRICE1)) < minprice
         && price > 0)
         minprice = price;
      else
         if(ObjectType(name) == OBJ_TREND && StringFind(name, "#", 0) < 0
            && (price = ObjectGetValueByShift(name, shift)) < minprice
            && price > 0)
            minprice = price;
     }
   if(minprice > MathPow(10, 307))
      minprice = -1; //not found => -1
   return(minprice);
  }








//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawFiboSimpleSell(string fiboName,datetime firstTime,double firstPrice,datetime secondTime,double secondPrice)
  {
   int HighestCandle=iHighest(Symbol(),Period(),MODE_OPEN,30,0);
   int LowestCandle=iLowest(Symbol(),Period(),MODE_CLOSE,1,0);

   ObjectDelete("TS261FiboBuy");
   ObjectDelete("TS261FiboSell");


   ObjectCreate(fiboName,OBJ_FIBO,0,Time[0],Low[LowestCandle],Time[30],High[HighestCandle]);
   ObjectSet(fiboName,OBJPROP_COLOR,Red);
   ObjectSet(fiboName,OBJPROP_BACK,true);
   ObjectSet(fiboName,OBJPROP_WIDTH,3);
   ObjectSet(fiboName,OBJPROP_FIBOLEVELS,25);
   ObjectSet(fiboName,OBJPROP_LEVELCOLOR,Red);
   ObjectSet(fiboName,OBJPROP_LEVELWIDTH,3);
//---

   ObjectSet(fiboName,OBJPROP_FIRSTLEVEL+0,-3.236);
   ObjectSetFiboDescription(fiboName,0,"SL 3= %$");
   ObjectSet(fiboName,OBJPROP_FIRSTLEVEL+1,-1.618);
   ObjectSetFiboDescription(fiboName,1,"SL 2= %$");
   ObjectSet(fiboName,OBJPROP_FIRSTLEVEL+2,-0.618);
   ObjectSetFiboDescription(fiboName,2,"SL 1= %$");
   ObjectSet(fiboName,OBJPROP_FIRSTLEVEL+3,0.000);
   ObjectSetFiboDescription(fiboName,3,"Highest Shadow= %$");
   ObjectSet(fiboName,OBJPROP_FIRSTLEVEL+4,1.000);
   ObjectSetFiboDescription(fiboName,4,"Entry= %$");
   ObjectSet(fiboName,OBJPROP_FIRSTLEVEL+5,1.618);
   ObjectSetFiboDescription(fiboName,5,"TP 1= %$");
   ObjectSet(fiboName,OBJPROP_FIRSTLEVEL+6,2.618);
   ObjectSetFiboDescription(fiboName,6,"TP 2= %$");
   ObjectSet(fiboName,OBJPROP_FIRSTLEVEL+7,4.236);
   ObjectSetFiboDescription(fiboName,7,"TP 3= %$");
//----
   ObjectSet(fiboName,OBJPROP_RAY,false);
   ObjectSet(fiboName,OBJPROP_RAY_RIGHT,false);



  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string AccountMode() // function: to known account trade mode
  {
//----
//--- Demo, Contest or Real account
   ENUM_ACCOUNT_TRADE_MODE account_type=(ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE);
//---
   string trade_mode;
//--
   switch(account_type)
     {
      case  ACCOUNT_TRADE_MODE_DEMO:
         trade_mode="Demo";
         break;
      case  ACCOUNT_TRADE_MODE_CONTEST:
         trade_mode="Contest";
         break;
      default:
         trade_mode="Real";
         break;
     }
//--
   return(trade_mode);
//----
  } //-end AccountMode()
//---------//

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void RemoveAllObjects()
  {
   for(int i = ObjectsTotal() - 1; i >= 0; i--)
     {
      if(StringFind(ObjectName(i),"EA-",0) > -1)
         ObjectDelete(ObjectName(i));
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void RESET_ALARMS()
  {
//fibo alarm
   alarm_fibo_level_1=false;
   alarm_fibo_level_2=false;
   alarm_fibo_level_3=false;
   alarm_fibo_level_4=false;
   alarm_fibo_level_5=false;
   alarm_fibo_level_6=false;
   alarm_fibo_level_7=false;
   alarm_fibo_level_8=false;
   alarm_fibo_level_9=false;
   alarm_fibo_level_10=false;
  }



//+------------------------------------------------------------------+
//|              AutoTrade                                                    |
//+------------------------------------------------------------------+
bool AutoTrade()
  {
   if(inpTradeMode ==AutoTrade)
     {
      return true;
     };

   return false ;
  }


//+------------------------------------------------------------------+
//|                         LongTradingts261H1                                          |
//+------------------------------------------------------------------+
bool LongTradingts261H1=false;
bool   ShortTradingts261H1=true;
bool LongTradingts261M30=false;
bool   ShortTradingts261M30=true;
bool LongTradingts261M15=false;
bool   ShortTradingts261M15=true;

//+------------------------------------------------------------------+
//|                 HedgeTrade                                                 |
//+------------------------------------------------------------------+
bool HedgeTrade()
  {
   if(!Hedging)
      return false;


   return true;
  }
//+------------------------------------------------------------------+
//|                  CheckStochts261m5                                          |
//+------------------------------------------------------------------+
bool CheckStochts261m5(string symbols)
  {
   double ts261m5;
   double OverSold;
   double OverBought;

   for(int i=1; i>=0; i--)
     {
      ts261m5=iCustom(symbols,Period(),"1mfsto",5,5,5,3,i);
      OverSold=-45;
      OverBought=45;

      if(bar!=Bars)

        {

         if(ts261m5<OverSold)
           {
            LongTradingts261M5=true;
            ShortTradingts261M5=false;
           }
         if(ts261m5>OverBought)

           {
            LongTradingts261M5=false;
            ShortTradingts261M5=true;
           }
        }
     }

   return(false);
  }
//+------------------------------------------------------------------+
//|                     CheckStochts261m15                                              |
//+------------------------------------------------------------------+
bool CheckStochts261m15(string symbols)
  {
   double ts261m15;
   double OverSold;
   double OverBought;
   for(int i=0; i<NumOfSymbols; i++)
     {
      ts261m15=iCustom(symbols,Period(),"1mfsto",15,15,15,3,i);
      OverSold=-45;
      OverBought=45;

      if(bar!=Bars)
        {
         if(ts261m15<OverSold)
           {
            LongTradingts261M15=true;
            ShortTradingts261M15=false;
           }
         if(ts261m15>OverBought)

           {
            LongTradingts261M15=false;
            ShortTradingts261M15=true;
           }
        }
     }
   return(false);
  }
//+------------------------------------------------------------------+
//|                     CheckStochts261m30                                             |
//+------------------------------------------------------------------+
string overboversellSymbol[2]= {};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckStochts261m30(string symbol1)
  {


   double ts261m30=0;
   double OverSold=0;
   double OverBought=0;
   for(int i=0; i<NumOfSymbols; i++)
     {
      ts261m30=iCustom(symbol1,InpTimFrame,"1mfsto",30,30,30,3,i);
      OverSold=-45;
      OverBought=45;
      overboversellSymbol[0]=symbol1;
      if(bar!=Bars)
        {
         if(ts261m30<OverSold)
           {
            LongTradingts261M30=true;
            ShortTradingts261M30=false;
           }
         if(ts261m30>OverBought)

           {
            LongTradingts261M30=false;
            ShortTradingts261M30=true;
           }
        }
     }
   return(false);
  }
  void TradeReport(string symbol, bool tradereportdates=false)
  {
   if(tradereportdates)
     {
      double totalprofit[],totalloss[],op_price[],cl_price[];
      string symbols[];
      long orderID=0;
      double winratio[];


      for(int jkl=OrdersHistoryTotal()-1;jkl>0;jkl--)
        {


         ArrayResize(symbols,OrdersHistoryTotal(),0);
         ArrayResize(totalloss,OrdersHistoryTotal(),0);
         ArrayResize(winratio,OrdersHistoryTotal(),0);

         ArrayResize(totalprofit,OrdersHistoryTotal(),0);
         ArrayResize(op_price,OrdersHistoryTotal(),0);
         ArrayResize(cl_price,OrdersHistoryTotal(),0);

         if(tradereportdates)
           {
            if(OrderSelect(jkl,SELECT_BY_POS,MODE_HISTORY)==true &&symbol==OrderSymbol())
              {

               symbols[jkl]+=OrderSymbol();
               op_price[jkl]+=OrderOpenPrice();
               cl_price[jkl]+=OrderClosePrice();

               if(OrderProfit()<=0)
                 {
                  totalloss[jkl]+=OrderProfit();
                 }


               if(OrderProfit()>0)
                 {
                  totalprofit[jkl]+=OrderProfit();
                 }

               winratio[jkl]+=(totalloss[jkl]/(1+totalprofit[jkl]));



               bool file=FileOpen(InpDirectoryName+"\\"+"TradeReport.csv",FILE_READ|FILE_WRITE|FILE_CSV|InpEncodingType);

               if(!file)
                 {
                  printf((string)ERR_FILE_CANNOT_OPEN+InpFileName);
                 }



               FileSeek(file,offset,SEEK_SET);
               bool write=FileWrite(file,"\n"+(string)TimeCurrent() +"    "+symbols[jkl]+"     "+(string)op_price[jkl]+"     "+(string)cl_price[jkl]+"      "+(string)totalloss[jkl]+"      "+(string)totalprofit[jkl]+"      "+(string)winratio[jkl]+"\n");

               if(!write)
                  printf("Unable to write data in "+ "TradeReport.csv");

               FileClose(file);

              }

           }


        }

    }}
  
//+------------------------------------------------------------------+
//| SpeedOmeter                                                      |
//+------------------------------------------------------------------+
void SpeedOmeter(string _Symb)
  {
//--- CalcSpeed
   double Pts = SymbolInfoDouble(_Symb, SYMBOL_POINT),
          LastPrice = 0,
          CurrentPrice = 0;

//---
   if(Pts != 0)
     {
      //---
      LastPrice = GlobalVariableGet(OBJPREFIX+_Symb+" - Price")/Pts;
      //---
      CurrentPrice = ((SymbolInfoDouble(_Symb, SYMBOL_ASK)+SymbolInfoDouble(_Symb, SYMBOL_BID))/2)/Pts;
     }

//---
   double Speed = NormalizeDouble((CurrentPrice-LastPrice), 0);

//---
   GlobalVariableSet(OBJPREFIX+_Symb+" - Price", (SymbolInfoDouble(_Symb, SYMBOL_ASK)+SymbolInfoDouble(_Symb, SYMBOL_BID))/2);

//--- SetMaxSpeed
   if(Speed > 99)
      Speed = 99;



//--- ResetColors
   if(showfibo)
     {
      //---
      for(int i = 0; i < (10); i++)
        {
         //--- SetObjects
         if(ObjectFind(0, OBJPREFIX+"SPEED#"+" - "+_Symb+IntegerToString(i, 0, 0)) == 0)
            ObjectSetInteger(0, OBJPREFIX+"SPEED#"+" - "+_Symb+IntegerToString(i, 0, 0), OBJPROP_COLOR, clrNONE);
         //---
         if(ObjectFind(0, OBJPREFIX+"SPEEDª"+" - "+_Symb) == 0)
            ObjectSetInteger(0, OBJPREFIX+"SPEEDª"+" - "+_Symb, OBJPROP_COLOR, clrNONE);
        }
      //--- SetColor&Text
      for(int i = 0; i < MathAbs(Speed); i++)
        {
         //--- PositiveValue
         if(Speed > 0)
           {
            //--- SetObjects
            if(ObjectFind(0, OBJPREFIX+"SPEED#"+" - "+_Symb+IntegerToString(i, 0, 0)) == 0)
               ObjectSetInteger(0, OBJPREFIX+"SPEED#"+" - "+_Symb+IntegerToString(i, 0, 0), OBJPROP_COLOR, clrGreen);
            //---
            if(ObjectFind(0, OBJPREFIX+"SPEEDª"+" - "+_Symb) == 0)
               ObjectSetInteger(0, OBJPREFIX+"SPEEDª"+" - "+_Symb, OBJPROP_COLOR,clrGreen);
           }
         //--- NegativeValue
         if(Speed < 0)
           {
            //--- SetObjects
            if(ObjectFind(0, OBJPREFIX+"SPEED#"+" - "+_Symb+IntegerToString(i, 0, 0)) == 0)
               ObjectSetInteger(0, OBJPREFIX+"SPEED#"+" - "+_Symb+IntegerToString(i, 0, 0), OBJPROP_COLOR, clrRed);
            //---
            if(ObjectFind(0, OBJPREFIX+"SPEEDª"+" - "+_Symb) == 0)
               ObjectSetInteger(0, OBJPREFIX+"SPEEDª"+" - "+_Symb, OBJPROP_COLOR, clrRed);
           }
         //---
         if(ObjectFind(0, OBJPREFIX+"SPEEDª"+" - "+_Symb) == 0)
            ObjectSetString(0, OBJPREFIX+"SPEEDª"+" - "+_Symb, OBJPROP_TEXT, 0, ±Str(Speed, 0)); //SetObject
        }
     }
//---
  }

string ±Str(double Inp, int Precision)
  {
//--- PositiveValue
   if(Inp > 0)
      return("+"+DoubleToString(Inp, Precision));
//--- NegativeValue
   else
      return(DoubleToString(Inp, Precision));
//---
  }
  
  
//+------------------------------------------------------------------+
//|                      CheckStochts261h1                                            |
//+------------------------------------------------------------------+
bool CheckStochts261h1(string sym)
  {
  string symbol=sym;

   double ts261h1;
   double OverSold;
   double OverBought;

   for(int i=0; i<NumOfSymbols; i++)
     {

      ts261h1=iCustom(symbol,Period(),"1mfsto",60,60,60,3,i);
      OverSold=-45;
      OverBought=45;

      if(bar!=Bars)
        {
         if(ts261h1<OverSold)
           {
            LongTradingts261H1=true;
            ShortTradingts261H1=false;
            overboversellSymbol[0]=symbol;
           }
         if(ts261h1>OverBought)

           {
            overboversellSymbol[0]=symbol;
            LongTradingts261H1=false;
            ShortTradingts261H1=true;
           }
        }
     }
   return(false);
  }
//+------------------------------------------------------------------+
//|                       CheckRSIts261m5                                           |
//+------------------------------------------------------------------+
bool CheckRSIts261m5()
  {
   double ts261m5high;
   double ts261m5low;
   double OverSold;
   double OverBought;

   for(int i=0; i<NumOfSymbols; i++)
     {
      ts261m5high=iCustom(TradeScheduleSymbol(i,InpSelectPairs_By_Basket_Schedule),Period(),"MTF_RSI",9,2,1,i);
      ts261m5low=iCustom(TradeScheduleSymbol(i,InpSelectPairs_By_Basket_Schedule),Period(),"MTF_RSI",9,3,1,i);
      OverSold=20;
      OverBought=80;

      if(bar!=Bars)

        {

         if(ts261m5low<OverSold)
           {
            LongTradingts261M5=true;
            ShortTradingts261M5=false;
           }
         if(ts261m5high>OverBought)

           {
            LongTradingts261M5=false;
            ShortTradingts261M5=true;
           }
        }
     }
   return(false);
  }

bool  LongTradingts261M5=false;
bool  ShortTradingts261M5=true;
//+------------------------------------------------------------------+
//|                       CheckRSIts261m15                                           |
//+------------------------------------------------------------------+
bool CheckRSIts261m15()
  {
   double ts261m15high;
   double ts261m15low;
   double OverSold;
   double OverBought;
   for(int i=0; i<=NumOfSymbols; i++)
     {
      ts261m15high=iCustom(TradeScheduleSymbol(i,InpSelectPairs_By_Basket_Schedule),Period(),"MTF_RSI",9,2,2,i);
      ts261m15low=iCustom(TradeScheduleSymbol(i,InpSelectPairs_By_Basket_Schedule),Period(),"MTF_RSI",9,3,2,i);
      OverSold=20;
      OverBought=80;

      if(bar!=Bars)
        {
         if(ts261m15low<OverSold)
           {
            LongTradingts261M15=true;
            ShortTradingts261M15=false;
           }
         if(ts261m15high>OverBought)

           {
            LongTradingts261M15=false;
            ShortTradingts261M15=true;
           }
        }
     }
   return(false);
  }
//+------------------------------------------------------------------------------+
//| ChartEventMouseMoveSet                                                       |
//+------------------------------------------------------------------------------+
bool ChartEventMouseMoveSet(const bool value)
  {
//-- reset the error value
   ResetLastError();
//--
   if(!ChartSetInteger(0,CHART_EVENT_MOUSE_MOVE,IndicatorSubWindow,value))
     {
      Print(__FUNCTION__,
            ", Error Code = ",_LastError);
      return(false);
     }
//--
   return(true);
  }


   




//+------------------------------------------------------------------+
//|                           ReleaseOtherButtons                                        |
//+------------------------------------------------------------------+
void ReleaseOtherButtons(const long index)
  {
   for(int s=0; s<NumOfSymbols; s++)
     {
      if(s != index)
        {
         string name = "SGGS"+IntegerToString(s);
         ObjectSetInteger(ChartID(),name,OBJPROP_BGCOLOR,clrRed);
         ObjectSetInteger(ChartID(),name,OBJPROP_STATE,false);
        }
     }
  }

//+------------------------------------------------------------------+
//|                            GetManualSignalIndex                                      |
//+------------------------------------------------------------------+
int GetManualSignalIndex()
  {
   bool found = false;
   int index = -1;
   int size = ArraySize(ManualSignals);
   for(int i=0; i<size; i++)
     {
      if(ManualSignals[i].done)
        {
         index = i;
         break;
        }
     }
   if(index < 0)
     {
      ArrayResize(ManualSignals,size+1);
      index = size;
     }
   return index;
  }

//+------------------------------------------------------------------+
//| Create the arrow                                                 |
//+------------------------------------------------------------------+
bool ArrowCreate(const long              chart_ID=0,           // chart's ID
                 const string            name="Arrow",         // arrow name
                 const int               sub_window=0,         // subwindow index
                 datetime                time=0,               // anchor point time
                 double                  price=0,              // anchor point price
                 const uchar             arrow_code=252,       // arrow code
                 const ENUM_ANCHOR_POINT anchors=ANCHOR_CENTER, // anchor point position
                 const color             clr=clrRed,           // arrow color
                 const ENUM_LINE_STYLE   style=STYLE_SOLID,    // border line style
                 const int               width=1,              // arrow size
                 const bool              back=true,           // in the background
                 const bool              selection=false,       // highlight to move
                 const bool              hidden=true,          // hidden in the object list
                 const long              z_order=0)            // priority for mouse click
  {
 
//--- set anchor point coordinates if they are not set
   ChangeArrowEmptyPoint(time,price);
//--- reset the error value
   ResetLastError();
//--- create an arrow
   if(!ObjectCreate(chart_ID,name,OBJ_ARROW,sub_window,time1x,price))
     {
      Print(__FUNCTION__,
            ": failed to create an arrow! Error code = ",GetLastError());
      return(false);
     }
//--- set the arrow code
   ObjectSetInteger(chart_ID,name,OBJPROP_ARROWCODE,arrow_code);
//--- set anchor type
   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchors);
//--- set the arrow color
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- set the border line style
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- set the arrow's size
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the arrow by mouse
//--- when creating a graphical object using ObjectCreate function, the object cannot be
//--- highlighted and moved by default. Inside this method, selection parameter
//--- is true by default making it possible to highlight and move the object
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Move the anchor point                                            |
//+------------------------------------------------------------------+
bool ArrowMove(const long   chart_ID=0,   // chart's ID
               const string name="Arrow", // object name
               datetime     time=0,       // anchor point time coordinate
               double       price0=0)      // anchor point price coordinate
  {
//--- if point position is not set, move it to the current bar having Bid price
   if(!time)
      time=mydate;
   if(!price0)
      price0=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- reset the error value
   ResetLastError();
//--- move the anchor point
   if(!ObjectMove(chart_ID,name,0,time,price0))
     {
      Print(__FUNCTION__,
            ": failed to move the anchor point! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Change the arrow code                                            |
//+------------------------------------------------------------------+
bool ArrowCodeChange(const long   chart_ID=0,   // chart's ID
                     const string name="Arrow", // object name
                     const uchar  code=252)     // arrow code
  {
//--- reset the error value
   ResetLastError();
//--- change the arrow code
   if(!ObjectSetInteger(chart_ID,name,OBJPROP_ARROWCODE,code))
     {
      Print(__FUNCTION__,
            ": failed to change the arrow code! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Change anchor type                                               |
//+------------------------------------------------------------------+
bool ArrowAnchorChange(const long              chart_ID=0,        // chart's ID
                       const string            name="Arrow",      // object name
                       const ENUM_ARROW_ANCHOR anchors=ANCHOR_TOP) // anchor type
  {
//--- reset the error value
   ResetLastError();
//--- change anchor type
   if(!ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchors))
     {
      Print(__FUNCTION__,
            ": failed to change anchor type! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Delete an arrow                                                  |
//+------------------------------------------------------------------+
bool ArrowDelete(const long   chart_ID=0,   // chart's ID
                 const string name="Arrow") // arrow name
  {
//--- reset the error value
   ResetLastError();
//--- delete an arrow
   if(!ObjectDelete(chart_ID,name))
     {
      Print(__FUNCTION__,
            ": failed to delete an arrow! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Check anchor point values and set default values                 |
//| for empty ones                                                   |
//+------------------------------------------------------------------+
void ChangeArrowEmptyPoint(datetime time2,double &prices)
  {
   
//--- if the point's time is not set, it will be on the current bar
   if(!time2)
      time2=mydate;
//--- if the point's price is not set, it will have Bid value
   if(!prices)
      prices=SymbolInfoDouble(Symbol(),SYMBOL_BID);
  }

//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                       CheckRSIts261m30                                            |
//+------------------------------------------------------------------+
bool CheckRSIts261m30(string symbol)
  {
   double ts261m30high;
   double ts261m30low;
   double OverSold;
   double OverBought;
   for(int i=0; i<NumOfSymbols; i++)
     {
      ts261m30high=iCustom(symbol,Period(),"MTF_RSI",9,2,3,i);
      ts261m30low=iCustom(symbol,Period(),"MTF_RSI",9,3,3,i);
      OverSold=20;
      OverBought=80;

      if(bar!=Bars)
        {
         if(ts261m30low<OverSold)
           {
            LongTradingts261M30=true;
            ShortTradingts261M30=false;
           }
         if(ts261m30high>OverBought)

           {
            LongTradingts261M30=false;
            ShortTradingts261M30=true;
           }
        }
     }
   return(false);
  }
//+------------------------------------------------------------------+
//|                         CheckRSIts261h1                                          |
//+------------------------------------------------------------------+
bool CheckRSIts261h1()
  {
   double ts261h1high;
   double ts261h1low;
   double OverSold;
   double OverBought;

   for(int i=0; i<=0; i++)
     {

      ts261h1high=iCustom(TradeScheduleSymbol(i,InpSelectPairs_By_Basket_Schedule),Period(),"MTF_RSI",9,2,4,i);
      ts261h1low=iCustom(TradeScheduleSymbol(i,InpSelectPairs_By_Basket_Schedule),Period(),"MTF_RSI",9,3,4,i);
      OverSold=20;
      OverBought=80;

      if(bar!=Bars)
        {
         if(ts261h1low<OverSold)
           {
            LongTradingts261H1=true;
            ShortTradingts261H1=false;
           }
         if(ts261h1high>OverBought)

           {
            LongTradingts261H1=false;
            ShortTradingts261H1=true;
           }
        }
     }
   return(false);
  }


//+------------------------------------------------------------------+
//|                          getRates                                        |
//+------------------------------------------------------------------+
double getRates(string selection, string symbols)   //v for digits m for point b for bid a for ask rates
  {             
  int digits=(int)MarketInfo(symbols,MODE_DIGITS);
 int point=(int)MarketInfo(symbols,MODE_POINT);
   tick.ask=MarketInfo(symbols,MODE_ASK);
   
   tick.bid=MarketInfo(symbols,MODE_BID);
  
   


  
   if(selection=="v111")
      return MarketInfo(symbols,MODE_DIGITS);

   else
      if(selection=="p111")
         return NormalizeDouble(MarketInfo(symbols,MODE_POINT),digits);
      else

         if(selection=="b111")
            return  SymbolInfoDouble(symbols,SYMBOL_BID);
         else
            if(selection=="a111")
               return SymbolInfoDouble(symbols,SYMBOL_ASK);

            else
               return 0;

  };




//+------------------------------------------------------------------+
//|                  CopyRightlogo                                                |
//+------------------------------------------------------------------+
void CopyRightlogo()
  {

   ObjectCreate(ChartID(),"logo",OBJ_BITMAP_LABEL,0,Time[0],Ask);
   ObjectSetString(ChartID(),"logo",OBJPROP_BMPFILE,"Images");
   ObjectSetInteger(ChartID(),"logo",OBJPROP_CORNER,CORNER_LEFT_LOWER);
   ObjectSetInteger(ChartID(),"logo",OBJPROP_ANCHOR,CORNER_LEFT_LOWER);
   ObjectSetInteger(ChartID(),"logo",OBJPROP_BACK,true);
   ObjectSetInteger(ChartID(),"logo",OBJPROP_XDISTANCE,40);
   ObjectSetInteger(ChartID(),"logo",OBJPROP_YDISTANCE,0);


  }
  
  
  

//+------------------------------------------------------------------+
//|                   ButtonCreate                                               |
//+------------------------------------------------------------------+
void ButtonCreate(string nm,int ys,color cl)
  {
   ObjectCreate(0,nm,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,nm,OBJPROP_XSIZE,110);
   ObjectSetInteger(0,nm,OBJPROP_YSIZE,30);
   ObjectSetInteger(0,nm,OBJPROP_BORDER_COLOR,clrSilver);
   ObjectSetInteger(0,nm,OBJPROP_XDISTANCE,ys);
   ObjectSetInteger(0,nm,OBJPROP_YDISTANCE,35);
   ObjectSetString(0,nm,OBJPROP_TEXT,nm);
   ObjectSetInteger(0,nm,OBJPROP_CORNER,2);
   ObjectSetInteger(0,nm,OBJPROP_BGCOLOR,cl);
   ObjectSetString(0,nm,OBJPROP_FONT,"Arial Bold");
   ObjectSetInteger(0,nm,OBJPROP_FONTSIZE,9);
   ObjectSetInteger(0,nm,OBJPROP_COLOR,White);
   ObjectSetInteger(0,nm,OBJPROP_BACK, false);
  }
//+------------------------------------------------------------------+
//|                            signalMessage                                       |
//+------------------------------------------------------------------+

void  signalMessage(ENUM_ORDER_TYPE type,int symbolIndex,string sym) //signalmessage return only signal message for channels or chats
  {
  
  
    int i=symbolIndex;
    string symbol=sym;
//avoid multiple messages within 10000 milsec
   bool check=true,trad1=true;
    if(type==ORDER_TYPE_SELL_LIMIT)
     {

      mytrade="tradePic";
      int count=0;        
                         tradeReason=StringFormat("\nSELL LIMIT  SIGNALS MATCHED: %s\n Date :%s \nSymbol:%s\n Stoploss %2.4f  \nTakeprofit %2.4f \n______Reasons_________\n%s\n,%s,\nTF1:%s ,\nShift1:%d,\nsignal1:%s, \n%s,\nTF2:%s,\nShift2:%d,\nsigna2:%s, \n%s,\nTF3:%s,\nShift3:%d ,\nsignal3:%s, \n%s,\nTF4:%s,\nShift4:%d,\n%s \n",
                                        "\xF4E3", (string)TimeCurrent(),symbol, iLow(symbol,PERIOD_CURRENT,0),iHigh(symbol,PERIOD_CURRENT,0),"__",
                                                           (string)Signal0(symbol),EnumToString(inpTF0),inpShift0, (string)Signal0(symbol),
                                         (string)Signal1(symbol),EnumToString(inpTF1),inpShift1,(string)Signal1(symbol),
                                (string)Signal2(symbol),EnumToString(inpTF2),inpShift2,(string)Signal2(symbol)
                               ,  (string)Signal3(symbol),EnumToString(inpTF3),inpShift3,(string)Signal3(symbol),"-----------------"
                                
                                       );
      check=false;

     }
   else
        if(type==ORDER_TYPE_BUY_LIMIT)
        {
         check=false;

                         tradeReason=StringFormat("\n BUYLIMT SIGNALS MATCHED: %s\n Date :%s \nSymbol:%s\n Stoploss %2.4f  \nTakeprofit %2.4f \n______Reasons_________\n%s\n,%s,\nTF1:%s ,\nShift1:%d,\nsignal1:%s, \n%s,\nTF2:%s,\nShift2:%d,\nsigna2:%s, \n%s,\nTF3:%s,\nShift3:%d ,\nsignal3:%s, \n%s,\nTF4:%s,\nShift4:%d,\n%s \n",
                                        "\xF4E3", (string)TimeCurrent(),symbol, iLow(symbol,PERIOD_CURRENT,0),iHigh(symbol,PERIOD_CURRENT,0),"__",
                                                           (string)Signal0(symbol),EnumToString(inpTF0),inpShift0, (string)Signal0(symbol),
                                         (string)Signal1(symbol),EnumToString(inpTF1),inpShift1,(string)Signal1(symbol),
                                (string)Signal2(symbol),EnumToString(inpTF2),inpShift2,(string)Signal2(symbol)
                               ,  (string)Signal3(symbol),EnumToString(inpTF3),inpShift3,(string)Signal3(symbol),"-----------------"
                                
                                       );
         mytrade="tradePic";
         int count=0;

        }

      else
         if(type==ORDER_TYPE_SELL_STOP)
           {
            check=false;



               
                         tradeReason=StringFormat("\n SELL STOP SIGNALS MATCHED: %s\n Date :%s \nSymbol:%s\n Stoploss %2.4f  \nTakeprofit %2.4f \n______Reasons_________\n%s\n,%s,\nTF1:%s ,\nShift1:%d,\nsignal1:%s, \n%s,\nTF2:%s,\nShift2:%d,\nsigna2:%s, \n%s,\nTF3:%s,\nShift3:%d ,\nsignal3:%s, \n%s,\nTF4:%s,\nShift4:%d,\n%s \n",
                                        "\xF4E3", (string)TimeCurrent(),symbol, iLow(symbol,PERIOD_CURRENT,0),iHigh(symbol,PERIOD_CURRENT,0),"__",
                                                           (string)Signal0(symbol),EnumToString(inpTF0),inpShift0, (string)Signal0(symbol),
                                         (string)Signal1(symbol),EnumToString(inpTF1),inpShift1,(string)Signal1(symbol),
                                (string)Signal2(symbol),EnumToString(inpTF2),inpShift2,(string)Signal2(symbol)
                               ,  (string)Signal3(symbol),EnumToString(inpTF3),inpShift3,(string)Signal3(symbol),"-----------------"
                                
                                       );   mytrade="tradePic";
            int count=0;




           }
         else
             if(type==ORDER_TYPE_BUY_STOP)
              {
               check=false;
               mytrade="tradePic";
               int count=0;


                        
                         tradeReason=StringFormat("\n MARKET  BUYSTOP SIGNALS MATCHED: %s\n Date :%s \nSymbol:%s\n Stoploss %2.4f  \nTakeprofit %2.4f \n______Reasons_________\n%s\n,%s,\nTF1:%s ,\nShift1:%d,\nsignal1:%s, \n%s,\nTF2:%s,\nShift2:%d,\nsigna2:%s, \n%s,\nTF3:%s,\nShift3:%d ,\nsignal3:%s, \n%s,\nTF4:%s,\nShift4:%d,\n%s \n",
                                        "\xF4E3", (string)TimeCurrent(),symbol, iLow(symbol,PERIOD_CURRENT,0),iHigh(symbol,PERIOD_CURRENT,0),"__",
                                                           (string)Signal0(symbol),EnumToString(inpTF0),inpShift0, (string)Signal0(symbol),
                                         (string)Signal1(symbol),EnumToString(inpTF1),inpShift1,(string)Signal1(symbol),
                                (string)Signal2(symbol),EnumToString(inpTF2),inpShift2,(string)Signal2(symbol)
                               ,  (string)Signal3(symbol),EnumToString(inpTF3),inpShift3,(string)Signal3(symbol),"-----------------"
                                
                                       );
              }

            else
               if(type==ORDER_TYPE_BUY)
                 {
                  mytrade="tradePic";
                  check=false;
                  int count=0;


           
                         tradeReason=StringFormat("\n MARKET  BUY SIGNALS MATCHED: %s\n Date :%s \nSymbol:%s\n Stoploss %2.4f  \nTakeprofit %2.4f \n______Reasons_________\n%s\n,%s,\nTF1:%s ,\nShift1:%d,\nsignal1:%s, \n%s,\nTF2:%s,\nShift2:%d,\nsigna2:%s, \n%s,\nTF3:%s,\nShift3:%d ,\nsignal3:%s, \n%s,\nTF4:%s,\nShift4:%d,\n%s \n",
                                        "\xF4E3", (string)TimeCurrent(),symbol, iLow(symbol,PERIOD_CURRENT,0),iHigh(symbol,PERIOD_CURRENT,0),"__",
                                                           (string)Signal0(symbol),EnumToString(inpTF0),inpShift0, (string)Signal0(symbol),
                                         (string)Signal1(symbol),EnumToString(inpTF1),inpShift1,(string)Signal1(symbol),
                                (string)Signal2(symbol),EnumToString(inpTF2),inpShift2,(string)Signal2(symbol)
                               ,  (string)Signal3(symbol),EnumToString(inpTF3),inpShift3,(string)Signal3(symbol),"-----------------"
                                
                                       );


                 }
   if(type==ORDER_TYPE_SELL)
     {
      mytrade="tradePic";
      check=false;
      int count=0;
                                
                                
                         tradeReason=StringFormat("\n MARKET  SELL SIGNALS MATCHED: %s\n Date :%s \nSymbol:%s\n Stoploss %2.4f  \nTakeprofit %2.4f \n______Reasons_________\n%s\n,%s,\nTF1:%s ,\nShift1:%d,\nsignal1:%s, \n%s,\nTF2:%s,\nShift2:%d,\nsigna2:%s, \n%s,\nTF3:%s,\nShift3:%d ,\nsignal3:%s, \n%s,\nTF4:%s,\nShift4:%d,\n%s \n",
                                        "\xF4E3", (string)TimeCurrent(),symbol, iLow(symbol,PERIOD_CURRENT,0),iHigh(symbol,PERIOD_CURRENT,0),"__",
                                                           (string)Signal0(symbol),EnumToString(inpTF0),inpShift0, (string)Signal0(symbol),
                                         (string)Signal1(symbol),EnumToString(inpTF1),inpShift1,(string)Signal1(symbol),
                                (string)Signal2(symbol),EnumToString(inpTF2),inpShift2,(string)Signal2(symbol)
                               ,  (string)Signal3(symbol),EnumToString(inpTF3),inpShift3,(string)Signal3(symbol),"-----------------"
                                
                                       );
                                
                                
                                
                                
                                
     }
   else
      if(check==true)
        {


         trad1=false;
         tradeReason=StringFormat("\nNO MATCHED SIGNALS: %s\n Date :%s \nSymbol:%s\n Stoploss %2.4f  \nTakeprofit %2.4f \n______Reasons_________\n%s\n,%s,\nTF1:%s ,\nShift1:%d,\nsignal1:%s, \n%s,\nTF2:%s,\nShift2:%d,\nsigna2:%s, \n%s,\nTF3:%s,\nShift3:%d ,\nsignal3:%s, \n%s,\nTF4:%s,\nShift4:%d,\n%s \n",
                                        "\xF4E3", (string)TimeCurrent(),symbol, iLow(symbol,PERIOD_CURRENT,0),iHigh(symbol,PERIOD_CURRENT,0),"__",
                                                           (string)Signal0(symbol),EnumToString(inpTF0),inpShift0, (string)Signal0(symbol),
                                         (string)Signal1(symbol),EnumToString(inpTF1),inpShift1,(string)Signal1(symbol),
                                (string)Signal2(symbol),EnumToString(inpTF2),inpShift2,(string)Signal2(symbol)
                               ,  (string)Signal3(symbol),EnumToString(inpTF3),inpShift3,(string)Signal3(symbol),"-----------------"
                                
                                       );
                                     smartBot.SendMessage(InpChatID2,tradeReason);


        };

 

  if(trad1==true){smartBot.SendMessage(InpChatID2,tradeReason);

   smartBot.SendScreenShot(symbol,(ENUM_TIMEFRAMES)InpTimFrame,Template,SendScreenshot);
   }

   
  }

 string mytrade="";
int MinAfter=60;
int MinBefore=30;
string indName0="",indName1="",indName2="",indName3="";
 
      
   
           int  starty_closepanel=-1;
  
       int     startx_closepanel=1;
       int     starty_symbolpanel=0;
       
       int     startx_symbolpanel=0;
       int SymbolButtonSelected=1;
    
     
       double Rx=0, Px=0;
     int _isBuy[],_isSell[]; 
     int ttlbuy=TradesCount(OP_BUY),ttlsell=TradesCount(OP_SELL);
///--+


  bool time1x=inTimeInterval(TimeCurrent(),TOD_From_Hour,TOD_From_Hour,TOD_To_Hour,TOD_To_Min);
 int LastMode=-1;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| SetStatus                                                        |
//+------------------------------------------------------------------+
void SetStatus(string Char, string Text)
  {
//---
   Comment("");
//---
   stauts_time = TimeLocal();
//---
   ObjectSetString(0, OBJPREFIX+"STATUS", OBJPROP_TEXT, Char);
   ObjectSetString(0, OBJPREFIX+"STATUS«", OBJPROP_TEXT, Text);
//---
  }
//+------------------------------------------------------------------+
//| ResetStatus                                                      |
//+------------------------------------------------------------------+
void ResetStatus()
  {
//---
   if(ObjectGetString(0, OBJPREFIX+"STATUS", OBJPROP_TEXT) != "\n" || ObjectGetString(0, OBJPREFIX+"STATUS«", OBJPROP_TEXT) != "\n")
     {
      ObjectSetString(0, OBJPREFIX+"STATUS", OBJPROP_TEXT, "\n");
      ObjectSetString(0, OBJPREFIX+"STATUS«", OBJPROP_TEXT, "\n");
     }
//---
  }
  

//+------------------------------------------------------------------+
//|                           OpenOrderManual                                       |
//+------------------------------------------------------------------+
void OpenOrderManual(const string symbol, ENUM_ORDER_TYPE op_type, double pip, double fVol,int i)
  {
   int ticket = -1;
  
   switch(op_type)
     {
      case OP_BUY:
        {
         if(AccountEquity()>=inpReqEquity && (inpTradeStyle== LONG||inpTradeStyle ==BOTH))
           {
            if(IsTesting() && (OrderSymbol() != symbol))
              {
               Print("Tester skip instant BUY " + symbol + ", lots:"+DoubleToString(fVol,2) + ", i:"+IntegerToString(i));
              }
            else
              { double entry_distance = GetDistanceInPoints(symbol,OrderDistanceUnit,inpStopDis,pip,fVol);
               double stop_distance  = GetDistanceInPoints(symbol,StopLossUnit,inpStopDis,pip,fVol);
               double tp_distance    = GetDistanceInPoints(symbol,TakeProfitUnit,inpTP*(i+1),pip,fVol);
         
                 ticket = OrderSend(symbol,OP_BUY,fVol,SymbolInfoDouble(symbol,SYMBOL_ASK),MaxSlippage,(SymbolInfoDouble(symbol,SYMBOL_ASK)+(entry_distance*pip))-(stop_distance*pip),
                 (SymbolInfoDouble(symbol,SYMBOL_ASK)+(entry_distance*pip))+((tp_distance*pip)),inpComment,MagicNumber,PendingOrderDeletes ? (TimeCurrent()+(Period()*inpPendingBar*60)):0,clrBlue);
             }
              
           }
         break;
        }
      case OP_BUYSTOP:
        {
         if(AccountEquity()>=inpReqEquity && (inpTradeStyle ==LONG || inpTradeStyle ==BOTH))
           {
            if(IsTesting() && (OrderSymbol() != symbol))
              {
               Print("Tester skip stop BUY " + symbol + ", lots:"+DoubleToString(fVol,2) );
              }
            else
              {
               double entry_distance = GetDistanceInPoints(symbol,OrderDistanceUnit,inpStopDis,pip,fVol);
               double stop_distance  = GetDistanceInPoints(symbol,StopLossUnit,inpStopDis,pip,fVol);
               double tp_distance    = GetDistanceInPoints(symbol,TakeProfitUnit,inpTP*(i+1),pip,fVol);
               ticket= -1;
               while(ticket<0)
                 {
                  ticket = OrderSend(symbol,ORDER_TYPE_BUY_STOP,fVol,SymbolInfoDouble(symbol,SYMBOL_ASK)+(entry_distance*pip),MaxSlippage,(SymbolInfoDouble(symbol,SYMBOL_ASK)+(entry_distance*pip))-(stop_distance*pip),(SymbolInfoDouble(symbol,SYMBOL_ASK)+(entry_distance*pip))+((tp_distance*pip)),inpComment,MagicNumber,PendingOrderDeletes ? (TimeCurrent()+(Period()*inpPendingBar*60)):0,clrBlue);
                  if(ticket<0)
                    {
                     Sleep(100);
                    }
                 }
              }
           }
         break;
        }
      case OP_BUYLIMIT:
        {
         if(AccountEquity()>=inpReqEquity && (inpTradeStyle ==LONG || inpTradeStyle ==BOTH))
           {
            if(IsTesting() && (symbol != Symbol()))
              {
            Print("Tester skip limit BUY " + symbol + ", lots:"+DoubleToString(fVol,2) + ", i:"+IntegerToString(i));
              }
            else
              {
               double entry_distance = GetDistanceInPoints(symbol,OrderDistanceUnit,inpStopDis,pip,fVol);
               double stop_distance  = GetDistanceInPoints(symbol,StopLossUnit,inpSL,pip,fVol);
               double tp_distance    = GetDistanceInPoints(symbol,TakeProfitUnit,inpTP*(i+1),pip,fVol);
               ticket = -1;
               while(ticket<0)
                 {
                  ticket = OrderSend(symbol,ORDER_TYPE_BUY_LIMIT,fVol,SymbolInfoDouble(symbol,SYMBOL_ASK)-(entry_distance*pip),MaxSlippage,(SymbolInfoDouble(symbol,SYMBOL_ASK)-(entry_distance*pip))-(stop_distance*pip),(SymbolInfoDouble(symbol,SYMBOL_ASK)-(entry_distance*pip))+(tp_distance*pip),inpComment,MagicNumber,DeletePendingOrders ? (TimeCurrent()+(Period()*inpPendingBar*60)):0,clrBlue);
                  if(ticket<0)
                    {
                     Sleep(100);
                    }
                 }
              }
           }
         break;
        }
      case OP_SELL:
        {
         if(AccountEquity()>=inpReqEquity && (inpTradeStyle ==SHORT || inpTradeStyle ==BOTH))
           {
            if(IsTesting() && (symbol != Symbol()))
              {
             Print("Tester skip instant SELL " + symbol + ", lots:"+DoubleToString(fVol,2) + ", i:"+IntegerToString(i));
              }
            else
              {   double entry_distance = GetDistanceInPoints(symbol,OrderDistanceUnit,inpStopDis,pip,fVol);
               double stop_distance  = GetDistanceInPoints(symbol,StopLossUnit,inpSL,pip,fVol);
               double tp_distance    = GetDistanceInPoints(symbol,TakeProfitUnit,inpTP*(i+1),pip,fVol);
                ticket = OrderSend(symbol,ORDER_TYPE_SELL_STOP,fVol,SymbolInfoDouble(symbol,SYMBOL_BID),MaxSlippage,(SymbolInfoDouble(symbol,SYMBOL_BID)-(entry_distance*pip))+(stop_distance*pip),SymbolInfoDouble(symbol,SYMBOL_BID)-(entry_distance*pip)-((tp_distance*pip)),inpComment,MagicNumber,PendingOrderDeletes ? (TimeCurrent()+(Period()*PendingOrderExpirationBars*60)):0,clrRed);
         ticket = -1;
               while(ticket<0)
                 {
                  ticket = OrderSend(symbol,ORDER_TYPE_SELL_STOP,fVol,SymbolInfoDouble(symbol,SYMBOL_BID)-(entry_distance*pip),MaxSlippage,(SymbolInfoDouble(symbol,SYMBOL_BID)-(entry_distance*pip))+(stop_distance*pip),SymbolInfoDouble(symbol,SYMBOL_BID)-(entry_distance*pip)-((tp_distance*pip)),inpComment,MagicNumber,PendingOrderDeletes ? (TimeCurrent()+(Period()*PendingOrderExpirationBars*60)):0,clrRed);
                  if(ticket<0)
                    {
                     Sleep(100);
                    }break;}
          
              }
           }
         break;
        }
      case OP_SELLSTOP:
        {
         if(AccountEquity()>=inpReqEquity && (inpTradeStyle ==SHORT ||inpTradeStyle ==BOTH))
           {
            if(IsTesting() && (symbol != Symbol()))
              {
              Print("Tester skip stop SELL " + symbol + ", lots:"+DoubleToString(fVol,2) + ", i:"+IntegerToString(i));
              }
            else
              {
               double entry_distance = GetDistanceInPoints(symbol,OrderDistanceUnit,inpStopDis,pip,fVol);
               double stop_distance  = GetDistanceInPoints(symbol,StopLossUnit,inpSL,pip,fVol);
               double tp_distance    = GetDistanceInPoints(symbol,TakeProfitUnit,inpTP*(i+1),pip,fVol);
               ticket = -1;
               while(ticket<0)
                 {
                  ticket = OrderSend(symbol,ORDER_TYPE_SELL_STOP,fVol,SymbolInfoDouble(symbol,SYMBOL_BID)-(entry_distance*pip),MaxSlippage,(SymbolInfoDouble(symbol,SYMBOL_BID)-(entry_distance*pip))+(stop_distance*pip),SymbolInfoDouble(symbol,SYMBOL_BID)-(entry_distance*pip)-((tp_distance*pip)),inpComment,MagicNumber,PendingOrderDeletes ? (TimeCurrent()+(Period()*PendingOrderExpirationBars*60)):0,clrRed);
                  if(ticket<0)
                    {
                     Sleep(100);
                    }
                 }
              }
           }
         break;
        }
      case OP_SELLLIMIT:
        {
         if(AccountEquity()>=inpReqEquity && (inpTradeStyle ==SHORT || inpTradeStyle ==BOTH))
           {
            if(IsTesting() && (symbol != Symbol()))
              {
               Print("Tester skip limit SELL " + symbol + ", lots:"+DoubleToString(fVol,2) + ", i:"+IntegerToString(i));
              }
            else
              {
               double entry_distance = GetDistanceInPoints(symbol,OrderDistanceUnit,inpStopDis,pip,fVol);
               double stop_distance  = GetDistanceInPoints(symbol,StopLossUnit,inpSL,pip,fVol);
               double tp_distance    = GetDistanceInPoints(symbol,TakeProfitUnit,takeprofit*(i+1),pip,fVol);
               ticket = -1;
               while(ticket<0)
                 {
                  ticket = OrderSend(symbol,ORDER_TYPE_SELL_LIMIT,fVol,SymbolInfoDouble(symbol,SYMBOL_BID)+(entry_distance*pip),MaxSlippage,(SymbolInfoDouble(symbol,SYMBOL_BID)+(entry_distance*pip))+(stop_distance*pip),(SymbolInfoDouble(symbol,SYMBOL_BID)+(entry_distance*pip))-((tp_distance*pip)),inpComment,MagicNumber,PendingOrderDeletes ? (TimeCurrent()+(Period()*PendingOrderExpirationBars*60)):0,clrBlueViolet);
                  if(ticket<0)
                    {
                     Sleep(100);
                    }
                 }
              }
           }
         break;
        }
     }
  }
  
//+--------------------------------------------------------------------+
//| ChartMouseScrollSet                                                |
//+--------------------------------------------------------------------+
//https://docs.mql4.com/constants/chartconstants/charts_samples
bool ChartMouseScrollSet(const bool value)
  {
//--- reset the error value
   ResetLastError();
//---
   if(!ChartSetInteger(0, CHART_MOUSE_SCROLL, 0, value))
     {
      Print(__FUNCTION__,
            ", Error Code = ", _LastError);
      return(false);
     }
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| PlaySound                                                        |
//+------------------------------------------------------------------+
void _PlaySound(const string FileName)
  {
//---
   if(SoundIsEnabled)
      PlaySound(FileName);
//---
  }
  
//+------------------------------------------------------------------+
//| Dpi                                                              |
//+------------------------------------------------------------------+
int Dpi(int Size)
  {
//---
   int screen_dpi = TerminalInfoInteger(TERMINAL_SCREEN_DPI);
   int base_width = Size;
   int width = (base_width*screen_dpi)/96;
   int scale_factor = (TerminalInfoInteger(TERMINAL_SCREEN_DPI)*100)/96;
//---
   width = (base_width*scale_factor)/100;
//---
   return(width);
  }
  
//+------------------------------------------------------------------+
//| CreateMinWindow                                                  |
//+------------------------------------------------------------------+
void CreateMinWindow()
  {
//---//---//---

   RectLabelCreate(0, OBJPREFIX+"MIN"+"BCKGRND[]", 0, Dpi(1), Dpi(20), Dpi(163), Dpi(25), COLOR_BORDER, BORDER_FLAT, CORNER_LEFT_LOWER, COLOR_BORDER, STYLE_SOLID, 1, false);
//---
   LabelCreate(0, OBJPREFIX+"MIN"+"CAPTION", 0, Dpi(140), Dpi(18), CORNER_LEFT_LOWER, "MultiTrading", "Arial Black", 8, C'59, 41, 40', 0, ANCHOR_LEFT_UPPER, false, false, true,true);
//---
   LabelCreate(0, OBJPREFIX+"MIN"+"MAXIMIZE", 0, Dpi(156), Dpi(23), CORNER_LEFT_LOWER, "1", "Webdings", 10, C'59, 41, 40', 0, ANCHOR_UPPER, false, false, true);

  }
//+------------------------------------------------------------------+
//|                    OnChartEvent                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
  
  
//----
   if(id==CHARTEVENT_KEYDOWN)
     {

      //---
      if(KeyboardTrading)
        {


         //--- Switch Symbol (UP)
         if(lparam==KEY_UP)
           {
            //---
            int index=0;
            //---
            for(int i=0; i<NumOfSymbols; i++)
              {
               if( Symbols[i]==TradeScheduleSymbol(i,InpSelectPairs_By_Basket_Schedule))
                 {
                  //---
                  index=i-1;
                  //---
                  if(index<0)
                     index=NumOfSymbols-1;
                  //---
                  if(SymbolFind(TradeScheduleSymbol(index,InpSelectPairs_By_Basket_Schedule),false))
                    {
                     ChartSetSymbolPeriod(0,TradeScheduleSymbol(index,InpSelectPairs_By_Basket_Schedule),PERIOD_CURRENT);
                     SetStatus("ÿ","Switched to "+TradeScheduleSymbol(index,InpSelectPairs_By_Basket_Schedule));
                     break;
                    }
                 }
              }
           }

         //--- Switch Symbol (DOWN)
         if(lparam==KEY_DOWN)
           {
            //---
            int index=0;
            //---
            for(int i=0; i<NumOfSymbols; i++)
              {
               //---
               if(Symbols[i]==TradeScheduleSymbol(i,InpSelectPairs_By_Basket_Schedule))
                 {
                  //--
                  index=i+1;
                  //---
                  if(index>=NumOfSymbols)
                     index=0;
                  //---
                  if(SymbolFind(TradeScheduleSymbol(index,InpSelectPairs_By_Basket_Schedule),false))
                    {
                     ChartSetSymbolPeriod(0,TradeScheduleSymbol(index,InpSelectPairs_By_Basket_Schedule),PERIOD_CURRENT);
                     SetStatus("ÿ","Switched to "+TradeScheduleSymbol(index,InpSelectPairs_By_Basket_Schedule));
                     break;
                    }
                 }
              }
           }
        }
     }

//--- OBJ_CLICKS
   if(id==CHARTEVENT_OBJECT_CLICK)
     {


      //---
      for(int i=0; i<NumOfSymbols; i++)
        {

         //--- SymoblSwitcher
         if(sparam==OBJPREFIX+TradeScheduleSymbol(i,InpSelectPairs_By_Basket_Schedule))
           {
            ChartSetSymbolPeriod(0,TradeScheduleSymbol(i,InpSelectPairs_By_Basket_Schedule),PERIOD_CURRENT);
            SetStatus("ÿ","Switched to "+TradeScheduleSymbol(i,InpSelectPairs_By_Basket_Schedule));
            break;
           }
        }

      //--- RemoveExpert
      if(sparam==OBJPREFIX+"EXIT")
        {
         //---
         if(MessageBox("Are you sure you want to exit?",MB_CAPTION,MB_ICONQUESTION|MB_YESNO)==IDYES)
            ExpertRemove();//Exit
        }

      //--- Minimize
      if(sparam==OBJPREFIX+"MINIMIZE")
        {
         ObjectsDeleteAll(0,OBJPREFIX,-1,-1);
         CreateMinWindow();
         ShowDashboard=false;
         ChartMouseScrollSet(true);
         ChartSetColor(2);
         ClearedTemplate=false;
        }

      //--- Maximize
      if(sparam==OBJPREFIX+"MIN"+"MAXIMIZE")
        {
         DelteMinWindow();
         ObjectsCreateAll();
         ShowDashboard=true;
         ChartMouseScrollSet(false);
        }

      //--- Ping
      if(sparam==OBJPREFIX+"CONNECTION")
        {
         //---
         double Ping=TerminalInfoInteger(TERMINAL_PING_LAST);//SetPingToMs
         //---
         if(TerminalInfoInteger(TERMINAL_CONNECTED))
            SetStatus("\n","Ping: "+DoubleToString(Ping/1000,2)+" ms");
         else
            SetStatus("ý","No Internet connection...");
        }


      //--- SwitchTheme
      if(sparam==OBJPREFIX+"THEME")
        {
         //---
         if(SelectedTheme==0)
           {
            ObjectsDeleteAll(0,OBJPREFIX,-1,-1);
            COLOR_BG=C'28,28,28';
            COLOR_FONT=clrSilver;
            COLOR_GREEN=clrLimeGreen;
            COLOR_RED=clrRed;
            COLOR_LOW=clrYellow;
            COLOR_MARKER=clrGold;
            ObjectsCreateAll();
            SelectedTheme=1;
            //---
            SetStatus("ÿ","Dark theme selected...");
            Sleep(250);
            ResetStatus();
           }
         else
           {
            ObjectsDeleteAll(0,OBJPREFIX,-1,-1);
            COLOR_BG=C'240,240,240';
            COLOR_FONT=C'40,41,59';
            COLOR_GREEN=clrForestGreen;
            COLOR_RED=clrIndianRed;
            COLOR_LOW=clrGoldenrod;
            COLOR_MARKER=clrDarkOrange;
            ObjectsCreateAll();
            SelectedTheme=0;
            //---
            SetStatus("ÿ","Light theme selected...");
            Sleep(250);
            ResetStatus();
           }
        }

      //--- SwitchTheme
      if(sparam==OBJPREFIX+"TEMPLATE")
        {
         //---
         if(!ClearedTemplate)
           {
            //---
            if(SelectedTheme==0)
              {
               ChartSetColor(0);
               ClearedTemplate=true;
               SetStatus("ÿ","Chart color cleared...");
              }
            else
              {
               ChartSetColor(1);
               ClearedTemplate=true;
               SetStatus("ÿ","Chart color cleared...");
              }
           }
         else
           {
            ChartSetColor(2);
            ClearedTemplate=false;
            SetStatus("ÿ","Original chart color applied...");
           }
        }

      //--- GetParameters
      GetParam(sparam);

      //--- SoundManagement
      if(sparam==OBJPREFIX+"SOUND" || sparam==OBJPREFIX+"SOUNDIO")
        {
         //--- EnableSound
         if(!SoundIsEnabled)
           {
            SoundIsEnabled=true;
            ObjectSetInteger(0,OBJPREFIX+"SOUNDIO",OBJPROP_COLOR,C'59,41,40');//SetObject
            SetStatus("þ","Sounds enabled...");
            PlaySound("sound.wav");
           }
         //--- DisableSound
         else
           {
            SoundIsEnabled=false;
            ObjectSetInteger(0,OBJPREFIX+"SOUNDIO",OBJPROP_COLOR,clrNONE);//SetObject
            SetStatus("ý","Sounds disabled...");
           }
        }
      //--- AlarmManagement
      if(sparam==OBJPREFIX+"ALARM" || sparam==OBJPREFIX+"ALARMIO")
        {
         //--- EnableSound
         if(!AlarmIsEnabled)
           {
            //---
            AlarmIsEnabled=true;
            //---
            ObjectSetInteger(0,OBJPREFIX+"ALARMIO",OBJPROP_COLOR,clrNONE);
            //---
          

            //---
            Alert("Alerts enabled "+message);
            SetStatus("þ","Alerts enabled...");
           }
         //--- DisableSound
         else
           {
            //---
            AlarmIsEnabled=false;
            ObjectSetInteger(0,OBJPREFIX+"ALARMIO",OBJPROP_COLOR,C'59,41,40');
            //---
            SetStatus("ý","Alerts disabled...");
           }
        }

      //--- Balance
      if(sparam==OBJPREFIX+"BALANCE«")
        {
         //---
         string text="";
         //---
         if(_AccountCurrency()=="$" || _AccountCurrency()=="£")
            text=_AccountCurrency()+DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY),2);
         else
            text=DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY),2)+_AccountCurrency();
         //---
         SetStatus("","Equity: "+text);
        }



      //--- Switch PriceRow Left
      if(sparam==OBJPREFIX+"PRICEROW_Lª")
        {
         //---
         PriceRowLeft++;
         //---
         if(PriceRowLeft>=NumOfSymbols)//Reset
            PriceRowLeft=0;
         //---
         ObjectSetString(0,OBJPREFIX+"PRICEROW_Lª",OBJPROP_TEXT,0,PriceRowLeftArr[PriceRowLeft]);/*SetObject*/
         //---
         SetStatus("É","Switched to "+PriceRowLeftArr[PriceRowLeft]+" mode...");
         //---
         for(int i=0; i<NumOfSymbols; i++)
            ObjectSetString(0,OBJPREFIX+"PRICEROW_L"+" - "+TradeScheduleSymbol(i,InpSelectPairs_By_Basket_Schedule),OBJPROP_TOOLTIP,PriceRowLeftArr[PriceRowLeft]+" "+TradeScheduleSymbol(i,InpSelectPairs_By_Basket_Schedule));
        }

      //--- Switch PriceRow Right
      if(sparam==OBJPREFIX+"PRICEROW_Rª")
        {
         //---
         PriceRowRight++;
         //---
         if(PriceRowRight>=ArraySize(PriceRowRightArr))//Reset
            PriceRowRight=0;
         //---
         ObjectSetString(0,OBJPREFIX+"PRICEROW_Rª",OBJPROP_TEXT,0,PriceRowRightArr[PriceRowRight]);/*SetObject*/
         //---
         SetStatus("Ê","Switched to "+PriceRowRightArr[PriceRowRight]+" mode...");
         //---
         for(int i=0; i<NumOfSymbols; i++){
            ObjectSetString(0,OBJPREFIX+"PRICEROW_R "+" - "+Symbols[i],OBJPROP_TOOLTIP,PriceRowRightArr[PriceRowRight]+" "+Symbols[i]);
        }
        
        }
      if(sparam==OBJPREFIX+"PRICEROW_Rª")
        {
         //---
         PriceRowRight++;
         //---
         if(PriceRowRight>=ArraySize(PriceRowRightArr))//Reset
            PriceRowRight=0;
         //---
         ObjectSetString(0,OBJPREFIX+"PRICEROW_Rª",OBJPROP_TEXT,0,PriceRowRightArr[PriceRowRight]);/*SetObject*/
         //---
         SetStatus("Ê","Switched to "+PriceRowRightArr[PriceRowRight]+" mode...");
         //---
         for(int i=0; i<NumOfSymbols; i++){
            ObjectSetString(0,OBJPREFIX+"PRICEROW_R"+" - "+Symbols[i],OBJPROP_TOOLTIP,PriceRowRightArr[PriceRowRight]+" "+Symbols[i]);
            }
        }

  

       
        
        
           if(StringFind(sparam,OBJPFX"SGGS",0)>=0)
        {
         ObjectSetInteger(ChartID(),sparam,OBJPROP_BGCOLOR,clrLime);
         //--- extract index from button name
         int index = (int)StringToInteger(StringSubstr(sparam,StringLen(OBJPFX"SGGS")));
             ReleaseOtherButtons(index);
         SymbolButtonSelected = (int)index;
        
         ObjectSetInteger(ChartID(),sparam,OBJPROP_BGCOLOR,clrBlue);
         //--- extract index from button name
      SymbolButtonSelected=  (int)StringToInteger(StringSubstr(sparam,StringLen(OBJPFX"SGGS")));
   
          
           
                   printf("symbol selected "+(string )SymbolButtonSelected+ Symbols[index]);
      
        }
        
        

      if(inpTradeMode == Manual)
        {
       
   string _sName = TradeScheduleSymbol(SymbolButtonSelected,InpSelectPairs_By_Basket_Schedule);
    
       
         double pip;
         pip=SymbolInfoDouble(_sName,SYMBOL_POINT);
         if(SymbolInfoInteger(_sName,SYMBOL_DIGITS)==5 || SymbolInfoInteger(_sName,SYMBOL_DIGITS)==3 || StringFind(_sName,"XAU",0)>=0)
            pip*=10;

         double vol = (double)ObjectGetString(0,OBJPFX"editLot",OBJPROP_TEXT);
         double sl = (double)ObjectGetString(0,OBJPFX"editStop",OBJPROP_TEXT)*pip;
         double tp = (double)ObjectGetString(0,OBJPFX"editTP",OBJPROP_TEXT)*pip;
         int not = (int)ObjectGetString(0,OBJPFX"editTN",OBJPROP_TEXT);
         double fVol = TradeSize(InpMoneyManagement);

         for(int i=MAX_CLOSE_BUTTONS-1;i>0; i--)
           {
            if(sparam==OBJPFX+CloseButtonNames[i])
              {
             
                  PrintFormat("%s pressed",CloseButtonNames[i]);
                 
               switch((ENUM_CLOSE_BUTTON_TYPES)i)
                 {
                  default:
                     PrintFormat("Unhandled close button type: %d",i);
                     break;
                  case CloseBuy:
                    { CloseBuyOrders(_sName); break; }
                  case CloseSell:
                    { CloseSellOrders(_sName); break; }
                  case CloseProfit:
                    { CloseProfitOrders(_sName); break; }
                  case CloseLoss:
                    { CloseLossOrders(_sName); break; }
                  case ClosePendingLimit:
                    { ClosePendingLimitOrders(_sName); break; }
                  case ClosePendingStop:
                    { ClosePendingStopOrders(_sName); break; }
                  case CloseAll:
                    { CloseAllOrders(_sName); break; }
                 }
               //--- unset state
               ObjectSetInteger(0,sparam,OBJPROP_STATE,false);
              }

           }
          if(sparam==OBJPFX"btnSell")
           {
                
           
            
   _sName = TradeScheduleSymbol( SymbolButtonSelected ,InpSelectPairs_By_Basket_Schedule);
    
           OpenOrderManual(_sName,OP_SELL,pip,fVol,GetManualSignalIndex());
            if(IsTesting())
               Print(_sName + ":"+ sparam+":"+IntegerToString(GetManualSignalIndex())+",t:"+IntegerToString(ManualSignals[GetManualSignalIndex()].type));

            ObjectSetInteger(0,sparam,OBJPROP_STATE,false);
           }
         else
            if(sparam==OBJPFX"btnBuy")
              {
           
                    
   _sName = TradeScheduleSymbol( SymbolButtonSelected ,InpSelectPairs_By_Basket_Schedule);
    
       
           OpenOrderManual(_sName,OP_BUY,pip,fVol,SymbolButtonSelected);
               if(IsTesting())
                  Print(_sName + ":"+ sparam+":"+IntegerToString(GetManualSignalIndex())+",t:"+IntegerToString(ManualSignals[GetManualSignalIndex()].type));

               ObjectSetInteger(0,sparam,OBJPROP_STATE,false);
              }
            else
               if(sparam==OBJPFX"btnSS")
                 {
            
   _sName = TradeScheduleSymbol( SymbolButtonSelected ,InpSelectPairs_By_Basket_Schedule);
    
           OpenOrderManual(_sName,OP_SELLSTOP,pip,fVol,GetManualSignalIndex());
                  if(IsTesting())
                     Print(_sName + ":"+ sparam+":"+IntegerToString(GetManualSignalIndex())+",t:"+IntegerToString(ManualSignals[GetManualSignalIndex()].type));

                  ObjectSetInteger(0,sparam,OBJPROP_STATE,false);
                 }
               else
                  if(sparam==OBJPFX"btnBS")
                    {
            
   _sName = TradeScheduleSymbol( SymbolButtonSelected ,InpSelectPairs_By_Basket_Schedule);
    
           OpenOrderManual(_sName,OP_BUYSTOP,pip,fVol,GetManualSignalIndex());
                     if(IsTesting())
                        Print(_sName + ":"+ sparam+":"+IntegerToString(GetManualSignalIndex())+",t:"+IntegerToString(ManualSignals[GetManualSignalIndex()].type));

                     ObjectSetInteger(0,sparam,OBJPROP_STATE,false);
                    }
                  else
                     if(sparam==OBJPFX"btnSL")
                       {
                      
   _sName = TradeScheduleSymbol( SymbolButtonSelected ,InpSelectPairs_By_Basket_Schedule);
    
       
           OpenOrderManual(_sName,OP_SELLLIMIT,pip,fVol,GetManualSignalIndex());
                        if(IsTesting())
                           Print(_sName + ":"+ sparam+":"+IntegerToString(GetManualSignalIndex())+",t:"+IntegerToString(ManualSignals[GetManualSignalIndex()].type));

                        ObjectSetInteger(0,sparam,OBJPROP_STATE,false);
                       }
                     else
                        if(sparam==OBJPFX"btnBL")
                          {
                          
   _sName = TradeScheduleSymbol( SymbolButtonSelected ,InpSelectPairs_By_Basket_Schedule);
    
                          
                          
       
           OpenOrderManual(_sName,OP_BUYLIMIT,pip,fVol,GetManualSignalIndex());
                        
                           if(IsTesting())
                              Print(_sName + ":"+ sparam+":"+IntegerToString(GetManualSignalIndex())+",t:"+IntegerToString(ManualSignals[GetManualSignalIndex()].type));

                           ObjectSetInteger(0,sparam,OBJPROP_STATE,false);
                          }
        }
     }
   if(id==CHARTEVENT_MOUSE_MOVE)
     {
      //-- UserIsHolding (Left-Click)
      if(sparam=="1")
        {
         bool coordinates_set = false;
         //-- MoveClient
         if(inpTradeMode == Manual)    //--- Trade panel is created in manual mode only
           {
            if(ObjectGetInteger(0,OBJPFX"Back",OBJPROP_SELECTED)/* || ObjectFind(0,OBJPFX"Back")!=0*/)
              {
               //-- MoveObjects
               GetSetCoordinates();
               MovePannel();
               coordinates_set = true;
              }
            if(ObjectGetInteger(0,OBJPFX"BackCP",OBJPROP_SELECTED)/* || ObjectFind(0,OBJPFX"Back")!=0*/)
              {
               //-- MoveObjects
               if(!coordinates_set)
                  GetSetCoordinates();
               MoveClosePanel();
               coordinates_set = true;
              }

           }
         if(ShowTradedSymbols)
           {
            if(ObjectGetInteger(0,OBJPFX"BackSP",OBJPROP_SELECTED)/* || ObjectFind(0,OBJPFX"Back")!=0*/)
              {
               //-- MoveObjects
               if(!coordinates_set)
                 {
                  GetSetCoordinates();
                  coordinates_set = true;
                 }
               MoveSymbolPanel();
              }
           }
        }
     }
    //--- Handling mouse events
   if(id==CHARTEVENT_OBJECT_CLICK)
     {
      //--- Handling pressing the buttons in the panel
   if(StringFind(sparam,"BUTT_")>0)
    PressButtonEvents(sparam);
     }
//--- Handling DoEasy library events
   if(id>CHARTEVENT_CUSTOM-1)
     {
     OnDoEasyEvent(id,lparam,dparam,sparam);
     } 
  
}

void OnDoEasyEvent(const int id,
                   const long &lparam,
                   const double &dparam,
                   const string &sparam)
  {
   int idx=id-CHARTEVENT_CUSTOM;
   string event="::"+string(idx);
   
//--- Retrieve (1) event time milliseconds, (2) reason and (3) source from lparam, as well as (4) set the exact event time
   ushort msc=engine.EventMSC(lparam);
   ushort reason=engine.EventReason(lparam);
   ushort source=engine.EventSource(lparam);
   long time=TimeCurrent()*1000+msc;
   
//--- Handling symbol events
   if(source==COLLECTION_SYMBOLS_ID)
     {
      CSymbol *symbol=engine.GetSymbolObjByName(sparam);
      if(symbol==NULL)
         return;
      //--- Number of decimal places in the event value - in case of a 'long' event, it is 0, otherwise - Digits() of a symbol
      int digits=(idx<SYMBOL_PROP_INTEGER_TOTAL ? 0 : symbol.Digits());
      //--- Event text description
      string id_descr=(idx<SYMBOL_PROP_INTEGER_TOTAL ? symbol.GetPropertyDescription((ENUM_SYMBOL_PROP_INTEGER)idx) : symbol.GetPropertyDescription((ENUM_SYMBOL_PROP_DOUBLE)idx));
      //--- Property change text value
      string value=DoubleToString(dparam,digits);
      
      //--- Check event reasons and display its description in the journal
      if(reason==BASE_EVENT_REASON_INC)
        {
         Print(symbol.EventDescription(idx,(ENUM_BASE_EVENT_REASON)reason,source,value,id_descr,digits));
        }
      if(reason==BASE_EVENT_REASON_DEC)
        {
         Print(symbol.EventDescription(idx,(ENUM_BASE_EVENT_REASON)reason,source,value,id_descr,digits));
        }
      if(reason==BASE_EVENT_REASON_MORE_THEN)
        {
         Print(symbol.EventDescription(idx,(ENUM_BASE_EVENT_REASON)reason,source,value,id_descr,digits));
        }
      if(reason==BASE_EVENT_REASON_LESS_THEN)
        {
         Print(symbol.EventDescription(idx,(ENUM_BASE_EVENT_REASON)reason,source,value,id_descr,digits));
        }
      if(reason==BASE_EVENT_REASON_EQUALS)
        {
         Print(symbol.EventDescription(idx,(ENUM_BASE_EVENT_REASON)reason,source,value,id_descr,digits));
        }
     }   
     
//--- Handling account events
   else if(source==COLLECTION_ACCOUNT_ID)
     {
      CAccount *account=engine.GetAccountCurrent();
      if(account==NULL)
         return;
      //--- Number of decimal places in the event value - in case of a 'long' event, it is 0, otherwise - Digits() of a symbol
      int digits=int(idx<ACCOUNT_PROP_INTEGER_TOTAL ? 0 : account.CurrencyDigits());
      //--- Event text description
      string id_descr=(idx<ACCOUNT_PROP_INTEGER_TOTAL ? account.GetPropertyDescription((ENUM_ACCOUNT_PROP_INTEGER)idx) : account.GetPropertyDescription((ENUM_ACCOUNT_PROP_DOUBLE)idx));
      //--- Property change text value
      string value=DoubleToString(dparam,digits);
      
      //--- Checking event reasons and handling the increase of funds by a specified value,
      
      //--- In case of a property value increase
      if(reason==BASE_EVENT_REASON_INC)
        {
         //--- Display an event in the journal
         Print(account.EventDescription(idx,(ENUM_BASE_EVENT_REASON)reason,source,value,id_descr,digits));
         //--- if this is an equity increase
         if(idx==ACCOUNT_PROP_EQUITY)
           {
            //--- Get the list of all open positions
            CArrayObj* list_positions=engine.GetListMarketPosition();
            //--- Select positions with the profit exceeding zero
            list_positions=CSelect::ByOrderProperty(list_positions,ORDER_PROP_PROFIT_FULL,0,MORE);
            if(list_positions!=NULL)
              {
               //--- Sort the list by profit considering commission and swap
               list_positions.Sort(SORT_BY_ORDER_PROFIT_FULL);
               //--- Get the position index with the highest profit
               int index=CSelect::FindOrderMax(list_positions,ORDER_PROP_PROFIT_FULL);
               if(index>WRONG_VALUE)
                 {
                  COrder* position=list_positions.At(index);
                  if(position!=NULL)
                    {
                     //--- Get a ticket of a position with the highest profit and close the position by a ticket
                     engine.ClosePosition(position.Ticket());
                    }
                 }
              }
           }
        }
      //--- Other events are simply displayed in the journal
      if(reason==BASE_EVENT_REASON_DEC)
        {
         Print(account.EventDescription(idx,(ENUM_BASE_EVENT_REASON)reason,source,value,id_descr,digits));
        }
      if(reason==BASE_EVENT_REASON_MORE_THEN)
        {
         Print(account.EventDescription(idx,(ENUM_BASE_EVENT_REASON)reason,source,value,id_descr,digits));
        }
      if(reason==BASE_EVENT_REASON_LESS_THEN)
        {
         Print(account.EventDescription(idx,(ENUM_BASE_EVENT_REASON)reason,source,value,id_descr,digits));
        }
      if(reason==BASE_EVENT_REASON_EQUALS)
        {
         Print(account.EventDescription(idx,(ENUM_BASE_EVENT_REASON)reason,source,value,id_descr,digits));
        }
     } 
     
//--- Handling trading events
   else if(idx>TRADE_EVENT_NO_EVENT && idx<TRADE_EVENTS_NEXT_CODE)
     {
      event=EnumToString((ENUM_TRADE_EVENT)ushort(idx));
      int digits=(int)SymbolInfoInteger(sparam,SYMBOL_DIGITS);
     }
     
//--- Handling market watch window events
   else if(idx>MARKET_WATCH_EVENT_NO_EVENT && idx<SYMBOL_EVENTS_NEXT_CODE)
     {
      string name="";
      //--- Market Watch window event
      string descr=engine.GetMWEventDescription((ENUM_MW_EVENT)idx);
      name=(idx==MARKET_WATCH_EVENT_SYMBOL_SORT ? "" : ": "+sparam);
      Print(TimeMSCtoString(lparam)," ",descr,name);
     }
  }
//+------------------------------------------------------------------+
//| Return the flag of a prefixed object presence                    |
//+------------------------------------------------------------------+
bool IsPresentObects(const string object_prefix)
  {
   for(int i=ObjectsTotal(0,0)-1;i>=0;i--)
      if(StringFind(ObjectName(0,i,0),object_prefix)>WRONG_VALUE)
         return true;
   return false;
  }
//+------------------------------------------------------------------+
//| Tracking the buttons' status                                     |
//+------------------------------------------------------------------+
void PressButtonsControl(void)
  {
   int total=ObjectsTotal(0,0);
   for(int i=0;i<total;i++)
     {
      string obj_name=ObjectName(0,i);
      if(StringFind(obj_name,prefix+"BUTT_")<0)
         continue;
      PressButtonEvents(obj_name);
     }
  }
//+------------------------------------------------------------------+
//| Create the buttons panel                                         |
//+------------------------------------------------------------------+
bool CreateButtons(const int shift_x=30,const int shift_y=0)
  {
   int h=18,w=84;
   int cx=offset+shift_x,cy=offset+shift_y+(h+1)*(TOTAL_BUTT/2)+3*h+1;
   int x=cx,y=cy;
   int shift=0;
   for(int i=0;i<TOTAL_BUTT;i++)
     {
      x=x+(i==7 ? w+2 : 0);
      if(i==TOTAL_BUTT-6) x=cx;
      y=(cy-(i-(i>6 ? 7 : 0))*(h+1));
      if(!ButtonCreate(butt_data[i].name,x,y,(i<TOTAL_BUTT-6 ? w : w*2+2),h,butt_data[i].text,(i<4 ? clrGreen : i>6 && i<11 ? clrRed : clrBlue)))
        {
         Alert(TextByLanguage("Не удалось создать кнопку \"","Could not create button \""),butt_data[i].text);
         return false;
        }
     }
   ChartRedraw(0);
   return true;
  }
//+------------------------------------------------------------------+
//| Create the button                                                |
//+------------------------------------------------------------------+
bool ButtonCreate(const string name,const int x,const int y,const int w,const int h,const string text,const color clr,const string font="Calibri",const int font_size=8)
  {
   if(ObjectFind(0,name)<0)
     {
      if(!ObjectCreate(0,name,OBJ_BUTTON,0,0,0)) 
        { 
         Print(DFUN,TextByLanguage("не удалось создать кнопку! Код ошибки=","Could not create button! Error code="),GetLastError()); 
         return false; 
        } 
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
      ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
      ObjectSetInteger(0,name,OBJPROP_XSIZE,w);
      ObjectSetInteger(0,name,OBJPROP_YSIZE,h);
      ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_LOWER);
      ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_LEFT_LOWER);
      ObjectSetInteger(0,name,OBJPROP_FONTSIZE,font_size);
      ObjectSetString(0,name,OBJPROP_FONT,font);
      ObjectSetString(0,name,OBJPROP_TEXT,text);
      ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
      ObjectSetString(0,name,OBJPROP_TOOLTIP,"\n");
      ObjectSetInteger(0,name,OBJPROP_BORDER_COLOR,clrGray);
      return true;
     }
   return false;
  }
//+------------------------------------------------------------------+
//| Return the button status                                         |
//+------------------------------------------------------------------+
bool ButtonState(const string name)
  {
   return (bool)ObjectGetInteger(0,name,OBJPROP_STATE);
  }
//+------------------------------------------------------------------+
//| Set the button status                                            |
//+------------------------------------------------------------------+
void ButtonState(const string name,const bool state)
  {
   ObjectSetInteger(0,name,OBJPROP_STATE,state);
   if(name==butt_data[TOTAL_BUTT-1].name)
     {
      if(state)
         ObjectSetInteger(0,name,OBJPROP_BGCOLOR,C'220,255,240');
      else
         ObjectSetInteger(0,name,OBJPROP_BGCOLOR,C'240,240,240');
     }
  }
//+------------------------------------------------------------------+
//| Transform enumeration into the button text                       |
//+------------------------------------------------------------------+
string EnumToButtText(const ENUM_BUTTONS member)
  {
   string txt=StringSubstr(EnumToString(member),5);
   StringToLower(txt);
   StringReplace(txt,"set_take_profit","Set TakeProfit");
   StringReplace(txt,"set_stop_loss","Set StopLoss");
   StringReplace(txt,"trailing_all","Trailing All");
   StringReplace(txt,"buy","Buy");
   StringReplace(txt,"sell","Sell");
   StringReplace(txt,"_limit"," Limit");
   StringReplace(txt,"_stop"," Stop");
   StringReplace(txt,"close_","Close ");
   StringReplace(txt,"2"," 1/2");
   StringReplace(txt,"_by_"," by ");
   StringReplace(txt,"profit_","Profit ");
   StringReplace(txt,"delete_","Delete ");
   return txt;
  }
//+------------------------------------------------------------------+
//| Handle pressing the buttons                                      |
//+------------------------------------------------------------------+
void PressButtonEvents(const string button_name)
  {
   string comment="";
   //--- Convert button name into its string ID
   string button=StringSubstr(button_name,StringLen(prefix));
   //--- If the button is pressed
   if(ButtonState(button_name))
     {
      //--- If the BUTT_BUY button is pressed: Open Buy position
      if(button==EnumToString(BUTT_BUY))
        {
         //--- Get the correct StopLoss and TakeProfit prices relative to StopLevel
         double sl=CorrectStopLoss(Symbol(),ORDER_TYPE_BUY,0,stoploss);
         double tp=CorrectTakeProfit(Symbol(),ORDER_TYPE_BUY,0,takeprofit);
         //--- Open Buy position
         engine.OpenBuy(lot,Symbol(),magic_number,sl,tp);   // No comment - the default comment is to be set
        }
      //--- If the BUTT_BUY_LIMIT button is pressed: Place BuyLimit
      else if(button==EnumToString(BUTT_BUY_LIMIT))
        {
         //--- Get correct order placement relative to StopLevel
         double price_set=CorrectPricePending(Symbol(),ORDER_TYPE_BUY_LIMIT,distance_pending);
         //--- Get correct StopLoss and TakeProfit prices relative to the order placement level considering StopLevel
         double sl=CorrectStopLoss(Symbol(),ORDER_TYPE_BUY_LIMIT,price_set,stoploss);
         double tp=CorrectTakeProfit(Symbol(),ORDER_TYPE_BUY_LIMIT,price_set,takeprofit);
         //--- Set BuyLimit order
         engine.PlaceBuyLimit(lot,Symbol(),price_set,sl,tp,magic_number,TextByLanguage("Отложенный BuyLimit","Pending BuyLimit order"));
        }
      //--- If the BUTT_BUY_STOP button is pressed: Set BuyStop
      else if(button==EnumToString(BUTT_BUY_STOP))
        {
         //--- Get correct order placement relative to StopLevel
         double price_set=CorrectPricePending(Symbol(),ORDER_TYPE_BUY_STOP,distance_pending);
         //--- Get correct StopLoss and TakeProfit prices relative to the order placement level considering StopLevel
         double sl=CorrectStopLoss(Symbol(),ORDER_TYPE_BUY_STOP,price_set,stoploss);
         double tp=CorrectTakeProfit(Symbol(),ORDER_TYPE_BUY_STOP,price_set,takeprofit);
         //--- Set BuyStop order
         engine.PlaceBuyStop(lot,Symbol(),price_set,sl,tp,magic_number,TextByLanguage("Отложенный BuyStop","Pending BuyStop order"));
        }
      //--- If the BUTT_BUY_STOP_LIMIT button is pressed: Set BuyStopLimit
      else if(button==EnumToString(BUTT_BUY_STOP_LIMIT))
        {
         //--- Get the correct BuyStop order placement price relative to StopLevel
         double price_set_stop=CorrectPricePending(Symbol(),ORDER_TYPE_BUY_STOP,distance_pending);
         //--- Calculate BuyLimit order price relative to BuyStop level considering StopLevel
         double price_set_limit=CorrectPricePending(Symbol(),ORDER_TYPE_BUY_LIMIT,distance_stoplimit,price_set_stop);
         //--- Get correct StopLoss and TakeProfit prices relative to the order placement level considering StopLevel
         double sl=CorrectStopLoss(Symbol(),ORDER_TYPE_BUY_STOP,price_set_limit,stoploss);
         double tp=CorrectTakeProfit(Symbol(),ORDER_TYPE_BUY_STOP,price_set_limit,takeprofit);
         //--- Set BuyStopLimit order
         engine.PlaceBuyStopLimit(lot,Symbol(),price_set_stop,price_set_limit,sl,tp,magic_number,TextByLanguage("Отложенный BuyStopLimit","Pending BuyStopLimit order"));
        }
      //--- If the BUTT_SELL button is pressed: Open Sell position
      else if(button==EnumToString(BUTT_SELL))
        {
         //--- Get the correct StopLoss and TakeProfit prices relative to StopLevel
         double sl=CorrectStopLoss(Symbol(),ORDER_TYPE_SELL,0,stoploss);
         double tp=CorrectTakeProfit(Symbol(),ORDER_TYPE_SELL,0,takeprofit);
         //--- Open Sell position
         engine.OpenSell(lot,Symbol(),magic_number,sl,tp);  // No comment - the default comment is to be set
        }
      //--- If the BUTT_SELL_LIMIT button is pressed: Set SellLimit
      else if(button==EnumToString(BUTT_SELL_LIMIT))
        {
         //--- Get correct order placement relative to StopLevel
         double price_set=CorrectPricePending(Symbol(),ORDER_TYPE_SELL_LIMIT,distance_pending);
         //--- Get correct StopLoss and TakeProfit prices relative to the order placement level considering StopLevel
         double sl=CorrectStopLoss(Symbol(),ORDER_TYPE_SELL_LIMIT,price_set,stoploss);
         double tp=CorrectTakeProfit(Symbol(),ORDER_TYPE_SELL_LIMIT,price_set,takeprofit);
         //--- Set SellLimit order
         engine.PlaceSellLimit(lot,Symbol(),price_set,sl,tp,magic_number,TextByLanguage("Отложенный SellLimit","Pending SellLimit order"));
        }
      //--- If the BUTT_SELL_STOP button is pressed: Set SellStop
      else if(button==EnumToString(BUTT_SELL_STOP))
        {
         //--- Get correct order placement relative to StopLevel
         double price_set=CorrectPricePending(Symbol(),ORDER_TYPE_SELL_STOP,distance_pending);
         //--- Get correct StopLoss and TakeProfit prices relative to the order placement level considering StopLevel
         double sl=CorrectStopLoss(Symbol(),ORDER_TYPE_SELL_STOP,price_set,stoploss);
         double tp=CorrectTakeProfit(Symbol(),ORDER_TYPE_SELL_STOP,price_set,takeprofit);
         //--- Set SellStop order
         engine.PlaceSellStop(lot,Symbol(),price_set,sl,tp,magic_number,TextByLanguage("Отложенный SellStop","Pending SellStop order"));
        }
      //--- If the BUTT_SELL_STOP_LIMIT button is pressed: Set SellStopLimit
      else if(button==EnumToString(BUTT_SELL_STOP_LIMIT))
        {
         //--- Get the correct SellStop order price relative to StopLevel
         double price_set_stop=CorrectPricePending(Symbol(),ORDER_TYPE_SELL_STOP,distance_pending);
         //--- Calculate SellLimit order price relative to SellStop level considering StopLevel
         double price_set_limit=CorrectPricePending(Symbol(),ORDER_TYPE_SELL_LIMIT,distance_stoplimit,price_set_stop);
         //--- Get correct StopLoss and TakeProfit prices relative to the order placement level considering StopLevel
         double sl=CorrectStopLoss(Symbol(),ORDER_TYPE_SELL_STOP,price_set_limit,stoploss);
         double tp=CorrectTakeProfit(Symbol(),ORDER_TYPE_SELL_STOP,price_set_limit,takeprofit);
         //--- Set SellStopLimit order
         engine.PlaceSellStopLimit(lot,Symbol(),price_set_stop,price_set_limit,sl,tp,magic_number,TextByLanguage("Отложенный SellStopLimit","Pending SellStopLimit order"));
        }
      //--- If the BUTT_CLOSE_BUY button is pressed: Close Buy with the maximum profit
      else if(button==EnumToString(BUTT_CLOSE_BUY))
        {
         //--- Get the list of all open positions
         CArrayObj* list=engine.GetListMarketPosition();
         //--- Select only Buy positions from the list
         list=CSelect::ByOrderProperty(list,ORDER_PROP_TYPE,POSITION_TYPE_BUY,EQUAL);
         //--- Sort the list by profit considering commission and swap
         list.Sort(SORT_BY_ORDER_PROFIT_FULL);
         //--- Get the index of the Buy position with the maximum profit
         int index=CSelect::FindOrderMax(list,ORDER_PROP_PROFIT_FULL);
         if(index>WRONG_VALUE)
           {
            //--- Get the Buy position object and close a position by ticket
            COrder* position=list.At(index);
            if(position!=NULL)
               engine.ClosePosition((ulong)position.Ticket());
           }
        }
      //--- If the BUTT_CLOSE_BUY2 button is pressed: Close the half of the Buy with the maximum profit
      else if(button==EnumToString(BUTT_CLOSE_BUY2))
        {
         //--- Get the list of all open positions
         CArrayObj* list=engine.GetListMarketPosition();
         //--- Select only Buy positions from the list
         list=CSelect::ByOrderProperty(list,ORDER_PROP_TYPE,POSITION_TYPE_BUY,EQUAL);
         //--- Sort the list by profit considering commission and swap
         list.Sort(SORT_BY_ORDER_PROFIT_FULL);
         //--- Get the index of the Buy position with the maximum profit
         int index=CSelect::FindOrderMax(list,ORDER_PROP_PROFIT_FULL);
         if(index>WRONG_VALUE)
           {
            COrder* position=list.At(index);
            if(position!=NULL)
              {
               //--- If this is a hedge account, close the half of the Buy position by the ticket
               if(engine.IsHedge())
                  engine.ClosePositionPartially((ulong)position.Ticket(),position.Volume()/2.0);
               //--- If this is a netting account, open a Sell position with the half of the Buy position volume
               else
                 engine.OpenSell(NormalizeLot(position.Symbol(),position.Volume()/2.0),Symbol(),magic_number,position.StopLoss(),position.TakeProfit(),"Partial closure Buy #"+(string)position.Ticket());
              }
           }
        }
      //--- If the BUTT_CLOSE_BUY_BY_SELL button is pressed: Close Buy with the maximum profit by the opposite Sell with the maximum profit
      else if(button==EnumToString(BUTT_CLOSE_BUY_BY_SELL))
        {
         //--- In case of a hedging account
         if(engine.IsHedge())
           {
            //--- Get the list of all open positions
            CArrayObj* list_buy=engine.GetListMarketPosition();
            //--- Select only Buy positions from the list
            list_buy=CSelect::ByOrderProperty(list_buy,ORDER_PROP_TYPE,POSITION_TYPE_BUY,EQUAL);
            //--- Sort the list by profit considering commission and swap
            list_buy.Sort(SORT_BY_ORDER_PROFIT_FULL);
            //--- Get the index of the Buy position with the maximum profit
            int index_buy=CSelect::FindOrderMax(list_buy,ORDER_PROP_PROFIT_FULL);
            //--- Get the list of all open positions
            CArrayObj* list_sell=engine.GetListMarketPosition();
            //--- Select only Sell positions from the list
            list_sell=CSelect::ByOrderProperty(list_sell,ORDER_PROP_TYPE,POSITION_TYPE_SELL,EQUAL);
            //--- Sort the list by profit considering commission and swap
            list_sell.Sort(SORT_BY_ORDER_PROFIT_FULL);
            //--- Get the index of the Sell position with the maximum profit
            int index_sell=CSelect::FindOrderMax(list_sell,ORDER_PROP_PROFIT_FULL);
            if(index_buy>WRONG_VALUE && index_sell>WRONG_VALUE)
              {
               //--- Select the Buy position with the maximum profit
               COrder* position_buy=list_buy.At(index_buy);
               //--- Select the Sell position with the maximum profit
               COrder* position_sell=list_sell.At(index_sell);
               //--- Close the Buy position by the opposite Sell one
               if(position_buy!=NULL && position_sell!=NULL)
                  engine.ClosePositionBy((ulong)position_buy.Ticket(),(ulong)position_sell.Ticket());
              }
           }
        }
      //--- If the BUTT_CLOSE_SELL button is pressed: Close Sell with the maximum profit
      else if(button==EnumToString(BUTT_CLOSE_SELL))
        {
         //--- Get the list of all open positions
         CArrayObj* list=engine.GetListMarketPosition();
         //--- Select only Sell positions from the list
         list=CSelect::ByOrderProperty(list,ORDER_PROP_TYPE,POSITION_TYPE_SELL,EQUAL);
         //--- Sort the list by profit considering commission and swap
         list.Sort(SORT_BY_ORDER_PROFIT_FULL);
         //--- Get the index of the Sell position with the maximum profit
         int index=CSelect::FindOrderMax(list,ORDER_PROP_PROFIT_FULL);
         if(index>WRONG_VALUE)
           {
            //--- Get the Sell position object and close a position by ticket
            COrder* position=list.At(index);
            if(position!=NULL)
               engine.ClosePosition((ulong)position.Ticket());
           }
        }
      //--- If the BUTT_CLOSE_SELL2 button is pressed: Close the half of the Sell with the maximum profit
      else if(button==EnumToString(BUTT_CLOSE_SELL2))
        {
         //--- Get the list of all open positions
         CArrayObj* list=engine.GetListMarketPosition();
         //--- Select only Sell positions from the list
         list=CSelect::ByOrderProperty(list,ORDER_PROP_TYPE,POSITION_TYPE_SELL,EQUAL);
         //--- Sort the list by profit considering commission and swap
         list.Sort(SORT_BY_ORDER_PROFIT_FULL);
         //--- Get the index of the Sell position with the maximum profit
         int index=CSelect::FindOrderMax(list,ORDER_PROP_PROFIT_FULL);
         if(index>WRONG_VALUE)
           {
            COrder* position=list.At(index);
            if(position!=NULL)
              {
               //--- If this is a hedge account, close the half of the Sell position by the ticket
               if(engine.IsHedge())
                  engine.ClosePositionPartially((ulong)position.Ticket(),position.Volume()/2.0);
               //--- If this is a netting account, open a Buy position with the half of the Sell position volume
               else
                  engine.OpenBuy(NormalizeLot(position.Symbol(),position.Volume()/2.0),Symbol(),position.Magic(),position.StopLoss(),position.TakeProfit(),"Partial closure Buy #"+(string)position.Ticket());
              }
           }
        }
      //--- If the BUTT_CLOSE_SELL_BY_BUY button is pressed: Close Sell with the maximum profit by the opposite Buy with the maximum profit
      else if(button==EnumToString(BUTT_CLOSE_SELL_BY_BUY))
        {
         //--- Get the list of all open positions
         CArrayObj* list_sell=engine.GetListMarketPosition();
         //--- Select only Sell positions from the list
         list_sell=CSelect::ByOrderProperty(list_sell,ORDER_PROP_TYPE,POSITION_TYPE_SELL,EQUAL);
         //--- Sort the list by profit considering commission and swap
         list_sell.Sort(SORT_BY_ORDER_PROFIT_FULL);
         //--- Get the index of the Sell position with the maximum profit
         int index_sell=CSelect::FindOrderMax(list_sell,ORDER_PROP_PROFIT_FULL);
         //--- Get the list of all open positions
         CArrayObj* list_buy=engine.GetListMarketPosition();
         //--- Select only Buy positions from the list
         list_buy=CSelect::ByOrderProperty(list_buy,ORDER_PROP_TYPE,POSITION_TYPE_BUY,EQUAL);
         //--- Sort the list by profit considering commission and swap
         list_buy.Sort(SORT_BY_ORDER_PROFIT_FULL);
         //--- Get the index of the Buy position with the maximum profit
         int index_buy=CSelect::FindOrderMax(list_buy,ORDER_PROP_PROFIT_FULL);
         if(index_sell>WRONG_VALUE && index_buy>WRONG_VALUE)
           {
            //--- Select the Sell position with the maximum profit
            COrder* position_sell=list_sell.At(index_sell);
            //--- Select the Buy position with the maximum profit
            COrder* position_buy=list_buy.At(index_buy);
            if(position_sell!=NULL && position_buy!=NULL)
              {
               //--- Close the Sell position by the opposite Buy one
             engine.ClosePositionBy((ulong)position_sell.Ticket(),(ulong)position_buy.Ticket());
              }
           }
        }
      //--- If the BUTT_CLOSE_ALL is pressed: Close all positions starting with the one with the least profit
      else if(button==EnumToString(BUTT_CLOSE_ALL))
        {
         //--- Get the list of all open positions
         CArrayObj* list=engine.GetListMarketPosition();
         if(list!=NULL)
           {
            //--- Sort the list by profit considering commission and swap
            list.Sort(SORT_BY_ORDER_PROFIT_FULL);
            int total=list.Total();
            //--- In the loop from the position with the least profit
            for(int i=0;i<total;i++)
              {
               COrder* position=list.At(i);
               if(position==NULL)
                  continue;
               //--- close each position by its ticket
              trades[i].ClosePosition((ulong)position.Ticket());
              }
           }
        }
      //--- If the BUTT_DELETE_PENDING button is pressed: Remove the first pending order
      else if(button==EnumToString(BUTT_DELETE_PENDING))
        {
         //--- Get the list of all orders
         CArrayObj* list=engine.GetListMarketPendings();
         if(list!=NULL)
           {
            //--- Sort the list by placement time
            list.Sort(SORT_BY_ORDER_TIME_OPEN);
            int total=list.Total();
            //--- In the loop from the position with the most amount of time
            for(int i=total-1;i>=0;i--)
              {
               COrder* order=list.At(i);
               if(order==NULL)
                  continue;
               //--- delete the order by its ticket
               trades[i].DeleteOrder((ulong)order.Ticket());
              }
           }
        }
      //--- If the BUTT_PROFIT_WITHDRAWAL button is pressed: Withdraw funds from the account
      if(button==EnumToString(BUTT_PROFIT_WITHDRAWAL))
        {
         //--- If the program is launched in the tester
         if(MQLInfoInteger(MQL_TESTER))
           {
            //--- Emulate funds withdrawal
            int withdrawal=23;
            TesterWithdrawal(withdrawal);
           }
        }
      //--- If the BUTT_SET_STOP_LOSS button is pressed: Place StopLoss to all orders and positions where it is not present
      if(button==EnumToString(BUTT_SET_STOP_LOSS))
        {
       
        }
      //--- If the BUTT_SET_TAKE_PROFIT button is pressed: Place TakeProfit to all orders and positions where it is not present
      if(button==EnumToString(BUTT_SET_TAKE_PROFIT))
        {
         SetTakeProfit();
        }
      //--- Wait for 1/10 of a second
      Sleep(100);
      //--- "Unpress" the button (if this is not a trailing button)
      if(button!=EnumToString(BUTT_TRAILING_ALL))
         ButtonState(button_name,false);
      //--- If the BUTT_TRAILING_ALL button is pressed
      else
        {
         //--- Set the color of the active button
         ButtonState(button_name,true);
         trailing_on=true;
        }
      //--- re-draw the chart
      ChartRedraw();
     }
   //--- Return the inactive button color (if this is a trailing button)
   else if(button==EnumToString(BUTT_TRAILING_ALL))
     {
      ButtonState(button_name,false);
      trailing_on=false;
      //--- re-draw the chart
      ChartRedraw();
     }
  }
//+------------------------------------------------------------------+
//| Set StopLoss to all orders and positions                         |
//+------------------------------------------------------------------+
void SetStopLoss(void)
  {
   if(stoploss_to_modify==0)
      return;
//--- Set StopLoss to all positions where it is absent
   CArrayObj* list=engine.GetListMarketPosition();
   list=CSelect::ByOrderProperty(list,ORDER_PROP_SL,0,EQUAL);
   if(list==NULL)
      return;
   int total=list.Total();
   for(int i=total-1;i>=0;i--)
     {
      COrder* position=list.At(i);
      if(position==NULL)
         continue;
      double sl=CorrectStopLoss(position.Symbol(),position.TypeByDirection(),0,stoploss_to_modify);
      engine.ModifyPosition((ulong)position.Ticket(),sl,-1);
     }
//--- Set StopLoss to all pending orders where it is absent
   list=engine.GetListMarketPendings();
   list=CSelect::ByOrderProperty(list,ORDER_PROP_SL,0,EQUAL);
   if(list==NULL)
      return;
   total=list.Total();
   for(int i=total-1;i>=0;i--)
     {
      COrder* order=list.At(i);
      if(order==NULL)
         continue;
      double sl=CorrectStopLoss(order.Symbol(),(ENUM_ORDER_TYPE)order.TypeOrder(),order.PriceOpen(),stoploss_to_modify);
      engine.ModifyOrder((ulong)order.Ticket(),-1,sl,-1);
     }
  }
//+------------------------------------------------------------------+
//| Set TakeProfit to all orders and positions                       |
//+------------------------------------------------------------------+
void SetTakeProfit(void)
  {
   if(takeprofit_to_modify==0)
      return;
//--- Set TakeProfit to all positions where it is absent
   CArrayObj* list=engine.GetListMarketPosition();
   list=CSelect::ByOrderProperty(list,ORDER_PROP_TP,0,EQUAL);
   if(list==NULL)
      return;
   int total=list.Total();
   for(int i=total-1;i>=0;i--)
     {
      COrder* position=list.At(i);
      if(position==NULL)
         continue;
      double tp=CorrectTakeProfit(position.Symbol(),position.TypeByDirection(),0,takeprofit_to_modify);
      engine.ModifyPosition((ulong)position.Ticket(),-1,tp);
     }
//--- Set TakeProfit to all pending orders where it is absent
   list=engine.GetListMarketPendings();
   list=CSelect::ByOrderProperty(list,ORDER_PROP_TP,0,EQUAL);
   if(list==NULL)
      return;
   total=list.Total();
   for(int i=total-1;i>=0;i--)
     {
      COrder* order=list.At(i);
      if(order==NULL)
         continue;
      double tp=CorrectTakeProfit(order.Symbol(),(ENUM_ORDER_TYPE)order.TypeOrder(),order.PriceOpen(),takeprofit_to_modify);
      engine.ModifyOrder((ulong)order.Ticket(),-1,-1,tp);
     }
  }
//+------------------------------------------------------------------+
//|                             ClosePendingLimitOrders                                      |
//+------------------------------------------------------------------+
void ClosePendingLimitOrders(const string symbols)
  {
   for(int i=OrdersTotal(); i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS)&& OrderSymbol()==symbols)
        {
         if((OrderType() == ORDER_TYPE_BUY_LIMIT)||(OrderType()==ORDER_TYPE_SELL_LIMIT))
           {
           
               if(OrderMagicNumber() == MagicNumber)
                 {
                  if(OrderCloseTime() == 0)
                    {
                     if(!OrderDelete(i,clrYellow))
                       {
                        PrintFormat("Failed to delete order %d, error:%d",OrderTicket(),GetLastError());
                       }
                    }
                 }
              
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                              ClosePendingStopOrders                                    |
//+------------------------------------------------------------------+
void ClosePendingStopOrders(const string symbols)
  {
   for(int i=OrdersTotal(); i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS))
        {
         if((OrderType() == ORDER_TYPE_BUY_STOP)||(OrderType()==ORDER_TYPE_SELL_STOP))
           {
            if(OrderSymbol() == symbols)
              {
               if(OrderMagicNumber() == MagicNumber)
                 {
                  if(OrderCloseTime() == 0)
                    {
                     if(!OrderDelete(i,clrYellow))
                       {
                        PrintFormat("Failed to delete order %d, error:%d",OrderTicket(),GetLastError());
                       }
                    }
                 }
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                             CloseAllOrders                                      |
//+------------------------------------------------------------------+
void CloseAllOrders(const string symbols)
  {
   string symbol=symbols;
   for(int i=OrdersTotal(); i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS))
        {
         if(OrderSymbol() == symbols)
           {
            if(OrderMagicNumber() == MagicNumber)
              {
               if(OrderCloseTime() == 0)
                 {
                  switch(OrderType())
                    {
                     default:
                        break;
                     case ORDER_TYPE_BUY:
                     case ORDER_TYPE_SELL:
                       {
                        double price = (OrderType() == ORDER_TYPE_BUY ? SymbolInfoDouble(symbols,SYMBOL_BID) : SymbolInfoDouble(symbols,SYMBOL_ASK));
                        if(!OrderClose(i,OrderLots(),price,5,clrYellow))
                          {
                           PrintFormat("Failed to close order %d, error:%d",OrderTicket(),GetLastError());
                          }
                        break;

                       }
                     case ORDER_TYPE_BUY_LIMIT:
                     case ORDER_TYPE_BUY_STOP:
                     case ORDER_TYPE_SELL_LIMIT:
                     case ORDER_TYPE_SELL_STOP:
                       {
                        if(!OrderDelete(OrderTicket(),clrYellow))
                          {
                           PrintFormat("Failed to delete order %d, error:%d",OrderTicket(),GetLastError());
                          }
                        break;
                       }
                    }

                 }
              }
           }
        }
     }
  }
//----------------------------------------------------------------+
//| GetSetCoordinates                                                |
//+------------------------------------------------------------------+
CComment comments;

CNews mynews[100];
void GetSetCoordinates()
  {
//--

//--- check symbol selection buttons

   int y=50;
   if(ChartGetInteger(0,CHART_SHOW_ONE_CLICK))
      y=130;
   comments.Create("BotPanel",20,y);
   comments.SetColor(clrDimGray,clrBlue,220);
   string name;
   bool state;
   long lparam = 0;
   double dparam = 0;
   if(ShowTradedSymbols)
     {
      for(int s=0; s<NumOfSymbols; s++)
        {
         name = OBJPFX+"SGGS"+IntegerToString(s);
         state = ObjectGetInteger(ChartID(),name,OBJPROP_STATE);
         if(state)    //--- button is selected, check if symbol selected has changed
           {

            if(SymbolButtonSelected != s)    //--- trigger button event
              {
               OnChartEvent(CHARTEVENT_OBJECT_CLICK,lparam,dparam,name);
              }
           }
        }
     }
   if(inpTradeMode == Manual)    //--- Trade panel is created in manual mode only
     {
      if(ObjectFind(OBJPFX"Back")<0)//--- ObjectNotFound
        {
         ExpertName ="TradeExpert@"+Symbol();
         //-- GetXYValues (Saved)
         if(GlobalVariableGet(ExpertName+" - X")!=0 && GlobalVariableGet(ExpertName+" - Y")!=0)
           {
            startx=(int)GlobalVariableGet(ExpertName+" - X");
            starty=(int)GlobalVariableGet(ExpertName+" - Y");
           }
         //-- SetXYValues (Default)
         else
           {
            startx=CLIENT_BG_X;
            starty=CLIENT_BG_Y;
           }

         //-- CreateObject (Background)
         RectLabelCreate(0,OBJPFX"Back",0,startx,starty,panelwidth,panelheight,(C'80,80,80'),true,CORNER_LEFT_UPPER, clrChocolate,STYLE_SOLID,2,false,true)   ;
             ObjectSetInteger(0,OBJPFX"Back",OBJPROP_SELECTED,false);//UnselectObject
        }

      //-- GetCoordinates
      startx=(int)ObjectGetInteger(0,OBJPFX"Back",OBJPROP_XDISTANCE);
      starty=(int)ObjectGetInteger(0,OBJPFX"Back",OBJPROP_YDISTANCE);
      //--- close panel
      if(ObjectFind(OBJPFX"BackCP")<0)//--- ObjectNotFound
        {
         ExpertName = "TradeExpert@"+Symbol();
         //-- GetXYValues (Saved)
         if(GlobalVariableGet(ExpertName+" - XCP")!=0 && GlobalVariableGet(ExpertName+" - YCP")!=0)
           {
            startx_closepanel=(int)GlobalVariableGet(ExpertName+" - XCP");
            starty_closepanel=(int)GlobalVariableGet(ExpertName+" - YCP");
           }
         //-- SetXYValues (Default)
         else
           {
            startx_closepanel=CLIENT_BG_X+panelwidth+10;
            starty_closepanel=CLIENT_BG_Y;
           }

         //-- CreateObject (Background)
         RectLabelCreate(0,OBJPFX"BackCP",0,startx_closepanel,starty_closepanel,buttonwidth+10,40+MAX_CLOSE_BUTTONS*buttonheight,(C'72,72,72'),true,CORNER_LEFT_UPPER, clrWhite,STYLE_SOLID,2,false,true);
         ObjectSetInteger(0,OBJPFX"BackCP",OBJPROP_SELECTED,false);//UnselectObject
        }

      //-- GetCoordinates
      startx_closepanel=(int)ObjectGetInteger(0,OBJPFX"BackCP",OBJPROP_XDISTANCE);
      starty_closepanel=(int)ObjectGetInteger(0,OBJPFX"BackCP",OBJPROP_YDISTANCE);
     }
//--- symbol panel
   if(ShowTradedSymbols)
     {
      if(ObjectFind(OBJPFX"BackSP")<0)//--- ObjectNotFound
        {
       ExpertName = "TradeExpert@"+Symbol();
         //-- GetXYValues (Saved)
         if(GlobalVariableGet(ExpertName+" - XSP")!=0 && GlobalVariableGet(ExpertName+" - YSP")!=0)
           {
            startx_symbolpanel=(int)GlobalVariableGet(ExpertName+" - XSP");
            starty_symbolpanel=(int)GlobalVariableGet(ExpertName+" - YSP");
           }
         //-- SetXYValues (Default)
         else
           {
            startx_symbolpanel=CLIENT_BG_X;
            starty_symbolpanel=CLIENT_BG_Y+panelheight+10;
           }

         //-- CreateObject (Background): set the width to a button width and the height to a button heigth + toolbar size in order to be able to select the dashboard
         //--- without selecting a symbol
         int pw = (panelwidth/5)*(1 + (NumOfSymbols>=5 ? 4 : (NumOfSymbols % 5)-1));
         int ph = 10 + buttonheight*(1 + (NumOfSymbols>5 ? NumOfSymbols/5 : 0));

         RectLabelCreate(0,OBJPFX"BackSP",0,startx_symbolpanel,starty_symbolpanel,pw,ph,(C'72,72,72'),true,CORNER_LEFT_UPPER, clrWhite,STYLE_SOLID,2,false,true);
         ObjectSetString(ChartID(),OBJPFX"BackSP",OBJPROP_TEXT,"Symbol"+(NumOfSymbols>1 ? "s":""));
         ObjectSetInteger(0,OBJPFX"BackSP",OBJPROP_SELECTED,false);//UnselectObject
        }

      //-- GetCoordinates
      startx_symbolpanel=(int)ObjectGetInteger(0,OBJPFX"BackSP",OBJPROP_XDISTANCE);
      starty_symbolpanel=(int)ObjectGetInteger(0,OBJPFX"BackSP",OBJPROP_YDISTANCE);
     }
  }
//+------------------------------------------------------------------+
//|                     CreatePannel                                              |
//+------------------------------------------------------------------+
void CreatePannel()
  {
   if(inpTradeMode == Manual)    //--- Trade panel is created in manual mode only
     {
      RectLabelCreate(0,OBJPFX"top",0,startx,starty,panelwidth,30,(C'33,33,33'),true,CORNER_LEFT_UPPER,  clrWhite,STYLE_SOLID,2,false,false,true);

      LabelCreate(0,OBJPFX"indName",0,startx+5,starty+2,CORNER_LEFT_UPPER,"TradeExpert  Panel","Calibri",PanelFontSize,clrWhite,0);

      ButtonCreate(0,OBJPFX"btnSell",0,startx+5,starty+32,buttonwidth,buttonheight,CORNER_LEFT_UPPER,"Sell","Calibri",PanelFontSize,
                   clrWhite,clrRed,clrNONE,false,false,false,true,0);

      EditCreate(0,OBJPFX"editLot",0,startx+5+(buttonwidth),starty+32,buttonwidth,buttonheight,(string)TradeSize(InpMoneyManagement),"Calibri",PanelFontSize,ALIGN_CENTER,false, CORNER_LEFT_UPPER,clrWhite,clrGray,clrNONE,false,false,true,10);
      ButtonCreate(0,OBJPFX"btnBuy",0,startx+5+(buttonwidth*2),starty+32,buttonwidth,buttonheight,CORNER_LEFT_UPPER,"Buy","Calibri",PanelFontSize, clrWhite,clrLime,clrNONE,false,false,false,true,0);

      LabelCreate(0,OBJPFX"lblStop",0,startx+5,starty+2+(buttonheight*2),CORNER_LEFT_UPPER,"STOP","Calibri",PanelFontSize,clrWhite,0,ANCHOR_LEFT_UPPER,false,false,false,0);
      LabelCreate(0,OBJPFX"lblTP",0,startx+5+(buttonwidth),starty+2+(buttonheight*2),CORNER_LEFT_UPPER,"PROFIT","Calibri",PanelFontSize,clrWhite,0,ANCHOR_LEFT_UPPER,false,false,false,0);


      LabelCreate(0,OBJPFX"lblTN",0,startx+5+(buttonwidth*2),starty+2+(buttonheight*2),CORNER_LEFT_UPPER,"No. Of Trades","Calibri",PanelFontSize,clrWhite,0,ANCHOR_LEFT_UPPER,false,false,false,0);


      EditCreate(0,OBJPFX"editStop",0,startx+5,starty-10+(buttonheight*3),buttonwidth,buttonheight,(string)stoploss,"Calibri",PanelFontSize,ALIGN_CENTER,false,
                 CORNER_LEFT_UPPER,clrWhite,clrGray,clrNONE,false,false,true,10);
      EditCreate(0,OBJPFX"editTP",0,startx+5+(buttonwidth),starty-10+(buttonheight*3),buttonwidth,buttonheight,(string)takeprofit,"Calibri",PanelFontSize,ALIGN_CENTER,false,
                 CORNER_LEFT_UPPER,clrWhite,clrGray,clrNONE,false,false,true,10);

      EditCreate(0,OBJPFX"editTN",0,startx+5+(buttonwidth*2),starty-10+(buttonheight*3),buttonwidth,buttonheight,(string)MaxOpenTrades,"Calibri",PanelFontSize,ALIGN_CENTER,false,
                 CORNER_LEFT_UPPER,clrWhite,clrGray,clrNONE,false,false,true,10);

      ButtonCreate(0,OBJPFX"btnSS",0,startx+(int)5,starty-10+(buttonheight*4),(int)(buttonwidth*1.5),(int)buttonheight,CORNER_LEFT_UPPER,"Sell Stop","Calibri",PanelFontSize,
                   clrWhite,clrRed,clrNONE,false,false,false,true,0);
      ButtonCreate(0,OBJPFX"btnBS",0,startx+(int)5+(int)(buttonwidth*1.5),starty-10+(buttonheight*4),(int)(buttonwidth*1.5),buttonheight,CORNER_LEFT_UPPER,"But Stop","Calibri",PanelFontSize,
                   clrWhite,clrLime,clrNONE,false,false,false,true,0);

      ButtonCreate(0,OBJPFX"btnSL",0,startx+5,starty-10+(buttonheight*5),(int)(buttonwidth*1.5),buttonheight,CORNER_LEFT_UPPER,"Sell Limit","Calibri",PanelFontSize,
                   clrWhite,clrRed,clrNONE,false,false,false,true,0);
      ButtonCreate(0,OBJPFX"btnBL",0,startx+5+(int)(buttonwidth*1.5),starty-10+(buttonheight*5),(int)(buttonwidth*1.5),buttonheight,CORNER_LEFT_UPPER,"Buy Limit","Calibri",PanelFontSize,
                   clrWhite,clrLime,clrNONE,false,false,false,true,0);
     }
  }
  
 
//+--------------=----------------------------------------------------+
//|                      MovePannel                                            |
//+------------------------------------------------------------------+
void  MovePannel ()
  {
   if(inpTradeMode == Manual)    // Trade panel is created in manual mode only
     {
      RectLabelMove(0,OBJPFX"top",startx,starty);

      LabelMove(0,OBJPFX"indName",startx+5,starty+2);

      ButtonMove(0,OBJPFX"btnSell",startx+5,starty+32);

      EditMove(0,OBJPFX"editLot",startx+5+(buttonwidth),starty+32);
      ButtonMove(0,OBJPFX"btnBuy",startx+5+(buttonwidth*2),starty+32);

      LabelMove(0,OBJPFX"lblStop",startx+5,starty+2+(buttonheight*2));
      LabelMove(0,OBJPFX"lblTP",startx+5+(buttonwidth),starty+2+(buttonheight*2));

      LabelMove(0,OBJPFX"lblTN",startx+5+(buttonwidth*2),starty+2+(buttonheight*2));

      EditMove(0,OBJPFX"editStop",startx+5,starty-10+(buttonheight*3));
      EditMove(0,OBJPFX"editTP",startx+5+(buttonwidth),starty-10+(buttonheight*3));

      EditMove(0,OBJPFX"editTN",startx+5+(buttonwidth*2),starty-10+(buttonheight*3));

      ButtonMove(0,OBJPFX"btnSS",startx+(int)5,starty-10+(buttonheight*4));
      ButtonMove(0,OBJPFX"btnBS",startx+(int)5+(int)(buttonwidth*1.5),starty-10+(buttonheight*4));

      ButtonMove(0,OBJPFX"btnSL",startx+5,starty-10+(buttonheight*5));
      ButtonMove(0,OBJPFX"btnBL",startx+5+(int)(buttonwidth*1.5),starty-10+(buttonheight*5));
     }
  }



//+------------------------------------------------------------------+
//| GetSetInputs                                                     |
//+------------------------------------------------------------------+
void GetSetInputs()
  {
//--
  }



void OnChartEventTesting()
  {
//--- check symbol selection buttons
   ENUM_ORDER_TYPE op_type;
   int y=40;
   if(ChartGetInteger(0,CHART_SHOW_ONE_CLICK))
      y=120;
   comments.Create("BotPanel",20,y);
   comments.SetColor(clrDimGray,clrGreen,220);
   string name;
   bool state;
   long lparam = 0;
   double dparam = 0;
   if(ShowTradedSymbols)
     {
      for(int s=0; s<NumOfSymbols; s++)
        {
         name = OBJPFX+"SGGS"+IntegerToString(s);
         state = ObjectGetInteger(ChartID(),name,OBJPROP_STATE);
         if(state)    //--- button is selected, check if symbol selected has changed
           {

            if(SymbolButtonSelected != s)    //--- trigger button event
              {


               OnChartEvent(CHARTEVENT_OBJECT_CLICK,lparam,dparam,name);
              }
           }
        }
     }
   if(inpTradeMode == Manual)    //--- Trade panel is created in manual mode only
     {
      //--- check buy / sell buttons
      name = OBJPFX"btnSell";
      state = ObjectGetInteger(ChartID(),name,OBJPROP_STATE);
      if(state)
        {
         op_type=OP_SELL;
         OnChartEvent(CHARTEVENT_OBJECT_CLICK,lparam,dparam,name);
        }
      name = OBJPFX"btnBuy";
      state = ObjectGetInteger(ChartID(),name,OBJPROP_STATE);
      if(state)
        {
         op_type=OP_BUY;
         OnChartEvent(CHARTEVENT_OBJECT_CLICK,lparam,dparam,name);
        }
      name = OBJPFX"btnSS";
      state = ObjectGetInteger(ChartID(),name,OBJPROP_STATE);
      if(state)
        {
         op_type=OP_SELLLIMIT;
         OnChartEvent(CHARTEVENT_OBJECT_CLICK,lparam,dparam,name);
        }
      name = OBJPFX"btnBS";
      state = ObjectGetInteger(ChartID(),name,OBJPROP_STATE);
      if(state)
        {
         op_type=OP_SELLSTOP;
         OnChartEvent(CHARTEVENT_OBJECT_CLICK,lparam,dparam,name);
        }
      name = OBJPFX"btnSL";
      state = ObjectGetInteger(ChartID(),name,OBJPROP_STATE);
      if(state)
        {
         op_type=OP_BUYSTOP;
         OnChartEvent(CHARTEVENT_OBJECT_CLICK,lparam,dparam,name);
        }
      name = OBJPFX"btnBL";
      state = ObjectGetInteger(ChartID(),name,OBJPROP_STATE);
      if(state)
        {
         op_type=OP_BUYLIMIT;
         OnChartEvent(CHARTEVENT_OBJECT_CLICK,lparam,dparam,name);
        }

      //--- close panel
      for(int i=0; i<MAX_CLOSE_BUTTONS; i++)
        {
         name = OBJPFX+CloseButtonNames[i];
         state = ObjectGetInteger(ChartID(),name,OBJPROP_STATE);
         if(state)
           {
            OnChartEvent(CHARTEVENT_OBJECT_CLICK,lparam,dparam,name);
           }
        }

     }
  }
 void MoveClosePanel()
  {
   if(inpTradeMode == Manual)    //--- Close panel is created in manual mode only
     {
      RectLabelMove(0,OBJPFX"CPTop",startx_closepanel,starty_closepanel);

      LabelMove(0,OBJPFX"CPTitle",startx_closepanel+5,starty_closepanel+2);

      ButtonMove(0,OBJPFX"CPCloseBuy",startx_closepanel+5,starty_closepanel+32);
      ButtonMove(0,OBJPFX"CPCloseSell",startx_closepanel+5,starty_closepanel+32+(1*buttonheight));
      ButtonMove(0,OBJPFX"CPCloseProfit",startx_closepanel+5,starty_closepanel+32+(2*buttonheight));
      ButtonMove(0,OBJPFX"CPCloseLoss",startx_closepanel+5,starty_closepanel+32+(3*buttonheight));
      ButtonMove(0,OBJPFX"CPCloseLimit",startx_closepanel+5,starty_closepanel+32+(4*buttonheight));
      ButtonMove(0,OBJPFX"CPCloseStop",startx_closepanel+5,starty_closepanel+32+(5*buttonheight));
      ButtonMove(0,OBJPFX"CPCloseAll",startx_closepanel+5,starty_closepanel+32+(6*buttonheight));

     }
  }

//--- GUI
//+------------------------------------------------------------------+
//| OnTester                                                         |
//+------------------------------------------------------------------+
void _OnTester()
  {
//--- CheckObjects
   OnChartEventTesting();

//-- GetSetUserInputs
   GetSetInputs();

//-- MoveClient
   bool coordinates_set = false;
   if(inpTradeMode == Manual)    //--- Trade panel is created in manual mode only
     {
      if(ObjectFind(0,OBJPFX"Back")==IndicatorSubWindow)//ObjectIsPresent
        {
         //-- GetCurrentPos
         int bg_x=(int)ObjectGetInteger(0,OBJPFX"Back",OBJPROP_XDISTANCE);
         int bg_y=(int)ObjectGetInteger(0,OBJPFX"Back",OBJPROP_YDISTANCE);
         //-- MoveObjects
         if(bg_x!=startx || bg_y!=starty)
           {
            GetSetCoordinates();
            MovePannel();
            coordinates_set = true;
           }
        }
      //--- Move close panel
      if(ObjectFind(0,OBJPFX"BackCP")==IndicatorSubWindow)//ObjectIsPresent
        {
         //-- GetCurrentPos
         int bg_x=(int)ObjectGetInteger(0,OBJPFX"BackCP",OBJPROP_XDISTANCE);
         int bg_y=(int)ObjectGetInteger(0,OBJPFX"BackCP",OBJPROP_YDISTANCE);
         //-- MoveObjects
         if(bg_x!=startx_closepanel || bg_y!=starty_closepanel)
           {
            if(!coordinates_set)
               GetSetCoordinates();
            MoveClosePanel();
            coordinates_set = true;
           }
        }
     }
//--- move symbol panel
   if(ObjectFind(0,OBJPFX"BackSP")==IndicatorSubWindow)//ObjectIsPresent
     {
      //-- GetCurrentPos
      int bg_x=(int)ObjectGetInteger(0,OBJPFX"BackSP",OBJPROP_XDISTANCE);
      int bg_y=(int)ObjectGetInteger(0,OBJPFX"BackSP",OBJPROP_YDISTANCE);
      //-- MoveObjects
      if(bg_x!=startx_symbolpanel || bg_y!=starty_symbolpanel)
        {
         if(!coordinates_set)
            GetSetCoordinates();
         MoveSymbolPanel();
         coordinates_set = true;
        }
     }
//---
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MoveSymbolPanel()
  {
   int x =0;
   int y =0;
   for(int j=0; j<NumOfSymbols; j++)
     {
      //--- Creation of GUI buttons
      ButtonMove(0,OBJPFX"SGGS"+(string)j,startx_symbolpanel+x,starty_symbolpanel+y+10);
      x+=(panelwidth/5);
      if(x>=panelwidth)
        {
         x=0;
         y+= buttonheight;
        }
     }
  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
//---
   _OnTester();
   double ret=0.0;
//---

//---
   return(ret);
  }

void DelteMinWindow()
  {
//---
   ObjectDelete(0, OBJPREFIX+"MIN"+"BCKGRND[]");
   ObjectDelete(0, OBJPREFIX+"MIN"+"CAPTION");
   ObjectDelete(0, OBJPREFIX+"MIN"+"MAXIMIZE");
//---
  }

//+------------------------------------------------------------------+
//| UpdateSymbolGUI                                                  |
//+------------------------------------------------------------------+
void ObjectsUpdateAll(string _Symb)
  {
//--- Market info
   double bid = SymbolInfoDouble(_Symb, SYMBOL_BID),
          ask = SymbolInfoDouble(_Symb, SYMBOL_ASK),
          avg = (ask+bid)/2;
//---
   double TFHigh = iHigh(_Symb, PERIOD_CURRENT, 0),
          TFLow = iLow(_Symb, PERIOD_CURRENT, 0),
          TFOpen = iOpen(_Symb, PERIOD_CURRENT, 0);
//---
   double TFLastHigh = iHigh(_Symb, PERIOD_CURRENT, 1),
          TFLastLow = iLow(_Symb, PERIOD_CURRENT, 1),
          TFLastClose = iClose(_Symb, PERIOD_CURRENT, 1);
//---
   long Spread = SymbolInfoInteger(_Symb, SYMBOL_SPREAD);
  int digits = (int)SymbolInfoInteger(_Symb, SYMBOL_DIGITS);

//--- Range
   double pts = SymbolInfoDouble(_Symb, SYMBOL_POINT);

  }

//
  
//+------------------------------------------------------------------+
//|                       CreateClosePanel                                           |
//+------------------------------------------------------------------+
void CreateClosePanel()
  {
   if(inpTradeMode == Manual)    //--- Close panel is created in manual mode only
     {
      RectLabelCreate(0,OBJPFX"CPTop",0,startx_closepanel,starty_closepanel,buttonwidth+10,30,(C'33,33,33'),true,CORNER_LEFT_UPPER, clrWhite,STYLE_SOLID,2,false,false);

      LabelCreate(0,OBJPFX"CPTitle",0,startx_closepanel+5,starty_closepanel+2,CORNER_LEFT_UPPER,"Close Panel","Calibri",PanelFontSize,clrWhite,0,ANCHOR_LEFT_UPPER,false,false,false,0);

      ButtonCreate(0,OBJPFX"CPCloseBuy",0,startx_closepanel+5,starty_closepanel+32,buttonwidth,buttonheight,CORNER_LEFT_UPPER,"Close Buy","Calibri",PanelFontSize,clrWhite,clrRed,clrNONE,false,false,false,true,0);
      ButtonCreate(0,OBJPFX"CPCloseSell",0,startx_closepanel+5,starty_closepanel+32+(1*buttonheight),buttonwidth,buttonheight,CORNER_LEFT_UPPER,"Close Sell","Calibri",PanelFontSize,clrWhite,clrRed,clrNONE,false,false,false,true,0);
      ButtonCreate(0,OBJPFX"CPCloseProfit",0,startx_closepanel+5,starty_closepanel+32+(2*buttonheight),buttonwidth,buttonheight,CORNER_LEFT_UPPER,"Close Profit","Calibri",PanelFontSize,clrWhite,clrRed,clrNONE,false,false,false,true,0);
      ButtonCreate(0,OBJPFX"CPCloseLoss",0,startx_closepanel+5,starty_closepanel+32+(3*buttonheight),buttonwidth,buttonheight,CORNER_LEFT_UPPER,"Close Loss","Calibri",PanelFontSize,clrWhite,clrRed,clrNONE,false,false,false,true,0);
      ButtonCreate(0,OBJPFX"CPCloseLimit",0,startx_closepanel+5,starty_closepanel+32+(4*buttonheight),buttonwidth,buttonheight,CORNER_LEFT_UPPER,"Close Pend. Limit","Calibri",PanelFontSize,clrWhite,clrRed,clrNONE,false,false,false,true,0);
      ButtonCreate(0,OBJPFX"CPCloseStop",0,startx_closepanel+5,starty_closepanel+32+(5*buttonheight),buttonwidth,buttonheight,CORNER_LEFT_UPPER,"Close Pend. Stop","Calibri",PanelFontSize,clrWhite,clrRed,clrNONE,false,false,false,true,0);
      ButtonCreate(0,OBJPFX"CPCloseAll",0,startx_closepanel+5,starty_closepanel+32+(6*buttonheight),buttonwidth,buttonheight,CORNER_LEFT_UPPER,"Clear All Positions","Calibri",PanelFontSize,clrWhite,clrRed,clrNONE,false,false,false,true,0);

     }
  }
  string _AccountCurrency()
  {
//---
   string txt = "";
//---
   if(AccountInfoString(ACCOUNT_CURRENCY) == "AUD")
      txt = "$";
//---
   if(AccountInfoString(ACCOUNT_CURRENCY) == "BGN")
      txt = "B";
//---
   if(AccountInfoString(ACCOUNT_CURRENCY) == "CAD")
      txt = "$";
//---
   if(AccountInfoString(ACCOUNT_CURRENCY) == "CHF")
      txt = "F";
//---
   if(AccountInfoString(ACCOUNT_CURRENCY) == "COP")
      txt = "$";
//---
   if(AccountInfoString(ACCOUNT_CURRENCY) == "CRC")
      txt = "₡";
//---
   if(AccountInfoString(ACCOUNT_CURRENCY) == "CUP")
      txt = "₱";
//---
   if(AccountInfoString(ACCOUNT_CURRENCY) == "CZK")
      txt = "K";
//---
   if(AccountInfoString(ACCOUNT_CURRENCY) == "EUR")
      txt = "€";
//---
   if(AccountInfoString(ACCOUNT_CURRENCY) == "GBP")
      txt = "£";
//---
   if(AccountInfoString(ACCOUNT_CURRENCY) == "GHS")
      txt = "¢";
//---
   if(AccountInfoString(ACCOUNT_CURRENCY) == "HKD")
      txt = "$";
//---
   if(AccountInfoString(ACCOUNT_CURRENCY) == "JPY")
      txt = "¥";
//---
   if(AccountInfoString(ACCOUNT_CURRENCY) == "NGN")
      txt = "₦";
//---
   if(AccountInfoString(ACCOUNT_CURRENCY) == "NOK")
      txt = "k";
//---
   if(AccountInfoString(ACCOUNT_CURRENCY) == "NZD")
      txt = "$";
//---
   if(AccountInfoString(ACCOUNT_CURRENCY) == "USD")
      txt = "$";
//---
   if(AccountInfoString(ACCOUNT_CURRENCY) == "RUB")
      txt = "₽";
//---
   if(AccountInfoString(ACCOUNT_CURRENCY) == "SGD")
      txt = "$";
//---
   if(AccountInfoString(ACCOUNT_CURRENCY) == "ZAR")
      txt = "R";
//---
   if(AccountInfoString(ACCOUNT_CURRENCY) == "SEK")
      txt = "k";
//---
   if(AccountInfoString(ACCOUNT_CURRENCY) == "VND")
      txt = "₫";
//---
   if(txt == "")
      txt = "$";
//---
   return(txt);
  }
  //+------------------------------------------------------------------+
//| SymbolFind                                                       |
//+------------------------------------------------------------------+
bool SymbolFind(const string _Symb, int mode)
  {
//---
   bool result = false;
//---
   for(int i = 0; i < SymbolsTotal(mode); i++)
     {
      //---
      if(_Symb == SymbolName(i, mode))
        {
         result = true; //SymbolFound
         break;
        }
     }
//---
   return(result);
  }
  

//+------------------------------------------------------------------+
//| GetSetInputsA                                                    |
//+------------------------------------------------------------------+
void GetSetInputsA()
  {
//---
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);

  }


   
   int Signal0(string sym){ return 0;};  
   int Signal1(string sym){ return 0;};
           int Signal2(string sym){ return 0;};
           int Signal3(string sym){ return 0;};
         int pointx=(int)MarketInfo(_Symbol,MODE_POINT);
         
         
         
         
         
         
//+------------------------------------------------------------------+
//| GetParam                                                         |
//+------------------------------------------------------------------+
void GetParam(string p)
  {
//---
   if(p == OBJPREFIX+" ")
     {
      //---
      double pVal = TerminalInfoInteger(TERMINAL_PING_LAST);
      //---
      MessageBox
      (
         //---
         dString("99A6D43B833CB976021189ABAEEACF5D")+AccountInfoString(ACCOUNT_NAME)
         +"\n"+
         dString("47D4F60E4272BE70FB300EB05BD2AEC9")+IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN))
         +"\n"+
         dString("83744D48C2D63F90DD2F812DBB5CFC0C")+IntegerToString(AccountInfoInteger(ACCOUNT_LEVERAGE))
         +"\n\n"+
         //---
         dString("B001C36F24DDD87AFB300EB05BD2AEC9")+AccountInfoString(ACCOUNT_COMPANY)
         +"\n"+
         dString("808FEF727352434E021189ABAEEACF5D")+AccountInfoString(ACCOUNT_SERVER)
         +"\n"+
         dString("70FA849373E41928")+DoubleToString(pVal/1000, 2)+dString("CDB9155CB6080FC4")
         +"\n\n"+
         //---
         dString("47EFF8FADDDA4F05FB300EB05BD2AEC9")+dString("97BA10D5D76C54AE")
         +"\n\n"+
         "Author: "+"PR NOEL M NGUEMECHIEU"
         +"\n\n"+
         "www.YousufMesalm.com"
         +"\n\n"+
        (string)0
         //---, MB_CAPTION, MB_ICONINFORMATION|MB_OK
      );
     }
//---
  }
  

//+------------------------------------------------------------------+
//| ObjectsCreateAll                                                 |
//+------------------------------------------------------------------+
void ObjectsCreateAll()
  {
//---
   int fr_y2 = Dpi(100);
//---
   for(int i = 0; i <NumOfSymbols; i++)
     {
      //---
      if(SelectedMode == FULL)
         fr_y2 += Dpi(25);
      //---
      if(SelectedMode == COMPACT)  fr_y2 += Dpi(21);
      //---
      if(SelectedMode == MINI)fr_y2 += Dpi(17);
     
//---
   int x = (Dpi(20));
   int y = (40);
//---
   int height = fr_y2+Dpi(3);
//---
   
    
   RectLabelCreate(0, OBJPREFIX+"BCKGRND[]", 0, x, y, Dpi(CLIENT_BG_WIDTH), height, COLOR_BG, BORDER_FLAT, CORNER_LEFT_UPPER, COLOR_BORDER, STYLE_SOLID, 1, false, true);
//---
   _x1 = (int)ObjectGetInteger(0, OBJPREFIX+"BCKGRND[]", OBJPROP_XDISTANCE);
   _y1 = (int)ObjectGetInteger(0, OBJPREFIX+"BCKGRND[]", OBJPROP_YDISTANCE);
//---
   RectLabelCreate(0, OBJPREFIX+"BORDER[]", 0, x, y, Dpi(CLIENT_BG_WIDTH), Dpi(INDENT_TOP), COLOR_BORDER, BORDER_FLAT, CORNER_LEFT_UPPER, COLOR_BORDER, STYLE_SOLID, 1, false,true);
//---
   LabelCreate(0, OBJPREFIX+"CAPTION", 0, _x1+(Dpi(CLIENT_BG_WIDTH)/2)-Dpi(16), _y1, CORNER_LEFT_UPPER, ExpertName, "Arial Black", 9, C'59, 41, 40', 0, ANCHOR_UPPER, false, false,1, true);
//---
   LabelCreate(0, OBJPREFIX+"EXIT", 0, (_x1+Dpi(CLIENT_BG_WIDTH))-Dpi(10), _y1-Dpi(2), CORNER_LEFT_UPPER, "r", "Webdings", 10, C'59, 41, 40', 0, ANCHOR_UPPER, false, false, true,true);
//---
   LabelCreate(0, OBJPREFIX+"MINIMIZE", 0, (_x1+Dpi(CLIENT_BG_WIDTH))-Dpi(30), _y1-Dpi(2), CORNER_LEFT_UPPER, "2", "Webdings", 10, C'59, 41, 40', 0, ANCHOR_UPPER, false, false, true );
//---
   LabelCreate(0, OBJPREFIX+" ", 0, (_x1+Dpi(CLIENT_BG_WIDTH))-Dpi(50), _y1-Dpi(2), CORNER_LEFT_UPPER, "s", "Webdings", 10, C'59, 41, 40', 0, ANCHOR_UPPER, false, false, true);
//---
   LabelCreate(0, OBJPREFIX+"TIME", 0, (_x1+Dpi(CLIENT_BG_WIDTH))-Dpi(85), _y1+Dpi(1), CORNER_LEFT_UPPER, TimeToString(TimeLocal(), TIME_SECONDS), "Tahoma", 8, C'59, 41, 40', 0, ANCHOR_UPPER, false, false, true);
   LabelCreate(0, OBJPREFIX+"TIME§", 0, (_x1+Dpi(CLIENT_BG_WIDTH))-Dpi(120), _y1, CORNER_LEFT_UPPER, "Â", "Wingdings", 12, C'59, 41, 40', 0, ANCHOR_UPPER, false, false, true);
//---
   LabelCreate(0, OBJPREFIX+"CONNECTION", 0, _x1+Dpi(15), _y1-Dpi(2), CORNER_LEFT_UPPER, "ü", "Webdings", 10, C'59, 41, 40', 0, ANCHOR_UPPER, false, false, true);
//---
   LabelCreate(0, OBJPREFIX+"THEME", 0, _x1+Dpi(40), _y1-Dpi(4), CORNER_LEFT_UPPER, "N", "Webdings", 15, C'59, 41, 40', 0, ANCHOR_UPPER, false, false, true);
//---
   LabelCreate(0, OBJPREFIX+"TEMPLATE", 0, _x1+Dpi(65), _y1-Dpi(2), CORNER_LEFT_UPPER, "+", "Webdings", 12, C'59, 41, 40', 0, ANCHOR_UPPER, false, false, true);
//---
   int middle = Dpi(CLIENT_BG_WIDTH/2);
//---
   LabelCreate(0, OBJPREFIX+"STATUS", 0, _x1+middle+(middle/2), _y1+Dpi(8), CORNER_LEFT_UPPER, "\n", "Wingdings", 10, C'59, 41, 40', 0, ANCHOR_LEFT, false, false, true);
//---
   LabelCreate(0, OBJPREFIX+"STATUS«", 0, _x1+middle+(middle/2)+Dpi(15), _y1+Dpi(8), CORNER_LEFT_UPPER, "\n", sFontType, 8, C'59, 41, 40', 0, ANCHOR_LEFT, false, false, true);
//---
   LabelCreate(0, OBJPREFIX+"SOUND", 0, _x1+Dpi(90), _y1-Dpi(2), CORNER_LEFT_UPPER, "X", "Webdings", 12, C'59, 41, 40', 0, ANCHOR_UPPER, false, false, true);
//---
   color soundclr = SoundIsEnabled?C'59,41,40': clrNONE;
//---
   LabelCreate(0, OBJPREFIX+"SOUNDIO", 0, _x1+Dpi(100), _y1-Dpi(1), CORNER_LEFT_UPPER, "ð", "Webdings", 10, soundclr, 0, ANCHOR_UPPER, false, false, true);
//---
   LabelCreate(0, OBJPREFIX+"ALARM", 0, _x1+Dpi(115), _y1-Dpi(1), CORNER_LEFT_UPPER, "%", "Wingdings", 12, C'59, 41, 40', 0, ANCHOR_UPPER, false, false, true);
//---
   color alarmclr = AlarmIsEnabled?clrNONE: C'59,41,40';
//---

//---
   LabelCreate(0, OBJPREFIX+"ALARMIO", 0, _x1+Dpi(115), _y1-Dpi(6), CORNER_LEFT_UPPER, "x", sFontType, 16, alarmclr, 0, ANCHOR_UPPER, false, false, true);
//---
   int csm_fr_x1 = _x1+Dpi(50);
   int csm_fr_x2 = _x1+Dpi(95);
   int csm_fr_x3 = _x1+Dpi(137);
   int csm_dist_b = Dpi(150);
//---

   LabelCreate(0, OBJPREFIX+"BALANCE«", 0, _x1+Dpi(200), _y1+Dpi(8), CORNER_LEFT_UPPER,"Balance",sFontType, 8, C'59, 41, 40', 0, ANCHOR_CENTER, false, false, true);
   LabelCreate(0, OBJPREFIX+"Pairs", 0, _x1+Dpi(100), _y1+Dpi(300), CORNER_LEFT_UPPER, "Pairs", "Arial Black", 12, COLOR_FONT, 0, ANCHOR_LEFT, false, false, true);
   LabelCreate(0, OBJPREFIX+"Master", 0, _x1+Dpi(100), _y1+Dpi(30), CORNER_LEFT_UPPER, "Master", "Arial Black", 10, COLOR_FONT, 0, ANCHOR_LEFT, false, false, true );
   LabelCreate(0, OBJPREFIX+"slave 1", 0, _x1+Dpi(200), _y1+Dpi(30), CORNER_LEFT_UPPER, "Slave 1", "Arial Black", 10, COLOR_FONT, 0, ANCHOR_LEFT, false, false, true);
   LabelCreate(0, OBJPREFIX+"slave 2", 0, _x1+Dpi(300), _y1+Dpi(30), CORNER_LEFT_UPPER, "Slave 2", "Arial Black", 10, COLOR_FONT, 0, ANCHOR_LEFT, false, false, true);
   LabelCreate(0, OBJPREFIX+"slave 3", 0, _x1+Dpi(400), _y1+Dpi(30), CORNER_LEFT_UPPER, "Slave 3", "Arial Black", 10, COLOR_FONT, 0, ANCHOR_LEFT, false, false, true);
   LabelCreate(0, OBJPREFIX+"Master Exit ", 0, _x1+Dpi(500), _y1+Dpi(30), CORNER_LEFT_UPPER, "Master Exit", "Arial Black", 10, COLOR_FONT, 0, ANCHOR_LEFT, false, false, true);
   LabelCreate(0, OBJPREFIX+"Exit 1", 0, _x1+Dpi(600), _y1+Dpi(30), CORNER_LEFT_UPPER, "Exit 1", "Arial Black", 12, COLOR_FONT, 0, ANCHOR_LEFT, false, false, true);
    LabelCreate(0, OBJPREFIX+"Exit 2", 0, _x1+Dpi(700), _y1+Dpi(30), CORNER_LEFT_UPPER, "Exit 2", "Arial Black", 10, COLOR_FONT, 0, ANCHOR_LEFT, false, false, true);
   LabelCreate(0, OBJPREFIX+"Exit 3", 0, _x1+Dpi(800), _y1+Dpi(30), CORNER_LEFT_UPPER, "Exit 3", "Arial Black", 10, COLOR_FONT, 0, ANCHOR_LEFT, false, false, true);
 

   LabelCreate(0, OBJPREFIX+"M", 0, _x1+Dpi(100), _y1+Dpi(45), CORNER_LEFT_UPPER, (inpInd0=="")?"None": (string) MasterSignal[i]+"["+(string)inpTF0+"]", "Arial Black", 8, COLOR_FONT, 0, ANCHOR_LEFT, false, false, true);
   LabelCreate(0, OBJPREFIX+"s 1", 0, _x1+Dpi(200), _y1+Dpi(45), CORNER_LEFT_UPPER,(inpInd1=="")?"None": (string) Signal1[i]+"["+(string)inpTF1+"]", "Arial Black", 8, COLOR_FONT, 0, ANCHOR_LEFT, false, false, true);
   LabelCreate(0, OBJPREFIX+"s 2", 0, _x1+Dpi(300), _y1+Dpi(45), CORNER_LEFT_UPPER,(inpInd2=="")?"None":(string) Signal2[i]+"["+(string)inpTF2+"]", "Arial Black", 8, COLOR_FONT, 0, ANCHOR_LEFT, false, false, true);
   LabelCreate(0, OBJPREFIX+"s 3", 0, _x1+Dpi(400), _y1+Dpi(45), CORNER_LEFT_UPPER, (inpInd3=="")?"None":(string)Signal3[i]+"["+(string)inpTF3+"]", "Arial Black", 8, COLOR_FONT, 0, ANCHOR_LEFT, false, false, true);
   LabelCreate(0, OBJPREFIX+"e 1", 0, _x1+Dpi(500), _y1+Dpi(45), CORNER_LEFT_UPPER,(inpInd1Ex=="")?"None": (string)ExitSignal0[i]+"["+(string)inpTF0Ex+"]", "Arial Black", 8, COLOR_FONT, 0, ANCHOR_LEFT, false, false, true);
   LabelCreate(0, OBJPREFIX+"e 2", 0, _x1+Dpi(600), _y1+Dpi(45), CORNER_LEFT_UPPER,(inpInd1Ex=="")?"None":(string)ExitSignal1[i]+"["+(string)inpTF1Ex+"]", "Arial Black", 8, COLOR_FONT, 0, ANCHOR_LEFT, false, false, true);
   LabelCreate(0, OBJPREFIX+"e 3", 0, _x1+Dpi(700), _y1+Dpi(45), CORNER_LEFT_UPPER,(inpInd2Ex=="")?"None": (string)ExitSignal2[i]+"["+(string)inpTF2Ex+"]", "Arial Black", 8, COLOR_FONT, 0, ANCHOR_LEFT, false, false, true);
   LabelCreate(0, OBJPREFIX+"e 4", 0, _x1+Dpi(800), _y1+Dpi(45), CORNER_LEFT_UPPER,(inpInd3Ex=="")?"None":(string)ExitSignal3[i]+"["+(string)inpTF3Ex+"]", "Arial Black", 8, COLOR_FONT, 0, ANCHOR_LEFT, false, false, true);

  

//--- SymbolsGUI
   int fr_y = _y1+Dpi(60);

//---
 
      //---
      CreateSymbGUI(i, fr_y);
      //---
      if(SelectedMode == FULL)
         fr_y += Dpi(25);
      //---
      if(SelectedMode == COMPACT)
         fr_y += Dpi(21);
      //---
      if(SelectedMode == MINI)
         fr_y += Dpi(17);
     }
  }
  
  
//+------------------------------------------------------------------+
//|  ChartSetColor                                                   |
//+------------------------------------------------------------------+
void ChartSetColor(const int Type)
  {
//--- Set Light
   if(Type == 0)
     {
      ChartSetInteger(0, CHART_COLOR_BACKGROUND, COLOR_CBG_LIGHT);
      ChartSetInteger(0, CHART_COLOR_FOREGROUND, COLOR_FONT);
      ChartSetInteger(0, CHART_COLOR_GRID, clrNONE);
      ChartSetInteger(0, CHART_COLOR_CHART_UP, COLOR_CBG_LIGHT);
      ChartSetInteger(0, CHART_COLOR_CHART_DOWN, COLOR_CBG_LIGHT);
      ChartSetInteger(0, CHART_COLOR_CANDLE_BULL, COLOR_CBG_LIGHT);
      ChartSetInteger(0, CHART_COLOR_CANDLE_BEAR, COLOR_CBG_LIGHT);
      ChartSetInteger(0, CHART_COLOR_CHART_LINE, COLOR_CBG_LIGHT);
      ChartSetInteger(0, CHART_COLOR_VOLUME, COLOR_CBG_LIGHT);
      ChartSetInteger(0, CHART_COLOR_ASK, clrNONE);
      ChartSetInteger(0, CHART_COLOR_STOP_LEVEL, COLOR_CBG_LIGHT);
      //---
      ChartSetInteger(0, CHART_SHOW_OHLC, false);
      ChartSetInteger(0, CHART_SHOW_ASK_LINE, false);
      ChartSetInteger(0, CHART_SHOW_PERIOD_SEP, false);
      ChartSetInteger(0, CHART_SHOW_GRID, false);
      ChartSetInteger(0, CHART_SHOW_VOLUMES, false);
      ChartSetInteger(0, CHART_SHOW_OBJECT_DESCR, false);
      ChartSetInteger(0, CHART_SHOW_TRADE_LEVELS, false);
     }

//--- Set Dark
   if(Type == 1)
     {
      ChartSetInteger(0, CHART_COLOR_BACKGROUND, COLOR_CBG_DARK);
      ChartSetInteger(0, CHART_COLOR_FOREGROUND, COLOR_FONT);
      ChartSetInteger(0, CHART_COLOR_GRID, clrNONE);
      ChartSetInteger(0, CHART_COLOR_CHART_UP, COLOR_CBG_DARK);
      ChartSetInteger(0, CHART_COLOR_CHART_DOWN, COLOR_CBG_DARK);
      ChartSetInteger(0, CHART_COLOR_CANDLE_BULL, COLOR_CBG_DARK);
      ChartSetInteger(0, CHART_COLOR_CANDLE_BEAR, COLOR_CBG_DARK);
      ChartSetInteger(0, CHART_COLOR_CHART_LINE, COLOR_CBG_DARK);
      ChartSetInteger(0, CHART_COLOR_VOLUME, COLOR_CBG_DARK);
      ChartSetInteger(0, CHART_COLOR_ASK, clrNONE);
      ChartSetInteger(0, CHART_COLOR_STOP_LEVEL, COLOR_CBG_DARK);
      //---
      ChartSetInteger(0, CHART_SHOW_OHLC, false);
      ChartSetInteger(0, CHART_SHOW_ASK_LINE, false);
      ChartSetInteger(0, CHART_SHOW_PERIOD_SEP, false);
      ChartSetInteger(0, CHART_SHOW_GRID, false);
      ChartSetInteger(0, CHART_SHOW_VOLUMES, false);
      ChartSetInteger(0, CHART_SHOW_OBJECT_DESCR, false);
      ChartSetInteger(0, CHART_SHOW_TRADE_LEVELS, false);
     }

//--- Set Original
   if(Type == 2)
     {
      ChartSetInteger(0, CHART_COLOR_BACKGROUND, ChartColor_BG);
      ChartSetInteger(0, CHART_COLOR_FOREGROUND, ChartColor_FG);
      ChartSetInteger(0, CHART_COLOR_GRID, ChartColor_GD);
      ChartSetInteger(0, CHART_COLOR_CHART_UP, ChartColor_UP);
      ChartSetInteger(0, CHART_COLOR_CHART_DOWN, ChartColor_DWN);
      ChartSetInteger(0, CHART_COLOR_CANDLE_BULL, ChartColor_BULL);
      ChartSetInteger(0, CHART_COLOR_CANDLE_BEAR, ChartColor_BEAR);
      ChartSetInteger(0, CHART_COLOR_CHART_LINE, ChartColor_LINE);
      ChartSetInteger(0, CHART_COLOR_VOLUME, ChartColor_VOL);
      ChartSetInteger(0, CHART_COLOR_ASK, ChartColor_ASK);
      ChartSetInteger(0, CHART_COLOR_STOP_LEVEL, ChartColor_LVL);
      //---
      ChartSetInteger(0, CHART_SHOW_OHLC, ChartColor_OHLC);
      ChartSetInteger(0, CHART_SHOW_ASK_LINE, ChartColor_ASKLINE);
      ChartSetInteger(0, CHART_SHOW_PERIOD_SEP, ChartColor_PERIODSEP);
      ChartSetInteger(0, CHART_SHOW_GRID, ChartColor_GRID);
      ChartSetInteger(0, CHART_SHOW_VOLUMES, ChartColor_SHOWVOL);
      ChartSetInteger(0, CHART_SHOW_OBJECT_DESCR, ChartColor_OBJDESCR);
      ChartSetInteger(0, CHART_SHOW_TRADE_LEVELS, ChartColor_TRADELVL);
     }

//---
   if(Type == 3)
     {
      ChartSetInteger(0, CHART_COLOR_BACKGROUND, clrWhite);
      ChartSetInteger(0, CHART_COLOR_FOREGROUND, clrBlack);
      ChartSetInteger(0, CHART_COLOR_GRID, clrSilver);
      ChartSetInteger(0, CHART_COLOR_CHART_UP, clrBlack);
      ChartSetInteger(0, CHART_COLOR_CHART_DOWN, clrBlack);
      ChartSetInteger(0, CHART_COLOR_CANDLE_BULL, clrWhite);
      ChartSetInteger(0, CHART_COLOR_CANDLE_BEAR, clrBlack);
      ChartSetInteger(0, CHART_COLOR_CHART_LINE, clrBlack);
      ChartSetInteger(0, CHART_COLOR_VOLUME, clrGreen);
      ChartSetInteger(0, CHART_COLOR_ASK, clrOrangeRed);
      ChartSetInteger(0, CHART_COLOR_STOP_LEVEL, clrOrangeRed);
      //---
      ChartSetInteger(0, CHART_SHOW_OHLC, false);
      ChartSetInteger(0, CHART_SHOW_ASK_LINE, false);
      ChartSetInteger(0, CHART_SHOW_PERIOD_SEP, false);
      ChartSetInteger(0, CHART_SHOW_GRID, false);
      ChartSetInteger(0, CHART_SHOW_VOLUMES, false);
      ChartSetInteger(0, CHART_SHOW_OBJECT_DESCR, false);
     }
//---
  }
//+------------------------------------------------------------------+
//| ChartGetColor                                                    |
//+------------------------------------------------------------------+
//---- Original Template
color ChartColor_BG = 0, ChartColor_FG = 0, ChartColor_GD = 0, ChartColor_UP = 0, ChartColor_DWN = 0, ChartColor_BULL = 0, ChartColor_BEAR = 0, ChartColor_LINE = 0, ChartColor_VOL = 0, ChartColor_ASK = 0, ChartColor_LVL = 0;
//---
bool ChartColor_OHLC = false, ChartColor_ASKLINE = false, ChartColor_PERIODSEP = false, ChartColor_GRID = false, ChartColor_SHOWVOL = false, ChartColor_OBJDESCR = false, ChartColor_TRADELVL = false;
//----
void ChartGetColor()
  {
   ChartColor_BG = (color)ChartGetInteger(0, CHART_COLOR_BACKGROUND, 0);
   ChartColor_FG = (color)ChartGetInteger(0, CHART_COLOR_FOREGROUND, 0);
   ChartColor_GD = (color)ChartGetInteger(0, CHART_COLOR_GRID, 0);
   ChartColor_UP = (color)ChartGetInteger(0, CHART_COLOR_CHART_UP, 0);
   ChartColor_DWN = (color)ChartGetInteger(0, CHART_COLOR_CHART_DOWN, 0);
   ChartColor_BULL = (color)ChartGetInteger(0, CHART_COLOR_CANDLE_BULL, 0);
   ChartColor_BEAR = (color)ChartGetInteger(0, CHART_COLOR_CANDLE_BEAR, 0);
   ChartColor_LINE = (color)ChartGetInteger(0, CHART_COLOR_CHART_LINE, 0);
   ChartColor_VOL = (color)ChartGetInteger(0, CHART_COLOR_VOLUME, 0);
   ChartColor_ASK = (color)ChartGetInteger(0, CHART_COLOR_ASK, 0);
   ChartColor_LVL = (color)ChartGetInteger(0, CHART_COLOR_STOP_LEVEL, 0);
//---
   ChartColor_OHLC = ChartGetInteger(0, CHART_SHOW_OHLC, 0);
   ChartColor_ASKLINE = ChartGetInteger(0, CHART_SHOW_ASK_LINE, 0);
   ChartColor_PERIODSEP = ChartGetInteger(0, CHART_SHOW_PERIOD_SEP, 0);
   ChartColor_GRID = ChartGetInteger(0, CHART_SHOW_GRID, 0);
   ChartColor_SHOWVOL = ChartGetInteger(0, CHART_SHOW_VOLUMES, 0);
   ChartColor_OBJDESCR = ChartGetInteger(0, CHART_SHOW_OBJECT_DESCR, 0);
   ChartColor_TRADELVL = ChartGetInteger(0, CHART_SHOW_TRADE_LEVELS, 0);
//---

}

//+------------------------------------------------------------------+
//| CreateSymbGUI                                                    |
//+------------------------------------------------------------------+

void CreateSymbGUI(int i, int Y)
  {
//---

ArrayResize(Symbols,NumOfSymbols,0);
for(i=0;i<NumOfSymbols;i++){
   string _Symb =Symbols[i];
   color startcolor = FirstRun?clrNONE: COLOR_FONT;
   double countb = 0,
          counts = 0,
          countf = 0;

//---
   LabelCreate(0,OBJPREFIX+_Symb,0,_x1+Dpi(10),Y,CORNER_LEFT_UPPER,_Symb +":",sFontType,FONTSIZE,COLOR_FONT,0,ANCHOR_LEFT,false,false,true);
//---

 ArrayResize(MasterSignal,NumOfSymbols+i,0); 
     ArrayResize(Signal1,NumOfSymbols+i,0);
     ArrayResize(Signal2,NumOfSymbols+i,0);
     ArrayResize(Signal3,NumOfSymbols+i,0);
     
     
     ArrayResize(Pendings,NumOfSymbols+1,0);
     
      ArrayResize( ExitSignal3,NumOfSymbols+i,0);
       ArrayResize( ExitSignal2,NumOfSymbols+i,0);
        ArrayResize( ExitSignal1,NumOfSymbols+i,0);
         ArrayResize( ExitSignal0,NumOfSymbols+i,0);
      
//---
   LabelCreate(0,OBJPREFIX+_Symb+"Master1",0,_x1+Dpi(110),Y,CORNER_LEFT_UPPER,MasterSignal[i]>0?"15":MasterSignal[i]<0?"6":"4","Webdings",20,MasterSignal[i]>0?clrLimeGreen:MasterSignal[i]<0?clrRed:clrYellow,0,ANCHOR_LEFT,false,true);
   LabelCreate(0,OBJPREFIX+_Symb+"Indicator 1",0,_x1+Dpi(210),Y,CORNER_LEFT_UPPER,Signal1[i]>0?"15":Signal1[i]<0?"6":"4","Webdings",20,Signal1[i]>0?clrLimeGreen:Signal1[i]<0?clrRed:clrYellow,0,ANCHOR_LEFT,false,false,true);
   LabelCreate(0,OBJPREFIX+_Symb+"Indicator 2",0,_x1+Dpi(310),Y,CORNER_LEFT_UPPER,Signal2[i]>0?"15":Signal2[i]<0?"6":"4","Webdings",20,Signal2[i]>0?clrLimeGreen:Signal2[i]<0?clrRed:clrYellow,0,ANCHOR_LEFT,false,false,true);
   LabelCreate(0,OBJPREFIX+_Symb+"Indicator 3",0,_x1+Dpi(410),Y,CORNER_LEFT_UPPER,Signal3[i]>0?"15":Signal3[i]<0?"6":"4","Webdings",20,Signal3[i]>0?clrLimeGreen:Signal3[i]<0?clrRed:clrYellow,0,ANCHOR_LEFT,false,false,true);
   LabelCreate(0,OBJPREFIX+_Symb+"Master Exit1",0,_x1+Dpi(510),Y,CORNER_LEFT_UPPER,ExitSignal0[i]>0?"15":ExitSignal0[i]<0?"6":"4","Webdings",20,ExitSignal0[i]>0?clrLimeGreen:ExitSignal0[i]<0?clrRed:clrYellow,0,ANCHOR_LEFT,false,false,true);
   LabelCreate(0,OBJPREFIX+_Symb+"Exit2",0,_x1+Dpi(610),Y,CORNER_LEFT_UPPER,ExitSignal1[i]>0?"15":ExitSignal1[i]<0?"6":"4","Webdings",20,ExitSignal1[i]>0?clrLimeGreen:ExitSignal1[i]<0?clrRed:clrYellow,0,ANCHOR_LEFT,false,false,true);
   LabelCreate(0,OBJPREFIX+_Symb+"Exit3",0,_x1+Dpi(710),Y,CORNER_LEFT_UPPER,ExitSignal2[i]>0?"15":ExitSignal2[i]<0?"6":"4","Webdings",20,ExitSignal2[i]>0?clrLimeGreen:ExitSignal2[i]<0?clrRed:clrYellow,0,ANCHOR_LEFT,false,false,true);
   LabelCreate(0,OBJPREFIX+_Symb+"Exit4",0,_x1+Dpi(810),Y,CORNER_LEFT_UPPER,ExitSignal3[i]>0?"15":ExitSignal3[i]<0?"6":"4","Webdings",20,ExitSignal3[i]>0?clrLimeGreen:ExitSignal3[i]<0?clrRed:clrYellow,0,ANCHOR_LEFT,false,false,true);
}
//---
  }
  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeletePeblndingWithCandle(COrder & pending)
  { 
   int size=pending.GroupTotal();
   for(int i=0; i<size; i++)
     {
      datetime timeOpen=Pendings[i].GetTimeSetUp();
      string symb=Pendings[i].GetSymbol();
      datetime timetoDelete=iTime(symb,0,PendingOrderExpirationBars);
      if(timeOpen<=PendingOrderExpirationMinutes)
        
         Pendings[i].Close(30);
         
         }
 }
//+------------------------------------------------------------------+
//| CreateProBar                                                     |
//+------------------------------------------------------------------+
void CreateProBar(string _Symb, int x, int y)
  {
//---
   int fr_y_pb = y;
//---
   for(int i = 1; i < 11; i++)
     {
      LabelCreate(0, OBJPREFIX+"PB#"+IntegerToString(i)+" - "+_Symb, 0, x, fr_y_pb, CORNER_LEFT_UPPER, "0", "Webdings", 25, clrNONE, 0, ANCHOR_RIGHT, false, false, true); fr_y_pb -= Dpi(5);
     }
//---
  }
 
void CloseBuyOrders(string symbols)
  {
   string symbol=symbols;

   for(int i=OrdersTotal(); i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS))
        {
         if(OrderType() == ORDER_TYPE_BUY)
           {
            if(OrderSymbol() == symbol)
              {
               if(OrderMagicNumber() == MagicNumber)
                 {
                  if(OrderCloseTime() == 0)
                    {
                     if(!OrderClose(OrderTicket(),OrderLots(),SymbolInfoDouble(symbol,SYMBOL_BID),1,clrYellow))
                       {
                        PrintFormat("Failed to close order %d, error:%d",OrderTicket(),GetLastError());
                       }
                    }
                 }
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                           CloseSellOrders                                       |
//+------------------------------------------------------------------+
void CloseSellOrders( string symbols)
  {
   string symbol=symbols;

   for(int i=OrdersTotal(); i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS))
        {
         if(OrderType() == ORDER_TYPE_SELL)
           {
            if(OrderSymbol() == symbol)
              {
               if(OrderMagicNumber() == MagicNumber)
                 {
                  if(OrderCloseTime() == 0)
                    {
                     if(!OrderClose(OrderTicket(),OrderLots(),SymbolInfoDouble(symbol,SYMBOL_ASK),1,clrYellow))
                       {
                        PrintFormat("Failed to close order %d, error:%d",OrderTicket(),GetLastError());
                       }
                    }
                 }
              }
           }
        }
     }

  }
//+------------------------------------------------------------------+
//|                              CloseProfitOrders                                    |
//+------------------------------------------------------------------+
void CloseProfitOrders( string symbols)
  {
   string symbol=symbols;
   for(int i=OrdersTotal(); i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS))
        {
         if((OrderType() == ORDER_TYPE_BUY)||(OrderType()==ORDER_TYPE_SELL))
           {
            if(OrderSymbol() == symbol)
              {
               if(OrderMagicNumber() == MagicNumber)
                 {
                  if(OrderCloseTime() == 0)
                    {
                     if(OrderProfit()>0)
                       {
                     double price = (OrderType() == ORDER_TYPE_BUY ? SymbolInfoDouble(symbol,SYMBOL_BID) : SymbolInfoDouble(symbol,SYMBOL_ASK));
                        if(!OrderClose(OrderTicket(),OrderLots(),price,1,clrYellow))
                          {
                           PrintFormat("Failed to close order %d, error:%d",OrderTicket(),GetLastError());
                          }
                       }
                    }
                 }
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                           CloseLossOrders                                       |
//+------------------------------------------------------------------+
void CloseLossOrders( string symbols)
  {
   for(int i=OrdersTotal(); i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS))
        {
         if((OrderType() == ORDER_TYPE_BUY)||(OrderType()==ORDER_TYPE_SELL))
           {
            if(OrderSymbol() == symbols)
              {
               if(OrderMagicNumber() == MagicNumber)
                 {
                  if(OrderCloseTime() == 0)
                    {
                     if(OrderProfit()<0)
                       {
                     double price = (OrderType() == ORDER_TYPE_BUY ? SymbolInfoDouble(symbols,SYMBOL_BID) : SymbolInfoDouble(symbols,SYMBOL_ASK));
                        if(!OrderClose(OrderTicket(),OrderLots(),price,5,clrYellow))
                          {
                           PrintFormat("Failed to close order %d, error:%d",OrderTicket(),GetLastError());
                          }
                       }
                    }
                 }
              }
           }
        }
     }
  }