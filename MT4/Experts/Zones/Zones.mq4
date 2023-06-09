//+------------------------------------------------------------------+
//|                                                        Zones_EA.mq4 |
//|                                               Noel M Nguemechieu |
//|                             https://github.com/nguemechieu/zones |
//+------------------------------------------------------------------+
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
//+--------------------------------------------------------------+
//|     DWX_ZeroMQ_Server_v2.0.1_RC8.mq4
//|     @author: Darwinex Labs (www.darwinex.com)
//|
//|     Copyright (c) 2017-2020, Darwinex. All rights reserved.
//|    
//|     Licensed under the BSD 3-Clause License, you may not use this file except 
//|     in compliance with the License. 
//|    
//|     You may obtain a copy of the License at:    
//|     https://opensource.org/licenses/BSD-3-Clause
//+--------------------------------------------------------------+
#include <stdlib.mqh>
#include <stderror.mqh>

// Required: MQL-ZMQ from https://github.com/dingmaotu/mql-zmq

#include <Zmq/Zmq.mqh>

 const string PROJECT_NAME = "DWX_ZeroMQ_MT4_Server";
 const  string ZEROMQ_PROTOCOL = "tcp";
 const string HOSTNAME = "*";
const  int PUSH_PORT = 32768;
const  int PULL_PORT = 32769;
const  int PUB_PORT = 32770;
const  int MILLISECOND_TIMER = 1;
const  int MILLISECOND_TIMER_PRICES = 500;

const string t0 = "--- Trading Parameters ---";
const  int MaximumOrders = 1;
const  double MaximumLotSize = 0.01;
const  int MaximumSlippage = 3;
const  bool DMA_MODE = true;

/** Now, MarketData and MarketRates flags can change in real time, according with
 *  registered symbols and instruments.
 */
//extern string t1 = "--- ZeroMQ Configuration ---";
bool Publish_MarketData  = false;
bool Publish_MarketRates = false;

string main_string_delimiter = ":|:";
long lastUpdateMillis = GetTickCount();
                                                                 
  

// Dynamic array initialized at OnInit(). Can be updated by TRACK_PRICES requests from client peers
string Publish_Symbols[];
string Publish_Symbols_LastTick[];

// CREATE ZeroMQ Context
Context context(PROJECT_NAME);

// CREATE ZMQ_PUSH SOCKET
Socket pushSocket(context, ZMQ_PUSH);

// CREATE ZMQ_PULL SOCKET
Socket pullSocket(context, ZMQ_PULL);

// CREATE ZMQ_PUB SOCKET
Socket pubSocket(context, ZMQ_PUB);

// VARIABLES FOR LATER
uchar _data[];
ZmqMsg request;

/**
 * Class definition for an specific instrument: the tuple (symbol,timeframe)
 */
class Instrument {
public:  
                
    //--------------------------------------------------------------
    /** Instrument constructor */
    Instrument() { _symbol = ""; _name = ""; _timeframe = PERIOD_CURRENT; _last_pub_rate =0;}    
                 
    //--------------------------------------------------------------
    /** Getters */
    string          symbol()    { return _symbol; }
    ENUM_TIMEFRAMES timeframe() { return _timeframe; }
    string          name()      { return _name; }
    datetime        getLastPublishTimestamp() { return _last_pub_rate; }
    /** Setters */
    void            setLastPublishTimestamp(datetime tmstmp) { _last_pub_rate = tmstmp; }
   
   //--------------------------------------------------------------
    /** Setup instrument with symbol and timeframe descriptions
     *  @param arg_symbol Symbol
     *  @param arg_timeframe Timeframe
     */
    void setup(string arg_symbol, ENUM_TIMEFRAMES arg_timeframe) {
        _symbol = arg_symbol;
        _timeframe = arg_timeframe;
        _name  = _symbol + "_" + GetTimeframeText(_timeframe);
        _last_pub_rate = 0;
    }
                
    //--------------------------------------------------------------
    /** Get last N MqlRates from this instrument (symbol-timeframe)
     *  @param rates Receives last 'count' rates
     *  @param count Number of requested rates
     *  @return Number of returned rates
     */
    int GetRates(MqlRates& rates[], int count) {
        // ensures that symbol is setup
        if(StringLen(_symbol) > 0) {
            return CopyRates(_symbol, _timeframe, 0, count, rates);
        }
        return 0;
    }
    
protected:
    string _name;                //!< Instrument descriptive name
    string _symbol;              //!< Symbol
    ENUM_TIMEFRAMES _timeframe;  //!< Timeframe
    datetime _last_pub_rate;     //!< Timestamp of the last published OHLC rate. Default = 0 (1 Jan 1970)
 
};

// Array of instruments whose rates will be published if Publish_MarketRates = True. It is initialized at OnInit() and
// can be updated through TRACK_RATES request from client peers.
Instrument Publish_Instruments[];

#property tester_file "trade.csv"    // file with the data to be read by an Expert Advisor TradeExpert_file "trade.csv"    // file with the data to be read by an Expert Advisor
#property icon "\\Images\\zones_ea.ico"
#property tester_library "Libraries"
#property stacksize 10000
#property description "This is a very interactive smart Bot. It uses multiples indicators base on your define strategy to get trade signals a"
#property description "nd open orders. It also integrate news filter to allow you to trade base on news events. In addition the ea generate s"
#property description "ignals with screenshot on telegram or others withoud using dll import.This  give ea ability to trade on your vps witho"
#property description "ut restrictions."
#property description "This Bot will can trade generate ,manage and generate trading signals on telegram channel"


//+------------------------------------------------------------------+
#define EXPERT_NAME     "ZONES EA"
#define EXPERT_VERSION  "0.1.0"
#property version       EXPERT_VERSION
#define CAPTION_COLOR   clrWhite
#define LOSS_COLOR      clrOrangeRed


#include <DiscordTelegram\Comment.mqh>
#include <DiscordTelegram\Telegram.mqh>
#include <DiscordTelegram/News.mqh>

string currency;
int GridError;
const ENUM_TIMEFRAMES _periods[] = {PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_M30, PERIOD_H1, PERIOD_H4, PERIOD_D1, PERIOD_W1, PERIOD_MN1};



//+------------------------------------------------------------------+
//|   TRADE EXPERT parameters                                               |
//+------------------------------------------------------------------+
input ENUM_LANGUAGES    InpLanguage = LANGUAGE_EN; //Language
input ENUM_UPDATE_MODE  InpUpdateMode = UPDATE_NORMAL; //Update Mode
input string            InpToken = ""; //TELEGRAM TOKEN
input string            InpUserNameFilter = ""; //Whitelist Usernames
input string            InpTemplates = "Stochastic,RSI,Triggerline,Moving Average,Equity-Monitor, Ichimoku, ADX,BollingerBands,Momentum"; //Templates

input string channel = "tradeexpert_infos"; // TELEGRAM CHANNEL
input long chatID = -1001648392740; // GROUP or BOT CHAT ID

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input string inpTemplate = "TradeExpert"; //Template or Indicator Name ("RSI ,FIBO ...")
//---

input   bool guaranteProfit = true; //USE GUARANTY PROFIT %
input int guaranteProfitPercentage = 2; //GUARANTY PROFIT %
input bool tradeNews = true;
bool Signal = tradeNews;

bool  Now = false;
input bool sendNews = true; //Send News ? (TRUE/FALSE)

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input bool useMulticurrencies;//Multi currencies(TRUE/FALSE)
input string symbolList = "AUDUSD,USDCAD,AUDCHF,EURUSD"; //LIST (EURUSD,AUDUSD)
string infoberita = "";
bool trade = false;
bool NewsFilter = false;
int offset = 0;


// Enter a unique number to identify this EA

// Setting this to true will close all open orders immediately
extern bool     EmergencyCloseAll   = false;

extern string   LabelAcc            = "Account Trading Settings:";//ACCUUNT TRADING SETTINGS
// Setting this to true will stop the EA trading after any open trades have been closed
extern bool     ShutDown            = false; //SHOT DOWN
// percent of account balance lost before trading stops
extern double   StopTradePercent    = 2;//STOP TRADE PERCENTAGE
// set to true for nano "penny a pip" account (contract size is $10,000)
extern bool     NanoAccount         = false;
// Percentage of account you want to trade on this pair
extern double   PortionPC           = 100;
// If Basket open: 0=no Portion change;1=allow portion to increase; -1=allow increase and decrease
extern int     PortionChange     = 1;
// Percent of portion for max drawdown level.
extern double   MaxDDPercent        = 50;
// Maximum allowed spread while placing trades
extern double   MaxSpread           = 5;
// Will shutdown over holiday period
extern bool     UseHolidayShutdown  = true;
// List of holidays, each seperated by a comma, [day]/[mth]-[day]/[mth], dates inclusive
extern string   Holidays            = "23/12-01/01";
// will sound alarms
extern bool     PlaySounds          = false;
// Alarm sound to be played
extern string   AlertSound          = "Alert.wav";

extern string   LabelIES            = "Indicator / Entry Settings:";
// Stop/Limits for entry if true, Buys/Sells if false
extern bool     B3Traditional       = true;
// Market condition 0=uptrend 1=downtrend 2=range 3=off
extern int      ForceMarketCond     = 3;
// true = ANY entry can be used to open orders, false = ALL entries used to open orders
extern bool     UseAnyEntry         = false;
// 0 = Off, 1 = will base entry on MA channel, 2 = will trade in reverse
extern int      MAEntry             = 1;
// 0 = Off, 1 = will base entry on CCI indicator, 2 = will trade in reverse
extern int      CCIEntry            = 0;
// 0 = Off, 1 = will base entry on BB, 2 = will trade in reverse
extern int      BollingerEntry      = 0;
// 0 = Off, 1 = will base entry on Stoch, 2 = will trade in reverse
extern int      StochEntry          = 0;
// 0 = Off, 1 = will base entry on MACD, 2 = will trade in reverse
extern int      MACDEntry           = 0;

extern string   LabelLS             = "Lot Size Settings:";
// Money Management
extern bool     UseMM               = true;
// Adjusts MM base lot for large accounts
extern double   LAF                 = 0.5;
// Starting lots if Money Management is off
extern double   Lot                 = 0.01;
// Multiplier on each level
extern double   Multiplier          = 1.4;

extern string   LabelGS             = "Grid Settings:";
// Auto calculation of TakeProfit and Grid size;
extern bool     AutoCal             = false;
extern string   LabelATRTFr         = "0:Chart, 1:M1, 2:M5, 3:M15, 4:M30, 5:H1, 6:H4, 7:D1, 8:W1, 9:MN1";
// TimeFrame for ATR calculation
extern int      ATRTF               = 0;
// Number of periods for the ATR calculation
extern int      ATRPeriods          = 21;
// Widens/Squishes Grid on increments/decrements of .1
extern double   GAF                 = 1.0;
// Time Grid in seconds, to avoid opening of lots of levels in fast market
extern int      EntryDelay          = 2400;
// In pips, used in conjunction with logic to offset first trade entry
extern double   EntryOffset         = 5;
// True = use RSI/MA calculation for next grid order
extern bool     UseSmartGrid        = true;

extern string   LabelTS             = "Trading Settings:";
// Maximum number of trades to place (stops placing orders when reaches MaxTrades)
extern int      MaxTrades           = 15;
// Close All level, when reaches this level, doesn't wait for TP to be hit
extern int      BreakEvenTrade      = 12;
// Pips added to Break Even Point before BE closure
extern double   BEPlusPips          = 2;
// True = will close the oldest open trade after CloseTradesLevel is reached
extern bool     UseCloseOldest      = false;
// will start closing oldest open trade at this level
extern int      CloseTradesLevel    = 5;
// Will close the oldest trade whether it has potential profit or not
extern bool     ForceCloseOldest    = true;
// Maximum number of oldest trades to close
extern int      MaxCloseTrades      = 4;
// After Oldest Trades have closed, Forces Take Profit to BE +/- xx Pips
extern double   CloseTPPips         = 10;
// Force Take Profit to BE +/- xx Pips
extern double   ForceTPPips         = 0;
// Ensure Take Profit is at least BE +/- xx Pips
extern double   MinTPPips           = 0;

extern string   LabelHS             = "Hedge Settings:";
// Enter the Symbol of the same/correlated pair EXACTLY as used by your broker.
extern string   HedgeSymbol         = "";
// Number of days for checking Hedge Correlation
extern int      CorrPeriod          = 30;
// Turns DD hedge on/off
extern bool     UseHedge            = false;
// DD = start hedge at set DD;Level = Start at set level
extern string   DDorLevel           = "DD";
// DD Percent or Level at which Hedge starts
extern double   HedgeStart          = 20;
// Hedge Lots = Open Lots * hLotMult
extern double   hLotMult            = 0.8;
// DD Hedge maximum pip loss - also hedge trailing stop
extern double   hMaxLossPips        = 30;
// true = fixed SL at hMaxLossPips
extern bool     hFixedSL            = false;
// Hedge Take Profit
extern double   hTakeProfit         = 30;
// Increase to HedgeStart to stop early re-entry of the hedge
extern double   hReEntryPC          = 5;
// True = Trailing Stop will stop at BE;False = Hedge will continue into profit
extern bool     StopTrailAtBE       = true;
// False = Trailing Stop is Fixed;True = Trailing Stop will reduce after BE is reached
extern bool     ReduceTrailStop     = true;

extern string   LabelES             = "Exit Settings:";
// Turns on TP move and Profit Trailing Stop Feature
extern bool     MaximizeProfit      = false;
// Locks in Profit at this percent of Total Profit Potential
extern double   ProfitSet           = 70;
// Moves TP this amount in pips
extern double   MoveTP              = 30;
// Number of times you want TP to move before stopping movement
extern int      TotalMoves          = 2;
// Use Stop Loss and/or Trailing Stop Loss
extern bool     UseStopLoss         = false;
// Pips for fixed StopLoss from BE, 0=off
extern double   SLPips              = 30;
// Pips for trailing stop loss from BE + TSLPips: +ve = fixed trail; -ve = reducing trail; 0=off
extern double   TSLPips             = 10;
// Minimum trailing stop pips if using reducing TS
extern double   TSLPipsMin          = 3;
// Transmits a SL in case of internet loss
extern bool     UsePowerOutSL       = false;
// Power Out Stop Loss in pips
extern double   POSLPips            = 600;
// Close trades in FIFO order
extern bool     UseFIFO             = false;

extern string   LabelEE             = "Early Exit Settings:";
// Reduces ProfitTarget by a percentage over time and number of levels open
extern bool     UseEarlyExit        = false;
// Number of Hours to wait before EE over time starts
extern double   EEStartHours        = 3;
// true = StartHours from FIRST trade: false = StartHours from LAST trade
extern bool     EEFirstTrade        = true;
// Percentage reduction per hour (0 = OFF)
extern double   EEHoursPC           = 0.5;
// Number of Open Trades before EE over levels starts
extern int      EEStartLevel        = 5;
// Percentage reduction at each level (0 = OFF)
extern double   EELevelPC           = 10;
// true = Will allow the basket to close at a loss : false = Minimum profit is Break Even
extern bool     EEAllowLoss         = false;

extern string   LabelAdv            = "Advanced Settings Change sparingly";

extern string   LabelGrid           = "Grid Size Settings:";
// Specifies number of open trades in each block (separated by a comma)
extern string   SetCountArray       = "4,4";
// Specifies number of pips away to issue limit order (separated by a comma)
extern string   GridSetArray        = "25,50,100";
// Take profit for each block (separated by a comma)
extern string   TP_SetArray         = "50,100,200";

extern string   LabelMA             = "MA Entry Settings:";
// Period of MA (H4 = 100, H1 = 400)
extern int      MAPeriod            = 100;
// Distance from MA to be treated as Ranging Market
extern double   MADistance          = 10;

extern string   LabelCCI            = "CCI Entry Settings:";
// Period for CCI calculation
extern int      CCIPeriod           = 14;

extern string   LabelBBS            = "Bollinger Bands Entry Settings:";
// Period for Bollinger
extern int      BollPeriod          = 10;
// Up/Down spread
extern double   BollDistance        = 10;
// Standard deviation multiplier for channel
extern double   BollDeviation       = 2.0;

extern string   LabelSto            = "Stochastic Entry Settings:";
// Determines Overbought and Oversold Zones
extern int      BuySellStochZone    = 20;
// Stochastic KPeriod
extern int      KPeriod             = 10;
// Stochastic DPeriod
extern int      DPeriod             = 2;
// Stochastic Slowing
extern int      Slowing             = 2;

extern string   LabelMACD           = "MACD Entry Settings:";
extern string   LabelMACDTF         = "0:Chart, 1:M1, 2:M5, 3:M15, 4:M30, 5:H1, 6:H4, 7:D1, 8:W1, 9:MN1";
// Time frame for MACD calculation
extern int      MACD_TF             = 0;
// MACD EMA Fast Period
extern int      FastPeriod          = 12;
// MACD EMA Slow Period
extern int      SlowPeriod          = 26;
// MACD EMA Signal Period
extern int      SignalPeriod        = 9;
// 0=close, 1=open, 2=high, 3=low, 4=HL/2, 5=HLC/3 6=HLCC/4
extern int      MACDPrice           = 0;

extern string   LabelSG             = "Smart Grid Settings:";
extern string   LabelSGTF           = "0:Chart, 1:M1, 2:M5, 3:M15, 4:M30, 5:H1, 6:H4, 7:D1, 8:W1, 9:MN1";
// Timeframe for RSI calculation - should be less than chart TF.
extern int      RSI_TF              = 3;
// Period for RSI calculation
extern int      RSI_Period          = 14;
// 0=close, 1=open, 2=high, 3=low, 4=HL/2, 5=HLC/3 6=HLCC/4
extern int      RSI_Price           = 0;
// Period for MA of RSI calculation
extern int      RSI_MA_Period       = 10;
// 0=Simple MA, 1=Exponential MA, 2=Smoothed MA, 3=Linear Weighted MA
extern int      RSI_MA_Method       = 0;

extern string   LabelOS             = "Other Settings:";
// true = Recoup any Hedge/CloseOldest losses: false = Use original profit target.
extern bool     RecoupClosedLoss    = true;
// Largest Assumed Basket size.  Lower number = higher start lots
extern int      Level               = 7;
// Adjusts opening and closing orders by "slipping" this amount
extern int      slip                = 99;
// true = will save equity statistics
extern bool     SaveStats           = false;
// seconds between stats entries - off by default
extern int      StatsPeriod         = 3600;
// true for backtest - false for forward/live to ACCUMULATE equity traces
extern bool     StatsInitialise     = true;

extern string   LabelUE             = "Email Settings:";
extern bool     UseEmail            = false;
extern string   LabelEDD            = "At what DD% would you like Email warnings (Max: 49, Disable: 0)?";
extern double   EmailDD1            = 20;
extern double   EmailDD2            = 30;
extern double   EmailDD3            = 40;
extern string   LabelEH             = "Number of hours before DD timer resets";
// Minimum number of hours between emails
extern double   EmailHours          = 24;

extern string   LabelDisplay        = "Used to Adjust Overlay";
// Turns the display on and off
extern bool     displayOverlay      = true;
// Turns off copyright and icon
extern bool     displayLogo         = true;
// Turns off the CCI display
extern bool     displayCCI          = true;
// Show BE, TP and TS lines
extern bool     displayLines        = true;
// Moves display left and right
extern int      displayXcord        = 100;
// Moves display up and down
extern int      displayYcord        = 22;
// Moves CCI display left and right
extern int      displayCCIxCord     = 10;
//Display font
extern string   displayFont         = "Arial Bold";
// Changes size of display characters
extern int      displayFontSize     = 9;
// Changes space between lines
extern int      displaySpacing      = 14;
// Ratio to increase label width spacing
extern double   displayRatio        = 1;
// default color of display characters
extern color    displayColor        = DeepSkyBlue;
// default color of profit display characters
extern color    displayColorProfit  = Green;
// default color of loss display characters
extern color    displayColorLoss    = Red;
// default color of ForeGround Text display characters
extern color    displayColorFGnd    = White;

extern bool     Debug2               = false;

extern string   LabelOpt            = "These values can only be used while optimizing";
// Set to true if you want to be able to optimize the grid settings.
extern bool     UseGridOpt          = false;
// These values will replace the normal SetCountArray,
// GridSetArray and TP_SetArray during optimization.
// The default values are the same as the normal array defaults
// REMEMBER:
// There must be one more value for GridArray and TPArray
// than there is for SetArray
extern int      SetArray1           = 4;
extern int      SetArray2           = 4;
extern int      SetArray3           = 0;
extern int      SetArray4           = 0;
extern int      GridArray1          = 25;
extern int      GridArray2          = 50;
extern int      GridArray3          = 100;
extern int      GridArray4          = 0;
extern int      GridArray5          = 0;
extern int      TPArray1            = 50;
extern int      TPArray2            = 100;
extern int      TPArray3            = 200;
extern int      TPArray4            = 0;
extern int      TPArray5            = 0;
int GridLevel = 1;
//CHART COLORS SETTINGS
input color BearCandle = clrRed;

input color BullCandle = clrGreen;
input color BackGround = clrAzure;
input color ForeGround = clrBlue;
input color Bear_Outline = clrRed;
input color Bull_Outline = clrGreen;

//+------------------------------------------------------------------+
//|   CMyBot                                                         |
//+------------------------------------------------------------------+
class CMyBot: public CCustomBot
  {
private:
   ENUM_LANGUAGES    m_lang;
   string            m_symbol;
   ENUM_TIMEFRAMES   m_period;
   string            m_template;
   CArrayString      m_templates;

public:
   //+------------------------------------------------------------------+
   void              Language(const ENUM_LANGUAGES _lang)
     {
      m_lang = _lang;
     }

   //+------------------------------------------------------------------+
   int               Templates(const string _list)
     {
      m_templates.Clear();
      //--- parsing
      string text = StringTrim(_list);
      if(text == "")
         return(0);
      //---
      while(StringReplace(text, "  ", " ") > 0);
      StringReplace(text, ";", " ");
      StringReplace(text, ",", " ");
      //---
      string array[];
      int amount = StringSplit(text, ' ', array);
      amount = fmin(amount, 5);
      for(int i = 0; i < amount; i++)
        {
         array[i] = StringTrim(array[i]);
         if(array[i] != "")
            m_templates.Add(array[i]);
        }
      return(amount);
     }

   //+------------------------------------------------------------------+
   int               SendScreenShot(const long _chat_id,
                                    const string _symbol,
                                    const ENUM_TIMEFRAMES _period,
                                    const string _template = NULL)
     {
      int result = 0;
      long chart_id = ChartOpen(_symbol, _period);
      if(chart_id == 0)
         return(ERR_CHART_NOT_FOUND);
      ChartSetInteger(ChartID(), CHART_BRING_TO_TOP, true);
      //--- updates chart
      int wait = 60;
      while(--wait > 0)
        {
         if(SeriesInfoInteger(_symbol, _period, SERIES_SYNCHRONIZED))
            break;
         Sleep(500);
        }
      if(_template != NULL)
         if(!ChartApplyTemplate(chart_id, _template))
            PrintError(_LastError, InpLanguage);
      ChartRedraw(chart_id);
      Sleep(500);
      ChartSetInteger(chart_id, CHART_SHOW_GRID, false);
      ChartSetInteger(chart_id, CHART_SHOW_PERIOD_SEP, false);
      string filename = StringFormat("%s%d.gif", _symbol, _period);
      if(FileIsExist(filename))
         FileDelete(filename);
      ChartRedraw(chart_id);
      Sleep(100);
      if(ChartScreenShot(chart_id, filename, 800, 600, ALIGN_RIGHT))
        {
         Sleep(100);
         //--- Need for MT4 on weekends !!!
         ChartRedraw(chart_id);
         bot.SendChatAction(_chat_id, ACTION_UPLOAD_PHOTO);
         //--- waitng 30 sec for save screenshot
         wait = 60;
         while(!FileIsExist(filename) && --wait > 0)
            Sleep(500);
         //---
         if(FileIsExist(filename))
           {
            string screen_id;
            result = bot.SendPhoto(screen_id, _chat_id, filename, _symbol + "_" + StringSubstr(EnumToString(_period), 7));
           }
         else
           {
            string mask = m_lang == LANGUAGE_EN ? "Screenshot file '%s' not created." : "Файл скриншота '%s' не создан.";
            PrintFormat(mask, filename);
           }
        }
      ChartClose(chart_id);
      return(result);
     }

   //+------------------------------------------------------------------+
   void              ProcessMessages(void)
     {
#define EMOJI_TOP    "\xF51D"
#define EMOJI_BACK   "\xF519"
#define KEYB_MAIN    (m_lang==LANGUAGE_EN)?"[[\"Account Info\"],[\"Quotes\"],[\"Charts\"],[\"trade\"],[\"analysis\"],[\"report\"],[\"news\"]]":"[[\"Информация\"],[\"Котировки\"],[\"Графики\"]]"
#define KEYB_SYMBOLS "[[\""+EMOJI_TOP+"\",\"GBPUSD\",\"EURUSD\"],[\"AUDUSD\",\"USDJPY\",\"EURJPY\"],[\"USDCAD\",\"USDCHF\",\"EURCHF\"],[\"EURCAD\"],[\"USDCHF\"],[\"USDDKK\"],[\"USDJPY\"],[\"AUDCAD\"]]"
#define KEYB_PERIODS "[[\""+EMOJI_TOP+"\",\"M1\",\"M5\",\"M15\"],[\""+EMOJI_BACK+"\",\"M30\",\"H1\",\"H4\"],[\" \",\"D1\",\"W1\",\"MN1\"]]"
#define  TRADE_SYMBOLS "[[\""+EMOJI_TOP+"\",\"BUY\",\"SELL\",\"BUY_LIMT\"],[\""+EMOJI_BACK+"\",\"SELLLIMIT\",\"BUY_STOP\",\"SELL_STOP\"]]"
      for(int i = 0; i < m_chats.Total(); i++)
        {
         CCustomChat *chat = m_chats.GetNodeAtIndex(i);
         if(!chat.m_new_one.done)
           {
            chat.m_new_one.done = true;
            string text = chat.m_new_one.message_text;
            //--- start
            string sym = text;
            if(text == "/start" || text == "/help")
              {
               chat.m_state = 0;
               string msg = "The bot works with your trading account:\n";
               msg += "/info - get account information\n";
               msg += "/quotes - get quotes\n";
               msg += "/charts - get chart images\n";
               msg += "/trade - start live  trade";
               msg += "/news - get market news events";
               msg += "/analysis  - get market analysis";
               if(m_lang == LANGUAGE_RU)
                 {
                  msg = "Бот работает с вашим торговым счетом:\n";
                  msg += "/info - запросить информацию по счету\n";
                  msg += "/quotes - запросить котировки\n";
                  msg += "/charts - запросить график\n";
                  msg += "/trade";
                  msg += "/news";
                  msg += "/analysis";
                 }
               SendMessage(chat.m_id, msg, ReplyKeyboardMarkup(KEYB_MAIN, false, false));
               continue;
              }
            //---
            if(text == EMOJI_TOP)
              {
               chat.m_state = 0;
               string msg = (m_lang == LANGUAGE_EN) ? "Choose a menu item" : "Выберите пункт меню";
               SendMessage(chat.m_id, msg, ReplyKeyboardMarkup(KEYB_MAIN, false, false));
               continue;
              }
            //---
            if(text == EMOJI_BACK)
              {
               if(chat.m_state == 31)
                 {
                  chat.m_state = 3;
                  string msg = (m_lang == LANGUAGE_EN) ? "Enter a symbol name like 'EURUSD'" : "Введите название инструмента, например 'EURUSD'";
                  SendMessage(chat.m_id, msg, ReplyKeyboardMarkup(KEYB_SYMBOLS, false, false));
                 }
               else
                  if(chat.m_state == 32)
                    {
                     chat.m_state = 31;
                     string msg = (m_lang == LANGUAGE_EN) ? "Select a timeframe like 'H1'" : "Введите период графика, например 'H1'";
                     SendMessage(chat.m_id, msg, ReplyKeyboardMarkup(KEYB_PERIODS, false, false));
                    }
                  else
                    {
                     chat.m_state = 0;
                     string msg = (m_lang == LANGUAGE_EN) ? "Choose a menu item" : "Выберите пункт меню";
                     SendMessage(chat.m_id, msg, ReplyKeyboardMarkup(KEYB_MAIN, false, false));
                    }
               continue;
              }
            //---
            if(text == "/info" || text == "Account Info" || text == "Информация")
              {
               chat.m_state = 1;
               currency = AccountInfoString(ACCOUNT_CURRENCY);
               string msg = StringFormat("%d:,  %s,\n", AccountInfoInteger(ACCOUNT_LOGIN), AccountInfoString(ACCOUNT_SERVER));
               msg += StringFormat("%s: %.2f %s\n", (m_lang == LANGUAGE_EN) ? "Balance" : "Баланс", AccountInfoDouble(ACCOUNT_BALANCE), currency);
               msg += StringFormat("%s: %.2f %s\n", (m_lang == LANGUAGE_EN) ? "Profit" : "Прибыль", AccountInfoDouble(ACCOUNT_PROFIT), currency);
               SendMessage(chat.m_id, msg, ReplyKeyboardMarkup(KEYB_MAIN, false, false));
              }
            //---
            if(text == "/quotes" || text == "Quotes" || text == "Котировки")
              {
               chat.m_state = 2;
               string msg = (m_lang == LANGUAGE_EN) ? "Enter a symbol name like 'EURUSD'" : "Введите название инструмента, например 'EURUSD'";
               SendMessage(chat.m_id, msg, ReplyKeyboardMarkup(KEYB_SYMBOLS, false, false));
               continue;
              }
            //---
            if(text == "/charts" || text == "Charts" || text == "chart" || text == "Графики")
              {
               chat.m_state = 3;
               string msg = (m_lang == LANGUAGE_EN) ? "Enter a symbol name like 'EURUSD'" : "Введите название инструмента, например 'EURUSD'";
               SendMessage(chat.m_id, msg, ReplyKeyboardMarkup(KEYB_SYMBOLS, false, false));
               continue;
              }
            //Trade
            if(text == "/trade")
              {
               string msg = "==TRADE MODE== \nClick buttons to trade";
               SendMessage(chat.m_id, msg, ReplyKeyboardMarkup(TRADE_SYMBOLS, false, false));
               chat.m_state = 4;
              }
            if(text == "/analysis")
              {
               string msg = "=========== Market Analysis ==========";
               SendMessage(chat.m_id, msg, ReplyKeyboardMarkup(TRADE_SYMBOLS, false, false));
              }
            if(text == "/report")
              {
               string msg = "========Trade Report ======";
               SendMessage(chat.m_id, msg, ReplyKeyboardMarkup(TRADE_SYMBOLS, false, false));
          
              }
            if(chat.m_state == 4)
              {
               int ticket = 0;
               if(text == "BUY" || text == "buy")
                 {
                  ticket = OrderSend(
                              sym,
                              OP_BUY, OrderLots(),  MarketInfo(sym, MODE_BID), 0, 0, 0, "TELEGRAM ORDER", 12034, 0, clrAliceBlue);
                 }
               else
                  if(text == "SELL" || text == "sell")
                    {
                     ticket =   OrderSend(
                                   sym,
                                   OP_SELL, OrderLots(), MarketInfo(sym, MODE_BID), 0, 0, 0, "TELEGRAM ORDER", 12034, 0, clrAliceBlue);
                    }
               if(text == "BUYSTOP" || text == "buystop")
                 {
                  ticket = OrderSend(
                              sym,
                              OP_BUYSTOP, OrderLots(), MarketInfo(sym, MODE_ASK), 0, 0, 0, "TELEGRAM ORDER", 12034, 0, clrAliceBlue);
                 }
               else
                  if(text == "SELL" || text == "sell")
                    {
                     ticket = OrderSend(
                                 Symbol(),
                                 OP_SELLSTOP, OrderLots(),  MarketInfo(sym, MODE_BID), 0, 0, 0, "TELEGRAM ORDER", 12034, 0, clrAliceBlue);
                    }
               if(text == "BUYLIMIT" || text == "buylimit")
                 {
                  ticket = OrderSend(
                              sym,
                              OP_BUYLIMIT, OrderLots(),  MarketInfo(sym, MODE_ASK), 0, 0, 0, "TELEGRAM ORDER", 12034, 0, clrAzure);
                 }
               else
                  if(text == "SELLLIMIT" || text == "selllimit")
                    {
                     ticket = OrderSend(
                                 sym,
                                 OP_SELLLIMIT, OrderLots(),  MarketInfo(sym, MODE_BID), 0, 0, 0, "TELEGRAM ORDER", 12034, 0, clrYellow);
                    }
              }
            //--- Quotes
            if(chat.m_state == 2)
              {
               string mask = (m_lang == LANGUAGE_EN) ? "Invalid symbol name '%s'" : "Инструмент '%s' не найден";
               string msg = StringFormat(mask, text);
               StringToUpper(text);
               string symbol = text;
               if(SymbolSelect(symbol, true))
                 {
                  double open[1] = {0};
                  m_symbol = symbol;
                  //--- upload history
                  for(int k = 0; k < 3; k++)
                    {
#ifdef __MQL4__
                     double array[][6];
                     ArrayCopyRates(array, symbol, PERIOD_D1);
#endif
                     Sleep(2000);
                     CopyOpen(symbol, PERIOD_D1, 0, 1, open);
                     if(open[0] > 0.0)
                        break;
                    }
                  int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
                  double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
                  CopyOpen(symbol, PERIOD_D1, 0, 1, open);
                  if(open[0] > 0.0)
                    {
                     double percent = 100 * (bid - open[0]) / open[0];
                     //--- sign
                     string sign = ShortToString(0x25B2);
                     if(percent < 0.0)
                        sign = ShortToString(0x25BC);
                     msg = StringFormat("%s: %s %s (%s%%)", symbol, DoubleToString(bid, digits), sign, DoubleToString(percent, 2));
                    }
                  else
                    {
                     msg = (m_lang == LANGUAGE_EN) ? "No history for " : "Нет истории для " + symbol;
                    }
                 }
               SendMessage(chat.m_id, msg, ReplyKeyboardMarkup(KEYB_SYMBOLS, false, false));
               continue;
              }
            //--- Charts
            if(chat.m_state == 3)
              {
               StringToUpper(text);
               string symbol = text;
               if(SymbolSelect(symbol, true))
                 {
                  m_symbol = symbol;
                  chat.m_state = 31;
                  string msg = (m_lang == LANGUAGE_EN) ? "Select a timeframe like 'H1'" : "Введите период графика, например 'H1'";
                  SendMessage(chat.m_id, msg, ReplyKeyboardMarkup(KEYB_PERIODS, false, false));
                 }
               else
                 {
                  string mask = (m_lang == LANGUAGE_EN) ? "Invalid symbol name '%s'" : "Инструмент '%s' не найден";
                  string msg = StringFormat(mask, text);
                  SendMessage(chat.m_id, msg, ReplyKeyboardMarkup(KEYB_SYMBOLS, false, false));
                 }
               continue;
              }
            //Charts->Periods
            if(chat.m_state == 31)
              {
               bool found = false;
               int total = ArraySize(_periods);
               for(int k = 0; k < total; k++)
                 {
                  string str_tf = StringSubstr(EnumToString(_periods[k]), 7);
                  if(StringCompare(str_tf, text, false) == 0)
                    {
                     m_period = _periods[k];
                     found = true;
                     break;
                    }
                 }
               if(found)
                 {
                  //--- template
                  chat.m_state = 32;
                  string str = "[[\"" + EMOJI_BACK + "\",\"" + EMOJI_TOP + "\"]";
                  str += ",[\"None\"]";
                  for(int k = 0; k < m_templates.Total(); k++)
                     str += ",[\"" + m_templates.At(k) + "\"]";
                  str += "]";
                  SendMessage(chat.m_id, (m_lang == LANGUAGE_EN) ? "Select a template" : "Выберите шаблон", ReplyKeyboardMarkup(str, false, false));
                 }
               else
                 {
                  SendMessage(chat.m_id, (m_lang == LANGUAGE_EN) ? "Invalid timeframe" : "Неправильно задан период графика", ReplyKeyboardMarkup(KEYB_PERIODS, false, false));
                 }
               continue;
              }
            //---
            if(chat.m_state == 32)
              {
               m_template = text;
               if(m_template == "None")
                  m_template = NULL;
               int result = SendScreenShot(chat.m_id, m_symbol, m_period, m_template);
               if(result != 0)
                  Print(GetErrorDescription(result, InpLanguage));
              }
           }
        }
     }
  }
;

//+-----------------------------------------------------------------+
//| Internal Parameters Set                                         |
//+-----------------------------------------------------------------+
int ca = 0;
int cci_01 = 0, cci_02 = 0, cci_03 = 0, cci_04 = 0, cci_0_5 = 0, cci_0_6 = 0, cci_0_7 = 0, cci_0_8 = 0, cci_0_9 = 0, cci_10 = 0, cci_11 = 0, cci_12 = 0, cci_13 = 0, cci_14 = 0;

;
double TPbMP = 0;

double dMess = 0;
double bSL = 0;
CComment       comment;
CMyBot         bot;
ENUM_RUN_MODE  run_mode;
datetime       time_check;
int            web_error;
int            init_error;
string         photo_id = NULL;
bool LDelete = false;
double GridTP = 0;
int Tab, EEpc, GridIndex;
int         Magic, hMagic;
int         CbT, CpT, ChT;
double      Pip, hPip;
int         POSLCount;
double      SLbL;
int         Moves;
double      MaxDD;
double      SLb;
int         AccountType;
double      StopTradeBalance;
double      InitialAB;
bool        Testing, Visual;
bool        AllowTrading;
bool        EmergencyWarning;
double      MaxDDPer;
int         Error;
int         Set1Level, Set2Level, Set3Level, Set4Level;
int         EmailCount;
string      sTF;
datetime    EmailSent;
int         GridArray[, 2];
double      Lots[], MinLotSize, LotStep, LotDecimal;
int         LotMult, MinMult;
bool        PendLot;
string      CS, UAE;
int         HolShutDown;
datetime    HolArray[, 4];
datetime    HolFirst, HolLast, NextStats, OTbF;
double      RSI[];
int         Digit[, 2], TF[10] = {0, 1, 5, 15, 30, 60, 240, 1440, 10080, 43200};

double      Email[3];
double      EETime, PbC, PhC, hDDStart, PbMax, PbMin, PhMax, PhMin, LastClosedPL, ClosedPips, SLh, hLvlStart, StatLowEquity, StatHighEquity;
int         hActive, EECount, TbF, CbC, CaL, FileHandle;
bool        TradesOpen, FileClosed, HedgeTypeDD, hThisChart, hPosCorr, dLabels, FirstRun;
string      FileName, ID, StatFile;
double      TPb, StopLevel, TargetPips, LbF, bTS, PortionBalance;

double TPa;

#define A 1 //All (Basket + Hedge)
#define B 2 //Basket
#define H 3 //Hedge
#define T 4 //Ticket
#define P 5 //Pending

//--- Alert
bool FirstAlert = false;
bool SecondAlert = false;
datetime AlertTime = 0;
//--- Buffers

//--- time
datetime xmlModifed;
int TimeOfDay = Hour();
datetime Midnight = 0;
string message = "";
//+------------------------------------------------------------------+
//|                          TimeNewsFunck                                        |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime TimeNewsFunck(int nomf)//RETURN CORRECT NEWS TIME FORMAT
  {
   string s = (string)mynews[nomf].getDate();
   string time = StringConcatenate(StringSubstr(s, 0, 4), ".", StringSubstr(s, 5, 2), ".", StringSubstr(s, 8, 2), " ", StringSubstr(s, 11, 2), ":", StringSubstr(s, 14, 5));
   string hour = StringSubstr(s, 5, 2);
   mynews[nomf].setHours((int)hour);
   string seconde = StringSubstr(s, 14, 5);
   mynews[nomf].setSecondes((int)seconde);
   return ((datetime)StringToTime(time) + offset * 3600);
  }



//+------------------------------------------------------------------+
//|                              ReadWEB                                 |
//+------------------------------------------------------------------+
string ReadWEB()
  {
   string google_urls = "https://nfs.faireconomy.media/ff_calendar_thisweek.json?version=bb202ad20af9b89d8ef8c6233e0b77a2";
   string params = "[]";
   int timeout = 5000;
   char data[];
   int data_size = StringLen(params);
   uchar result[];
   string result_headers;
   int   start_index = 0;
//--- application/x-www-form-urlencoded
   int res = WebRequest("GET", "https://nfs.faireconomy.media/ff_calendar_thisweek.json?version=bb202ad20af9b89d8ef8c6233e0b77a2", "0", params, 5000, data, 0, result, result_headers);
   string  out;
   out = CharArrayToString(result, 0, WHOLE_ARRAY);
   printf("News output " + out);
   if(res == 200) //OK
     {
      //--- delete BOM
      int size = ArraySize(result);
      //---
      CJAVal  js(NULL, out);
      js.Deserialize(result);
      int total = ArraySize(js[""].m_e);
      printf("json array size" + (string)total);
      NomNews = total;
      ArrayResize(mynews, total, 0);
      for(int i = 0; i < total; i++)
        {
         //Getting jason data'
         CJAVal item = js.m_e[i];
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
      for(int i = 0; i < total; i++)
        {
         bool handle = FileOpen("News" + "\\" + newsfile, FILE_READ | FILE_CSV | FILE_WRITE);
         if(!handle)
           {
            printf("Error Can't open file" + newsfile + " to store news events! \nIf open please close it while bot is running.");
           }
         else
           {
            message = mynews[i].toString();
            FileSeek(handle, offset, SEEK_END);
            FileWrite(handle, message);
            FileClose(handle);
            printf(mynews[i].toString());
           }
        }
     }
   else
     {
      if(res == -1)
        {
         printf((string)(_LastError));
        }
      else
        {
         //--- HTTP errors
         if(res >= 100 && res <= 511)
           {
            out = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
            Print(out);
            printf((string)(ERR_HTTP_ERROR_FIRST + res));
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
   if(TimeDayOfWeek(Midnight) == 6)
      return;
   else
     {
      Print(" check for updates...");
      Print("Delete old file" + newsfile);
      FileDelete(newsfile);
      ReadWEB();
      xmlModifed = (datetime)FileGetInteger(newsfile, FILE_MODIFY_DATE, false);
      PrintFormat("Updated successfully! last modified: %s", newsfile);
     }
  }

bool Vmedium = false;
bool Vlow = false;
bool Vhigh = True;
CNews mynews[1000];
string jamberita = "";
bool judulnews = true;
int NomNews = 0;
int LastUpd = 0;
int Upd = 0;
input bool DrawLines = true; //Draw News Lines


input int MinAfter = 0; //Minutes after News
bool Next = false;
bool sendnews = sendNews;
input int BeforeNewsStop = 60;
input int AfterNewsStop = 60;
string google_urlx = "";

input string newsfile = "news.csv";
//-------- Debit/Credit total -------------------
bool StopTarget()


  {
   double ProfitValue = AccountBalance() - AccountEquity();
   if((2 / AccountBalance()) * 100 >= ProfitValue)
     {
      return (true);
     }
   return (false);
  }
//---
//+------------------------------------------------------------------+
//|                  TRADE REPORT                                                |
//+------------------------------------------------------------------+
void TradeReport()
  {
   string account;
   string  account_id;
   string phone ;
   datetime tradeSession;
   int time;
   string msgs = StringFormat(
                    "Date :%s , AccountNumber %d , AccountName %s , Balance %d, Profit %d , Open Order %n", TimeToString(TimeCurrent()), AccountNumber(), AccountName(),
                    AccountBalance()
                    , AccountProfit(), OrdersTotal()
                 );
   Print("Symbol=", Symbol());
   Print("Low day price=", MarketInfo(Symbol(), MODE_LOW));
   Print("High day price=", MarketInfo(Symbol(), MODE_HIGH));
   Print("The last incoming tick time=", (MarketInfo(Symbol(), MODE_TIME)));
   Print("Last incoming bid price=", MarketInfo(Symbol(), MODE_BID));
   Print("Last incoming ask price=", MarketInfo(Symbol(), MODE_ASK));
   Print("Point size in the quote currency=", MarketInfo(Symbol(), MODE_POINT));
   Print("Digits after decimal point=", MarketInfo(Symbol(), MODE_DIGITS));
   Print("Spread value in points=", MarketInfo(Symbol(), MODE_SPREAD));
   Print("Stop level in points=", MarketInfo(Symbol(), MODE_STOPLEVEL));
   Print("Lot size in the base currency=", MarketInfo(Symbol(), MODE_LOTSIZE));
   Print("Tick value in the deposit currency=", MarketInfo(Symbol(), MODE_TICKVALUE));
   Print("Tick size in points=", MarketInfo(Symbol(), MODE_TICKSIZE));
   Print("Swap of the buy order=", MarketInfo(Symbol(), MODE_SWAPLONG));
   Print("Swap of the sell order=", MarketInfo(Symbol(), MODE_SWAPSHORT));
   Print("Market starting date (for futures)=", MarketInfo(Symbol(), MODE_STARTING));
   Print("Market expiration date (for futures)=", MarketInfo(Symbol(), MODE_EXPIRATION));
   Print("Trade is allowed for the symbol=", MarketInfo(Symbol(), MODE_TRADEALLOWED));
   Print("Minimum permitted amount of a lot=", MarketInfo(Symbol(), MODE_MINLOT));
   Print("Step for changing lots=", MarketInfo(Symbol(), MODE_LOTSTEP));
   Print("Maximum permitted amount of a lot=", MarketInfo(Symbol(), MODE_MAXLOT));
   Print("Swap calculation method=", MarketInfo(Symbol(), MODE_SWAPTYPE));
   Print("Profit calculation mode=", MarketInfo(Symbol(), MODE_PROFITCALCMODE));
   Print("Margin calculation mode=", MarketInfo(Symbol(), MODE_MARGINCALCMODE));
   Print("Initial margin requirements for 1 lot=", MarketInfo(Symbol(), MODE_MARGININIT));
   Print("Margin to maintain open orders calculated for 1 lot=", MarketInfo(Symbol(), MODE_MARGINMAINTENANCE));
   Print("Hedged margin calculated for 1 lot=", MarketInfo(Symbol(), MODE_MARGINHEDGED));
   Print("Free margin required to open 1 lot for buying=", MarketInfo(Symbol(), MODE_MARGINREQUIRED));
   Print("Order freeze level in points=", MarketInfo(Symbol(), MODE_FREEZELEVEL));
   
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
   int gmtoffset = offset;
   timegmt = TimeGMT();
   timecurrent = TimeCurrent();
   gmthour = (int)StringToInteger(StringSubstr(TimeToStr(timegmt), 11, 2));
   gmtminute = (int)StringToInteger(StringSubstr(TimeToStr(timegmt), 14, 2));
   gmtoffset = TimeHour(timecurrent) - gmthour;
   if(gmtoffset < 0)
      gmtoffset = 24 + gmtoffset;
   return(gmtoffset);
  }
//+------------------------------------------------------------------+
//|               NEWSTRADE                                                   |
//+------------------------------------------------------------------+
bool newsTrade(string sym) //RETURN TRUE IF TRADE IS ALLOWED
  {
   double ask = MarketInfo(sym, MODE_ASK);
   double bid = MarketInfo(sym, MODE_BID);
   string InpChannel = channel;
   offset = gmtoffset();
   double CheckNews = 0;
   newsUpdate();//update news
   if(MinAfter > 0)
     {
      if(TimeCurrent() - LastUpd >= Upd)
        {
         Comment("News Loading...");
         Print("News Loading...");
         LastUpd = TimeCurrent();
         Comment("News Loading");
         
        }
      WindowRedraw();
      //---Draw a line on the chart news--------------------------------------------
      if(DrawLines==true)
        {
         for(int i = 0; i < NomNews; i++)
           {
            string Name = StringSubstr(TimeToStr(mynews[i].getMinutes(), TIME_MINUTES) + "_" + mynews[i].getImpact() + "_" + mynews[i].getTitle(), 0, 63);
        
        
            if(TimeNewsFunck(i) < TimeCurrent() && Next)
               continue;
            color clrf = clrNONE;
            if(Vhigh &&  StringFind(mynews[i].getTitle(), judulnews, 0) >= 0)
               clrf = clrRed;
            if( mynews[i].getImpact() == "High" ||  mynews[i].getImpact() == "high")
               clrf = clrRed;
            if( mynews[i].getImpact() == "Medium" || mynews[i].getImpact() == "medium")
               clrf = clrYellow;
            if( mynews[i].getImpact() == "Low"||  mynews[i].getImpact() == "low")
               clrf = clrGreen;
            if(clrf == clrNONE)
               continue;
       
               ObjectCreate(0, Name, OBJ_VLINE,0, TimeNewsFunck(i), Ask);
               ObjectSet(Name, OBJPROP_COLOR, clrf);
               ObjectSet(Name,1,9);
               ObjectSetInteger(ChartID(), Name, OBJPROP_BACK, true);
              
           }
        }
      //---------------event Processing------------------------------------
      int i;
      CheckNews = 0;
      int power = 0;
      for(i = 0; i < NomNews; i++)
        {
         google_urlx = "https://www.forexfactory.com/calendar?day";
         if(Vhigh && StringFind(mynews[i].getTitle(), judulnews, 0) >= 0)
           {
            power = 1;
            comment.SetText(1, mynews[i].getTitle() + "   Impact " + mynews[i].getImpact(), clrRed);
   
            comment.Show();
           }
         if(Vhigh && mynews[i].getImpact() == "High"||  mynews[i].getImpact() == "high")
            power = 1;
         if(Vmedium &&  mynews[i].getImpact() == "Medium"||  mynews[i].getImpact() == "medium")
            power = 2;
         if(Vlow &&  mynews[i].getImpact() == "Low"||  mynews[i].getImpact() == "low")
            power = 3;
         if(power == 0)
           {
            continue;
           }
         if(TimeCurrent() + BeforeNewsStop > TimeNewsFunck(i) && TimeCurrent() - 60 * AfterNewsStop < TimeNewsFunck(i) && mynews[i].getTitle() != "")
           {
            jamberita = "==>Within " + (string)mynews[i].getMinutes() + " minutes\n" + mynews[i].toString();
            CheckNews = 1;
            string ms;
            ms  = message = mynews[i].toString(); //get message data with format
            if(ms != message)
              {
               ms = message;
               bot.SendMessage(chatID, ms);
              }
            else
              {
               bot.SendMessage(chatID, ms);
              }
           }
         else
           {
            CheckNews = 0;
           }
         if((CheckNews == 1 && i != Now && Signal) || (CheckNews == 1 && i != Now && sendnews == true))
           {
            message = mynews[i].toString();
           bot.SendMessage(chatID, message);
            
            Now = i;
           }
         if(CheckNews > 0 && NewsFilter)
          
         if(CheckNews > 0)
           {
         
               infoberita = " we are in the framework of the news\nAttention!! News Time \n!";
               /////  We are doing here if we are in the framework of the news
               if(mynews[i].getMinutes() == AfterNewsStop - 1 && !FirstAlert && (CheckNews == 1 && i == Now && sendnews == true))
                 {
                  FirstAlert = true;
                  bot.SendMessage(chatID, "-->>First Alert\n " + message);
                 }else
               //--- second alert
               if(mynews[i].getMinutes() == BeforeNewsStop - 1 && !SecondAlert && (CheckNews == 1 && i == Now && sendnews == true))
                 {
                  bot.SendMessage(chatID, ">>Second Alert\n " + message);
                  SecondAlert = true;
                 }
                 else {        bot.SendMessage(chatID,infoberita);
                 
                   trade = false;
                   }
              
           }
         else
           {
            if(NewsFilter){
               trade = true;
            // We are out of scope of the news release (No News)
            if( mynews[i].getMinutes() == BeforeNewsStop - 1 && !SecondAlert && (CheckNews == 1 && i == Now && sendnews == true))
              {
               jamberita = " We are out of scope of the news release\n (No News)\n";
               infoberita = "Waiting......";
               bot.SendMessage(chatID, jamberita + infoberita);
              }}
           }
        }
      return trade;
     }
   return trade;
  }

//+-----------------------------------------------------------------+
//| expert initialization function                                  |
//+-----------------------------------------------------------------+
int init2()
  {
   string sym = _Symbol;
   double ask = MarketInfo(sym, MODE_ASK);
   double bid = MarketInfo(sym, MODE_BID);
   int dig = (int)MarketInfo(sym, MODE_DIGITS);
   Pip = Point;
   if(dig % 2 == 1)
      Pip *= 10;
   if(NanoAccount)
      AccountType = 10;
   else
      AccountType = 1;
   MoveTP = ND(MoveTP * Pip, dig);
   EntryOffset = ND(EntryOffset * Pip, dig);
   MADistance = ND(MADistance * Pip, dig);
   BollDistance = ND(BollDistance * Pip, dig);
   POSLPips = ND(POSLPips * Pip, dig);
   hMaxLossPips = ND(hMaxLossPips * Pip, dig);
   hTakeProfit = ND(hTakeProfit * Pip, dig);
   CloseTPPips = ND(CloseTPPips * Pip, dig);
   ForceTPPips = ND(ForceTPPips * Pip, dig);
   MinTPPips = ND(MinTPPips * Pip, dig);
   BEPlusPips = ND(BEPlusPips * Pip, dig);
   SLPips = ND(SLPips * Pip, dig);
   TSLPips = ND(TSLPips * Pip, dig);
   TSLPipsMin = ND(TSLPipsMin * Pip, dig);
   if(UseHedge)
     {
      if(HedgeSymbol == "")
         HedgeSymbol = sym;
      if(HedgeSymbol == sym)
         hThisChart = true;
      else
         hThisChart = false;
      hPip = MarketInfo(sym, MODE_POINT);
      int hDigits = MarketInfo(sym, MODE_DIGITS);
      if(hDigits % 2 == 1)
         hPip *= 10;
      if(CheckCorr(sym) > 0.9 || hThisChart)
         hPosCorr = true;
      else
         if(CheckCorr(sym) < -0.9)
            hPosCorr = false;
         else
           {
            AllowTrading = false;
            UseHedge = false;
            Print("The Hedge Symbol you have entered (" + HedgeSymbol + ") is not closely correlated to " + Symbol());
           }
      if(StringSubstr(DDorLevel, 0, 1) == "D" || StringSubstr(DDorLevel, 0, 1) == "d")
         HedgeTypeDD = true;
      else
         if(StringSubstr(DDorLevel, 0, 1) == "L" || StringSubstr(DDorLevel, 0, 1) == "l")
            HedgeTypeDD = false;
         else
            UseHedge = false;
      if(HedgeTypeDD)
        {
         HedgeStart /= 100;
         hDDStart = HedgeStart;
        }
     }
   StopTradePercent /= 100;
   ProfitSet /= 100;
   EEHoursPC /= 100;
   EELevelPC /= 100;
   hReEntryPC /= 100;
   PortionPC /= 100;
   InitialAB = AccountBalance();
   StopTradeBalance = InitialAB * (1 - StopTradePercent);
   if(Testing)
      ID = "B3Test.";
   else
      ID = DTS(Magic, 0) + ".";
   HideTestIndicators(true);
   MinLotSize = MarketInfo(Symbol(), MODE_MINLOT);
   if(MinLotSize > Lot)
     {
      Print("Lot is less than your brokers minimum lot size");
      AllowTrading = false;
     }
   LotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
   double MinLot = MathMin(MinLotSize, LotStep);
   LotMult = ND(MathMax(Lot, MinLotSize) / MinLot, 0);
   MinMult = LotMult;
   Lot = MinLot;
   if(MinLot < 0.01)
      LotDecimal = 3;
   else
      if(MinLot < 0.1)
         LotDecimal = 2;
      else
         if(MinLot < 1)
            LotDecimal = 1;
         else
            LotDecimal = 0;
   FileHandle = FileOpen(FileName, FILE_BIN | FILE_READ);
   if(FileHandle != -1)
     {
      TbF = FileReadInteger(FileHandle, LONG_VALUE);
      FileClose(FileHandle);
      Error = GetLastError();
      if(OrderSelect(TbF, SELECT_BY_TICKET))
        {
         OTbF = OrderOpenTime();
         LbF = OrderLots();
         LotMult = MathMax(1, LbF / MinLot);
         PbC = FindClosedPL(B);
         PhC = FindClosedPL(H);
         TradesOpen = true;
         if(Debug2)
            Print(FileName + " File Read: " + TbF + " Lots: " + DTS(LbF, (string)LotDecimal));
        }
      else
        {
         FileDelete(FileName);
         TbF = 0;
         OTbF = 0;
         LbF = 0;
         Error = GetLastError();
         if(Error == ERR_NO_ERROR)
           {
            if(Debug2)
               Print(FileName + " File Deleted");
           }
         else
            Print("Error deleting file: " + FileName + " " + Error + " " + ErrorDescription(Error));
        }
     }
   GlobalVariableSet(ID + "LotMult", LotMult);
   if(Debug2)
      Print("MinLotSize: " + DTS(MinLotSize, 2) + " LotStep: " + DTS(LotStep, 2) + " MinLot: " + DTS(MinLot, 2) + " StartLot: " + DTS(Lot, 2) +
            " LotMult: " + DTS(LotMult, 0) + " Lot Decimal: " + DTS(LotDecimal, 0));
   EmergencyWarning = EmergencyCloseAll;
   if(IsOptimization())
      Debug2= false;
   if(UseAnyEntry)
      UAE = "||";
   else
      UAE = "&&";
   if(ForceMarketCond < 0 || ForceMarketCond > 3)
      ForceMarketCond = 3;
   if(MAEntry < 0 || MAEntry > 2)
      MAEntry = 0;
   if(CCIEntry < 0 || CCIEntry > 2)
      CCIEntry = 0;
   if(BollingerEntry < 0 || BollingerEntry > 2)
      BollingerEntry = 0;
   if(StochEntry < 0 || StochEntry > 2)
      StochEntry = 0;
   if(MACDEntry < 0 || MACDEntry > 2)
      MACDEntry = 0;
   if(MaxCloseTrades == 0)
      MaxCloseTrades = MaxTrades;
   ArrayResize(Digit, 6);
   for(int y = 0; y < ArrayRange(Digit, 0); y++)
     {
      if(y > 0)
         Digit[y, 0] = MathPow(10, y);
      Digit[y, 1] = y;
      if(Debug2)
         Print("Digit: " + (string)y + " [" + Digit[y, 0] + "," + Digit[y, 1] + "]");
     }
   LabelCreate();
   dLabels = false;
//+-----------------------------------------------------------------+
//| Set Lot Array                                                   |
//+-----------------------------------------------------------------+
   ArrayResize(Lots, MaxTrades);
   for(int y = 0; y < MaxTrades; y++)
     {
      if(y == 0 || Multiplier < 1)
         Lots[y] = Lot;
      else
         Lots[y] = ND(MathMax(Lots[y - 1] * Multiplier, Lots[y - 1] + LotStep), LotDecimal);
      if(Debug2)
         Print("Lot Size for level " + DTS(y + 1, 0) + " : " + DTS(Lots[y]*MathMax(LotMult, 1), LotDecimal));
     }
   if(Multiplier < 1)
      Multiplier = 1;
//+-----------------------------------------------------------------+
//| Set Grid and TP array                                           |
//+-----------------------------------------------------------------+
   if(!AutoCal)
     {
      int GridSet, GridTemp;
      ArrayResize(GridArray, MaxTrades);
      if(IsOptimization() && UseGridOpt)
        {
         if(SetArray1 > 0)
           {
            SetCountArray = DTS(SetArray1, 0);
            GridSetArray = DTS(GridArray1, 0);
            TP_SetArray = DTS(TPArray1, 0);
           }
         if(SetArray2 > 0 || (SetArray1 > 0 && GridArray2 > 0))
           {
            if(SetArray2 > 0)
               SetCountArray = SetCountArray + "," + DTS(SetArray2, 0);
            GridSetArray = GridSetArray + "," + DTS(GridArray2, 0);
            TP_SetArray = TP_SetArray + "," + DTS(TPArray2, 0);
           }
         if(SetArray3 > 0 || (SetArray2 > 0 && GridArray3 > 0))
           {
            if(SetArray3 > 0)
               SetCountArray = SetCountArray + "," + DTS(SetArray3, 0);
            GridSetArray = GridSetArray + "," + DTS(GridArray3, 0);
            TP_SetArray = TP_SetArray + "," + DTS(TPArray3, 0);
           }
         if(SetArray4 > 0 || (SetArray3 > 0 && GridArray4 > 0))
           {
            if(SetArray4 > 0)
               SetCountArray = SetCountArray + "," + DTS(SetArray4, 0);
            GridSetArray = GridSetArray + "," + DTS(GridArray4, 0);
            TP_SetArray = TP_SetArray + "," + DTS(TPArray4, 0);
           }
         if(SetArray4 > 0 && GridArray5 > 0)
           {
            GridSetArray = GridSetArray + "," + DTS(GridArray5, 0);
            TP_SetArray = TP_SetArray + "," + DTS(TPArray5, 0);
           }
        }
      while(GridIndex < MaxTrades)
        {
         if(StringFind(SetCountArray, ",") == -1 && GridIndex == 0)
           {
            GridError = 1;
            break;
           }
         else
            GridSet = StrToInteger(StringSubstr(SetCountArray, 0, StringFind(SetCountArray, ",")));
         if(GridSet > 0)
           {
            SetCountArray = StringSubstr(SetCountArray, StringFind(SetCountArray, ",") + 1);
            GridTemp = StrToInteger(StringSubstr(GridSetArray, 0, StringFind(GridSetArray, ",")));
            GridSetArray = StringSubstr(GridSetArray, StringFind(GridSetArray, ",") + 1);
            GridTP = StrToInteger(StringSubstr(TP_SetArray, 0, StringFind(TP_SetArray, ",")));
            TP_SetArray = StringSubstr(TP_SetArray, StringFind(TP_SetArray, ",") + 1);
           }
         else
            GridSet = MaxTrades;
         if(GridTemp == 0 || GridTP == 0)
           {
            GridError = 2;
            break;
           }
         for(GridLevel = GridIndex; GridLevel <= MathMin(GridIndex + GridSet - 1, MaxTrades - 1); GridLevel++)
           {
            GridArray[GridLevel, 0] = GridTemp;
            GridArray[GridLevel, 1] = GridTP;
            if(Debug2)
               Print("GridArray " + (GridLevel + 1) + "  : [" + GridArray[GridLevel, 0] + "," + GridArray[GridLevel, 1] + "]");
           }
         GridIndex = GridLevel;
        }
      if(GridError > 0 || GridArray[0, 0] == 0 || GridArray[0, 1] == 0)
        {
         if(GridError == 1)
            Print("Grid Array Error. Each value should be separated by a comma.");
         else
            Print("Grid Array Error. Check that there is one more 'Grid' and 'TP' number than there are 'Set' numbers, separated by commas.");
         AllowTrading = false;
        }
     }
   else
     {
      while(GridIndex < 4)
        {
         int GridSet = StrToInteger(StringSubstr(SetCountArray, 0, StringFind(SetCountArray, ",")));
         SetCountArray = StringSubstr(SetCountArray, StringFind(SetCountArray, DTS(GridSet, 0)) + 2);
         if(GridIndex == 0 && GridSet < 1)
           {
            GridError = 1;
            break;
           }
         if(GridSet > 0)
            GridLevel += GridSet;
         else
            if(GridLevel < MaxTrades)
               GridLevel = MaxTrades;
            else
               GridLevel = MaxTrades + 1;
         if(GridIndex == 0)
            Set1Level = GridLevel;
         else
            if(GridIndex == 1 && GridLevel <= MaxTrades)
               Set2Level = GridLevel;
            else
               if(GridIndex == 2 && GridLevel <= MaxTrades)
                  Set3Level = GridLevel;
               else
                  if(GridIndex == 3 && GridLevel <= MaxTrades)
                     Set4Level = GridLevel;
         GridIndex++;
        }
      if(GridError == 1 || Set1Level == 0)
        {
         Print("Error setting up the Grid Levels. Check that the SetCountArray has valid numbers, separated by a comma.");
         AllowTrading = false;
        }
     }
//+-----------------------------------------------------------------+
//| Set holidays array                                              |
//+-----------------------------------------------------------------+
   if(UseHolidayShutdown)
     {
      int HolTemp, NumHols, NumBS, HolCounter;
      string HolTempStr;
      if(StringFind(Holidays, ",", 0) == -1)
         NumHols = 1;
      else
        {
         NumHols = 1;
         while(HolTemp != -1)
           {
            HolTemp = StringFind(Holidays, ",", HolTemp + 1);
            if(HolTemp != -1)
               NumHols += 1;
           }
        }
      HolTemp = 0;
      while(HolTemp != -1)
        {
         HolTemp = StringFind(Holidays, "/", HolTemp + 1);
         if(HolTemp != -1)
            NumBS += 1;
        }
      if(NumBS != NumHols * 2)
        {
         Print("Holidays Error, number of back-slashes (" + (string)NumBS + ") should be equal to 2* number of Holidays (" + NumHols +
               ", and separators should be a comma.");
         AllowTrading = false;
        }
      else
        {
         HolTemp = 0;
         ArrayResize(HolArray, NumHols);
         while(HolTemp != -1)
           {
            if(HolTemp == 0)
               HolTempStr = StringTrimLeft(StringTrimRight(StringSubstr(Holidays, 0, StringFind(Holidays, ",", HolTemp))));
            else
               HolTempStr = StringTrimLeft(StringTrimRight(StringSubstr(Holidays, HolTemp + 1,
                                           StringFind(Holidays, ",", HolTemp + 1) - StringFind(Holidays, ",", HolTemp) - 1)));
            HolTemp = StringFind(Holidays, ",", HolTemp + 1);
            HolArray[HolCounter, 0] = StrToInteger(StringSubstr(StringSubstr(HolTempStr, 0, StringFind(HolTempStr, "-", 0)),
                                                   StringFind(StringSubstr(HolTempStr, 0, StringFind(HolTempStr, "-", 0)), "/") + 1));
            HolArray[HolCounter, 1] = StrToInteger(StringSubstr(StringSubstr(HolTempStr, 0, StringFind(HolTempStr, "-", 0)), 0,
                                                   StringFind(StringSubstr(HolTempStr, 0, StringFind(HolTempStr, "-", 0)), "/")));
            HolArray[HolCounter, 2] = StrToInteger(StringSubstr(StringSubstr(HolTempStr, StringFind(HolTempStr, "-", 0) + 1),
                                                   StringFind(StringSubstr(HolTempStr, StringFind(HolTempStr, "-", 0) + 1), "/") + 1));
            HolArray[HolCounter, 3] = StrToInteger(StringSubstr(StringSubstr(HolTempStr, StringFind(HolTempStr, "-", 0) + 1), 0,
                                                   StringFind(StringSubstr(HolTempStr, StringFind(HolTempStr, "-", 0) + 1), "/")));
            HolCounter += 1;
           }
        }
      for(HolTemp = 0; HolTemp < HolCounter; HolTemp++)
        {
         int Start1, Start2, Temp0, Temp1, Temp2, Temp3;
         for(int Item1 = HolTemp + 1; Item1 < HolCounter; Item1++)
           {
            Start1 = HolArray[HolTemp, 0] * 100 + HolArray[HolTemp, 1];
            Start2 = HolArray[Item1, 0] * 100 + HolArray[Item1, 1];
            if(Start1 > Start2)
              {
               Temp0 = (int)HolArray[Item1, 0];
               Temp1 = (int)HolArray[Item1, 1];
               Temp2 = (int)HolArray[Item1, 2];
               Temp3 = (int)HolArray[Item1, 3];
               HolArray[Item1, 0] = HolArray[HolTemp, 0];
               HolArray[Item1, 1] = HolArray[HolTemp, 1];
               HolArray[Item1, 2] = HolArray[HolTemp, 2];
               HolArray[Item1, 3] = HolArray[HolTemp, 3];
               HolArray[HolTemp, 0] = Temp0;
               HolArray[HolTemp, 1] = Temp1;
               HolArray[HolTemp, 2] = Temp2;
               HolArray[HolTemp, 3] = Temp3;
              }
           }
        }
      if(Debug2)
        {
         for(HolTemp = 0; HolTemp < HolCounter; HolTemp++)
            Print("Holidays - From: ", HolArray[HolTemp, 1], "/", HolArray[HolTemp, 0], " - ", HolArray[HolTemp, 3], "/", HolArray[HolTemp, 2]);
        }
     }
//+-----------------------------------------------------------------+
//| Set email parameters                                            |
//+-----------------------------------------------------------------+
   if(UseEmail)
     {
      if(Period() == 43200)
         sTF = "MN1";
      else
         if(Period() == 10800)
            sTF = "W1";
         else
            if(Period() == 1440)
               sTF = "D1";
            else
               if(Period() == 240)
                  sTF = "H4";
               else
                  if(Period() == 60)
                     sTF = "H1";
                  else
                     if(Period() == 30)
                        sTF = "M30";
                     else
                        if(Period() == 15)
                           sTF = "M15";
                        else
                           if(Period() == 5)
                              sTF = "M5";
                           else
                              if(Period() == 1)
                                 sTF = "M1";
      Email[0] = MathMax(MathMin(EmailDD1, MaxDDPercent - 1), 0) / 100;
      Email[1] = MathMax(MathMin(EmailDD2, MaxDDPercent - 1), 0) / 100;
      Email[2] = MathMax(MathMin(EmailDD3, MaxDDPercent - 1), 0) / 100;
      ArraySort(Email, WHOLE_ARRAY, 0, MODE_ASCEND);
      for(int z = 0; z <= 2; z++)
        {
         for(int y = 0; y <= 2; y++)
           {
            if(Email[y] == 0)
              {
               Email[y] = Email[y + 1];
               Email[y + 1] = 0;
              }
           }
         if(Debug2)
            Print("Email [" + (z + 1) + "] : " + Email[z]);
        }
     }
//+-----------------------------------------------------------------+
//| Set SmartGrid parameters                                        |
//+-----------------------------------------------------------------+
   if(UseSmartGrid)
     {
      ArrayResize(RSI, RSI_Period + RSI_MA_Period);
      ArraySetAsSeries(RSI, true);
     }
//+---------------------------------------------------------------+
//| Initialize Statistics                                         |
//+---------------------------------------------------------------+
   if(SaveStats)
     {
      StatFile = "B3" + sym + "_" + Period() + "_" + "zones_ea" + ".csv";
      NextStats = TimeCurrent();
      Stats(StatsInitialise, false, AccountBalance()*PortionPC, 0);
     }
   return(0);
  }
//+------------------------------------------------------------------+
//|   OnInit                                                         |
//+------------------------------------------------------------------+
int OnInit()
  {
  OnInit2();
   ChartColorSet();//SET CHART COLOR
// for single account licence you can remove the slash followed by a star
   string broker = AccountInfoString(ACCOUNT_COMPANY);
   long account = AccountInfoInteger(ACCOUNT_LOGIN);
   printf("The name of the broker = %s", broker);
   printf("Account number =  %d", account);
//Check ea status before all
   printf("This EA is valid until %s", TimeToString(allowed_until, TIME_DATE | TIME_MINUTES));
   Comment("This EA is valid until %s", TimeToString(allowed_until, TIME_DATE | TIME_MINUTES));
   datetime now = TimeCurrent();
//if(now > allowed_until)
//   Comment("EA EXPIRED since " + allowed_until + "\n Please contact support at https://t.me/+EgyQSXmXuPhjNTJh");
//return 0;
   Print("EA time limit verified, EA init time : " + TimeToString(now, TIME_DATE | TIME_MINUTES));
   CS = "Waiting for next tick .";   // To display comments while testing, simply use CS = .... and
   Comment(CS);                        // it will be displayed by the line at the end of the start() block.
   CS = "";
   Testing = IsTesting();
   Visual = IsVisualMode();
   FirstRun = true;
   AllowTrading = true;
   Magic = GenerateMagicNumber(Symbol());
   hMagic = JenkinsHash(Magic);
   FileName = "B3_" + (string)Magic + ".dat";
   init2();
   if(Debug2)
     {
      Print("Magic Number: " + DTS(Magic, 0));
      Print("Hedge Number: " + DTS(hMagic, 0));
      Print("FileName: " + FileName);
     }
   if(!IsTesting())
     {
      //---
      run_mode = GetRunMode();
      //--- stop working in tester
      if(run_mode != RUN_LIVE)
        {
         PrintError(ERR_RUN_LIMITATION, InpLanguage);
         return(INIT_FAILED);
        }
      int y = 40;
      if(ChartGetInteger(0, CHART_SHOW_ONE_CLICK))
         y = 120;
      comment.Create("myPanel", 20, y);
      comment.SetColor(clrDimGray, clrGreen, 220);
      //--- set language
      bot.Language(InpLanguage);
      //--- set token
      init_error = bot.Token(InpToken);
      //--- set filter
      bot.UserNameFilter(InpUserNameFilter);
      //--- set templates
      bot.Templates(InpTemplates);
      datetime time = __DATETIME__  ;
      //--- set timer
      int timer_ms = 3000;
      switch(InpUpdateMode)
        {
         case UPDATE_FAST:
            timer_ms = 1000;
            break;
         case UPDATE_NORMAL:
            timer_ms = 2000;
            break;
         case UPDATE_SLOW:
            timer_ms = 3000;
            break;
         default:
            timer_ms = 3000;
            break;
        };
      EventSetMillisecondTimer(timer_ms);
      OnTimer();
     }
//--- done
   return(INIT_SUCCEEDED);
  }

//+-----------------------------------------------------------------+
//| expert deinitialization function                                |
//+-----------------------------------------------------------------+
 void deinits()
  {
   switch(UninitializeReason())
     {
      case REASON_REMOVE:
      case REASON_CHARTCLOSE:
      case REASON_CHARTCHANGE:
         if(CpT > 0)
            while(CpT > 0)
               CpT -= ExitTrades(P, displayColorLoss, "zones_ea Removed");
         GlobalVariablesDeleteAll(ID);
      case REASON_RECOMPILE:
      case REASON_PARAMETERS:
      case REASON_ACCOUNT:
         if(!Testing)
            LabelDelete();
         Comment("");
     }
  
  }

//+------------------------------------------------------------------+
//|   OnDeinit                                                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   if(reason == REASON_CLOSE ||
      reason == REASON_PROGRAM ||
      reason == REASON_PARAMETERS ||
      reason == REASON_REMOVE ||
      reason == REASON_RECOMPILE ||
      reason == REASON_ACCOUNT ||
      reason == REASON_INITFAILED)
     {
      time_check = 0;
      comment.Destroy();
      deinits();
      OnDeinit2(reason);
     }
//---
   EventKillTimer();
   ChartRedraw();
  }
//+------------------------------------------------------------------+
//|   OnChartEvent                                                   |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   comment.OnChartEvent(id, lparam, dparam, sparam);
  }
//+------------------------------------------------------------------+
//|   OnTimer                                                        |
//+------------------------------------------------------------------+
void OnTimer()
  {
  
 
//--- show init error
   if(init_error != 0)
     {
      //--- show error on display
      CustomInfo info;
      GetCustomInfo(info, init_error, InpLanguage);
      //---
      comment.Clear();
      comment.SetText(0, StringFormat("%s v.%s", EXPERT_NAME, EXPERT_VERSION), CAPTION_COLOR);
      comment.SetText(1, info.text1, LOSS_COLOR);
      bot.SendMessage(channel, info.text1 + info.text2);
      if(info.text2 != "")
         comment.SetText(2, info.text2, LOSS_COLOR);
      comment.Show();
      return;
     }
//--- show web error
   if(run_mode == RUN_LIVE)
     { OnTimer2();
      bot.ProcessMessages();
     
      TradeReport();
      //--- check bot registration
      if(time_check < TimeLocal() - PeriodSeconds(PERIOD_H1))
        {
         time_check = TimeLocal();
         if(TerminalInfoInteger(TERMINAL_CONNECTED))
           {
            //---
            web_error = bot.GetMe();
            if(web_error != 0)
              {
               //---
               if(web_error == ERR_NOT_ACTIVE)
                 {
                  time_check = TimeCurrent() - PeriodSeconds(PERIOD_H1) + 300;
                 }
               //---
               else
                 {
                  time_check = TimeCurrent() - PeriodSeconds(PERIOD_H1) + 5;
                 }
              }
           }
         else
           {
            web_error = ERR_NOT_CONNECTED;
            time_check = 0;
           }
        }
      //--- show error
      if(web_error != 0)
        {
         comment.Clear();
         comment.SetText(0, StringFormat("%s v.%s", EXPERT_NAME, EXPERT_VERSION), CAPTION_COLOR);
         if(
#ifdef __MQL4__ web_error==ERR_FUNCTION_NOT_CONFIRMED #endif
#ifdef __MQL5__ web_error==ERR_FUNCTION_NOT_ALLOWED #endif
         )
           {
            time_check = 0;
            CustomInfo info = {0};
            GetCustomInfo(info, web_error, InpLanguage);
            comment.SetText(1, info.text1, LOSS_COLOR);
            comment.SetText(2, info.text2, LOSS_COLOR);
           }
         else
            comment.SetText(1, GetErrorDescription(web_error, InpLanguage), LOSS_COLOR);
         comment.Show();
         return;
        }
     }
//---
   bot.GetUpdates();
//---
   if(run_mode == RUN_LIVE)
     {
      comment.Clear();
      comment.SetText(0, StringFormat("%s v.%s", EXPERT_NAME, EXPERT_VERSION), CAPTION_COLOR);
      comment.SetText(1, StringFormat("%s: %s", (InpLanguage == LANGUAGE_EN) ? "Bot Name" : "Имя Бота", bot.Name()), CAPTION_COLOR);
      comment.SetText(2, StringFormat("%s: %d", (InpLanguage == LANGUAGE_EN) ? "Chats" : "Чаты", bot.ChatsTotal()), CAPTION_COLOR);
      comment.Show();
     }
//---
   bot.ProcessMessages();
  }
//+------------------------------------------------------------------+
//|   GetCustomInfo                                                  |
//+------------------------------------------------------------------+
void GetCustomInfo(CustomInfo &info,
                   const int _error_code,
                   const ENUM_LANGUAGES _lang)
  {
   switch(_error_code)
     {
#ifdef __MQL5__
      case ERR_FUNCTION_NOT_ALLOWED:
         info.text1 = (_lang == LANGUAGE_EN) ? "The URL does not allowed for WebRequest" : "Этого URL нет в списке для WebRequest.";
         info.text2 = TELEGRAM_BASE_URL;
         break;
#endif
#ifdef __MQL4__
      case ERR_FUNCTION_NOT_CONFIRMED:
         info.text1 = (_lang == LANGUAGE_EN) ? "The URL does not allowed for WebRequest" : "Этого URL нет в списке для WebRequest.";
         info.text2 = TELEGRAM_BASE_URL;
         break;
#endif
      case ERR_TOKEN_ISEMPTY:
         info.text1 = (_lang == LANGUAGE_EN) ? "The 'Token' parameter is empty." : "Параметр 'Token' пуст.";
         info.text2 = (_lang == LANGUAGE_EN) ? "Please fill this parameter." : "Пожалуйста задайте значение для этого параметра.";
         break;
     }
  }
//+------------------------------------------------------------------+


int LotDigits; //initialized in OnInit
int MagicNumber = 1088884;
int NextOpenTradeAfterMinutes = 59; //next open trade after time
int PendingOrderExpirationMinutes = 60; //pending order expiration
double DeleteOrderAtDistance = 20; //delete order when too far from current price
double MM_Martingale_Start = 0.1;
double MM_Martingale_ProfitFactor = 1;
double MM_Martingale_LossFactor = 2;
bool MM_Martingale_RestartProfit = true;
bool MM_Martingale_RestartLoss = false;
int MM_Martingale_RestartLosses = 3;
int MM_Martingale_RestartProfits = 3;
int MaxSlippage = 3; //slippage, adjusted in OnInit
bool TradeMonday = true;
bool TradeTuesday = true;
bool TradeWednesday = true;
bool TradeThursday = true;
bool TradeFriday = true;
bool TradeSaturday = false;
bool TradeSunday = true;
double MaxSL = 200;
double MinSL = 100;
double MaxTP = 400;
double MinTP = 200;
double CloseAtPL = 200;
double PriceTooClose = 50;
bool crossed[4]; //initialized to true, used in function Cross
int MaxOpenTrades = 15;
int MaxLongTrades = 16;
int MaxShortTrades = 12;
int MaxPendingOrders = 23;
int MaxLongPendingOrders = 12;
int MaxShortPendingOrders = 12;
bool Hedging = true;
int OrderRetry = 5; //# of retries if sending order returns error
int OrderWait = 5; //# of seconds to wait if sending order returns error
double myPoint; //initialized in OnInit

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeleteByDuration(int sec, string sym) //delete pending order after time since placing the order
  {
   if(!IsTradeAllowed())
      return;
   bool success = false;
   int err = 0;
   int total = OrdersTotal();
   ulong orderList[][2];
   int orderCount = 0;
   int i;
   for(i = 0; i < total; i++)
     {
      while(IsTradeContextBusy())
         Sleep(100);
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;
      if(OrderMagicNumber() != MagicNumber || OrderSymbol() != sym || OrderType() <= 1 || OrderOpenTime() + sec > TimeCurrent())
         continue;
      orderCount++;
      ArrayResize(orderList, orderCount);
      orderList[orderCount - 1][0] = OrderOpenTime();
      orderList[orderCount - 1][1] = OrderTicket();
     }
   if(orderCount > 0)
      ArraySort(orderList, WHOLE_ARRAY, 0, MODE_ASCEND);
   for(i = 0; i < orderCount; i++)
     {
      if(!OrderSelect(orderList[i][1], SELECT_BY_TICKET, MODE_TRADES))
         continue;
      while(IsTradeContextBusy())
         Sleep(100);
      RefreshRates();
      success = OrderDelete(OrderTicket());
      if(!success)
        {
         err = GetLastError();
         myAlert("error", "OrderDelete failed; error #" + IntegerToString(err) + " " + ErrorDescription(err), sym);
        }
     }
   if(success)
      myAlert("order", "Orders deleted by duration: " + sym + " Magic #" + IntegerToString(MagicNumber), sym);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeleteByDistance(double distance, string sym) //delete pending order if price went too far from it
  {
   double ask = MarketInfo(sym, MODE_ASK);
   double bid = MarketInfo(sym, MODE_BID);
   if(!IsTradeAllowed())
      return;
   bool success = false;
   int err = 0;
   int total = OrdersTotal();
   ulong orderList[][2];
   int orderCount = 0;
   int i;
   for(i = 0; i < total; i++)
     {
      while(IsTradeContextBusy())
         Sleep(100);
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;
      if(OrderMagicNumber() != MagicNumber || OrderSymbol() != Symbol() || OrderType() <= 1)
         continue;
      orderCount++;
      ArrayResize(orderList, orderCount);
      orderList[orderCount - 1][0] = OrderOpenTime();
      orderList[orderCount - 1][1] = OrderTicket();
     }
   if(orderCount > 0)
      ArraySort(orderList, WHOLE_ARRAY, 0, MODE_ASCEND);
   for(i = 0; i < orderCount; i++)
     {
      if(!OrderSelect(orderList[i][1], SELECT_BY_TICKET, MODE_TRADES))
         continue;
      while(IsTradeContextBusy())
         Sleep(100);
      RefreshRates();
      double price = (OrderType() % 2 == 1) ? ask : bid;
      if(MathAbs(OrderOpenPrice() - price) <= distance)
         continue;
      success = OrderDelete(OrderTicket());
      if(!success)
        {
         err = GetLastError();
         myAlert("error", "OrderDelete failed; error #" + IntegerToString(err) + " " + ErrorDescription(err), sym);
        }
     }
   if(success)
      myAlert("order", "Orders deleted by distance: " + sym + " Magic #" + IntegerToString(MagicNumber), sym);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MM_Size(string symbol) //martingale / anti-martingale
  {
   double lots = MM_Martingale_Start;
   double MaxLot = MarketInfo(symbol, MODE_MAXLOT);
   double MinLot = MarketInfo(symbol, MODE_MINLOT);
   if(SelectLastHistoryTrade(symbol))
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
   if(ConsecutivePL(false, MM_Martingale_RestartLosses, symbol))
      lots = MM_Martingale_Start;
   if(ConsecutivePL(true, MM_Martingale_RestartProfits, symbol))
      lots = MM_Martingale_Start;
   if(lots > MaxLot)
      lots = MaxLot;
   if(lots < MinLot)
      lots = MinLot;
   return(lots);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
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

void CloseTradesAtPL(double PL, string sym) //close all trades if total P/L >= profit (positive) or total P/L <= loss (negative)
  {
   double totalPL = TotalOpenProfit(0, sym);
   if((PL > 0 && totalPL >= PL) || (PL < 0 && totalPL <= PL))
     {
      myOrderClose(OP_BUY, 100, "", sym);
      myOrderClose(OP_SELL, 100, "", sym);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Cross(int i, bool condition) //returns true if "condition" is true and was false in the previous call
  {
   bool ret = condition && !crossed[i];
   crossed[i] = condition;
   return(ret);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void myAlert(string type, string message, string sym)
  {
   if(type == "print")
      Print(message);
   else
      if(type == "error")
        {
         Print(type + " | tab @ " + sym + "," + IntegerToString(Period()) + " | " + message);
         bot.SendMessage(channel, type + " | Zones EA @ " + sym + "," + IntegerToString(Period()) + " | " + message);
        }
      else
         if(type == "order")
           {
           }
         else
            if(type == "modify")
              {
              }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int TradesCount(int type, string sym) //returns # of open trades for order type, current symbol and magic number
  {
   int result = 0;
   int total = OrdersTotal();
   for(int i = 0; i < total; i++)
     {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false)
         continue;
      if(OrderMagicNumber() != MagicNumber || OrderSymbol() != sym || OrderType() != type)
         continue;
      result++;
     }
   return(result);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime LastOpenTradeTime(string sym)
  {
   datetime result = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;
      if(OrderType() > 1)
         continue;
      if(OrderSymbol() == sym && OrderMagicNumber() == MagicNumber)
        {
         result = OrderOpenTime();
         break;
        }
     }
   return(result);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SelectLastHistoryTrade(string sym)
  {
   int lastOrder = -1;
   int total = OrdersHistoryTotal();
   for(int i = total - 1; i >= 0; i--)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
         continue;
      if(OrderSymbol() == sym && OrderMagicNumber() == MagicNumber)
        {
         lastOrder = i;
         break;
        }
     }
   return(lastOrder >= 0);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double BOProfit(int ticket) //Binary Options profit
  {
   int total = OrdersHistoryTotal();
   for(int i = total - 1; i >= 0; i--)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
         continue;
      if(StringSubstr(OrderComment(), 0, 2) == "BO" && StringFind(OrderComment(), "#" + IntegerToString(ticket) + " ") >= 0)
         return OrderProfit();
     }
   return 0;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ConsecutivePL(bool profits, int n, string sym)
  {
   int count = 0;
   int total = OrdersHistoryTotal();
   for(int i = total - 1; i >= 0; i--)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
         continue;
      if(OrderSymbol() == sym && OrderMagicNumber() == MagicNumber)
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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double TotalOpenProfit(int direction, string sym)
  {
   double result = 0;
   int total = OrdersTotal();
   for(int i = 0; i < total; i++)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;
      if(OrderSymbol() != sym || OrderMagicNumber() != MagicNumber)
         continue;
      if((direction < 0 && OrderType() == OP_BUY) || (direction > 0 && OrderType() == OP_SELL))
         continue;
      result += OrderProfit();
     }
   return(result);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime LastOpenTime(string sym)
  {
   datetime opentime1 = 0, opentime2 = 0;
   if(SelectLastHistoryTrade(sym))
      opentime1 = OrderOpenTime();
   opentime2 = LastOpenTradeTime(sym);
   if(opentime1 > opentime2)
      return opentime1;
   else
      return opentime2;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int myOrderModify(int ticket, double SL, double TP, string sym) //modify SL and TP (absolute price), zero targets do not modify
  {
   double ask = MarketInfo(sym, MODE_ASK);
   double bid = MarketInfo(sym, MODE_BID);
   int dig = MarketInfo(sym, MODE_DIGITS);
   if(!IsTradeAllowed())
      return(-1);
   bool success = false;
   int retries = 0;
   int err = 0;
   SL = NormalizeDouble(SL, dig);
   TP = NormalizeDouble(TP, dig);
   if(SL < 0)
      SL = 0;
   if(TP < 0)
      TP = 0;
//prepare to select order
   while(IsTradeContextBusy())
      Sleep(100);
   if(!OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
     {
      err = GetLastError();
      myAlert("error", "OrderSelect failed; error #" + IntegerToString(err) + " " + ErrorDescription(err), sym);
      return(-1);
     }
//prepare to modify order
   while(IsTradeContextBusy())
      Sleep(100);
   RefreshRates();
//adjust targets for market order if too close to the market price
   double MinDistance = PriceTooClose * myPoint;
   if(OrderType() == OP_BUY)
     {
      if(NormalizeDouble(SL, dig) != 0 && ask - SL < MinDistance)
         SL = ask - MinDistance;
      if(NormalizeDouble(TP, dig) != 0 && TP - ask < MinDistance)
         TP = ask + MinDistance;
     }
   else
      if(OrderType() == OP_SELL)
        {
         if(NormalizeDouble(SL, dig) != 0 && SL - bid < MinDistance)
            SL = bid + MinDistance;
         if(NormalizeDouble(TP, dig) != 0 && bid - TP < MinDistance)
            TP = bid - MinDistance;
        }
   if(CompareDoubles(SL, 0))
      SL = OrderStopLoss(); //not to modify
   if(CompareDoubles(TP, 0))
      TP = OrderTakeProfit(); //not to modify
   if(CompareDoubles(SL, OrderStopLoss()) && CompareDoubles(TP, OrderTakeProfit()))
      return(0); //nothing to do
   while(!success && retries < OrderRetry + 1)
     {
      success = OrderModify(ticket, NormalizeDouble(OrderOpenPrice(), dig), NormalizeDouble(SL, dig), NormalizeDouble(TP, dig), OrderExpiration(), CLR_NONE);
      if(!success)
        {
         err = GetLastError();
         myAlert("print", "OrderModify error #" + IntegerToString(err) + " " + ErrorDescription(err), sym);
         Sleep(OrderWait * 1000);
        }
      retries++;
     }
   if(!success)
     {
      myAlert("error", "OrderModify failed " + IntegerToString(OrderRetry + 1) + " times; error #" + IntegerToString(err) + " " + ErrorDescription(err), sym);
      return(-1);
     }
   string alertstr = "Order modified: ticket=" + IntegerToString(ticket);
   if(!CompareDoubles(SL, 0))
      alertstr = alertstr + " SL=" + DoubleToString(SL);
   if(!CompareDoubles(TP, 0))
      alertstr = alertstr + " TP=" + DoubleToString(TP);
   myAlert("modify", alertstr, sym);
   return(0);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void myOrderClose(int type, double volumepercent, string ordername, string sym) //close open orders for current symbol, magic number and "type" (OP_BUY or OP_SELL)
  {
   double ask = MarketInfo(sym, MODE_ASK);
   double bid = MarketInfo(sym, MODE_BID);
   int dig = MarketInfo(sym, MODE_DIGITS);
   if(!IsTradeAllowed())
      return;
   if(type > 1)
     {
      myAlert("error", "Invalid type in myOrderClose", sym);
      return;
     }
   bool success = false;
   int retries = 0;
   int err = 0;
   string ordername_ = ordername;
   if(ordername != "")
      ordername_ = "(" + ordername + ")";
   int total = OrdersTotal();
   ulong orderList[][2];
   int orderCount = 0;
   int i;
   for(i = 0; i < total; i++)
     {
      while(IsTradeContextBusy())
         Sleep(100);
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;
      if(OrderMagicNumber() != MagicNumber || OrderSymbol() != sym || OrderType() != type)
         continue;
      orderCount++;
      ArrayResize(orderList, orderCount);
      orderList[orderCount - 1][0] = OrderOpenTime();
      orderList[orderCount - 1][1] = OrderTicket();
     }
   if(orderCount > 0)
      ArraySort(orderList, WHOLE_ARRAY, 0, MODE_ASCEND);
   for(i = 0; i < orderCount; i++)
     {
      if(!OrderSelect(orderList[i][1], SELECT_BY_TICKET, MODE_TRADES))
         continue;
      while(IsTradeContextBusy())
         Sleep(100);
      RefreshRates();
      double price = (type == OP_SELL) ? ask : bid;
      double volume = NormalizeDouble(OrderLots() * volumepercent * 1.0 / 100, LotDigits);
      if(NormalizeDouble(volume, LotDigits) == 0)
         continue;
      success = false;
      retries = 0;
      while(!success && retries < OrderRetry + 1)
        {
         success = OrderClose(OrderTicket(), volume, NormalizeDouble(price, dig), MaxSlippage, clrWhite);
         if(!success)
           {
            err = GetLastError();
            myAlert("print", "OrderClose" + ordername_ + " failed; error #" + IntegerToString(err) + " " + ErrorDescription(err), sym);
            Sleep(OrderWait * 1000);
           }
         retries++;
        }
      if(!success)
        {
         myAlert("error", "OrderClose" + ordername_ + " failed " + IntegerToString(OrderRetry + 1) + " times; error #" + IntegerToString(err) + " " + ErrorDescription(err), sym);
         return;
        }
     }
   string typestr[6] = {"Buy", "Sell", "Buy Limit", "Sell Limit", "Buy Stop", "Sell Stop"};
   if(success)
      myAlert("order", "Orders closed" + ordername_ + ": " + typestr[type] + " " + Symbol() + " Magic #" + IntegerToString(MagicNumber), sym);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawLine(string objname, double price, int count, int start_index) //creates or modifies existing object if necessary
  {
   if((price < 0) && ObjectFind(objname) >= 0)
     {
      ObjectDelete(objname);
     }
   else
      if(ObjectFind(objname) >= 0 && ObjectType(objname) == OBJ_TREND)
        {
         ObjectSet(objname, OBJPROP_TIME1, Time[start_index]);
         ObjectSet(objname, OBJPROP_PRICE1, price);
         ObjectSet(objname, OBJPROP_TIME2, Time[start_index + count - 1]);
         ObjectSet(objname, OBJPROP_PRICE2, price);
        }
      else
        {
         ObjectCreate(objname, OBJ_TREND, 0, Time[start_index], price, Time[start_index + count - 1], price);
         ObjectSet(objname, OBJPROP_RAY, false);
         ObjectSet(objname, OBJPROP_COLOR, C'0x00,0x00,0xFF');
         ObjectSet(objname, OBJPROP_STYLE, STYLE_SOLID);
         ObjectSet(objname, OBJPROP_WIDTH, 2);
        }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Support(int time_interval, bool fixed_tod, int hh, int mm, bool draw, int shift)
  {
   int start_index = shift;
   int count = time_interval / 60 / Period();
   if(fixed_tod)
     {
      datetime start_time;
      if(shift == 0)
         start_time = TimeCurrent();
      else
         start_time = Time[shift - 1];
      datetime dt = StringToTime(StringConcatenate(TimeToString(start_time, TIME_DATE), " ", hh, ":", mm)); //closest time hh:mm
      if(dt > start_time)
         dt -= 86400; //go 24 hours back
      int dt_index = iBarShift(NULL, 0, dt, true);
      datetime dt2 = dt;
      while(dt_index < 0 && dt > Time[Bars - 1 - count]) //bar not found => look a few days back
        {
         dt -= 86400; //go 24 hours back
         dt_index = iBarShift(NULL, 0, dt, true);
        }
      if(dt_index < 0)  //still not found => find nearest bar
         dt_index = iBarShift(NULL, 0, dt2, false);
      start_index = dt_index + 1; //bar after S/R opens at dt
     }
   double ret = Low[iLowest(NULL, 0, MODE_LOW, count, start_index)];
   if(draw)
      DrawLine("Support", ret, count, start_index);
   return(ret);
  }

//+------------------------------------------------------------------+
//|                           RESISTANCE                                       |
//+------------------------------------------------------------------+
double Resistance(int time_interval, bool fixed_tod, int hh, int mm, bool draw, int shift)
  {
   int start_index = shift;
   int count = time_interval / 60 / Period();
   if(fixed_tod)
     {
      datetime start_time;
      if(shift == 0)
         start_time = TimeCurrent();
      else
         start_time = Time[shift - 1];
      datetime dt = StringToTime(StringConcatenate(TimeToString(start_time, TIME_DATE), " ", hh, ":", mm)); //closest time hh:mm
      if(dt > start_time)
         dt -= 86400; //go 24 hours back
      int dt_index = iBarShift(NULL, 0, dt, true);
      datetime dt2 = dt;
      while(dt_index < 0 && dt > Time[Bars - 1 - count]) //bar not found => look a few days back
        {
         dt -= 86400; //go 24 hours back
         dt_index = iBarShift(NULL, 0, dt, true);
        }
      if(dt_index < 0)  //still not found => find nearest bar
         dt_index = iBarShift(NULL, 0, dt2, false);
      start_index = dt_index + 1; //bar after S/R opens at dt
     }
   double ret = High[iHighest(NULL, 0, MODE_HIGH, count, start_index)];
   if(draw)
      DrawLine("Resistance", ret, count, start_index);
   return(ret);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ChartColorSet()//set chart colors
  {
   ChartSetInteger(ChartID(), CHART_COLOR_CANDLE_BEAR, BearCandle);
   ChartSetInteger(ChartID(), CHART_COLOR_CANDLE_BULL, BullCandle);
   ChartSetInteger(ChartID(), CHART_COLOR_CHART_DOWN, Bear_Outline);
   ChartSetInteger(ChartID(), CHART_COLOR_CHART_UP, Bull_Outline);
   ChartSetInteger(ChartID(), CHART_SHOW_GRID, 0);
   ChartSetInteger(ChartID(), CHART_SHOW_PERIOD_SEP, false);
   ChartSetInteger(ChartID(), CHART_MODE, 1);
   ChartSetInteger(ChartID(), CHART_SHIFT, 1);
   ChartSetInteger(ChartID(), CHART_SHOW_ASK_LINE, 1);
   ChartSetInteger(ChartID(), CHART_COLOR_BACKGROUND, BackGround);
   ChartSetInteger(ChartID(), CHART_COLOR_FOREGROUND, ForeGround);
   return(true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TrailingStopTrail(int type, double TS, double step, bool aboveBE, double aboveBEval, string sym) //set Stop Loss to "TS" if price is going your way with "step"
  {
   double ask = MarketInfo(sym, MODE_ASK);
   double bid = MarketInfo(sym, MODE_BID);
   int dig = MarketInfo(sym, MODE_DIGITS);
   int total = OrdersTotal();
   TS = NormalizeDouble(TS, dig);
   step = NormalizeDouble(step, dig);
   for(int i = total - 1; i >= 0; i--)
     {
      while(IsTradeContextBusy())
         Sleep(100);
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;
      if(OrderMagicNumber() != MagicNumber || OrderSymbol() != sym || OrderType() != type)
         continue;
      RefreshRates();
      if(type == OP_BUY && (!aboveBE || bid > OrderOpenPrice() + TS + aboveBEval) && (NormalizeDouble(OrderStopLoss(), dig) <= 0 || bid > OrderStopLoss() + TS + step))
         myOrderModify(OrderTicket(), ask - TS, 0, sym);
      else
         if(type == OP_SELL && (!aboveBE || ask < OrderOpenPrice() - TS - aboveBEval) && (NormalizeDouble(OrderStopLoss(), dig) <= 0 || ask < OrderStopLoss() - TS - step))
            myOrderModify(OrderTicket(), ask + TS, 0, sym);
     }
  }

string data0[] ;



//+-----------------------------------------------------------------+
//| expert start function                                           |
//+-----------------------------------------------------------------+

datetime allowed_until = "D'2024.01.01 00:00'"; //EA EXPIRATIOM DATE


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int start2(string sym)
  {
   double hAsk = MarketInfo(sym, MODE_ASK);
   double hBid = MarketInfo(sym, MODE_BID);
   int dig = MarketInfo(sym, MODE_DIGITS);
   double ask = MarketInfo(sym, MODE_ASK);
   double bid = MarketInfo(sym, MODE_BID);
// this line is to check single account license
   /*
    if (password_status == 1)
   {
     // password correct
   }
   */
   int OPbN = 0;
   double TPaF = 0;
   int     CbB          = 0;    // Count buy
   int     CbS          = 0;    // Count sell
   int     CpBL         = 0;    // Count buy limit
   int     CpSL         = 0;    // Count sell limit
   int     CpBS         = 0;    // Count buy stop
   int     CpSS         = 0;    // Count sell stop
   double  LbB          = 0;    // Count buy lots
   double  LbS          = 0;    // Count sell lots
   double  LbT          = 0;    // total lots out
   double  OPpBL        = 0;    // Buy limit open price
   double  OPpSL        = 0;    // Sell limit open price
   double  SLbB         = 0;    // stop losses are set to zero if POSL off
   double  SLbS         = 0;    // stop losses are set to zero if POSL off
   double  BCb, BCh, BCa;       // Broker costs (swap + commission)
   double  ProfitPot    = 0;    // The Potential Profit of a basket of Trades
   double  PipValue, PipVal2, ASK, BID;
   double  OrderLot;
   double  OPbL, OPhO;          // last open price
   int     OTbL;                // last open time
   double  g2, tp2, Entry, RSI_MA, LhB, LhS, LhT, OPbO, OTbO, OThO, TbO, ThO;
   int     Ticket, ChB, ChS, IndEntry;
   double  Pb, Ph, PaC, PbPips, PbTarget, DrawDownPC, BEb, BEh, BEa;
   bool    BuyMe, SellMe, Success, SetPOSL;
   string  IndicatorUsed;
//+-----------------------------------------------------------------+
//| Count Open Orders, Lots and Totals                              |
//+-----------------------------------------------------------------+
   if(MarketInfo(sym, MODE_TICKSIZE) == 0)
      return 0;
   PipVal2 = MarketInfo(sym, MODE_TICKVALUE) / MarketInfo(Symbol(), MODE_TICKSIZE);
   PipValue = PipVal2 * Pip;
   StopLevel = MarketInfo(sym, MODE_STOPLEVEL) * Point;
   ASK = ND(MarketInfo(sym, MODE_ASK), MarketInfo(sym, MODE_DIGITS));
   BID = ND(MarketInfo(sym, MODE_BID), MarketInfo(sym, MODE_DIGITS));
   if(ASK == 0 || BID == 0)
      return(0);
   for(int y = 0; y < OrdersTotal(); y++)
     {
      if(!OrderSelect(y, SELECT_BY_POS, MODE_TRADES))
         continue;
      int Type = OrderType();
      if(OrderMagicNumber() == hMagic)
        {
         Ph += OrderProfit();
         BCh += OrderSwap() + OrderCommission();
         BEh += OrderLots() * OrderOpenPrice();
         if(OrderOpenTime() < OThO || OThO == 0)
           {
            OThO = OrderOpenTime();
            ThO = OrderTicket();
            OPhO = OrderOpenPrice();
           }
         if(Type == OP_BUY)
           {
            ChB++;
            LhB += OrderLots();
           }
         else
            if(Type == OP_SELL)
              {
               ChS++;
               LhS += OrderLots();
              }
         continue;
        }
      if(OrderMagicNumber() != Magic || OrderSymbol() != sym)
         continue;
      if(OrderTakeProfit() > 0)
         ModifyOrder(OrderOpenPrice(), OrderStopLoss());
      if(Type <= OP_SELL)
        {
         Pb += OrderProfit();
         BCb += OrderSwap() + OrderCommission();
         BEb += OrderLots() * OrderOpenPrice();
         if(OrderOpenTime() >= OTbL)
           {
            OTbL = OrderOpenTime();
            OPbL = OrderOpenPrice();
           }
         if(OrderOpenTime() < OTbF || TbF == 0)
           {
            OTbF = OrderOpenTime();
            TbF = OrderTicket();
            LbF = OrderLots();
           }
         if(OrderOpenTime() < OTbO || OTbO == 0)
           {
            OTbO = OrderOpenTime();
            TbO = OrderTicket();
            OPbO = OrderOpenPrice();
           }
         if(UsePowerOutSL && ((POSLPips > 0 && OrderStopLoss() == 0) || (POSLPips == 0 && OrderStopLoss() > 0)))
            SetPOSL = true;
         if(Type == OP_BUY)
           {
            CbB++;
            LbB += OrderLots();
            continue;
           }
         else
           {
            CbS++;
            LbS += OrderLots();
            continue;
           }
        }
      else
        {
         if(Type == OP_BUYLIMIT)
           {
            CpBL++;
            OPpBL = OrderOpenPrice();
            continue;
           }
         else
            if(Type == OP_SELLLIMIT)
              {
               CpSL++;
               OPpSL = OrderOpenPrice();
               continue;
              }
            else
               if(Type == OP_BUYSTOP)
                  CpBS++;
               else
                  CpSS++;
        }
     }
   CbT = CbB + CbS;
   LbT = LbB + LbS;
   Pb = ND(Pb + BCb, 2);
   ChT = ChB + ChS;
   LhT = LhB + LhS;
   Ph = ND(Ph + BCh, 2);
   CpT = CpBL + CpSL + CpBS + CpSS;
   BCa = BCb + BCh;
//+-----------------------------------------------------------------+
//| Calculate Min/Max Profit and Break Even Points                  |
//+-----------------------------------------------------------------+
   if(LbT > 0)
     {
      BEb = ND(BEb / LbT, dig);
      if(BCa < 0)
         BEb -= ND(BCa / PipVal2 / (LbB - LbS), dig);
      if(Pb > PbMax || PbMax == 0)
         PbMax = Pb;
      if(Pb < PbMin || PbMin == 0)
         PbMin = Pb;
      if(!TradesOpen)
        {
         FileHandle = FileOpen(FileName, FILE_BIN | FILE_WRITE);
         if(FileHandle > -1)
           {
            FileWriteInteger(FileHandle, TbF);
            FileClose(FileHandle);
            TradesOpen = true;
            if(Debug2)
               Print(FileName + " File Written: " + (string)TbF);
           }
        }
     }
   else
      if(TradesOpen)
        {
         TPb = 0;
         PbMax = 0;
         PbMin = 0;
         OTbF = 0;
         TbF = 0;
         LbF = 0;
         PbC = 0;
         PhC = 0;
         PaC = 0;
         ClosedPips = 0;
         CbC = 0;
         CaL = 0;
         bTS = 0;
         if(HedgeTypeDD)
            hDDStart = HedgeStart;
         else
            hLvlStart = HedgeStart;
         EmailCount = 0;
         EmailSent = 0;
         FileHandle = FileOpen(FileName, FILE_BIN | FILE_READ);
         if(FileHandle > -1)
           {
            FileClose(FileHandle);
            Error = GetLastError();
            FileDelete(FileName);
            Error = GetLastError();
            if(Error == ERR_NO_ERROR)
              {
               if(Debug2)
                  Print(FileName + " File Deleted");
               TradesOpen = false;
              }
            else
               Print("Error deleting file: " + FileName + " " + (string)Error + " " + ErrorDescription(Error));
           }
         else
            TradesOpen = false;
        }
   if(LhT > 0)
     {
      BEh = ND(BEh / LhT, dig);
      if(Ph > PhMax || PhMax == 0)
         PhMax = Ph;
      if(Ph < PhMin || PhMin == 0)
         PhMin = Ph;
     }
   else
     {
      PhMax = 0;
      PhMin = 0;
      SLh = 0;
     }
//+-----------------------------------------------------------------+
//| Check if trading is allowed                                     |
//+-----------------------------------------------------------------+
   if(CbT == 0 && ChT == 0 && ShutDown)
     {
      if(CpT > 0)
        {
         ExitTrades(P, displayColorLoss, " Zones EA is shutting down");
         return(0);
        }
      if(AllowTrading)
        {
         Print("Zones EA has ShutDown. Set ShutDown = 'false' to continue trading");
         if(PlaySounds)
            PlaySound(AlertSound);
         AllowTrading = false;
        }
      if(UseEmail && EmailCount < 4 && !Testing)
        {
         SendMail(" Zones EA", " Zones EA has shut down on " + sym + " " + sTF +
                  ". Trading has been suspended. To resume trading, set ShutDown to false.");
         Error = GetLastError();
         if(Error > 0)
            Print("Error sending Email: " + (string)Error + " " + ErrorDescription(Error));
         else
            EmailCount = 4;
        }
     }
   if(!AllowTrading)
     {
      string tab = "";
      if(!LDelete)
        {
         LDelete = true;
         LabelDelete();
         if(ObjectFind("B3LStop") == -1)
            CreateLabel("B3LStop", "Trading has been stopped on this pair.", 10, 0, 0, 3, displayColorLoss);
         if(Testing)
            tab = "Tester Journal";
         else
            Tab = (int)"Terminal Experts";
         if(ObjectFind("B3LExpt") == -1)
            CreateLabel("B3LExpt", "Check the " + tab + " tab for the reason why.", 10, 0, 0, 6, displayColorLoss);
         if(ObjectFind("B3LResm") == -1)
            CreateLabel("B3LResm", "Reset  Zones EA to resume trading.", 10, 0, 0, 9, displayColorLoss);
        }
      return(0);
     }
   else
     {
      LDelete = false;
      ObjDel("B3LStop");
      ObjDel("B3LExpt");
      ObjDel("B3LResm");
     }
   DrawDownPC = 0;
//+-----------------------------------------------------------------+
//| Calculate Drawdown and Equity Protection                        |
//+-----------------------------------------------------------------+
   double NewPortionBalance = ND(AccountBalance() * PortionPC, 2);
   if(CbT == 0 || PortionChange < 0 || (PortionChange > 0 && NewPortionBalance > PortionBalance))
      PortionBalance = NewPortionBalance;
   if(Pb + Ph < 0)
      DrawDownPC = -(Pb + Ph) / PortionBalance;
   if(!FirstRun && DrawDownPC >= MaxDDPercent / 100)
     {
      ExitTrades(A, displayColorLoss, "Equity Stop Loss Reached");
      if(PlaySounds)
         PlaySound(AlertSound);
      return(0);
     }
   if(-(Pb + Ph) > MaxDD)
      MaxDD = -(Pb + Ph);
   MaxDDPer = MathMax(MaxDDPer, DrawDownPC * 100);
   if(SaveStats)
      Stats(false, TimeCurrent() < NextStats, PortionBalance, Pb + Ph);
//+-----------------------------------------------------------------+
//| Calculate  Stop Trade Percent                                   |
//+-----------------------------------------------------------------+
   double StepAB = InitialAB * (1 + StopTradePercent);
   double StepSTB = AccountBalance() * (1 - StopTradePercent);
   double NextISTB = StepAB * (1 - StopTradePercent);
   if(StepSTB > NextISTB)
     {
      InitialAB = StepAB;
      StopTradeBalance = StepSTB;
     }
   double InitialAccountMultiPortion = StopTradeBalance * PortionPC;
   if(PortionBalance < InitialAccountMultiPortion)
     {
      if(CbT == 0)
        {
         AllowTrading = false;
         if(PlaySounds)
            PlaySound(AlertSound);
         Print("Portion Balance dropped below stop trade percent");
         bot.SendMessage(chatID, "Portion Balance dropped below stop trade percent");
         MessageBox("Reset  Zones EA, account balance dropped below stop trade percent on " + sym + (string)Period(), "TradeExpert 3: Warning", 48);
         return(0);
        }
      else
         if(!ShutDown && !RecoupClosedLoss)
           {
            ShutDown = true;
            if(PlaySounds)
               PlaySound(AlertSound);
            Print("Portion Balance dropped below stop trade percent");
            bot.SendMessage(chatID, "Portion Balance dropped below stop trade percent");
            return(0);
           }
     }
//+-----------------------------------------------------------------+
//| Calculation of Trend Direction                                  |
//+-----------------------------------------------------------------+
   int Trend;
   string ATrend;
   double ima_0 = iMA(sym, 0, MAPeriod, 0, MODE_EMA, PRICE_CLOSE, 0);
   if(ForceMarketCond == 3)
     {
      if(BID > ima_0 + MADistance)
         Trend = 0;
      else
         if(ASK < ima_0 - MADistance)
            Trend = 1;
         else
            Trend = 2;
     }
   else
     {
      Trend = ForceMarketCond;
      if(Trend != 0 && BID > ima_0 + MADistance)
         ATrend = "U";
      if(Trend != 1 && ASK < ima_0 - MADistance)
         ATrend = "D";
      if(Trend != 2 && (BID < ima_0 + MADistance && ASK > ima_0 - MADistance))
         ATrend = "R";
     }
//+-----------------------------------------------------------------+
//| Hedge/Basket/ClosedTrades Profit Management                     |
//+-----------------------------------------------------------------+
   double Pa = Pb;
   PaC = PbC + PhC;
   BEb = 0;
   if(hActive == 1 && ChT == 0)
     {
      PhC = FindClosedPL(H);
      hActive = 0;
      return(0);
     }
   else
      if(hActive == 0 && ChT > 0)
         hActive = 1;
   if(LbT > 0)
     {
      if(PbC > 0 || (PbC < 0 && RecoupClosedLoss))
        {
         Pa += PbC;
         BEb -= ND(PbC / PipVal2 / (LbB - LbS), dig);
        }
      if(PhC > 0 || (PhC < 0 && RecoupClosedLoss))
        {
         Pa += PhC;
         BEb -= ND(PhC / PipVal2 / (LbB - LbS), dig);
        }
      if(Ph > 0 || (Ph < 0 && RecoupClosedLoss))
         Pa += Ph;
     }
//+-----------------------------------------------------------------+
//| Close oldest open trade after CloseTradesLevel reached          |
//+-----------------------------------------------------------------+
   if(UseCloseOldest && CbT >= CloseTradesLevel && CbC < MaxCloseTrades)
     {
      if(!FirstRun && TPb > 0 && (ForceCloseOldest || (CbB > 0 && OPbO > TPb) || (CbS > 0 && OPbO < TPb)))
        {
         int y = ExitTrades(T, DarkViolet, "Close Oldest Trade", TbO, sym);
         if(y == 1)
           {
            if(OrderSelect((int)TbO, SELECT_BY_TICKET))
              {
               ;
               PbC += OrderProfit() + OrderSwap() + OrderCommission();
               ca = 0;
               CbC++;
              }
            return(0);
           }
        }
     }
//+-----------------------------------------------------------------+
//| ATR for Auto Grid Calculation and Grid Set Block                |
//+-----------------------------------------------------------------+
   if(AutoCal)
     {
      double GridATR = iATR(sym, TF[ATRTF], ATRPeriods, 0) / Pip;
      if((CbT + CbC > Set4Level) && Set4Level > 0)
        {
         g2 = GridATR * 12; //GS*2*2*2*1.5
         tp2 = GridATR * 18; //GS*2*2*2*1.5*1.5
        }
      else
         if((CbT + CbC > Set3Level) && Set3Level > 0)
           {
            g2 = GridATR * 8; //GS*2*2*2
            tp2 = GridATR * 12; //GS*2*2*2*1.5
           }
         else
            if((CbT + CbC > Set2Level) && Set2Level > 0)
              {
               g2 = GridATR * 4; //GS*2*2
               tp2 = GridATR * 8; //GS*2*2*2
              }
            else
               if((CbT + CbC > Set1Level) && Set1Level > 0)
                 {
                  g2 = GridATR * 2; //GS*2
                  tp2 = GridATR * 4; //GS*2*2
                 }
               else
                 {
                  g2 = GridATR;
                  tp2 = GridATR * 2;
                 }
      GridTP = GridATR * 2;
     }
   else
     {
      int y = MathMax(MathMin(CbT + CbC, MaxTrades) - 1, 0);
      g2 = GridArray[y, 0];
      tp2 = GridArray[y, 1];
      GridTP = GridArray[0, 1];
     }
   g2 = ND(MathMax(g2 * GAF * Pip, Pip), dig);
   tp2 = ND(tp2 * GAF * Pip, dig);
   GridTP = ND(GridTP * GAF * Pip, dig);
//+-----------------------------------------------------------------+
//| Money Management and Lot size coding                            |
//+-----------------------------------------------------------------+
   if(UseMM)
     {
      if(CbT > 0)
        {
         if(GlobalVariableCheck(ID + "LotMult"))
            LotMult = (float) GlobalVariableGet(ID + "LotMult");
         if(LbF != LotSize(Lots[0]*LotMult, sym))
           {
            LotMult = LbF / Lots[0];
            GlobalVariableSet(ID + "LotMult", LotMult);
            Print("LotMult reset to " + DTS(LotMult, 0));
           }
        }
      if(CbT == 0)
        {
         double Contracts, Factor, Lotsize;
         Contracts = PortionBalance / 10000;
         if(Multiplier <= 1)
            Factor = Level;
         else
            Factor = (MathPow(Multiplier, Level) - Multiplier) / (Multiplier - 1);
         Lotsize = LAF * AccountType * Contracts / (1 + Factor);
         LotMult = MathMax(MathFloor(Lotsize / Lot), MinMult);
         GlobalVariableSet(ID + "LotMult", LotMult);
        }
     }
   else
      if(CbT == 0)
         LotMult = MinMult;
//+-----------------------------------------------------------------+
//| Calculate Take Profit                                           |
//+-----------------------------------------------------------------+
   static double BCaL, BEbL;
   double nLots = LbB - LbS;
   if(CbT > 0 && (TPb == 0 || CbT + ChT != CaL || BEbL != BEb || BCa != BCaL || FirstRun))
     {
      string sCalcTP = "Set New TP:  BE: " + DTS(BEb, dig);
      double NewTP = 0, BasePips = 0;
      CaL = CbT + ChT;
      BCaL = BCa;
      BEbL = BEb;
      if(nLots == 0)
        {
         nLots = 1;
        }
      BasePips = ND(Lot * LotMult * GridTP * (CbT + CbC) / nLots, dig);
      if(CbB > 0)
        {
         if(ForceTPPips > 0)
           {
            NewTP = BEb + ForceTPPips;
            sCalcTP = sCalcTP + " +Force TP (" + DTS(ForceTPPips, dig) + ") ";
           }
         else
            if(CbC > 0 && CloseTPPips > 0)
              {
               NewTP = BEb + CloseTPPips;
               sCalcTP = sCalcTP + " +Close TP (" + DTS(CloseTPPips, dig) + ") ";
              }
            else
               if(BEb + BasePips > OPbL + tp2)
                 {
                  NewTP = BEb + BasePips;
                  sCalcTP = sCalcTP + " +Base TP: (" + DTS(BasePips, dig) + ") ";
                 }
               else
                 {
                  NewTP = OPbL + tp2;
                  sCalcTP = sCalcTP + " +Grid TP: (" + DTS(tp2, dig) + ") ";
                 }
         if(MinTPPips > 0)
           {
            NewTP = MathMax(NewTP, BEb + MinTPPips);
            sCalcTP = sCalcTP + " >Minimum TP: ";
           }
         NewTP += MoveTP * Moves;
         if(BreakEvenTrade > 0 && CbT + CbC >= BreakEvenTrade)
           {
            NewTP = BEb + BEPlusPips;
            sCalcTP = sCalcTP + " >BreakEven: (" + DTS(BEPlusPips, dig) + ") ";
           }
         sCalcTP = (sCalcTP + "Buy: TakeProfit: ");
        }
      else
         if(CbS > 0)
           {
            if(ForceTPPips > 0)
              {
               NewTP = BEb - ForceTPPips;
               sCalcTP = sCalcTP + " -Force TP (" + DTS(ForceTPPips, dig) + ") ";
              }
            else
               if(CbC > 0 && CloseTPPips > 0)
                 {
                  NewTP = BEb - CloseTPPips;
                  sCalcTP = sCalcTP + " -Close TP (" + DTS(CloseTPPips, dig) + ") ";
                 }
               else
                  if(BEb + BasePips < OPbL - tp2)
                    {
                     NewTP = BEb + BasePips;
                     sCalcTP = sCalcTP + " -Base TP: (" + DTS(BasePips, dig) + ") ";
                    }
                  else
                    {
                     NewTP = OPbL - tp2;
                     sCalcTP = sCalcTP + " -Grid TP: (" + DTS(tp2, dig) + ") ";
                    }
            if(MinTPPips > 0)
              {
               NewTP = MathMin(NewTP, BEb - MinTPPips);
               sCalcTP = sCalcTP + " >Minimum TP: ";
              }
            NewTP -= MoveTP * Moves;
            if(BreakEvenTrade > 0 && CbT + CbC >= BreakEvenTrade)
              {
               NewTP = BEb - BEPlusPips;
               sCalcTP = sCalcTP + " >BreakEven: (" + DTS(BEPlusPips, dig) + ") ";
              }
            sCalcTP = (sCalcTP + "Sell: TakeProfit: ");
           }
      if(TPb != NewTP)
        {
         TPb = NewTP;
         if(nLots > 0)
            TargetPips = ND(TPb - BEb, dig);
         else
            TargetPips = ND(BEb - TPb, dig);
         Print(sCalcTP + DTS(NewTP, dig));
         return(0);
        }
     }
   PbTarget = TargetPips / Pip;
   ProfitPot = ND(TargetPips * PipVal2 * MathAbs(nLots), 2);
   if(CbB > 0)
      PbPips = ND((BID - BEb) / Pip, 1);
   if(CbS > 0)
      PbPips = ND((BEb - ASK) / Pip, 1);
//+-----------------------------------------------------------------+
//| Adjust BEb/TakeProfit if Hedge is active                        |
//+-----------------------------------------------------------------+
   double hSpread = hAsk - hBid;
   if(hThisChart)
      nLots += LhB - LhS;
   if(hActive == 1)
     {
      double TPa, PhPips;
      if(nLots == 0)
        {
         BEa = 0;
         TPa = 0;
        }
      else
         if(hThisChart)
           {
            if(nLots > 0)
              {
               if(CbB > 0)
                  BEa = ND((BEb * LbT - (BEh - hSpread) * LhT) / (LbT - LhT), dig);
               else
                  BEa = ND(((BEb - (ASK - BID)) * LbT - BEh * LhT) / (LbT - LhT), dig);
               TPa = ND(BEa + TargetPips, dig);
              }
            else
              {
               if(CbS > 0)
                  BEa = ND((BEb * LbT - (BEh + hSpread) * LhT) / (LbT - LhT), dig);
               else
                  BEa = ND(((BEb + ASK - BID) * LbT - BEh * LhT) / (LbT - LhT), dig);
               TPa = ND(BEa - TargetPips, dig);
              }
           }
         else
           {
           }
      if(ChB > 0)
         PhPips = ND((hBid - BEh) / hPip, 1);
      if(ChS > 0)
         PhPips = ND((BEh - hAsk) / hPip, 1);
     }
   else
     {
      BEa = BEb;
      TPa = TPb;
     }
//+-----------------------------------------------------------------+
//| Calculate Early Exit Percentage                                 |
//+-----------------------------------------------------------------+
   if(UseEarlyExit && CbT > 0)
     {
      double EEpc, EEopt, EEStartTime, TPaF;
      if(EEFirstTrade)
         EEopt = OTbF;
      else
         EEopt = OTbL;
      if(DayOfWeek() < TimeDayOfWeek(EEopt))
         EEStartTime = 2 * 24 * 3600;
      EEStartTime += EEopt + EEStartHours * 3600;
      if(EEHoursPC > 0 && TimeCurrent() >= EEStartTime)
         EEpc = EEHoursPC * (TimeCurrent() - EEStartTime) / 3600;
      if(EELevelPC > 0 && (CbT + CbC) >= EEStartLevel)
         EEpc += EELevelPC * (CbT + CbC - EEStartLevel + 1);
      EEpc = 1 - EEpc;
      if(!EEAllowLoss && EEpc < 0)
         EEpc = 0;
      PbTarget *= EEpc;
      
      
      TPaF = ND((TPa - BEa) * EEpc + BEa, (int)MarketInfo(sym,Digits()));
      if(displayOverlay && displayLines && (hActive != 1 || (hActive == 1 && hThisChart)) && (!Testing || (Testing && Visual)) && EEpc < 1
         && (CbT + CbC + ChT > EECount || EETime != Time[0]) && ((EEHoursPC > 0 && EEopt + EEStartHours * 3600 < Time[0]) || (EELevelPC > 0 && CbT + CbC >= EEStartLevel)))
        {
         EETime = Time[0];
         EECount = CbT + CbC + ChT;
         if(ObjectFind("B3LEELn") < 0)
           {
            ObjectCreate("B3LEELn", OBJ_TREND, 0, 0, 0);
            ObjectSet("B3LEELn", OBJPROP_COLOR, Yellow);
            ObjectSet("B3LEELn", OBJPROP_WIDTH, 1);
            ObjectSet("B3LEELn", OBJPROP_STYLE, 0);
            ObjectSet("B3LEELn", OBJPROP_RAY, false);
           }
         if(EEHoursPC > 0)
            ObjectMove("B3LEELn", 0, MathFloor(EEopt / 3600 + EEStartHours) * 3600, TPa);
         else
            ObjectMove("B3LEELn", 0, MathFloor(EEopt / 3600) * 3600, TPaF);
         ObjectMove("B3LEELn", 1, Time[1], TPaF);
         if(ObjectFind("B3VEELn") < 0)
           {
            ObjectCreate("B3VEELn", OBJ_TEXT, 0, 0, 0);
            ObjectSet("B3VEELn", OBJPROP_COLOR, Yellow);
            ObjectSet("B3VEELn", OBJPROP_WIDTH, 1);
            ObjectSet("B3VEELn", OBJPROP_STYLE, 0);
           }
         ObjSetTxt("B3VEELn", "              " + DTS(TPaF, dig), -1, Yellow);
         ObjectSet("B3VEELn", OBJPROP_PRICE1, TPaF + 2 * Pip);
         ObjectSet("B3VEELn", OBJPROP_TIME1, Time[1]);
        }
      else
         if((!displayLines || EEpc == 1 || (!EEAllowLoss && EEpc == 0) || (EEHoursPC > 0 && EEopt + EEStartHours * 3600 >= Time[0])))
           {
            ObjDel("B3LEELn");
            ObjDel("B3VEELn");
           }
     }
   else
     {
      TPaF = TPa;
      EETime = 0;
      EECount = 0;
      ObjDel("B3LEELn");
      ObjDel("B3VEELn");
     }
//+-----------------------------------------------------------------+
//| Maximize Profit with Moving TP and setting Trailing Profit Stop |
//+-----------------------------------------------------------------+
   if(MaximizeProfit)
     {
      if(CbT == 0)
        {
         SLbL = 0;
         Moves = 0;
         SLb = 0;
        }
      if(!FirstRun && CbT > 0)
        {
         if(Pb + Ph < 0 && SLb > 0)
            SLb = 0;
         if(SLb > 0 && ((nLots > 0 && bid < SLb) || (nLots < 0 && ASK > SLb)))
           {
            ExitTrades(A, displayColorProfit, "Profit Trailing Stop Reached (" + DTS(ProfitSet * 100, 2) + "%)");
            return(0);
           }
         if(PbTarget > 0)
           {
            double TPbMP = ND(BEa + (TPa - BEa) * ProfitSet, dig);
            if((nLots > 0 && bid > TPbMP) || (nLots < 0 && ask < TPbMP))
               SLb = TPbMP;
           }
         if(SLb > 0 && SLb != SLbL && MoveTP > 0 && TotalMoves > Moves)
           {
            TPb = 0;
            Moves++;
            if(Debug2)
               Print("MoveTP");
            SLbL = SLb;
            if(PlaySounds)
               PlaySound(AlertSound);
            return(0);
           }
        }
     }
   if(!FirstRun && TPaF > 0)
     {
      if((nLots > 0 && bid >= TPaF) || (nLots < 0 && ask <= TPaF))
        {
         ExitTrades(A, displayColorProfit, "Profit Target Reached @ " + DTS(TPaF, dig));
         return(0);
        }
     }
   if(!FirstRun && UseStopLoss)
     {
      double bSL;
      if(SLPips > 0)
        {
         if(nLots > 0)
           {
            bSL = BEa - SLPips;
            if(BID <= bSL)
              {
               ExitTrades(A, displayColorProfit, "Stop Loss Reached");
               return(0);
              }
           }
         else
            if(nLots < 0)
              {
               bSL = BEa + SLPips;
               if(ask >= bSL)
                 {
                  ExitTrades(A, displayColorProfit, "Stop Loss Reached");
                  return(0);
                 }
              }
        }
      if(TSLPips != 0)
        {
         if(nLots > 0)
           {
            if(TSLPips > 0 && BID > BEa + TSLPips)
               bTS = MathMax(bTS, BID - TSLPips);
            if(TSLPips < 0 && BID > BEa - TSLPips)
               bTS = MathMax(bTS, BID - MathMax(TSLPipsMin, -TSLPips * (1 - (BID - BEa + TSLPips) / (-TSLPips * 2))));
            if(bTS > 0 && BID <= bTS)
              {
               ExitTrades(A, displayColorProfit, "Trailing Stop Reached");
               return(0);
              }
           }
         else
            if(nLots < 0)
              {
               if(TSLPips > 0 && ask < BEa - TSLPips)
                 {
                  if(bTS > 0)
                     bTS = MathMin(bTS, ask + TSLPips);
                  else
                     bTS = ask + TSLPips;
                 }
               if(TSLPips < 0 && ask < BEa + TSLPips)
                  bTS = MathMin(bTS, ask + MathMax(TSLPipsMin, -TSLPips * (1 - (BEa - ask + TSLPips) / (-TSLPips * 2))));
               if(bTS > 0 && ask >= bTS)
                 {
                  ExitTrades(A, displayColorProfit, "Trailing Stop Reached");
                  return(0);
                 }
              }
        }
     }
//+-----------------------------------------------------------------+
//| Check for and Delete hanging pending orders                     |
//+-----------------------------------------------------------------+
   if(CbT == 0 && !PendLot)
     {
      PendLot = true;
      for(int y = OrdersTotal() - 1; y >= 0; y--)
        {
         if(!OrderSelect(y, SELECT_BY_POS, MODE_TRADES))
            continue;
         if(OrderMagicNumber() != Magic || OrderType() <= OP_SELL)
            continue;
         if(ND(OrderLots(), LotDecimal) > ND(Lots[0]*LotMult, LotDecimal))
           {
            PendLot = false;
            while(IsTradeContextBusy())
               Sleep(100);
            if(IsStopped())
               return(-1);
            Success = OrderDelete(OrderTicket());
            if(Success)
              {
               PendLot = true;
               if(Debug2)
                  Print("Delete pending > Lot");
              }
           }
        }
      return(0);
     }
   else
      if((CbT > 0 || (CbT == 0 && CpT > 0 && !B3Traditional)) && PendLot)
        {
         PendLot = false;
         for(int y = OrdersTotal() - 1; y >= 0; y--)
           {
            if(!OrderSelect(y, SELECT_BY_POS, MODE_TRADES))
               continue;
            if(OrderMagicNumber() != Magic || OrderType() <= OP_SELL)
               continue;
            if(ND(OrderLots(), LotDecimal) == ND(Lots[0]*LotMult, LotDecimal))
              {
               PendLot = true;
               while(IsTradeContextBusy())
                  Sleep(100);
               if(IsStopped())
                  return(-1);
               Success = OrderDelete(OrderTicket());
               if(Success)
                 {
                  PendLot = false;
                  if(Debug2)
                     Print("Delete pending = Lot");
                 }
              }
           }
         return(0);
        }
//+-----------------------------------------------------------------+
//| Check ca, Breakeven Trades and Emergency Close All              |
//+-----------------------------------------------------------------+
   switch(ca)
     {
      case B:
         if(CbT == 0 && CpT == 0)
            ca = 0;
         break;
      case H:
         if(ChT == 0)
            ca = 0;
         break;
      case A:
         if(CbT == 0 && CpT == 0 && ChT == 0)
            ca = 0;
         break;
      case P:
         if(CpT == 0)
            ca = 0;
         break;
      case T:
         break;
      default:
         break;
     }
   if(ca > 0)
     {
      ExitTrades(ca, displayColorLoss, "Close All (" + DTS(ca, 0) + ")");
      bot.SendMessage(channel, "Close All " + DTS(ca, 0));
      return(0);
     }
   if(CbT == 0 && ChT > 0)
     {
      ExitTrades(H, displayColorLoss, "Basket Closed");
      bot.SendMessage(channel, "Close All " + DTS(ca, 0));
      return(0);
     }
   if(EmergencyCloseAll)
     {
      ExitTrades(A, displayColorLoss, "Emergency Close All Trades");
      EmergencyCloseAll = false;
      return(0);
     }
//+-----------------------------------------------------------------+
//| Check Holiday Shutdown                                          |
//+-----------------------------------------------------------------+
   if(UseHolidayShutdown)
     {
      if(HolShutDown > 0 && TimeCurrent() >= HolLast && HolLast > 0)
        {
         Print(" Zones EA  has resumed after the holidays. From: " + TimeToStr(HolFirst, TIME_DATE) + " To: " + TimeToStr(HolLast, TIME_DATE));
         HolShutDown = 0;
         LabelDelete();
         LabelCreate();
         if(PlaySounds)
            PlaySound(AlertSound);
        }
      if(HolShutDown == 3)
        {
         if(ObjectFind("B3LStop") == -1)
            CreateLabel("B3LStop", "Trading has been stopped on this pair for the holidays.", 10, 0, 0, 3, displayColorLoss);
         if(ObjectFind("B3LResm") == -1)
           {
            CreateLabel("B3LResm", " Zones EA will resume trading after " + TimeToStr(HolLast, TIME_DATE) + ".", 10, 0, 0, 9, displayColorLoss);
            bot.SendMessage(channel, " Zones EA will resume trading after " + TimeToStr(HolLast, TIME_DATE));
            return(0);
           }
        }
      else
         if((HolShutDown == 0 && TimeCurrent() >= HolLast) || HolFirst == 0)
           {
            for(int y = 0; y < ArraySize(HolArray); y++)
              {
               HolFirst = StrToTime(Year() + "." + HolArray[y, 0] + "." + HolArray[y, 1]);
               HolLast = StrToTime(Year() + "." + HolArray[y, 2] + "." + HolArray[y, 3] + " 23:59:59");
               if(TimeCurrent() < HolFirst)
                 {
                  if(HolFirst > HolLast)
                     HolLast = StrToTime(DTS(Year() + 1, 0) + "." + HolArray[y, 2] + "." + HolArray[y, 3] + " 23:59:59");
                  break;
                 }
               if(TimeCurrent() < HolLast)
                 {
                  if(HolFirst > HolLast)
                     HolFirst = StrToTime(DTS(Year() - 1, 0) + "." + HolArray[y, 0] + "." + HolArray[y, 1]);
                  break;
                 }
               if(TimeCurrent() > HolFirst && HolFirst > HolLast)
                 {
                  HolLast = StrToTime(DTS(Year() + 1, 0) + "." + HolArray[y, 2] + "." + HolArray[y, 3] + " 23:59:59");
                  if(TimeCurrent() < HolLast)
                     break;
                 }
              }
            if(TimeCurrent() >= HolFirst && TimeCurrent() <= HolLast)
              {
               Comment("");
               HolShutDown = 1;
              }
           }
         else
            if(HolShutDown == 0 && TimeCurrent() >= HolFirst && TimeCurrent() < HolLast)
               HolShutDown = 1;
      if(HolShutDown == 1 && CbT == 0)
        {
         Print(" Zones EA has shut down for the holidays. From: " + TimeToStr(HolFirst, TIME_DATE) +
               " To: " + TimeToStr(HolLast, TIME_DATE));
         if(CpT > 0)
           {
            int y = ExitTrades(P, displayColorLoss, "Holiday Shutdown");
            if(y == CpT)
               ca = 0;
           }
         HolShutDown = 2;
         ObjDel("B3LClos");
        }
      else
         if(HolShutDown == 1)
           {
            if(ObjectFind("B3LClos") == -1)
               CreateLabel("B3LClos", "", 5, 0, 0, 23, displayColorLoss);
            ObjSetTxt("B3LClos", " Zones EA will shutdown for the holidays when this basket closes", 5);
           }
      if(HolShutDown == 2)
        {
         LabelDelete();
         if(PlaySounds)
            PlaySound(AlertSound);
         HolShutDown = 3;
        }
      if(HolShutDown == 3)
        {
         if(ObjectFind("B3LStop") == -1)
            CreateLabel("B3LStop", "Trading has been stopped on this pair for the holidays.", 10, 0, 0, 3, displayColorLoss);
         if(ObjectFind("B3LResm") == -1)
            CreateLabel("B3LResm", " Zones EA will resume trading after " + TimeToStr(HolLast, TIME_DATE) + ".", 10, 0, 0, 9, displayColorLoss);
         Comment("");
         return(0);
        }
     }
//+-----------------------------------------------------------------+
//| Power Out Stop Loss Protection                                  |
//+-----------------------------------------------------------------+
   if(SetPOSL)
     {
      if(UsePowerOutSL && POSLPips > 0)
        {
         double POSL = MathMin(PortionBalance * (MaxDDPercent + 1) / 100 / PipVal2 / LbT, POSLPips);
         SLbB = ND(BEb - POSL, dig);
         SLbS = ND(BEb + POSL, dig);
        }
      else
        {
         SLbB = 0;
         SLbS = 0;
        }
      for(int y = 0; y < OrdersTotal(); y++)
        {
         if(!OrderSelect(y, SELECT_BY_POS, MODE_TRADES))
            continue;
         if(OrderMagicNumber() != Magic || OrderSymbol() != sym || OrderType() > OP_SELL)
            continue;
         if(OrderType() == OP_BUY && OrderStopLoss() != SLbB)
           {
            Success = ModifyOrder(OrderOpenPrice(), SLbB, Purple, sym);
            if(Debug2 && Success)
               Print("Order: " + OrderTicket() + " Sync POSL Buy");
           }
         else
            if(OrderType() == OP_SELL && OrderStopLoss() != SLbS)
              {
               Success = ModifyOrder(OrderOpenPrice(), SLbS, Purple, sym);
               if(Debug2 && Success)
                  Print("Order: " + OrderTicket() + " Sync POSL Sell");
              }
        }
     }
//+-----------------------------------------------------------------+  << This must be the first Entry check.
//| Moving Average Indicator for Order Entry                        |  << Add your own Indicator Entry checks
//+-----------------------------------------------------------------+  << after the Moving Average Entry.
   if(MAEntry > 0 && CbT == 0 && CpT < 2)
     {
      if(BID > ima_0 + MADistance && (!B3Traditional || (B3Traditional && Trend != 2)))
        {
         if(MAEntry == 1)
           {
            if(ForceMarketCond != 1 && (UseAnyEntry || IndEntry == 0 || (!UseAnyEntry && IndEntry > 0 && BuyMe)))
               BuyMe = true;
            else
               BuyMe = false;
            if(!UseAnyEntry && IndEntry > 0 && SellMe && (!B3Traditional || (B3Traditional && Trend != 2)))
               SellMe = false;
           }
         else
            if(MAEntry == 2)
              {
               if(ForceMarketCond != 0 && (UseAnyEntry || IndEntry == 0 || (!UseAnyEntry && IndEntry > 0 && SellMe)))
                  SellMe = true;
               else
                  SellMe = false;
               if(!UseAnyEntry && IndEntry > 0 && BuyMe && (!B3Traditional || (B3Traditional && Trend != 2)))
                  BuyMe = false;
              }
        }
      else
         if(ASK < ima_0 - MADistance && (!B3Traditional || (B3Traditional && Trend != 2)))
           {
            if(MAEntry == 1)
              {
               if(ForceMarketCond != 0 && (UseAnyEntry || IndEntry == 0 || (!UseAnyEntry && IndEntry > 0 && SellMe)))
                  SellMe = true;
               else
                  SellMe = false;
               if(!UseAnyEntry && IndEntry > 0 && BuyMe && (!B3Traditional || (B3Traditional && Trend != 2)))
                  BuyMe = false;
              }
            else
               if(MAEntry == 2)
                 {
                  if(ForceMarketCond != 1 && (UseAnyEntry || IndEntry == 0 || (!UseAnyEntry && IndEntry > 0 && BuyMe)))
                     BuyMe = true;
                  else
                     BuyMe = false;
                  if(!UseAnyEntry && IndEntry > 0 && SellMe && (!B3Traditional || (B3Traditional && Trend != 2)))
                     SellMe = false;
                 }
           }
         else
            if(B3Traditional && Trend == 2)
              {
               if(ForceMarketCond != 1 && (UseAnyEntry || IndEntry == 0 || (!UseAnyEntry && IndEntry > 0 && BuyMe)))
                  BuyMe = true;
               if(ForceMarketCond != 0 && (UseAnyEntry || IndEntry == 0 || (!UseAnyEntry && IndEntry > 0 && SellMe)))
                  SellMe = true;
              }
            else
              {
               BuyMe = false;
               SellMe = false;
              }
      if(IndEntry > 0)
         IndicatorUsed = IndicatorUsed + UAE;
      IndEntry++;
      IndicatorUsed = IndicatorUsed + " MA ";
     }
//+----------------------------------------------------------------+
//| CCI of 5M,15M,30M,1H for Market Condition and Order Entry      |
//+----------------------------------------------------------------+
   if(CCIEntry > 0)
     {
      double cci_01 = iCCI(sym, PERIOD_M5, CCIPeriod, PRICE_CLOSE, 0);
      double cci_02 = iCCI(sym, PERIOD_M15, CCIPeriod, PRICE_CLOSE, 0);
      double cci_03 = iCCI(sym, PERIOD_M30, CCIPeriod, PRICE_CLOSE, 0);
      double cci_04 = iCCI(sym, PERIOD_H1, CCIPeriod, PRICE_CLOSE, 0);
      double cci_11 = iCCI(sym, PERIOD_M5, CCIPeriod, PRICE_CLOSE, 1);
      double cci_12 = iCCI(sym, PERIOD_M15, CCIPeriod, PRICE_CLOSE, 1);
      double cci_13 = iCCI(sym, PERIOD_M30, CCIPeriod, PRICE_CLOSE, 1);
      double cci_14 = iCCI(sym, PERIOD_H1, CCIPeriod, PRICE_CLOSE, 1);
     }
   if(CCIEntry > 0 && CbT == 0 && CpT < 2)
     {
      if(cci_11 > 0 && cci_12 > 0 && cci_13 > 0 && cci_14 > 0 && cci_01 > 0 && cci_02 > 0 && cci_03 > 0 && cci_04 > 0)
        {
         if(ForceMarketCond == 3)
            Trend = 0;
         if(CCIEntry == 1)
           {
            if(ForceMarketCond != 1 && (UseAnyEntry || IndEntry == 0 || (!UseAnyEntry && IndEntry > 0 && BuyMe)))
               BuyMe = true;
            else
               BuyMe = false;
            if(!UseAnyEntry && IndEntry > 0 && SellMe && (!B3Traditional || (B3Traditional && Trend != 2)))
               SellMe = false;
           }
         else
            if(CCIEntry == 2)
              {
               if(ForceMarketCond != 0 && (UseAnyEntry || IndEntry == 0 || (!UseAnyEntry && IndEntry > 0 && SellMe)))
                  SellMe = true;
               else
                  SellMe = false;
               if(!UseAnyEntry && IndEntry > 0 && BuyMe && (!B3Traditional || (B3Traditional && Trend != 2)))
                  BuyMe = false;
              }
        }
      else
         if(cci_11 < 0 && cci_12 < 0 && cci_13 < 0 && cci_14 < 0 && cci_01 < 0 && cci_02 < 0 && cci_03 < 0 && cci_04 < 0)
           {
            if(ForceMarketCond == 3)
               Trend = 1;
            if(CCIEntry == 1)
              {
               if(ForceMarketCond != 0 && (UseAnyEntry || IndEntry == 0 || (!UseAnyEntry && IndEntry > 0 && SellMe)))
                  SellMe = true;
               else
                  SellMe = false;
               if(!UseAnyEntry && IndEntry > 0 && BuyMe && (!B3Traditional || (B3Traditional && Trend != 2)))
                  BuyMe = false;
              }
            else
               if(CCIEntry == 2)
                 {
                  if(ForceMarketCond != 1 && (UseAnyEntry || IndEntry == 0 || (!UseAnyEntry && IndEntry > 0 && BuyMe)))
                     BuyMe = true;
                  else
                     BuyMe = false;
                  if(!UseAnyEntry && IndEntry > 0 && SellMe && (!B3Traditional || (B3Traditional && Trend != 2)))
                     SellMe = false;
                 }
           }
         else
            if(!UseAnyEntry && IndEntry > 0)
              {
               BuyMe = false;
               SellMe = false;
              }
      if(IndEntry > 0)
         IndicatorUsed = IndicatorUsed + UAE;
      IndEntry++;
      IndicatorUsed = IndicatorUsed + " CCI ";
     }
//+----------------------------------------------------------------+
//| Bollinger Band Indicator for Order Entry                       |
//+----------------------------------------------------------------+
   if(BollingerEntry > 0 && CbT == 0 && CpT < 2)
     {
      double ma = iMA(sym, 0, BollPeriod, 0, MODE_SMA, PRICE_OPEN, 0);
      double stddev = iStdDev(sym, 0, BollPeriod, 0, MODE_SMA, PRICE_OPEN, 0);
      double bup = ma + (BollDeviation * stddev);
      double bdn = ma - (BollDeviation * stddev);
      double bux = bup + BollDistance;
      double bdx = bdn - BollDistance;
      if(ASK < bdx)
        {
         if(BollingerEntry == 1)
           {
            if(ForceMarketCond != 1 && (UseAnyEntry || IndEntry == 0 || (!UseAnyEntry && IndEntry > 0 && BuyMe)))
               BuyMe = true;
            else
               BuyMe = false;
            if(!UseAnyEntry && IndEntry > 0 && SellMe && (!B3Traditional || (B3Traditional && Trend != 2)))
               SellMe = false;
           }
         else
            if(BollingerEntry == 2)
              {
               if(ForceMarketCond != 0 && (UseAnyEntry || IndEntry == 0 || (!UseAnyEntry && IndEntry > 0 && SellMe)))
                  SellMe = true;
               else
                  SellMe = false;
               if(!UseAnyEntry && IndEntry > 0 && BuyMe && (!B3Traditional || (B3Traditional && Trend != 2)))
                  BuyMe = false;
              }
        }
      else
         if(BID > bux)
           {
            if(BollingerEntry == 1)
              {
               if(ForceMarketCond != 0 && (UseAnyEntry || IndEntry == 0 || (!UseAnyEntry && IndEntry > 0 && SellMe)))
                  SellMe = true;
               else
                  SellMe = false;
               if(!UseAnyEntry && IndEntry > 0 && BuyMe && (!B3Traditional || (B3Traditional && Trend != 2)))
                  BuyMe = false;
              }
            else
               if(BollingerEntry == 2)
                 {
                  if(ForceMarketCond != 1 && (UseAnyEntry || IndEntry == 0 || (!UseAnyEntry && IndEntry > 0 && BuyMe)))
                     BuyMe = true;
                  else
                     BuyMe = false;
                  if(!UseAnyEntry && IndEntry > 0 && SellMe && (!B3Traditional || (B3Traditional && Trend != 2)))
                     SellMe = false;
                 }
           }
         else
            if(!UseAnyEntry && IndEntry > 0)
              {
               BuyMe = false;
               SellMe = false;
              }
      if(IndEntry > 0)
         IndicatorUsed = IndicatorUsed + UAE;
      IndEntry++;
      IndicatorUsed = IndicatorUsed + " BBands ";
     }
//+----------------------------------------------------------------+
//| Stochastic Indicator for Order Entry                           |
//+----------------------------------------------------------------+
   if(StochEntry > 0 && CbT == 0 && CpT < 2)
     {
      int zoneBUY = BuySellStochZone;
      int zoneSELL = 100 - BuySellStochZone;
      double stoc_0 = iStochastic(sym, 0, KPeriod, DPeriod, Slowing, MODE_LWMA, 1, 0, 1);
      double stoc_1 = iStochastic(sym, 0, KPeriod, DPeriod, Slowing, MODE_LWMA, 1, 1, 1);
      if(stoc_0 < zoneBUY && stoc_1 < zoneBUY)
        {
         if(StochEntry == 1)
           {
            if(ForceMarketCond != 1 && (UseAnyEntry || IndEntry == 0 || (!UseAnyEntry && IndEntry > 0 && BuyMe)))
               BuyMe = true;
            else
               BuyMe = false;
            if(!UseAnyEntry && IndEntry > 0 && SellMe && (!B3Traditional || (B3Traditional && Trend != 2)))
               SellMe = false;
           }
         else
            if(StochEntry == 2)
              {
               if(ForceMarketCond != 0 && (UseAnyEntry || IndEntry == 0 || (!UseAnyEntry && IndEntry > 0 && SellMe)))
                  SellMe = true;
               else
                  SellMe = false;
               if(!UseAnyEntry && IndEntry > 0 && BuyMe && (!B3Traditional || (B3Traditional && Trend != 2)))
                  BuyMe = false;
              }
        }
      else
         if(stoc_0 > zoneSELL && stoc_1 > zoneSELL)
           {
            if(StochEntry == 1)
              {
               if(ForceMarketCond != 0 && (UseAnyEntry || IndEntry == 0 || (!UseAnyEntry && IndEntry > 0 && SellMe)))
                  SellMe = true;
               else
                  SellMe = false;
               if(!UseAnyEntry && IndEntry > 0 && BuyMe && (!B3Traditional || (B3Traditional && Trend != 2)))
                  BuyMe = false;
              }
            else
               if(StochEntry == 2)
                 {
                  if(ForceMarketCond != 1 && (UseAnyEntry || IndEntry == 0 || (!UseAnyEntry && IndEntry > 0 && BuyMe)))
                     BuyMe = true;
                  else
                     BuyMe = false;
                  if(!UseAnyEntry && IndEntry > 0 && SellMe && (!B3Traditional || (B3Traditional && Trend != 2)))
                     SellMe = false;
                 }
           }
         else
            if(!UseAnyEntry && IndEntry > 0)
              {
               BuyMe = false;
               SellMe = false;
              }
      if(IndEntry > 0)
         IndicatorUsed = IndicatorUsed + UAE;
      IndEntry++;
      IndicatorUsed = IndicatorUsed + " Stoch ";
     }
//+----------------------------------------------------------------+
//| MACD Indicator for Order Entry                                 |
//+----------------------------------------------------------------+
   if(MACDEntry > 0 && CbT == 0 && CpT < 2)
     {
      double MACDm = iMACD(sym, TF[MACD_TF], FastPeriod, SlowPeriod, SignalPeriod, MACDPrice, 0, 0);
      double MACDs = iMACD(sym, TF[MACD_TF], FastPeriod, SlowPeriod, SignalPeriod, MACDPrice, 1, 0);
      if(MACDm > MACDs)
        {
         if(MACDEntry == 1)
           {
            if(ForceMarketCond != 1 && (UseAnyEntry || IndEntry == 0 || (!UseAnyEntry && IndEntry > 0 && BuyMe)))
               BuyMe = true;
            else
               BuyMe = false;
            if(!UseAnyEntry && IndEntry > 0 && SellMe && (!B3Traditional || (B3Traditional && Trend != 2)))
               SellMe = false;
           }
         else
            if(MACDEntry == 2)
              {
               if(ForceMarketCond != 0 && (UseAnyEntry || IndEntry == 0 || (!UseAnyEntry && IndEntry > 0 && SellMe)))
                  SellMe = true;
               else
                  SellMe = false;
               if(!UseAnyEntry && IndEntry > 0 && BuyMe && (!B3Traditional || (B3Traditional && Trend != 2)))
                  BuyMe = false;
              }
        }
      else
         if(MACDm < MACDs)
           {
            if(MACDEntry == 1)
              {
               if(ForceMarketCond != 0 && (UseAnyEntry || IndEntry == 0 || (!UseAnyEntry && IndEntry > 0 && SellMe)))
                  SellMe = true;
               else
                  SellMe = false;
               if(!UseAnyEntry && IndEntry > 0 && BuyMe && (!B3Traditional || (B3Traditional && Trend != 2)))
                  BuyMe = false;
              }
            else
               if(MACDEntry == 2)
                 {
                  if(ForceMarketCond != 1 && (UseAnyEntry || IndEntry == 0 || (!UseAnyEntry && IndEntry > 0 && BuyMe)))
                     BuyMe = true;
                  else
                     BuyMe = false;
                  if(!UseAnyEntry && IndEntry > 0 && SellMe && (!B3Traditional || (B3Traditional && Trend != 2)))
                     SellMe = false;
                 }
           }
         else
            if(!UseAnyEntry && IndEntry > 0)
              {
               BuyMe = false;
               SellMe = false;
              }
      if(IndEntry > 0)
         IndicatorUsed = IndicatorUsed + UAE;
      IndEntry++;
      IndicatorUsed = IndicatorUsed + " MACD ";
     }
//+-----------------------------------------------------------------+  << This must be the last Entry check before
//| UseAnyEntry Check && Force Market Condition Buy/Sell Entry      |  << the Trade Selection Logic. Add checks for
//+-----------------------------------------------------------------+  << additional indicators before this block.
   if((!UseAnyEntry && IndEntry > 1 && BuyMe && SellMe) || FirstRun)
     {
      BuyMe = false;
      SellMe = false;
     }
   if(ForceMarketCond < 2 && IndEntry == 0 && CbT == 0 && !FirstRun)
     {
      if(ForceMarketCond == 0)
         BuyMe = true;
      if(ForceMarketCond == 1)
         SellMe = true;
      IndicatorUsed = " FMC ";
     }
//+-----------------------------------------------------------------+
//| Trade Selection Logic                                           |
//+-----------------------------------------------------------------+
   OrderLot = LotSize(Lots[StrToInteger(DTS(MathMin(CbT + CbC, MaxTrades - 1), 0))] * LotMult, sym);
   if(CbT == 0 && CpT < 2 && !FirstRun)
     {
      if(B3Traditional)
        {
         if(BuyMe)
           {
            if(CpBS == 0 && CpSL == 0 && ((Trend != 2 || MAEntry == 0) || (Trend == 2 && MAEntry == 1)))
              {
               Entry = g2 - MathMod(ASK, g2) + EntryOffset;
               if(Entry > StopLevel)
                 {
                  Ticket = SendOrder(sym, OP_BUYSTOP, OrderLot, Entry, 0, Magic, CLR_NONE);
                  if(Ticket > 0)
                    {
                     if(Debug2)
                        Print("Indicator Entry - (" + IndicatorUsed + ") BuyStop MC = " + Trend);
                     CpBS++;
                    }
                 }
              }
            if(CpBL == 0 && CpSS == 0 && ((Trend != 2 || MAEntry == 0) || (Trend == 2 && MAEntry == 2)))
              {
               Entry = MathMod(ASK, g2) + EntryOffset;
               if(Entry > StopLevel)
                 {
                  Ticket = SendOrder(sym, OP_BUYLIMIT, OrderLot, -Entry, 0, Magic, CLR_NONE);
                  if(Ticket > 0)
                    {
                     if(Debug2)
                        Print("Indicator Entry - (" + IndicatorUsed + ") BuyLimit MC = " + Trend);
                     CpBL++;
                    }
                 }
              }
           }
         if(SellMe)
           {
            if(CpSL == 0 && CpBS == 0 && ((Trend != 2 || MAEntry == 0) || (Trend == 2 && MAEntry == 2)))
              {
               Entry = g2 - MathMod(BID, g2) + EntryOffset;
               if(Entry > StopLevel)
                 {
                  Ticket = SendOrder(sym, OP_SELLLIMIT, OrderLot, Entry, 0, Magic, CLR_NONE);
                  if(Ticket > 0 && Debug2)
                     Print("Indicator Entry - (" + IndicatorUsed + ") SellLimit MC = " + Trend);
                 }
              }
            if(CpSS == 0 && CpBL == 0 && ((Trend != 2 || MAEntry == 0) || (Trend == 2 && MAEntry == 1)))
              {
               Entry = MathMod(BID, g2) + EntryOffset;
               if(Entry > StopLevel)
                 {
                  Ticket = SendOrder(sym, OP_SELLSTOP, OrderLot, -Entry, 0, Magic, CLR_NONE);
                  if(Ticket > 0 && Debug2)
                     Print("Indicator Entry - (" + IndicatorUsed + ") SellStop MC = " + Trend);
                 }
              }
           }
        }
      else
        {
         if(BuyMe)
           {
            Ticket = SendOrder(sym, OP_BUY, OrderLot, 0, slip, Magic, Blue);
            if(Ticket > 0 && Debug2)
               Print("Indicator Entry - (" + IndicatorUsed + ") Buy");
           }
         else
            if(SellMe)
              {
               Ticket = SendOrder(sym, OP_SELL, OrderLot, 0, slip, Magic, displayColorLoss);
               if(Ticket > 0 && Debug2)
                  Print("Indicator Entry - (" + IndicatorUsed + ") Sell");
              }
        }
      if(Ticket > 0)
         return(0);
     }
   else
      if(TimeCurrent() - EntryDelay > OTbL && CbT + CbC < MaxTrades && !FirstRun)
        {
         if(UseSmartGrid)
           {
            if(RSI[1] != iRSI(NULL, TF[RSI_TF], RSI_Period, RSI_Price, 1))
               for(int y = 0; y < RSI_Period + RSI_MA_Period; y++)
                  RSI[y] = iRSI(NULL, TF[RSI_TF], RSI_Period, RSI_Price, y);
            else
               RSI[0] = iRSI(NULL, TF[RSI_TF], RSI_Period, RSI_Price, 0);
            RSI_MA = iMAOnArray(RSI, 0, RSI_MA_Period, 0, RSI_MA_Method, 0);
           }
         if(CbB > 0)
           {
            if(OPbL > ASK)
               Entry = OPbL - (MathRound((OPbL - ASK) / g2) + 1) * g2;
            else
               Entry = OPbL - g2;
            double OPbN;
            if(UseSmartGrid)
              {
               if(ASK < OPbL - g2)
                 {
                  if(RSI[0] > RSI_MA)
                    {
                     Ticket = SendOrder(sym, OP_BUY, OrderLot, 0, slip, Magic, Blue);
                     if(Ticket > 0 && Debug2)
                        Print("SmartGrid Buy RSI: " + RSI[0] + " > MA: " + RSI_MA);
                    }
                  OPbN = 0;
                 }
               else
                  OPbN = OPbL - g2;
              }
            else
               if(CpBL == 0)
                 {
                  if(ASK - Entry <= StopLevel)
                     Entry = OPbL - (MathFloor((OPbL - ASK + StopLevel) / g2) + 1) * g2;
                  Ticket = SendOrder(sym, OP_BUYLIMIT, OrderLot, Entry - ASK, 0, Magic, SkyBlue);
                  if(Ticket > 0 && Debug2)
                     Print("BuyLimit grid");
                 }
               else
                  if(CpBL == 1 && Entry - OPpBL > g2 / 2 && ASK - Entry > StopLevel)
                    {
                     for(int y = OrdersTotal(); y >= 0; y--)
                       {
                        if(!OrderSelect(y, SELECT_BY_POS, MODE_TRADES))
                           continue;
                        if(OrderMagicNumber() != Magic || OrderSymbol() != sym || OrderType() != OP_BUYLIMIT)
                           continue;
                        Success = ModifyOrder(Entry, 0, SkyBlue, sym);
                        if(Success && Debug2)
                           Print("Mod BuyLimit Entry");
                       }
                    }
           }
         else
            if(CbS > 0)
              {
               if(BID > OPbL)
                  Entry = OPbL + (MathRound((-OPbL + BID) / g2) + 1) * g2;
               else
                  Entry = OPbL + g2;
               if(UseSmartGrid)
                 {
                  if(BID > OPbL + g2)
                    {
                     if(RSI[0] < RSI_MA)
                       {
                        Ticket = SendOrder(sym, OP_SELL, OrderLot, 0, slip, Magic, displayColorLoss);
                        if(Ticket > 0 && Debug2)
                           Print("SmartGrid Sell RSI: " + RSI[0] + " < MA: " + RSI_MA);
                       }
                     OPbN = 0;
                    }
                  else
                     OPbN = OPbL + g2;
                 }
               else
                  if(CpSL == 0)
                    {
                     if(Entry - BID <= StopLevel)
                        Entry = OPbL + (MathFloor((-OPbL + BID + StopLevel) / g2) + 1) * g2;
                     Ticket = SendOrder(sym, OP_SELLLIMIT, OrderLot, Entry - BID, 0, Magic, Coral);
                     if(Ticket > 0 && Debug2)
                        Print("SellLimit grid");
                    }
                  else
                     if(CpSL == 1 && OPpSL - Entry > g2 / 2 && Entry - BID > StopLevel)
                       {
                        for(int y = OrdersTotal() - 1; y >= 0; y--)
                          {
                           if(!OrderSelect(y, SELECT_BY_POS, MODE_TRADES))
                              continue;
                           if(OrderMagicNumber() != Magic || OrderSymbol() != sym || OrderType() != OP_SELLLIMIT)
                              continue;
                           Success = ModifyOrder(Entry, 0, Coral, sym);
                           if(Success && Debug2)
                              Print("Mod SellLimit Entry");
                          }
                       }
              }
         if(Ticket > 0)
            return(0);
        }
//+-----------------------------------------------------------------+
//| Hedge Trades Set-Up and Monitoring                              |
//+-----------------------------------------------------------------+
   if((UseHedge && CbT > 0) || ChT > 0)
     {
      int hLevel = CbT + CbC;
      if(HedgeTypeDD)
        {
         if(hDDStart == 0 && ChT > 0)
            hDDStart = MathMax(HedgeStart, DrawDownPC + hReEntryPC);
         if(hDDStart > HedgeStart && hDDStart > DrawDownPC + hReEntryPC)
            hDDStart = DrawDownPC + hReEntryPC;
         if(hActive == 2)
           {
            hActive = 0;
            hDDStart = MathMax(HedgeStart, DrawDownPC + hReEntryPC);
           }
        }
      if(hActive == 0)
        {
         if(!hThisChart && ((hPosCorr && CheckCorr(sym) < 0.9) || (!hPosCorr && CheckCorr(sym) > -0.9)))
           {
            if(ObjectFind("B3LhCor") == -1)
               CreateLabel("B3LhCor", "The correlation with the hedge pair has dropped below 90%.", 0, 0, 190, 10, displayColorLoss);
           }
         else
            ObjDel("B3LhCor");
         if(hLvlStart > hLevel + 1 || (!HedgeTypeDD && hLvlStart == 0))
            hLvlStart = MathMax(HedgeStart, hLevel + 1);
         if((HedgeTypeDD && DrawDownPC > hDDStart) || (!HedgeTypeDD && hLevel >= hLvlStart))
           {
            OrderLot = LotSize(LbT * hLotMult, sym);
            if((CbB > 0 && !hPosCorr) || (CbS > 0 && hPosCorr))
              {
               Ticket = SendOrder(HedgeSymbol, OP_BUY, OrderLot, 0, slip, hMagic, MidnightBlue);
               if(Ticket > 0)
                 {
                  if(hMaxLossPips > 0)
                     SLh = hAsk - hMaxLossPips;
                  if(Debug2)
                     Print("Hedge Buy : Stoploss @ " + DTS(SLh, dig));
                 }
              }
            if((CbB > 0 && hPosCorr) || (CbS > 0 && !hPosCorr))
              {
               Ticket = SendOrder(HedgeSymbol, OP_SELL, OrderLot, 0, slip, hMagic, Maroon);
               if(Ticket > 0)
                 {
                  if(hMaxLossPips > 0)
                     SLh = hBid + hMaxLossPips;
                  if(Debug2)
                     Print("Hedge Sell : Stoploss @ " + DTS(SLh, dig));
                 }
              }
            if(Ticket > 0)
              {
               hActive = 1;
               if(HedgeTypeDD)
                  hDDStart += hReEntryPC;
               hLvlStart = hLevel + 1;
               return(0);
              }
           }
        }
      else
         if(hActive == 1)
           {
            if(HedgeTypeDD && hDDStart > HedgeStart && hDDStart < DrawDownPC + hReEntryPC)
               hDDStart = DrawDownPC + hReEntryPC;
            if(hLvlStart == 0)
              {
               if(HedgeTypeDD)
                  hLvlStart = hLevel + 1;
               else
                  hLvlStart = MathMax(HedgeStart, hLevel + 1);
              }
            if(hLevel >= hLvlStart)
              {
               OrderLot = LotSize(Lots[CbT + CbC - 1] * LotMult * hLotMult, sym);
               if(OrderLot > 0 && ((CbB > 0 && !hPosCorr) || (CbS > 0 && hPosCorr)))
                 {
                  Ticket = SendOrder(HedgeSymbol, OP_BUY, OrderLot, 0, slip, hMagic, MidnightBlue);
                  if(Ticket > 0 && Debug2)
                     Print("Hedge Buy");
                 }
               if(OrderLot > 0 && ((CbB > 0 && hPosCorr) || (CbS > 0 && !hPosCorr)))
                 {
                  Ticket = SendOrder(HedgeSymbol, OP_SELL, OrderLot, 0, slip, hMagic, Maroon);
                  if(Ticket > 0 && Debug2)
                     Print("Hedge Sell");
                 }
               if(Ticket > 0)
                 {
                  hLvlStart = hLevel + 1;
                  return(0);
                 }
              }
            int y = 0;
            if(!FirstRun && hMaxLossPips > 0)
              {
               if(ChB > 0)
                 {
                  if(hFixedSL)
                    {
                     if(SLh == 0)
                        SLh = hBid - hMaxLossPips;
                    }
                  else
                    {
                     if(SLh == 0 || (SLh < BEh && SLh < hBid - hMaxLossPips))
                        SLh = hBid - hMaxLossPips;
                     else
                        if(StopTrailAtBE && hBid - hMaxLossPips >= BEh)
                           SLh = BEh;
                        else
                           if(SLh >= BEh && !StopTrailAtBE)
                             {
                              if(!ReduceTrailStop)
                                 SLh = MathMax(SLh, hBid - hMaxLossPips);
                              else
                                 SLh = MathMax(SLh, hBid - MathMax(StopLevel, hMaxLossPips * (1 - (hBid - hMaxLossPips - BEh) / (hMaxLossPips * 2))));
                             }
                    }
                  if(hBid <= SLh)
                     y = ExitTrades(H, DarkViolet, "Hedge Stop Loss");
                 }
               else
                  if(ChS > 0)
                    {
                     if(hFixedSL)
                       {
                        if(SLh == 0)
                           SLh = hAsk + hMaxLossPips;
                       }
                     else
                       {
                        if(SLh == 0 || (SLh > BEh && SLh > hAsk + hMaxLossPips))
                           SLh = hAsk + hMaxLossPips;
                        else
                           if(StopTrailAtBE && hAsk + hMaxLossPips <= BEh)
                              SLh = BEh;
                           else
                              if(SLh <= BEh && !StopTrailAtBE)
                                {
                                 if(!ReduceTrailStop)
                                    SLh = MathMin(SLh, hAsk + hMaxLossPips);
                                 else
                                    SLh = MathMin(SLh, hAsk + MathMax(StopLevel, hMaxLossPips * (1 - (BEh - hAsk - hMaxLossPips) / (hMaxLossPips * 2))));
                                }
                       }
                     if(hAsk >= SLh)
                        y = ExitTrades(H, DarkViolet, "Hedge Stop Loss");
                    }
              }
            if(y == 0 && hTakeProfit > 0)
              {
               if(ChB > 0 && hBid > OPhO + hTakeProfit)
                  y = ExitTrades(T, DarkViolet, "Hedge Take Profit reached", ThO, sym);
               if(ChS > 0 && hAsk < OPhO - hTakeProfit)
                  y = ExitTrades(T, DarkViolet, "Hedge Take Profit reached", ThO, sym);
              }
            if(y > 0)
              {
               PhC = FindClosedPL(H);
               if(y == ChT)
                 {
                  if(HedgeTypeDD)
                     hActive = 2;
                  else
                     hActive = 0;
                 }
               return(0);
              }
           }
     }
//+-----------------------------------------------------------------+
//| Check DD% and send Email                                        |
//+-----------------------------------------------------------------+
   if((UseEmail || PlaySounds) && !Testing)
     {
      if(EmailCount < 2 && Email[EmailCount] > 0 && DrawDownPC > Email[EmailCount])
        {
         GetLastError();
         if(UseEmail)
           {
            SendMail(" Zones EA", " Zones EA has exceeded a drawdown of " + Email[EmailCount] * 100 + "% on " + sym + " " + sTF);
            Error = GetLastError();
            if(Error > 0)
               Print("Email DD: " + DTS(DrawDownPC * 100, 2) + " Error: " + Error + " " + ErrorDescription(Error));
            else
               if(Debug2)
                  Print("DrawDown Email sent on " + sym + " " + sTF + " DD: " + DTS(DrawDownPC * 100, 2));
            EmailSent = TimeCurrent();
            EmailCount++;
           }
         if(PlaySounds)
            PlaySound(AlertSound);
        }
      else
         if(EmailCount > 0 && EmailCount < 3 && DrawDownPC < Email[EmailCount] && TimeCurrent() > EmailSent + EmailHours * 3600)
            EmailCount--;
     }
//+-----------------------------------------------------------------+
//| Display Overlay Code                                            |
//+-----------------------------------------------------------------+
   if((Testing && Visual) || !Testing)
     {
      if(displayOverlay)
        {
         color Colour;
         int dDigits;
         ObjSetTxt("B3VTime", TimeToStr(TimeCurrent(), TIME_SECONDS));
         DrawLabel("B3VSTAm", InitialAccountMultiPortion, 167, 2, displayColorLoss);
         if(UseHolidayShutdown)
           {
            ObjSetTxt("B3VHolF", TimeToStr(HolFirst, TIME_DATE));
            ObjSetTxt("B3VHolT", TimeToStr(HolLast, TIME_DATE));
           }
         DrawLabel("B3VPBal", PortionBalance, 167);
         if(DrawDownPC > 0.4)
            Colour = displayColorLoss;
         else
            if(DrawDownPC > 0.3)
               Colour = Orange;
            else
               if(DrawDownPC > 0.2)
                  Colour = Yellow;
               else
                  if(DrawDownPC > 0.1)
                     Colour = displayColorProfit;
                  else
                     Colour = displayColor;
         DrawLabel("B3VDrDn", DrawDownPC * 100, 315, 2, Colour);
         if(UseHedge && HedgeTypeDD)
            ObjSetTxt("B3VhDDm", DTS(hDDStart * 100, 2));
         else
            if(UseHedge && !HedgeTypeDD)
              {
               DrawLabel("B3VhLvl", CbT + CbC, 318, 0);
               ObjSetTxt("B3VhLvT", DTS(hLvlStart, 0));
              }
         ObjSetTxt("B3VSLot", DTS(Lot * LotMult, 2));
         if(ProfitPot >= 0)
            DrawLabel("B3VPPot", ProfitPot, 190);
         else
           {
            ObjSetTxt("B3VPPot", DTS(ProfitPot, 2), 0, displayColorLoss);
            dDigits = Digit[ArrayBsearch(Digit, -ProfitPot, WHOLE_ARRAY, 0, MODE_ASCEND), 1];
            ObjSet("B3VPPot", 186 - dDigits * 7);
           }
         if(UseEarlyExit && EEpc < 1)
           {
            if(ObjectFind("B3SEEPr") == -1)
               CreateLabel("B3SEEPr", "/", 0, 0, 220, 12);
            if(ObjectFind("B3VEEPr") == -1)
               CreateLabel("B3VEEPr", "", 0, 0, 229, 12);
            ObjSetTxt("B3VEEPr", DTS(PbTarget * PipValue * MathAbs(LbB - LbS), 2));
           }
         else
           {
            ObjDel("B3SEEPr");
            ObjDel("B3VEEPr");
           }
         if(SLb > 0)
            DrawLabel("B3VPrSL", SLb, 190, dig);
         else
            if(bSL > 0)
               DrawLabel("B3VPrSL", bSL, 190, dig);
            else
               if(bTS > 0)
                  DrawLabel("B3VPrSL", bTS, 190, dig);
               else
                  DrawLabel("B3VPrSL", 0, 190, 2);
         if(Pb >= 0)
           {
            DrawLabel("B3VPnPL", Pb, 190, 2, displayColorProfit);
            ObjSetTxt("B3VPPip", DTS(PbPips, 1), 0, displayColorProfit);
            ObjSet("B3VPPip", 229);
           }
         else
           {
            ObjSetTxt("B3VPnPL", DTS(Pb, 2), 0, displayColorLoss);
            dDigits = Digit[ArrayBsearch(Digit, -Pb, WHOLE_ARRAY, 0, MODE_ASCEND), 1];
            ObjSet("B3VPnPL", 186 - dDigits * 7);
            ObjSetTxt("B3VPPip", DTS(PbPips, 1), 0, displayColorLoss);
            ObjSet("B3VPPip", 225);
           }
         if(PbMax >= 0)
            DrawLabel("B3VPLMx", PbMax, 190, 2, displayColorProfit);
         else
           {
            ObjSetTxt("B3VPLMx", DTS(PbMax, 2), 0, displayColorLoss);
            dDigits = Digit[ArrayBsearch(Digit, -PbMax, WHOLE_ARRAY, 0, MODE_ASCEND), 1];
            ObjSet("B3VPLMx", 186 - dDigits * 7);
           }
         if(PbMin < 0)
            ObjSet("B3VPLMn", 225);
         else
            ObjSet("B3VPLMn", 229);
         ObjSetTxt("B3VPLMn", DTS(PbMin, 2), 0, displayColorLoss);
         if(CbT + CbC < BreakEvenTrade && CbT + CbC < MaxTrades)
            Colour = displayColor;
         else
            if(CbT + CbC < MaxTrades)
               Colour = Orange;
            else
               Colour = displayColorLoss;
         if(CbB > 0)
           {
            ObjSetTxt("B3LType", "Buy:");
            DrawLabel("B3VOpen", CbB, 207, 0, Colour);
           }
         else
            if(CbS > 0)
              {
               ObjSetTxt("B3LType", "Sell:");
               DrawLabel("B3VOpen", CbS, 207, 0, Colour);
              }
            else
              {
               ObjSetTxt("B3LType", "");
               ObjSetTxt("B3VOpen", DTS(0, 0), 0, Colour);
               ObjSet("B3VOpen", 207);
              }
         ObjSetTxt("B3VLots", DTS(LbT, 2));
         ObjSetTxt("B3VMove", DTS(Moves, 0));
         DrawLabel("B3VMxDD", MaxDD, 107);
         DrawLabel("B3VDDPC", MaxDDPer, 229);
         if(Trend == 0)
           {
            ObjSetTxt("B3LTrnd", "Trend is UP", 10, displayColorProfit);
            if(ObjectFind("B3ATrnd") == -1)
               CreateLabel("B3ATrnd", "", 0, 0, 160, 20, displayColorProfit, "Wingdings");
            ObjectSetText("B3ATrnd", "é", displayFontSize + 9, "Wingdings", displayColorProfit);
            ObjSet("B3ATrnd", 160);
            ObjectSet("B3ATrnd", OBJPROP_YDISTANCE, displayYcord + displaySpacing * 20);
            if(StringLen(ATrend) > 0)
              {
               if(ObjectFind("B3AATrn") == -1)
                  CreateLabel("B3AATrn", "", 0, 0, 200, 20, displayColorProfit, "Wingdings");
               if(ATrend == "D")
                 {
                  ObjectSetText("B3AATrn", "ê", displayFontSize + 9, "Wingdings", displayColorLoss);
                  ObjectSet("B3AATrn", OBJPROP_YDISTANCE, displayYcord + displaySpacing * 20 + 5);
                 }
               else
                  if(ATrend == "R")
                    {
                     ObjSetTxt("B3AATrn", "R", 10, Orange);
                     ObjectSet("B3AATrn", OBJPROP_YDISTANCE, displayYcord + displaySpacing * 20);
                    }
              }
            else
               ObjDel("B3AATrn");
           }
         else
            if(Trend == 1)
              {
               ObjSetTxt("B3LTrnd", "Trend is DOWN", 10, displayColorLoss);
               if(ObjectFind("B3ATrnd") == -1)
                  CreateLabel("B3ATrnd", "", 0, 0, 210, 20, displayColorLoss, "WingDings");
               ObjectSetText("B3ATrnd", "ê", displayFontSize + 9, "Wingdings", displayColorLoss);
               ObjSet("B3ATrnd", 210);
               ObjectSet("B3ATrnd", OBJPROP_YDISTANCE, displayYcord + displaySpacing * 20 + 5);
               if(StringLen(ATrend) > 0)
                 {
                  if(ObjectFind("B3AATrn") == -1)
                     CreateLabel("B3AATrn", "", 0, 0, 250, 20, displayColorProfit, "Wingdings");
                  if(ATrend == "U")
                    {
                     ObjectSetText("B3AATrn", "é", displayFontSize + 9, "Wingdings", displayColorProfit);
                     ObjectSet("B3AATrn", OBJPROP_YDISTANCE, displayYcord + displaySpacing * 20);
                    }
                  else
                     if(ATrend == "R")
                       {
                        ObjSetTxt("B3AATrn", "R", 10, Orange);
                        ObjectSet("B3AATrn", OBJPROP_YDISTANCE, displayYcord + displaySpacing * 20);
                       }
                 }
               else
                  ObjDel("B3AATrn");
              }
            else
               if(Trend == 2)
                 {
                  ObjSetTxt("B3LTrnd", "Trend is Ranging", 10, Orange);
                  ObjDel("B3ATrnd");
                  if(StringLen(ATrend) > 0)
                    {
                     if(ObjectFind("B3AATrn") == -1)
                        CreateLabel("B3AATrn", "", 0, 0, 220, 20, displayColorProfit, "Wingdings");
                     if(ATrend == "U")
                       {
                        ObjectSetText("B3AATrn", "é", displayFontSize + 9, "Wingdings", displayColorProfit);
                        ObjectSet("B3AATrn", OBJPROP_YDISTANCE, displayYcord + displaySpacing * 20);
                       }
                     else
                        if(ATrend == "D")
                          {
                           ObjectSetText("B3AATrn", "ê", displayFontSize + 8, "Wingdings", displayColorLoss);
                           ObjectSet("B3AATrn", OBJPROP_YDISTANCE, displayYcord + displaySpacing * 20 + 5);
                          }
                    }
                  else
                     ObjDel("B3AATrn");
                 }
         if(PaC != 0)
           {
            if(ObjectFind("B3LClPL") == -1)
               CreateLabel("B3LClPL", "Closed P/L", 0, 0, 312, 11);
            if(ObjectFind("B3VClPL") == -1)
               CreateLabel("B3VClPL", "", 0, 0, 327, 12);
            if(PaC >= 0)
               DrawLabel("B3VClPL", PaC, 327, 2, displayColorProfit);
            else
              {
               ObjSetTxt("B3VClPL", DTS(PaC, 2), 0, displayColorLoss);
               dDigits = Digit[ArrayBsearch(Digit, -PaC, WHOLE_ARRAY, 0, MODE_ASCEND), 1];
               ObjSet("B3VClPL", 323 - dDigits * 7);
              }
           }
         else
           {
            ObjDel("B3LClPL");
            ObjDel("B3VClPL");
           }
         if(hActive == 1)
           {
            if(ObjectFind("B3LHdge") == -1)
               CreateLabel("B3LHdge", "Hedge", 0, 0, 323, 13);
            if(ObjectFind("B3VhPro") == -1)
               CreateLabel("B3VhPro", "", 0, 0, 312, 14);
            if(Ph >= 0)
               DrawLabel("B3VhPro", Ph, 312, 2, displayColorProfit);
            else
              {
               ObjSetTxt("B3VhPro", DTS(Ph, 2), 0, displayColorLoss);
               dDigits = Digit[ArrayBsearch(Digit, -Ph, WHOLE_ARRAY, 0, MODE_ASCEND), 1];
               ObjSet("B3VhPro", 308 - dDigits * 7);
              }
            if(ObjectFind("B3VhPMx") == -1)
               CreateLabel("B3VhPMx", "", 0, 0, 312, 15);
            if(PhMax >= 0)
               DrawLabel("B3VhPMx", PhMax, 312, 2, displayColorProfit);
            else
              {
               ObjSetTxt("B3VhPMx", DTS(PhMax, 2), 0, displayColorLoss);
               dDigits = Digit[ArrayBsearch(Digit, -PhMax, WHOLE_ARRAY, 0, MODE_ASCEND), 1];
               ObjSet("B3VhPMx", 308 - dDigits * 7);
              }
            if(ObjectFind("B3ShPro") == -1)
               CreateLabel("B3ShPro", "/", 0, 0, 342, 15);
            if(ObjectFind("B3VhPMn") == -1)
               CreateLabel("B3VhPMn", "", 0, 0, 351, 15, displayColorLoss);
            if(PhMin < 0)
               ObjSet("B3VhPMn", 347);
            else
               ObjSet("B3VhPMn", 351);
            ObjSetTxt("B3VhPMn", DTS(PhMin, 2), 0, displayColorLoss);
            if(ObjectFind("B3LhTyp") == -1)
               CreateLabel("B3LhTyp", "", 0, 0, 292, 16);
            if(ObjectFind("B3VhOpn") == -1)
               CreateLabel("B3VhOpn", "", 0, 0, 329, 16);
            if(ChB > 0)
              {
               ObjSetTxt("B3LhTyp", "Buy:");
               DrawLabel("B3VhOpn", ChB, 329, 0);
           
              }
            else
               if(ChS > 0)
                 {
                  ObjSetTxt("B3LhTyp", "Sell:");
                  DrawLabel("B3VhOpn", ChS, 329, 0);
                 }
               else
                 {
                  ObjSetTxt("B3LhTyp", "");
                  ObjSetTxt("B3VhOpn", DTS(0, 0));
                  ObjSet("B3VhOpn", 329);
                 }
            if(ObjectFind("B3ShOpn") == -1)
               CreateLabel("B3ShOpn", "/", 0, 0, 342, 16);
            if(ObjectFind("B3VhLot") == -1)
               CreateLabel("B3VhLot", "", 0, 0, 351, 16);
            ObjSetTxt("B3VhLot", DTS(LhT, 2));
           }
         else
           {
            ObjDel("B3LHdge");
            ObjDel("B3VhPro");
            ObjDel("B3VhPMx");
            ObjDel("B3ShPro");
            ObjDel("B3VhPMn");
            ObjDel("B3LhTyp");
            ObjDel("B3VhOpn");
            ObjDel("B3ShOpn");
            ObjDel("B3VhLot");
           }
        }
      if(displayLines)
        {
         if(BEb > 0)
           {
            if(ObjectFind("B3LBELn") == -1)
               CreateLine("B3LBELn", DodgerBlue, 1, 0);
            ObjectMove("B3LBELn", 0, Time[1], BEb);
           }
         else
            ObjDel("B3LBELn");
         if(TPa > 0)
           {
            if(ObjectFind("B3LTPLn") == -1)
               CreateLine("B3LTPLn", Gold, 1, 0);
            ObjectMove("B3LTPLn", 0, Time[1], TPa);
           }
         else
            if(TPb > 0 && nLots != 0)
              {
               if(ObjectFind("B3LTPLn") == -1)
                  CreateLine("B3LTPLn", Gold, 1, 0);
               ObjectMove("B3LTPLn", 0, Time[1], TPb);
              }
            else
               ObjDel("B3LTPLn");
         if(OPbN > 0)
           {
            if(ObjectFind("B3LOPLn") == -1)
               CreateLine("B3LOPLn", Red, 1, 4);
            ObjectMove("B3LOPLn", 0, Time[1], OPbN);
           }
         else
            ObjDel("B3LOPLn");
         if(bSL > 0)
           {
            if(ObjectFind("B3LSLbT") == -1)
               CreateLine("B3LSLbT", Red, 1, 3);
            ObjectMove("B3LSLbT", 0, Time[1], bSL);
           }
         else
            ObjDel("B3LSLbT");
         if(bTS > 0)
           {
            if(ObjectFind("B3LTSbT") == -1)
               CreateLine("B3LTSbT", Gold, 1, 3);
            ObjectMove("B3LTSbT", 0, Time[1], bTS);
           }
         else
            ObjDel("B3LTSbT");
         if(hActive == 1 && BEa > 0)
           {
            if(ObjectFind("B3LNBEL") == -1)
               CreateLine("B3LNBEL", Crimson, 1, 0);
            ObjectMove("B3LNBEL", 0, Time[1], BEa);
           }
         else
            ObjDel("B3LNBEL");
         if(TPbMP > 0)
           {
            if(ObjectFind("B3LMPLn") == -1)
               CreateLine("B3LMPLn", Gold, 1, 4);
            ObjectMove("B3LMPLn", 0, Time[1], TPbMP);
           }
         else
            ObjDel("B3LMPLn");
         if(SLb > 0)
           {
            if(ObjectFind("B3LTSLn") == -1)
               CreateLine("B3LTSLn", Gold, 1, 2);
            ObjectMove("B3LTSLn", 0, Time[1], SLb);
           }
         else
            ObjDel("B3LTSLn");
         if(hThisChart && BEh > 0)
           {
            if(ObjectFind("B3LhBEL") == -1)
               CreateLine("B3LhBEL", SlateBlue, 1, 0);
            ObjectMove("B3LhBEL", 0, Time[1], BEh);
           }
         else
            ObjDel("B3LhBEL");
         if(hThisChart && SLh > 0)
           {
            if(ObjectFind("B3LhSLL") == -1)
               CreateLine("B3LhSLL", SlateBlue, 1, 3);
            ObjectMove("B3LhSLL", 0, Time[1], SLh);
           }
         else
            ObjDel("B3LhSLL");
        }
      else
        {
         ObjDel("B3LBELn");
         ObjDel("B3LTPLn");
         ObjDel("B3LOPLn");
         ObjDel("B3LSLbT");
         ObjDel("B3LTSbT");
         ObjDel("B3LNBEL");
         ObjDel("B3LMPLn");
         ObjDel("B3LTSLn");
         ObjDel("B3LhBEL");
         ObjDel("B3LhSLL");
        }
      if(CCIEntry && displayCCI)
        {
         if(cci_01 > 0 && cci_11 > 0)
            ObjectSetText("B3VCm05", "Ù", displayFontSize + 6, "Wingdings", displayColorProfit);
         else
            if(cci_01 < 0 && cci_11 < 0)
               ObjectSetText("B3VCm05", "Ú", displayFontSize + 6, "Wingdings", displayColorLoss);
            else
               ObjectSetText("B3VCm05", "Ø", displayFontSize + 6, "Wingdings", Orange);
         if(cci_02 > 0 && cci_12 > 0)
            ObjectSetText("B3VCm15", "Ù", displayFontSize + 6, "Wingdings", displayColorProfit);
         else
            if(cci_02 < 0 && cci_12 < 0)
               ObjectSetText("B3VCm15", "Ú", displayFontSize + 6, "Wingdings", displayColorLoss);
            else
               ObjectSetText("B3VCm15", "Ø", displayFontSize + 6, "Wingdings", Orange);
         if(cci_03 > 0 && cci_13 > 0)
            ObjectSetText("B3VCm30", "Ù", displayFontSize + 6, "Wingdings", displayColorProfit);
         else
            if(cci_03 < 0 && cci_13 < 0)
               ObjectSetText("B3VCm30", "Ú", displayFontSize + 6, "Wingdings", displayColorLoss);
            else
               ObjectSetText("B3VCm30", "Ø", displayFontSize + 6, "Wingdings", Orange);
         if(cci_04 > 0 && cci_14 > 0)
            ObjectSetText("B3VCm60", "Ù", displayFontSize + 6, "Wingdings", displayColorProfit);
         else
            if(cci_04 < 0 && cci_14 < 0)
               ObjectSetText("B3VCm60", "Ú", displayFontSize + 6, "Wingdings", displayColorLoss);
            else
               ObjectSetText("B3VCm60", "Ø", displayFontSize + 6, "Wingdings", Orange);
        }
      if(Debug2)
        {
         string dSpace;
         for(int y = 0; y <= 175; y++)
            dSpace = dSpace + " ";
         string dMess = "\n\n" + dSpace + "Ticket   Magic     Type Lots OpenPrice  Costs  Profit  Potential";
         for(int y = 0; y < OrdersTotal(); y++)
           {
            if(!OrderSelect(y, SELECT_BY_POS, MODE_TRADES))
               continue;
            if(OrderMagicNumber() != Magic && OrderMagicNumber() != hMagic)
               continue;
            dMess = (dMess + "\n" + dSpace + " " + OrderTicket() + "  " + DTS(OrderMagicNumber(), 0) + "   " + OrderType());
            dMess = (dMess + "   " + DTS(OrderLots(), LotDecimal) + "  " + DTS(OrderOpenPrice(), dig));
            dMess = (dMess + "     " + DTS(OrderSwap() + OrderCommission(), 2));
            dMess = (dMess + "    " + DTS(OrderProfit() + OrderSwap() + OrderCommission(), 2));
            if(OrderMagicNumber() != Magic)
               continue;
            if(OrderType() == OP_BUY)
               dMess = (dMess + "      " + DTS(OrderLots() * (TPb - OrderOpenPrice()) * PipVal2 + OrderSwap() + OrderCommission(), 2));
            if(OrderType() == OP_SELL)
               dMess = (dMess + "      " + DTS(OrderLots() * (OrderOpenPrice() - TPb) * PipVal2 + OrderSwap() + OrderCommission(), 2));
           }
         if(!dLabels)
           {
            dLabels = true;
            CreateLabel("B3LPipV", "Pip Value", 0, 2, 0, 0);
            CreateLabel("B3VPipV", "", 0, 2, 100, 0);
            CreateLabel("B3LDigi", "Digits Value", 0, 2, 0, 1);
            CreateLabel("B3VDigi", "", 0, 2, 100, 1);
            ObjSetTxt("B3VDigi", DTS(dig, 0));
            CreateLabel("B3LPoin", "Point Value", 0, 2, 0, 2);
            CreateLabel("B3VPoin", "", 0, 2, 100, 2);
            ObjSetTxt("B3VPoin", DTS(Point, dig));
            CreateLabel("B3LSprd", "Spread Value", 0, 2, 0, 3);
            CreateLabel("B3VSprd", "", 0, 2, 100, 3);
            CreateLabel("B3LBid", "Bid Value", 0, 2, 0, 4);
            CreateLabel("B3VBid", "", 0, 2, 100, 4);
            CreateLabel("B3LAsk", "Ask Value", 0, 2, 0, 5);
            CreateLabel("B3VAsk", "", 0, 2, 100, 5);
            CreateLabel("B3LLotP", "Lot Step", 0, 2, 200, 0);
            CreateLabel("B3VLotP", "", 0, 2, 300, 0);
            ObjSetTxt("B3VLotP", DTS(MarketInfo(sym, MODE_LOTSTEP), LotDecimal));
            CreateLabel("B3LLotX", "Lot Max", 0, 2, 200, 1);
            CreateLabel("B3VLotX", "", 0, 2, 300, 1);
            ObjSetTxt("B3VLotX", DTS(MarketInfo(sym, MODE_MAXLOT), 0));
            CreateLabel("B3LLotN", "Lot Min", 0, 2, 200, 2);
            CreateLabel("B3VLotN", "", 0, 2, 300, 2);
            ObjSetTxt("B3VLotN", DTS(MarketInfo(sym, MODE_MINLOT), LotDecimal));
            CreateLabel("B3LLotD", "Lot Decimal", 0, 2, 200, 3);
            CreateLabel("B3VLotD", "", 0, 2, 300, 3);
            ObjSetTxt("B3VLotD", DTS(LotDecimal, 0));
            CreateLabel("B3LAccT", "Account Type", 0, 2, 200, 4);
            CreateLabel("B3VAccT", "", 0, 2, 300, 4);
            ObjSetTxt("B3VAccT", DTS(AccountType, 0));
            CreateLabel("B3LPnts", "Pip", 0, 2, 200, 5);
            CreateLabel("B3VPnts", "", 0, 2, 300, 5);
            ObjSetTxt("B3VPnts", DTS(Pip, dig));
            CreateLabel("B3LTicV", "Tick Value", 0, 2, 400, 0);
            CreateLabel("B3VTicV", "", 0, 2, 500, 0);
            CreateLabel("B3LTicS", "Tick Size", 0, 2, 400, 1);
            CreateLabel("B3VTicS", "", 0, 2, 500, 1);
            ObjSetTxt("B3VTicS", DTS(MarketInfo(sym, MODE_TICKSIZE), dig));
            CreateLabel("B3LLev", "Leverage", 0, 2, 400, 2);
            CreateLabel("B3VLev", "", 0, 2, 500, 2);
            ObjSetTxt("B3VLev", DTS(AccountLeverage(), 0) + ":1");
            CreateLabel("B3LSGTF", "SmartGrid", 0, 2, 400, 3);
            if(UseSmartGrid)
               CreateLabel("B3VSGTF", "True", 0, 2, 500, 3);
            else
               CreateLabel("B3VSGTF", "False", 0, 2, 500, 3);
            CreateLabel("B3LCOTF", "Close Oldest", 0, 2, 400, 4);
            if(UseCloseOldest)
               CreateLabel("B3VCOTF", "True", 0, 2, 500, 4);
            else
               CreateLabel("B3VCOTF", "False", 0, 2, 500, 4);
            CreateLabel("B3LUHTF", "Hedge", 0, 2, 400, 5);
            if(UseHedge && HedgeTypeDD)
               CreateLabel("B3VUHTF", "DrawDown", 0, 2, 500, 5);
            else
               if(UseHedge && !HedgeTypeDD)
                  CreateLabel("B3VUHTF", "Level", 0, 2, 500, 5);
               else
                  CreateLabel("B3VUHTF", "False", 0, 2, 500, 5);
           }
         ObjSetTxt("B3VPipV", DTS(PipValue, 2));
         ObjSetTxt("B3VSprd", DTS(ASK - BID, dig));
         ObjSetTxt("B3VBid", DTS(BID, dig));
         ObjSetTxt("B3VAsk", DTS(ASK, dig));
         ObjSetTxt("B3VTicV", DTS(MarketInfo(sym, MODE_TICKVALUE), dig));
        }
      if(EmergencyWarning)
        {
         if(ObjectFind("B3LClos") == -1)
            CreateLabel("B3LClos", "", 5, 0, 0, 23, displayColorLoss);
         ObjSetTxt("B3LClos", "WARNING: EmergencyCloseAll is set to TRUE", 5, displayColorLoss);
        }
      else
         if(ShutDown)
           {
            if(ObjectFind("B3LClos") == -1)
               CreateLabel("B3LClos", "", 5, 0, 0, 23, displayColorLoss);
            ObjSetTxt("B3LClos", " Zones EA will stop trading when this basket closes.", 5, displayColorLoss);
           }
         else
            if(HolShutDown != 1)
               ObjDel("B3LClos");
     }
   WindowRedraw();
   FirstRun = false;
   Comment(CS, dMess);
   return(0);
  }


//+-----------------------------------------------------------------+
//| Check Lot Size Funtion                                          |
//+-----------------------------------------------------------------+
double LotSize(double NewLot, string sym)
  {
   NewLot = ND(NewLot, LotDecimal);
   NewLot = MathMin(NewLot, MarketInfo(sym, MODE_MAXLOT));
   NewLot = MathMax(NewLot, MinLotSize);
   return(NewLot);
  }

//+-----------------------------------------------------------------+
//| Open Order Funtion                                              |
//+-----------------------------------------------------------------+
int SendOrder(string OSymbol, int OCmd, double OLot, double OPrice, double OSlip, int OMagic, color OColor = CLR_NONE)
  {
   if(FirstRun)
      return(-1);
   int Ticket;
   int retryTimes = 5, i = 0;
   int OType = MathMod(OCmd, 2);
   double OrderPrice;
   if(Pip == 0)
     {
      Pip = 5;
     }
   int dig = MarketInfo(OSymbol, MODE_DIGITS);
   if(AccountFreeMarginCheck(OSymbol, OType, OLot) <= 0)
      return(-1);
   if(MaxSpread > 0 && MarketInfo(OSymbol, MODE_SPREAD)*MarketInfo(OSymbol, MODE_POINT) / Pip > MaxSpread)
      return(-1);
   while(i < 5)
     {
      i += 1;
      while(IsTradeContextBusy())
         Sleep(100);
      if(IsStopped())
         return(-1);
      if(OType == 0)
         OrderPrice = ND(MarketInfo(OSymbol, MODE_ASK) + OPrice, dig);
      else
         OrderPrice = ND(MarketInfo(OSymbol, MODE_BID) + OPrice, dig);
      Ticket = OrderSend(OSymbol, OCmd, OLot, OrderPrice, OSlip, 0, 0, TradeComment, OMagic, 0, OColor);
      if(Ticket < 0)
        {
         Error = GetLastError();
         if(Error != 0)
            Print("Error opening order: " + Error + " " + ErrorDescription(Error)
                  + " Symbol: " + OSymbol
                  + " TradeOP: " + OCmd
                  + " OType: " + OType
                  + " Ask: " + DTS(MarketInfo(OSymbol, MODE_ASK), dig)
                  + " Bid: " + DTS(MarketInfo(OSymbol, MODE_BID), dig)
                  + " OPrice: " + DTS(OPrice, dig)
                  + " Price: " + DTS(OrderPrice, dig)
                  + " Lots: " + DTS(OLot, 2)
                 );
         switch(Error)
           {
            case ERR_TRADE_DISABLED:
               AllowTrading = false;
               Print("Your broker has not allowed EAs on this account");
               i = retryTimes;
               break;
            case ERR_OFF_QUOTES:
            case ERR_INVALID_PRICE:
               Sleep(5000);
            case ERR_PRICE_CHANGED:
            case ERR_REQUOTE:
               RefreshRates();
            case ERR_SERVER_BUSY:
            case ERR_NO_CONNECTION:
            case ERR_BROKER_BUSY:
            case ERR_TRADE_CONTEXT_BUSY:
               i++;
               break;
            case 149://ERR_TRADE_HEDGE_PROHIBITED:
               UseHedge = false;
               if(Debug2)
                  Print("Hedge trades are not allowed on this pair");
               i = retryTimes;
               break;
            default:
               i = retryTimes;
           }
        }
      else
        {
         if(PlaySounds)
            PlaySound(AlertSound);
         break;
        }
     }
   return(Ticket);
  }

//+-----------------------------------------------------------------+
//| Modify Order Function                                           |
//+-----------------------------------------------------------------+
bool ModifyOrder(double OrderOP, double OrderSL, color Color = CLR_NONE, string sym = "")
  {
   bool Success = false;
   int retryTimes = 5, i = 0;
   while(i < 5 && !Success)
     {
      i++;
      while(IsTradeContextBusy())
         Sleep(100);
      if(IsStopped())
         return false;
      Success = OrderModify(OrderTicket(), OrderOP, OrderSL, 0, 0, Color);
      if(!Success)
        {
         Error = GetLastError();
         if(Error > 1)
           {
            Print(" Error Modifying Order:", OrderTicket(), ", ", Error, " :" + ErrorDescription(Error), ", Ask:",  MarketInfo(sym, MODE_ASK),
                  ", Bid:", MarketInfo(sym, MODE_BID) + " OrderPrice: ", OrderOP, " StopLevel: ", StopLevel, ", SL: ", OrderSL, ", OSL: ", OrderStopLoss());
            switch(Error)
              {
               case ERR_TRADE_MODIFY_DENIED:
                  Sleep(10000);
               case ERR_OFF_QUOTES:
               case ERR_INVALID_PRICE:
                  Sleep(5000);
               case ERR_PRICE_CHANGED:
               case ERR_REQUOTE:
                  RefreshRates();
               case ERR_SERVER_BUSY:
               case ERR_NO_CONNECTION:
               case ERR_BROKER_BUSY:
               case ERR_TRADE_CONTEXT_BUSY:
               case ERR_TRADE_TIMEOUT:
                  i += 1;
                  break;
               default:
                  i = retryTimes;
                  break;
              }
           }
         else
            Success = true;
        }
      else
         break;
     }
   return(Success);
  }

//+-------------------------------------------------------------------------+
//| Exit Trade Function - Type: All Basket Hedge Ticket Pending             |
//+-------------------------------------------------------------------------+
int ExitTrades(int Type, color Color, string Reason, int OTicket = 0, string sym = "")
  {
   static int OTicketNo;
   bool Success;
   int Tries, Closed, CloseCount;
   int CloseTrades[, 2];
   double OPrice;
   string s;
   ca = Type;
   if(Type == T)
     {
      if(OTicket == 0)
         OTicket = OTicketNo;
      else
         OTicketNo = OTicket;
     }
   for(int y = OrdersTotal() - 1; y >= 0; y--)
     {
      if(!OrderSelect(y, SELECT_BY_POS, MODE_TRADES))
         continue;
      if(Type == B && OrderMagicNumber() != Magic)
         continue;
      else
         if(Type == H && OrderMagicNumber() != hMagic)
            continue;
         else
            if(Type == A && OrderMagicNumber() != Magic && OrderMagicNumber() != hMagic)
               continue;
            else
               if(Type == T && OrderTicket() != OTicket)
                  continue;
               else
                  if(Type == P && (OrderMagicNumber() != Magic || OrderType() <= OP_SELL))
                     continue;
      ArrayResize(CloseTrades, CloseCount + 1);
      CloseTrades[CloseCount, 0] = OrderOpenTime();
      CloseTrades[CloseCount, 1] = OrderTicket();
      CloseCount++;
     }
   if(CloseCount > 0)
     {
      if(!UseFIFO)
         ArraySort(CloseTrades, WHOLE_ARRAY, 0, MODE_DESCEND);
      else
         if(CloseCount != ArraySort(CloseTrades))
            Print("Error sorting CloseTrades Array");
      for(int y = 0; y < CloseCount; y++)
        {
         if(!OrderSelect(CloseTrades[y, 1], SELECT_BY_TICKET))
            continue;
         while(IsTradeContextBusy())
            Sleep(100);
         if(IsStopped())
            return(-1);
         if(OrderType() > OP_SELL)
            Success = OrderDelete(OrderTicket(), Color);
         else
           {
            if(OrderType() == OP_BUY)
               OPrice = ND(MarketInfo(OrderSymbol(), MODE_BID), MarketInfo(sym, MODE_DIGITS));
            else
               OPrice = ND(MarketInfo(OrderSymbol(), MODE_ASK), MarketInfo(sym, MODE_DIGITS));
            Success = OrderClose(OrderTicket(), OrderLots(), OPrice, slip, Color);
           }
         if(Success)
            Closed++;
         else
           {
            Error = GetLastError();
            Print("Order ", OrderTicket(), " failed to close. Error:", ErrorDescription(Error));
            switch(Error)
              {
               case ERR_NO_ERROR:
               case ERR_NO_RESULT:
                  Success = true;
                  break;
               case ERR_OFF_QUOTES:
               case ERR_INVALID_PRICE:
                  Sleep(5000);
               case ERR_PRICE_CHANGED:
               case ERR_REQUOTE:
                  RefreshRates();
               case ERR_SERVER_BUSY:
               case ERR_NO_CONNECTION:
               case ERR_BROKER_BUSY:
               case ERR_TRADE_CONTEXT_BUSY:
                  Print("Try: " + (Tries + 1) + " of 5: Order ", OrderTicket(), " failed to close. Error:", ErrorDescription(Error));
                  Tries++;
                  break;
               case ERR_TRADE_TIMEOUT:
               default:
                  Print("Try: " + (Tries + 1) + " of 5: Order ", OrderTicket(), " failed to close. Fatal Error:", ErrorDescription(Error));
                  Tries = 5;
                  ca = 0;
                  break;
              }
           }
        }
      if(Closed == CloseCount || Closed == 0)
         ca = 0;
     }
   else
      ca = 0;
   if(Closed > 0)
     {
      if(Closed != 1)
         s = "s";
      Print("Closed " + Closed + " position" + s + " because ", Reason);
      if(PlaySounds)
         PlaySound(AlertSound);
     }
   return(Closed);
  }

//+-----------------------------------------------------------------+
//| Find Hedge Profit                                               |
//+-----------------------------------------------------------------+
double FindClosedPL(int Type)
  {
   double ClosedProfit;
   if(Type == B && UseCloseOldest)
      CbC = 0;
   if(OTbF > 0)
     {
      for(int y = OrdersHistoryTotal() - 1; y >= 0; y--)
        {
         if(!OrderSelect(y, SELECT_BY_POS, MODE_HISTORY))
            continue;
         if(OrderOpenTime() < OTbF)
            continue;
         if(Type == B && OrderMagicNumber() == Magic && OrderType() <= OP_SELL)
           {
            ClosedProfit += OrderProfit() + OrderSwap() + OrderCommission();
            if(UseCloseOldest)
               CbC++;
           }
         if(Type == H && OrderMagicNumber() == hMagic)
            ClosedProfit += OrderProfit() + OrderSwap() + OrderCommission();
        }
     }
   return(ClosedProfit);
  }

//+-----------------------------------------------------------------+
//| Check Correlation                                               |
//+-----------------------------------------------------------------+
double CheckCorr(string sym)
  {
   double BaseDiff, HedgeDiff, BasePow, HedgePow, Mult;
   for(int y = CorrPeriod - 1; y >= 0; y--)
     {
      BaseDiff = iClose(sym, 1440, y) - iMA(sym, 1440, CorrPeriod, 0, MODE_SMA, PRICE_CLOSE, y);
      HedgeDiff = iClose(HedgeSymbol, 1440, y) - iMA(HedgeSymbol, 1440, CorrPeriod, 0, MODE_SMA, PRICE_CLOSE, y);
      Mult += BaseDiff * HedgeDiff;
      BasePow += MathPow(BaseDiff, 2);
      HedgePow += MathPow(HedgeDiff, 2);
     }
   if(BasePow * HedgePow > 0)
      return(Mult / MathSqrt(BasePow * HedgePow));
   else
      return(0);
  }
string TradeComment = "";
//+------------------------------------------------------------------+
//|  Save Equity / Balance Statistics                                |
//+------------------------------------------------------------------+
void Stats(bool NewFile, bool IsTick, double Balance, double DrawDown)
  {
   double Equity = Balance + DrawDown;
   datetime TimeNow = TimeCurrent();
   if(IsTick)
     {
      if(Equity < StatLowEquity)
         StatLowEquity = Equity;
      if(Equity > StatHighEquity)
         StatHighEquity = Equity;
     }
   else
     {
      while(TimeNow >= NextStats)
         NextStats += StatsPeriod;
      int StatHandle;
      if(NewFile)
        {
         StatHandle = FileOpen(StatFile, FILE_WRITE | FILE_CSV, ',');
         Print("Stats " + StatFile + " " + StatHandle);
         FileWrite(StatHandle, "Date", "Time", "Balance", "Equity Low", "Equity High", TradeComment);
        }
      else
        {
         StatHandle = FileOpen(StatFile, FILE_READ | FILE_WRITE | FILE_CSV, ',');
         FileSeek(StatHandle, 0, SEEK_END);
        }
      if(StatLowEquity == 0)
        {
         StatLowEquity = Equity;
         StatHighEquity = Equity;
        }
      FileWrite(StatHandle, TimeToStr(TimeNow, TIME_DATE), TimeToStr(TimeNow, TIME_SECONDS), DTS(Balance, 0), DTS(StatLowEquity, 0), DTS(StatHighEquity, 0));
      FileClose(StatHandle);
      StatLowEquity = Equity;
      StatHighEquity = Equity;
     }
  }

//+-----------------------------------------------------------------+
//| Magic Number Generator                                          |
//+-----------------------------------------------------------------+
int GenerateMagicNumber(string sym)
  {
   return(JenkinsHash(((int)(rand() % 12394)) + "_" + sym + "__" + Period()));
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int JenkinsHash(string Input)
  {
   int MagicNo;
   for(int y = 0; y < StringLen(Input); y++)
     {
      MagicNo += StringGetChar(Input, y);
      MagicNo += (MagicNo << 10);
      MagicNo ^= (MagicNo >> 6);
     }
   MagicNo += (MagicNo << 3);
   MagicNo ^= (MagicNo >> 11);
   MagicNo += (MagicNo << 15);
   MagicNo = MathAbs(MagicNo);
   
     
   return(MagicNo);
  }

//+-----------------------------------------------------------------+
//| Normalize Double                                                |
//+-----------------------------------------------------------------+
double ND(double Value, int Precision) {return(NormalizeDouble(Value, Precision));}

//+-----------------------------------------------------------------+
//| Double To String                                                |
//+-----------------------------------------------------------------+
string DTS(double Value, int Precision) {return(DoubleToStr(Value, Precision));}

//+-----------------------------------------------------------------+
//| Create Label Function (OBJ_LABEL ONLY)                          |
//+-----------------------------------------------------------------+
void CreateLabel(string Name, string Text, int FontSize, int Corner, int XOffset, double YLine, color Colour = CLR_NONE, string Font = "")
  {
   int XDistance, YDistance;
   if(Font == "")
      Font = displayFont;
   FontSize += displayFontSize;
   YDistance = displayYcord + displaySpacing * YLine;
   if(Corner == 0)
      XDistance = displayXcord + (XOffset * displayFontSize / 9 * displayRatio);
   else
      if(Corner == 1)
         XDistance = displayCCIxCord + XOffset * displayRatio;
      else
         if(Corner == 2)
            XDistance = displayXcord + (XOffset * displayFontSize / 9 * displayRatio);
         else
            if(Corner == 3)
              {
               XDistance = XOffset * displayRatio;
               YDistance = YLine;
              }
            else
               if(Corner == 5)
                 {
                  XDistance = XOffset * displayRatio;
                  YDistance = 14 * YLine;
                  Corner = 1;
                 }
   if(Colour == CLR_NONE)
      Colour = displayColor;
   ObjectCreate(Name, OBJ_LABEL, 0, 0, 0);
   ObjectSetText(Name, Text, FontSize, Font, Colour);
   ObjectSet(Name, OBJPROP_CORNER, Corner);
   ObjectSet(Name, OBJPROP_XDISTANCE, XDistance);
   ObjectSet(Name, OBJPROP_YDISTANCE, YDistance);
  }

//+-----------------------------------------------------------------+
//| Create Line Function (OBJ_HLINE ONLY)                           |
//+-----------------------------------------------------------------+
void CreateLine(string Name, color Colour, int Width, int Style)
  {
   ObjectCreate(Name, OBJ_HLINE, 0, 0, 0);
   ObjectSet(Name, OBJPROP_COLOR, Colour);
   ObjectSet(Name, OBJPROP_WIDTH, Width);
   ObjectSet(Name, OBJPROP_STYLE, Style);
  }

//+------------------------------------------------------------------+
//| Draw Label Function (OBJ_LABEL ONLY)                             |
//+------------------------------------------------------------------+
void DrawLabel(string Name, double Value, int XOffset, int Decimal = 2, color Colour = CLR_NONE)
  {
   int dDigits;
   dDigits = Digit[ArrayBsearch(Digit, Value, WHOLE_ARRAY, 0, MODE_ASCEND), 1];
   ObjectSet(Name, OBJPROP_XDISTANCE, displayXcord + (XOffset - 7 * dDigits)*displayFontSize / 9 * displayRatio);
   ObjSetTxt(Name, DTS(Value, Decimal), 0, Colour);
  }

//+-----------------------------------------------------------------+
//| Object Set Function                                             |
//+-----------------------------------------------------------------+
void ObjSet(string Name, int XCoord) {ObjectSet(Name, OBJPROP_XDISTANCE, displayXcord + XCoord * displayFontSize / 9 * displayRatio);}

//+-----------------------------------------------------------------+
//| Object Set Text Function                                        |
//+-----------------------------------------------------------------+
void ObjSetTxt(string Name, string Text, int FontSize = 0, color Colour = CLR_NONE, string Font = "")
  {
   FontSize += displayFontSize;
   if(Font == "")
      Font = displayFont;
   if(Colour == CLR_NONE)
      Colour = displayColor;
   ObjectSetText(Name, Text, FontSize, Font, Colour);
  }

//+------------------------------------------------------------------+
//| Delete Overlay Label Function                                    |
//+------------------------------------------------------------------+
void LabelDelete() {for(int y = ObjectsTotal(); y >= 0; y--) {if(StringSubstr(ObjectName(y), 0, 2) == "B3")ObjectDelete(ObjectName(y));}}

//+------------------------------------------------------------------+
//| Delete Object Function                                           |
//+------------------------------------------------------------------+
void ObjDel(string Name) {if(ObjectFind(Name) != -1)ObjectDelete(Name);}

//+-----------------------------------------------------------------+
//| Create Object List Function                                     |
//+-----------------------------------------------------------------+
void LabelCreate()
  {
   if(displayOverlay && ((Testing && Visual) || !Testing))
     {
      int dDigits;
      string ObjText;
      color ObjClr;
      CreateLabel("B3LMNum", "Magic: ", 5 - displayFontSize, 5, 59, 1, displayColorFGnd, "Tahoma");
      CreateLabel("B3VMNum", DTS(Magic, 0), 8 - displayFontSize, 5, 5, 1, displayColorFGnd, "Tahoma");
      CreateLabel("B3LComm",  TradeComment, 8 - displayFontSize, 5, 5, 1.8, displayColorFGnd, "Tahoma");
      if(displayLogo)
        {
         CreateLabel("B3LLogo", "Q", 27, 3, 10, 10, Crimson, "Wingdings");
         CreateLabel("B3LCopy", "© " + DTS(Year(), 0) + ",  Zones EA LLC", 10 - displayFontSize, 3, 5, 3, Silver, "Arial");
        }
      CreateLabel("B3LTime", "Broker Time is:", 0, 0, 0, 0);
      CreateLabel("B3VTime", TimeCurrent(), 0, 0, 125, 0);
      CreateLabel("B3Line1", "=========================", 0, 0, 0, 1);
      CreateLabel("B3LEPPC", "Equity Protection % Set:", 0, 0, 0, 2);
      dDigits = Digit[ArrayBsearch(Digit, MaxDDPercent, WHOLE_ARRAY, 0, MODE_ASCEND), 1];
      CreateLabel("B3VEPPC", DTS(MaxDDPercent, 2), 0, 0, 167 - 7 * dDigits, 2);
      CreateLabel("B3PEPPC", "%", 0, 0, 193, 2);
      CreateLabel("B3LSTPC", "Stop Trade % Set:", 0, 0, 0, 3);
      dDigits = Digit[ArrayBsearch(Digit, StopTradePercent * 100, WHOLE_ARRAY, 0, MODE_ASCEND), 1];
      CreateLabel("B3VSTPC", DTS(StopTradePercent * 100, 2), 0, 0, 167 - 7 * dDigits, 3);
      CreateLabel("B3PSTPC", "%", 0, 0, 193, 3);
      CreateLabel("B3LSTAm", "Stop Trade Amount:", 0, 0, 0, 4);
      CreateLabel("B3VSTAm", "", 0, 0, 167, 4, displayColorLoss);
      CreateLabel("B3LAPPC", "Account Portion:", 0, 0, 0, 5);
      dDigits = Digit[ArrayBsearch(Digit, PortionPC * 100, WHOLE_ARRAY, 0, MODE_ASCEND), 1];
      CreateLabel("B3VAPPC", DTS(PortionPC * 100, 2), 0, 0, 167 - 7 * dDigits, 5);
      CreateLabel("B3PAPPC", "%", 0, 0, 193, 5);
      CreateLabel("B3LPBal", "Portion Balance:", 0, 0, 0, 6);
      CreateLabel("B3VPBal", "", 0, 0, 167, 6);
      CreateLabel("B3LAPCR", "Account % Risked:", 0, 0, 228, 6);
      CreateLabel("B3VAPCR", DTS(MaxDDPercent * PortionPC, 2), 0, 0, 347, 6);
      CreateLabel("B3PAPCR", "%", 0, 0, 380, 6);
      if(UseMM)
        {
         ObjText = "Money Management is On";
         ObjClr = displayColorProfit;
        }
      else
        {
         ObjText = "Money Management is Off";
         ObjClr = displayColorLoss;
        }
      CreateLabel("B3LMMOO", ObjText, 0, 0, 0, 7, ObjClr);
      if(UsePowerOutSL)
        {
         ObjText = "Power Off Stop Loss is On";
         ObjClr = displayColorProfit;
        }
      else
        {
         ObjText = "Power Off Stop Loss is Off";
         ObjClr = displayColorLoss;
        }
      CreateLabel("B3LPOSL", ObjText, 0, 0, 0, 8, ObjClr);
      CreateLabel("B3LDrDn", "Draw Down %:", 0, 0, 228, 8);
      CreateLabel("B3VDrDn", "", 0, 0, 315, 8);
      if(UseHedge)
        {
         if(HedgeTypeDD)
           {
            CreateLabel("B3LhDDn", "Hedge", 0, 0, 190, 8);
            CreateLabel("B3ShDDn", "/", 0, 0, 342, 8);
            CreateLabel("B3VhDDm", "", 0, 0, 347, 8);
           }
         else
           {
            CreateLabel("B3LhLvl", "Hedge Level:", 0, 0, 228, 9);
            CreateLabel("B3VhLvl", "", 0, 0, 318, 9);
            CreateLabel("B3ShLvl", "/", 0, 0, 328, 9);
            CreateLabel("B3VhLvT", "", 0, 0, 333, 9);
           }
        }
      CreateLabel("B3Line2", "======================", 0, 0, 0, 9);
      CreateLabel("B3LSLot", "Starting Lot Size:", 0, 0, 0, 10);
      CreateLabel("B3VSLot", "", 0, 0, 130, 10);
      if(MaximizeProfit)
        {
         ObjText = "Profit Maximizer is On";
         ObjClr = displayColorProfit;
        }
      else
        {
         ObjText = "Profit Maximizer is Off";
         ObjClr = displayColorLoss;
        }
      CreateLabel("B3LPrMx", ObjText, 0, 0, 0, 11, ObjClr);
      CreateLabel("B3LBask", "Basket", 0, 0, 200, 11);
      CreateLabel("B3LPPot", "Profit Potential:", 0, 0, 30, 12);
      CreateLabel("B3VPPot", "", 0, 0, 190, 12);
      CreateLabel("B3LPrSL", "Profit Trailing Stop:", 0, 0, 30, 13);
      CreateLabel("B3VPrSL", "", 0, 0, 190, 13);
      CreateLabel("B3LPnPL", "Portion P/L / Pips:", 0, 0, 30, 14);
      CreateLabel("B3VPnPL", "", 0, 0, 190, 14);
      CreateLabel("B3SPnPL", "/", 0, 0, 220, 14);
      CreateLabel("B3VPPip", "", 0, 0, 229, 14);
      CreateLabel("B3LPLMM", "Profit/Loss Max/Min:", 0, 0, 30, 15);
      CreateLabel("B3VPLMx", "", 0, 0, 190, 15);
      CreateLabel("B3SPLMM", "/", 0, 0, 220, 15);
      CreateLabel("B3VPLMn", "", 0, 0, 225, 15);
      CreateLabel("B3LOpen", "Open Trades / Lots:", 0, 0, 30, 16);
      CreateLabel("B3LType", "", 0, 0, 170, 16);
      CreateLabel("B3VOpen", "", 0, 0, 207, 16);
      CreateLabel("B3SOpen", "/", 0, 0, 220, 16);
      CreateLabel("B3VLots", "", 0, 0, 229, 16);
      CreateLabel("B3LMvTP", "Move TP by:", 0, 0, 0, 17);
      CreateLabel("B3VMvTP", DTS(MoveTP / Pip, 0), 0, 0, 100, 17);
      CreateLabel("B3LMves", "# Moves:", 0, 0, 150, 17);
      CreateLabel("B3VMove", "", 0, 0, 229, 17);
      CreateLabel("B3SMves", "/", 0, 0, 242, 17);
      CreateLabel("B3VMves", DTS(TotalMoves, 0), 0, 0, 249, 17);
      CreateLabel("B3LMxDD", "Max DD:", 0, 0, 0, 18);
      CreateLabel("B3VMxDD", "", 0, 0, 107, 18);
      CreateLabel("B3LDDPC", "Max DD %:", 0, 0, 150, 18);
      CreateLabel("B3VDDPC", "", 0, 0, 229, 18);
      CreateLabel("B3PDDPC", "%", 0, 0, 257, 18);
      if(ForceMarketCond < 3)
         CreateLabel("B3LFMCn", "Market trend is forced", 0, 0, 0, 19);
      CreateLabel("B3LTrnd", "", 0, 0, 0, 20);
      if(CCIEntry > 0 && displayCCI)
        {
         CreateLabel("B3LCCIi", "CCI", 2, 1, 12, 1);
         CreateLabel("B3LCm05", "m5", 2, 1, 25, 2.2);
         CreateLabel("B3VCm05", "Ø", 6, 1, 0, 2, Orange, "Wingdings");
         CreateLabel("B3LCm15", "m15", 2, 1, 25, 3.4);
         CreateLabel("B3VCm15", "Ø", 6, 1, 0, 3.2, Orange, "Wingdings");
         CreateLabel("B3LCm30", "m30", 2, 1, 25, 4.6);
         CreateLabel("B3VCm30", "Ø", 6, 1, 0, 4.4, Orange, "Wingdings");
         CreateLabel("B3LCm60", "h1", 2, 1, 25, 5.8);
         CreateLabel("B3VCm60", "Ø", 6, 1, 0, 5.6, Orange, "Wingdings");
        }
      if(UseHolidayShutdown)
        {
         CreateLabel("B3LHols", "Next Holiday Period", 0, 0, 240, 2);
         CreateLabel("B3LHolD", "From: (yyyy.mm.dd) To:", 0, 0, 232, 3);
         CreateLabel("B3VHolF", "", 0, 0, 232, 4);
         CreateLabel("B3VHolT", "", 0, 0, 300, 4);
        }
     }
  }

const ushort us = ',';

 input int inpMaxOpenOrder =50;//MAX OPEN ORDER
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
        
   string data0[];
   int ind = StringSplit(symbolList, ',', data0);
   ArrayResize(data0, ind);
   int i = 0;//Control symbol selection
   if(useMulticurrencies)
     {
      i = 1;
     }
   else
     {
      i = ind;
      printf("size :" + i);
     }
   i = rand() % ind;
    if(i  <ind  )
    
     {
      //Calling secnd ea to for trade assistance
      start2(data0[i]);
      string sym = data0[i];
      newsTrade(sym);
      double  ask = MarketInfo(data0[i], MODE_ASK);
      double bid = MarketInfo(data0[i], MODE_BID);
      double digits = MarketInfo(data0[i], MODE_DIGITS);
      LotStep = MarketInfo(data0[i], MODE_LOW);
      printf("Symbol ++>" + data0[i]);
      double hAsk = MarketInfo(data0[i], MODE_ASK);
      double hBid = MarketInfo(data0[i], MODE_BID);
      double lot = MM_Size(data0[0]);
      int ticket = -1;
      double price = 0;
    
      myPoint = MarketInfo(data0[i], MODE_POINT);
      DeleteByDuration(PendingOrderExpirationMinutes * 60, data0[i]);
      DeleteByDistance(DeleteOrderAtDistance * myPoint, data0[i]);
      CloseTradesAtPL(CloseAtPL, sym);
      TrailingStopTrail(OP_BUY, 20 * myPoint, 50 * myPoint, true, 20 * myPoint, data0[i]); //Trailing Stop = trail
      TrailingStopTrail(OP_SELL, 20 * myPoint, 50 * myPoint, true, 20 * myPoint, data0[i]); //Trailing Stop = trail
      //Close Long Positions, instant signal is tested first
      if(Cross(1, Resistance(12 * PeriodSeconds(), false, 00, 00, true, 0) > iRVI(data0[i], PERIOD_CURRENT, 10, MODE_MAIN, 0)) //Resistance crosses above Relative Vigor Index
        )
        {
         if(IsTradeAllowed())
           {
            myOrderClose(OP_BUY, 100, "", sym);
         
           }
         else //not autotrading => only send alert
            myAlert("order", "", sym);
        }
      //Close Short Positions, instant signal is tested first
      if(Cross(0, Support(12 * PeriodSeconds(), false, 00, 00, true, 0) < iRVI(data0[i], PERIOD_CURRENT, 10, MODE_MAIN, 0)) //Support crosses below Relative Vigor Index
        )
        {
         if(IsTradeAllowed())
           {
            myOrderClose(OP_SELL, 100, "", sym);
           // bot.SendScreenShot(chatID, data0[i], PERIOD_CURRENT, inpTemplate);
           }
         else //not autotrading => only send alert
            myAlert("order", "", sym);
        }
      double TP = 0, SL = 0;
      //Open Buy Order, instant signal is tested first
      if(Cross(2, Low[6] > Support(12 * PeriodSeconds(), false, 00, 00, false, 0) && OrdersTotal()< inpMaxOpenOrder) //Candlestick Low crosses above Support
        )
        {
         RefreshRates();
         price = MarketInfo(data0[i], MODE_ASK);
         if(TimeCurrent() - LastOpenTime(sym) < NextOpenTradeAfterMinutes * 60)
            return ; //next open trade after time after previous trade's open
         if(!TradeDayOfWeek())
            return ; //open trades only on specific days of the week
         if(IsTradeAllowed())
           {
          //  bot.SendScreenShot(chatID, data0[i], PERIOD_CURRENT, inpTemplate);
            string msg = "OP_BUYLIMIT    " + data0[i] + "  price:" + (string)price  + "  lot:" + MM_Size(data0[0] + "SL :" + SL + " TP :" + TP);
            ticket = SendOrder(data0[i], OP_BUYLIMIT, lot, price, 2, MagicNumber, clrGreen);
            bot.SendMessage(chatID, msg);
            if(ticket <= 0)
               return ;
           }
         else //not autotrading => only send alert
            myAlert("order", "", sym);
        }
      //Open Sell Order, instant signal is tested first
      if(Cross(3, High[6] < Resistance(12 * PeriodSeconds(), false, 00, 00, false, 0)  && OrdersTotal()< inpMaxOpenOrder) //Candlestick High crosses below Resistance
        )
        {
         RefreshRates();
         price = MarketInfo(data0[i], MODE_BID);
         if(TimeCurrent() - LastOpenTime(data0[i]) < NextOpenTradeAfterMinutes * 60)
            return ; //next open trade after time after previous trade's open
         if(!TradeDayOfWeek())
            return ; //open trades only on specific days of the week
         if(IsTradeAllowed())
           {
            ticket = SendOrder(data0[i], OP_SELLLIMIT, lot, price, 2, MagicNumber, clrGreen);
            string msg = "OP_SELLLIMIT   " + data0[i] + "  price:" + (string)price  + "  lot:" + (string)MM_Size(data0[0] + "SL :" + SL + " TP :" + (string)TP);
            bot.SendMessage(chatID, msg);
      //    bot.SendScreenShot(chatID, data0[i], PERIOD_CURRENT, inpTemplate);
            if(ticket <= 0)
               return ;
           }
         else //not autotrading => only send alert
            myAlert("order", "", sym);
        }
      if(guaranteProfit == true)
        {
         double distance = price - OrderOpenPrice();
         double distancePercentage = distance * 100;
         if(distancePercentage == guaranteProfitPercentage)
           {
            if(OrderClose(OrderTicket(), OrderLots() / 2, price, (float)(OrderLots() / 2), clrGold))
              {
               bot.SendMessage(chatID, "Warranty profit reached!Closing 1/2 of current  trade profit due to change. price :" + (string)price);
               printf("Warranty profit reached!Closing 1/2 of current  trade profit due to change. price :" + (string) price);
              }
            else
              {
               Comment("Error order not closed");
               printf("Error order not closed");
              }
           }
        }
     }
   return ;
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+







//+------------------------------------------------------------------+
//| Expert initialization function      for zmq connector                              |
//+------------------------------------------------------------------+
void OnInit2() {

       // Set Millisecond Timer to get client socket input
   
   context.setBlocky(false);
   
   // Send responses to PULL_PORT that client is listening on.   
   if(!pushSocket.bind(StringFormat("%s://%s:%d", ZEROMQ_PROTOCOL, HOSTNAME, PULL_PORT))) {
      Print("[PUSH] ####ERROR#### Binding MT4 Server to Socket on Port " + IntegerToString(PULL_PORT) + "..");
      
   } else {
      Print("[PUSH] Binding MT4 Server to Socket on Port " + IntegerToString(PULL_PORT) + "..");
      pushSocket.setSendHighWaterMark(1);
      pushSocket.setLinger(0);
   }
   
   // Receive commands from PUSH_PORT that client is sending to.     
   if(!pullSocket.bind(StringFormat("%s://%s:%d", ZEROMQ_PROTOCOL, HOSTNAME, PUSH_PORT))) {
      Print("[PULL] ####ERROR#### Binding MT4 Server to Socket on Port " + IntegerToString(PUSH_PORT) + "..");
      
   } else {
      Print("[PULL] Binding MT4 Server to Socket on Port " + IntegerToString(PUSH_PORT) + "..");
      pullSocket.setReceiveHighWaterMark(1);   
      pullSocket.setLinger(0); 
   }
   
   // Send new market data to PUB_PORT that client is subscribed to.      
   if(!pubSocket.bind(StringFormat("%s://%s:%d", ZEROMQ_PROTOCOL, HOSTNAME, PUB_PORT))) {
      Print("[PUB] ####ERROR#### Binding MT4 Server to Socket on Port " + IntegerToString(PUB_PORT) + "..");
      
   } else {
      Print("[PUB] Binding MT4 Server to Socket on Port " + IntegerToString(PUB_PORT) + "..");
      pubSocket.setSendHighWaterMark(1);
      pubSocket.setLinger(0);
   }
  
}
//+------------------------------------------------------------------+
//| Expert deinitialization function        zmq connector                         |
//+------------------------------------------------------------------+
void OnDeinit2(const int reason) {

   Print("[PUSH] Unbinding MT4 Server from Socket on Port " + IntegerToString(PULL_PORT) + "..");
   pushSocket.unbind(StringFormat("%s://%s:%d", ZEROMQ_PROTOCOL, HOSTNAME, PULL_PORT));
   pushSocket.disconnect(StringFormat("%s://%s:%d", ZEROMQ_PROTOCOL, HOSTNAME, PULL_PORT));
   
   Print("[PULL] Unbinding MT4 Server from Socket on Port " + IntegerToString(PUSH_PORT) + "..");
   pullSocket.unbind(StringFormat("%s://%s:%d", ZEROMQ_PROTOCOL, HOSTNAME, PUSH_PORT));
   pullSocket.disconnect(StringFormat("%s://%s:%d", ZEROMQ_PROTOCOL, HOSTNAME, PUSH_PORT));
   
   if (Publish_MarketData == true || Publish_MarketRates == true) {
      Print("[PUB] Unbinding MT4 Server from Socket on Port " + IntegerToString(PUB_PORT) + "..");
      pubSocket.unbind(StringFormat("%s://%s:%d", ZEROMQ_PROTOCOL, HOSTNAME, PUB_PORT));
      pubSocket.disconnect(StringFormat("%s://%s:%d", ZEROMQ_PROTOCOL, HOSTNAME, PUB_PORT));
   }
   
   // Shutdown ZeroMQ Context
   context.shutdown();
   context.destroy(0);
   
}

//+------------------------------------------------------------------+
//| Expert tick function                                            |
//+------------------------------------------------------------------+
void OnTick2() {
   /*
      Use this OnTick() function to send market data to subscribed client.
   */
   lastUpdateMillis = GetTickCount();
                                  
   if(CheckServerStatus() == true) {
      // Python clients can subscribe to a price feed for each tracked symbol
      if(Publish_MarketData == true) {
       
        for(int s = 0; s < ArraySize(Publish_Symbols); s++) {
          
          string _tick = GetBidAsk(Publish_Symbols[s]);
          // only update if bid or ask changed. 
          if (StringCompare(Publish_Symbols_LastTick[s], _tick) == 0) continue;
          Publish_Symbols_LastTick[s] = _tick;
          // publish: topic=symbol msg=tick_data
          ZmqMsg reply(StringFormat("%s%s%s", Publish_Symbols[s], main_string_delimiter, _tick));
          Print("Sending PRICE [" + reply.getData() + "] to PUB Socket");
          if(!pubSocket.send(reply, true)) {
            Print("###ERROR### Sending price");
          }
        }
      }
      
      // Python clients can also subscribe to a rates feed for each tracked instrument
      if(Publish_MarketRates == true) {
        for(int s = 0; s < ArraySize(Publish_Instruments); s++) {
            MqlRates curr_rate[];
            int count = Publish_Instruments[s].GetRates(curr_rate, 1);
            // if last rate is returned and its timestamp is greater than the last published...
            if(count > 0 && curr_rate[0].time > Publish_Instruments[s].getLastPublishTimestamp()) {
                // then send a new pub message with this new rate
                string _rates = StringFormat("%u;%f;%f;%f;%f;%d;%d;%d", 
                                    curr_rate[0].time,
                                    curr_rate[0].open, 
                                    curr_rate[0].high, 
                                    curr_rate[0].low, 
                                    curr_rate[0].close, 
                                    curr_rate[0].tick_volume, 
                                    curr_rate[0].spread, 
                                    curr_rate[0].real_volume);
                ZmqMsg reply(StringFormat("%s%s%s", Publish_Instruments[s].name(), main_string_delimiter, _rates));
                Print("Sending Rates @"+TimeToStr(curr_rate[0].time) + " [" + reply.getData() + "] to PUB Socket");
                if(!pubSocket.send(reply, true)) {
                    Print("###ERROR### Sending rate");            
                }
                // updates the timestamp
                Publish_Instruments[s].setLastPublishTimestamp(curr_rate[0].time);
                
          }
        }
     }
   }
   
 
   
}

//+------------------------------------------------------------------+
//| Expert timer function              zmq connector                              |
//+------------------------------------------------------------------+
void OnTimer2() {

   /*
      Use this OnTimer() function to get and respond to commands
   */
   
   if(CheckServerStatus() == true) {
      // Get client's response, but don't block.
      pullSocket.recv(request, true);
      
      if (request.size() > 0) {
         // Wait 
         // pullSocket.recv(request,false);
         
         // MessageHandler() should go here.   
         ZmqMsg reply = MessageHandler(request);
         
         // Send response, and block
         // pushSocket.send(reply);
         
         // Send response, but don't block
         if(!pushSocket.send(reply, true)) {
           Print("###ERROR### Sending message");
         }
      }
      
      // update prices regularly in case there was no tick within X milliseconds (for non-chart symbols). 
      if (GetTickCount() >= lastUpdateMillis + MILLISECOND_TIMER_PRICES) OnTick2();
   }
}
//+------------------------------------------------------------------+

ZmqMsg MessageHandler(ZmqMsg &_request) {
   
   // Output object
   ZmqMsg reply;
   
   // Message components for later.
   string components[11];
   
   if(_request.size() > 0) {
   
      // Get data from request   
      ArrayResize(_data, _request.size());
      _request.getData(_data);
      string dataStr = CharArrayToString(_data);
      
      // Process data
      ParseZmqMessage(dataStr, components);
      
      // Interpret data
      InterpretZmqMessage(pushSocket, components);
      
   } else {
      // NO DATA RECEIVED
   }
   
   return(reply);
}

//+------------------------------------------------------------------+
// Interpret Zmq Message and perform actions
void InterpretZmqMessage(Socket &pSocket, string &compArray[]) {

   // Message Structures:
   
   // 1) Trading
   // TRADE|ACTION|TYPE|SYMBOL|PRICE|SL|TP|COMMENT|TICKET
   // e.g. TRADE|OPEN|1|EURUSD|0|50|50|R-to-MetaTrader4|12345678
   
   // The 12345678 at the end is the ticket ID, for MODIFY and CLOSE.
   
   // 2) Data Requests
   
   // 2.1) RATES|SYMBOL   -> Returns Current Bid/Ask
   
   // 2.2) DATA|SYMBOL|TIMEFRAME|START_DATETIME|END_DATETIME
   
   // 2.3) HIST|SYMBOL|TIMEFRAME|START_DATETIME|END_DATETIME
   
   // 3) Instruments configuration
   
   // 3.1) TRACK_PRICES|SYMBOL_1|SYMBOL_2|...|SYMBOL_N  -> List of symbols to receive real-time price updates (bid-ask)

   // 3.2) TRACK_RATES|INSTRUMENT_1|INSTRUMENT_2|...|INSTRUMENT_N  -> List of instruments to receive OHLC rates
           // Note: Instruments are bilt with format: SYMBOL_TIMEFRAME for example:
           //       Symbol: EURUSD, Timeframe: PERIOD_M1 ----> Instrument = "EURUSD_M1"          
           //       Symbol: GDAXI,  Timeframe: PERIOD_H4 ----> Instrument = "GDAXI_H4"
   
   // NOTE: datetime has format: D'2015.01.01 00:00'
   
   /*
      compArray[0] = TRADE, HIST, TRACK_PRICES, TRACK_RATES
      If HIST, TRACK_PRICES, TRACK_RATES -> compArray[1] = Symbol
      
      If TRADE ->
         compArray[0] = TRADE
         compArray[1] = ACTION (e.g. OPEN, MODIFY, CLOSE)
         compArray[2] = TYPE (e.g. OP_BUY, OP_SELL, etc - only used when ACTION=OPEN)
         
         // ORDER TYPES: 
         // https://docs.mql4.com/constants/tradingconstants/orderproperties
         
         // OP_BUY = 0
         // OP_SELL = 1
         // OP_BUYLIMIT = 2
         // OP_SELLLIMIT = 3
         // OP_BUYSTOP = 4
         // OP_SELLSTOP = 5
         
         compArray[3] = Symbol (e.g. EURUSD, etc.)
         compArray[4] = Open/Close Price (ignored if ACTION = MODIFY)
         compArray[5] = SL
         compArray[6] = TP
         compArray[7] = Trade Comment
         compArray[8] = Lots
         compArray[9] = Magic Number
         compArray[10] = Ticket Number (MODIFY/CLOSE)
   */
   
   int switch_action = 0;
   
   /* 02-08-2019 10:41 CEST - HEARTBEAT */
   if(compArray[0] == "HEARTBEAT")
      InformPullClient(pSocket, "{'_action': 'heartbeat', '_response': 'loud and clear!'}");
      
   /* Process Messages */
   if(compArray[0] == "TRADE" && compArray[1] == "OPEN")
      switch_action = 1;
   if(compArray[0] == "TRADE" && compArray[1] == "MODIFY")
      switch_action = 2;
   if(compArray[0] == "TRADE" && compArray[1] == "CLOSE")
      switch_action = 3;
   if(compArray[0] == "TRADE" && compArray[1] == "CLOSE_PARTIAL")
      switch_action = 4;
   if(compArray[0] == "TRADE" && compArray[1] == "CLOSE_MAGIC")
      switch_action = 5;
   if(compArray[0] == "TRADE" && compArray[1] == "CLOSE_ALL")
      switch_action = 6;
   if(compArray[0] == "TRADE" && compArray[1] == "GET_OPEN_TRADES")
      switch_action = 7;
   if(compArray[0] == "HIST")
      switch_action = 8;
   if(compArray[0] == "TRACK_PRICES")
      switch_action = 9;
   if(compArray[0] == "TRACK_RATES")
      switch_action = 10;
   if (compArray[0] == "TRADE" && compArray[1] == "GET_ACCOUNT_INFO")
      switch_action = 11;
   
   // IMPORTANT: when adding new functions, also increase the max switch_action in CheckOpsStatus()!
   
   /* Setup processing variables */
   string zmq_ret = "";
   string ret = "";
   int ticket = -1;
   bool ans = false;
   
   /****************************
    * PERFORM SOME CHECKS HERE *
    ****************************/
   if (CheckOpsStatus(pSocket, switch_action) == true) {
   
      switch(switch_action) {
         case 1: // OPEN TRADE
            
            zmq_ret = "{";
            
            // Function definition:
            ticket = DWX_OpenOrder(compArray[3], StrToInteger(compArray[2]), StrToDouble(compArray[8]), StrToDouble(compArray[4]), 
                                   StrToInteger(compArray[5]), StrToInteger(compArray[6]), compArray[7], StrToInteger(compArray[9]), zmq_ret);
                                    
            // Send TICKET back as JSON
            InformPullClient(pSocket, zmq_ret + "}");
            
            break;


         case 2: // MODIFY SL/TP
      
            zmq_ret = "{'_action': 'MODIFY'";
            
            // Function definition:
            ans = DWX_ModifyOrder(StrToInteger(compArray[10]), StrToDouble(compArray[4]), StrToDouble(compArray[5]), StrToDouble(compArray[6]), 3, zmq_ret);
            
            InformPullClient(pSocket, zmq_ret + "}");
            
            break;
         
         case 3: // CLOSE TRADE
      
            zmq_ret = "{";
            
            // IMPLEMENT CLOSE TRADE LOGIC HERE
            DWX_CloseOrder_Ticket(StrToInteger(compArray[10]), zmq_ret);
            
            InformPullClient(pSocket, zmq_ret + "}");
            
            break;
         
         case 4: // CLOSE PARTIAL
      
            zmq_ret = "{";
            
            ans = DWX_ClosePartial(StrToDouble(compArray[8]), zmq_ret, StrToInteger(compArray[10]), true);

            InformPullClient(pSocket, zmq_ret + "}");
            
            break;
         
         case 5: // CLOSE MAGIC
      
            zmq_ret = "{";
            
            DWX_CloseOrder_Magic(StrToInteger(compArray[9]), zmq_ret);
               
            InformPullClient(pSocket, zmq_ret + "}");
            
            break;
            
         case 6: // CLOSE ALL ORDERS
      
            zmq_ret = "{";
            
            DWX_CloseAllOrders(zmq_ret);
               
            InformPullClient(pSocket, zmq_ret + "}");
            
            break;
            
         case 7: // GET OPEN ORDERS
      
            zmq_ret = "{";
            
            DWX_GetOpenOrders(zmq_ret);
               
            InformPullClient(pSocket, zmq_ret + "}");
            
            break;
         
         case 8: // HIST REQUEST
         
            zmq_ret = "{";
            
            DWX_GetHist(compArray, zmq_ret);
            
            InformPullClient(pSocket, zmq_ret + "}");
            
            break;
           
         case 9: // SETUP LIST OF SYMBOLS TO TRACK PRICES
            
            zmq_ret = "{";
            
            DWX_SetSymbolList(compArray, zmq_ret);
            
            InformPullClient(pSocket, zmq_ret + "}");
            
            break;
              
         case 10: // SETUP LIST OF INSTRUMENTS TO TRACK RATES
            
            zmq_ret = "{";
            
            DWX_SetInstrumentList(compArray, zmq_ret);
            
            InformPullClient(pSocket, zmq_ret + "}");
            
            break;

         case 11: // GET ACCOUNT INFORMATION

            zmq_ret = "{";

            DWX_GetAccountInformation(compArray, zmq_ret);

            InformPullClient(pSocket, zmq_ret + "}");

            break;
        
         // if a case is added, also change max switch_action in CheckOpsStatus()!
            
         default: 
            break;
      }
   }
}

// Check if operations are permitted
bool CheckOpsStatus(Socket &pSocket, int switch_action) {

   if (switch_action >= 1 && switch_action <= 11) {
   
      if (!IsTradeAllowed()) {
         InformPullClient(pSocket, "{'_response': 'TRADING_IS_NOT_ALLOWED__ABORTED_COMMAND'}");
         return(false);
      }
      else if (!IsExpertEnabled()) {
         InformPullClient(pSocket, "{'_response': 'EA_IS_DISABLED__ABORTED_COMMAND'}");
         return(false);
      }
      else if (IsTradeContextBusy()) {
         InformPullClient(pSocket, "{'_response': 'TRADE_CONTEXT_BUSY__ABORTED_COMMAND'}");
         return(false);
      }
      else if (!IsDllsAllowed()) {
         InformPullClient(pSocket, "{'_response': 'DLLS_DISABLED__ABORTED_COMMAND'}");
         return(false);
      }
      else if (!IsLibrariesAllowed()) {
         InformPullClient(pSocket, "{'_response': 'LIBS_DISABLED__ABORTED_COMMAND'}"); 
         return(false);
      }
      else if (!IsConnected()) {
         InformPullClient(pSocket, "{'_response': 'NO_BROKER_CONNECTION__ABORTED_COMMAND'}");
         return(false);
      }
   }
   
   return(true);
}

// Parse Zmq Message
void ParseZmqMessage(string& message, string& retArray[]) {
   
   //Print("Parsing: " + message);
   
   string sep = ";";
   ushort u_sep = StringGetCharacter(sep,0);
   
   int splits = StringSplit(message, u_sep, retArray);
   
   /*
   for(int i = 0; i < splits; i++) {
      Print(IntegerToString(i) + ") " + retArray[i]);
   }
   */
}

//+------------------------------------------------------------------+
// Generate string for Bid/Ask by symbol
string GetBidAsk(string symbol) {
   
   MqlTick last_tick;
    
   if(SymbolInfoTick(symbol,last_tick)) {
       return(StringFormat("%f;%f", last_tick.bid, last_tick.ask));
   }
   
   // Default
   return "";
}

//+------------------------------------------------------------------+
// Get historic for request datetime range
void DWX_GetHist(string& compArray[], string& zmq_ret) {
         
   // Format: HIST|SYMBOL|TIMEFRAME|START_DATETIME|END_DATETIME
   
   string _symbol = compArray[1];
   ENUM_TIMEFRAMES _timeframe = (ENUM_TIMEFRAMES)StrToInteger(compArray[2]);
   
   MqlRates rates_array[];
      
   // Get prices
   int rates_count = 0;
   
   // Handling ERR_HISTORY_WILL_UPDATED (4066) and ERR_NO_HISTORY_DATA (4073) errors. 
   // For non-chart symbols and time frames MT4 often needs a few requests until the data is available. 
   // But even after 10 requests it can happen that it is not available. So it is best to have the charts open. 
   for (int i=0; i<10; i++) {
      rates_count = CopyRates(_symbol, 
                              _timeframe, StrToTime(compArray[3]),
                              StrToTime(compArray[4]), rates_array);
      int errorCode = GetLastError();
      // Print("errorCode: ", errorCode);
      if (rates_count > 0 || (errorCode != 4066 && errorCode != 4073)) break;
      Sleep(200);
   }
   
   zmq_ret = zmq_ret + "'_action': 'HIST', '_symbol': '" + _symbol+ "_" + GetTimeframeText(_timeframe) + "'";
               
   // if data then forms response as json:
   // {'_action: 'HIST', 
   //  '_data':[{'time': 'YYYY:MM:DD,HH:MM:SS', 'open':0.0, 'high':0.0, 'low':0.0, 'close':0.0, 'tick_volume:0, 'spread':0, 'real_volume':0},
   //           {...},
   //           ...  
   //          ]
   // }
   if (rates_count > 0) {
      
      zmq_ret = zmq_ret + ", '_data': [";
      
      // Construct string of rates and send to PULL client.
      for(int i = 0; i < rates_count; i++ ) {
         
         if(i == 0)
            zmq_ret = zmq_ret + "{'time':'" + TimeToString(rates_array[i].time) + "', 'open':" + DoubleToString(rates_array[i].open) + ", 'high':" + DoubleToString(rates_array[i].high) + ", 'low':" + DoubleToString(rates_array[i].low) + ", 'close':" + DoubleToString(rates_array[i].close) + ", 'tick_volume':" + IntegerToString(rates_array[i].tick_volume) + ", 'spread':" + IntegerToString(rates_array[i].spread)  + ", 'real_volume':" + IntegerToString(rates_array[i].real_volume) + "}";
         else
            zmq_ret = zmq_ret + ", {'time':'" + TimeToString(rates_array[i].time) + "', 'open':" + DoubleToString(rates_array[i].open) + ", 'high':" + DoubleToString(rates_array[i].high) + ", 'low':" + DoubleToString(rates_array[i].low) + ", 'close':" + DoubleToString(rates_array[i].close) + ", 'tick_volume':" + IntegerToString(rates_array[i].tick_volume) + ", 'spread':" + IntegerToString(rates_array[i].spread)  + ", 'real_volume':" + IntegerToString(rates_array[i].real_volume) + "}";
       
      }
      
      zmq_ret = zmq_ret + "]";
      
   }
   // if NO data then forms response as json:
   // {'_action: 'HIST', 
   //  '_response': 'NOT_AVAILABLE'
   // }
   else {
      zmq_ret = zmq_ret + ", " + "'_response': 'NOT_AVAILABLE'";
   }
}

//+------------------------------------------------------------------+
// Set list of symbols to get real-time price data
void DWX_SetSymbolList(string& compArray[], string& zmq_ret) {
    
   zmq_ret = zmq_ret + "'_action': 'TRACK_PRICES'";
   
   // Format: TRACK_PRICES|SYMBOL_1|SYMBOL_2|...|SYMBOL_N
   string result = "Tracking PRICES from";
   string errorSymbols = "";
   int _num_symbols = ArraySize(compArray) - 1;
   if(_num_symbols > 0) {
      for(int s=0; s<_num_symbols; s++) {
         if (SymbolSelect(compArray[s+1], true)) {
               ArrayResize(Publish_Symbols, s+1);
               ArrayResize(Publish_Symbols_LastTick, s+1);
               Publish_Symbols[s] = compArray[s+1];
               result += " " + Publish_Symbols[s];
            } else {
               errorSymbols += "'" + compArray[s+1] + "', ";
         }
      }
      if (StringLen(errorSymbols) > 0)
         errorSymbols = "[" + StringSubstr(errorSymbols, 0, StringLen(errorSymbols)-2) + "]";
      else
         errorSymbols = "[]";
      zmq_ret = zmq_ret + ", '_data': {'symbol_count':" + IntegerToString(_num_symbols) + ", 'error_symbols':" + errorSymbols + "}";
      Publish_MarketData = true;
   } else {
      Publish_MarketData = false;
      ArrayResize(Publish_Symbols, 1);
      ArrayResize(Publish_Symbols_LastTick, 1);
      zmq_ret = zmq_ret + ", '_data': {'symbol_count': 0}";
      result += " NONE";
   }
   Print(result);
}


//+------------------------------------------------------------------+
// Set list of instruments to get OHLC rates
void DWX_SetInstrumentList(string& compArray[], string& zmq_ret) {
   
   zmq_ret = zmq_ret + "'_action': 'TRACK_RATES'";
   
   // printArray(compArray);
   
   // Format: TRACK_RATES|SYMBOL_1|TIMEFRAME_1|SYMBOL_2|TIMEFRAME_2|...|SYMBOL_N|TIMEFRAME_N
   string result = "Tracking RATES from";
   string errorSymbols = "";
   int _num_instruments = (ArraySize(compArray) - 1)/2;
   if(_num_instruments > 0) {
      for(int s=0; s<_num_instruments; s++) {
         if (SymbolSelect(compArray[(2*s)+1], true)) {
            ArrayResize(Publish_Instruments, s+1);
            Publish_Instruments[s].setup(compArray[(2*s)+1], (ENUM_TIMEFRAMES)StrToInteger(compArray[(2*s)+2]));
            result += " " + Publish_Instruments[s].name();
         } else {
            errorSymbols += "'" + compArray[(2*s)+1] + "', ";
         }
      }
      if (StringLen(errorSymbols) > 0)
         errorSymbols = "[" + StringSubstr(errorSymbols, 0, StringLen(errorSymbols)-2) + "]";
      else
         errorSymbols = "[]";
      zmq_ret = zmq_ret + ", '_data': {'instrument_count':" + IntegerToString(_num_instruments) + ", 'error_symbols':" + errorSymbols + "}";
      Publish_MarketRates = true;
   } else {
      Publish_MarketRates = false;
      ArrayResize(Publish_Instruments, 1);
      zmq_ret = zmq_ret + ", '_data': {'instrument_count': 0}";
      result += " NONE";
   }
   Print(result);
}

//+------------------------------------------------------------------+
// Get Current Account Information
void DWX_GetAccountInformation(string& compArray[], string& zmq_ret){
   zmq_ret += "'_action': 'GET_ACCOUNT_INFORMATION', 'account_number':" +IntegerToString(AccountNumber());
   zmq_ret += ", '_data': [{";
   zmq_ret += "'currenttime': '" + TimeToString(TimeCurrent()) + "'";
   zmq_ret += ", 'account_name':'" + string(AccountName()) + "'";
   zmq_ret += ", 'account_balance':" + DoubleToString(AccountBalance());
   zmq_ret += ", 'account_equity':" + DoubleToString(AccountEquity());
   zmq_ret += ", 'account_profit':" + DoubleToString(AccountProfit());
   zmq_ret += ", 'account_free_margin':" + DoubleToString(AccountFreeMargin());
   zmq_ret += ", 'account_leverage' :" + IntegerToString(AccountLeverage());
   zmq_ret += "}]";

   // Additional information available at: https://docs.mql4.com/account
}
//+------------------------------------------------------------------+
// Get Timeframe from text
string GetTimeframeText(ENUM_TIMEFRAMES tf) {
    // Standard timeframes
    switch(tf) {
        case PERIOD_M1:    return "M1";
        case PERIOD_M5:    return "M5";
        case PERIOD_M15:   return "M15";
        case PERIOD_M30:   return "M30";
        case PERIOD_H1:    return "H1";
        case PERIOD_H4:    return "H4";
        case PERIOD_D1:    return "D1";
        case PERIOD_W1:    return "W1";
        case PERIOD_MN1:   return "MN1";
        default:           return "UNKNOWN";
    }
}

// Inform Client
void InformPullClient(Socket& pSocket, string message) {

   ZmqMsg pushReply(message);
   
   pSocket.send(pushReply,true); // NON-BLOCKING
   
}

//+------------------------------------------------------------------+

// OPEN NEW ORDER
int DWX_OpenOrder(string _symbol, int _type, double _lots, double _price, double _SL, double _TP, string _comment, int _magic, string &zmq_ret) {
   
   int ticket, error;
   
   zmq_ret = zmq_ret + "'_action': 'EXECUTION'";
   
   if(_lots > MaximumLotSize) {
      zmq_ret = zmq_ret + ", " + "'_response': 'LOT_SIZE_ERROR', 'response_value': 'MAX_LOT_SIZE_EXCEEDED'";
      return(-1);
   }
   
   if(OrdersTotal() >= MaximumOrders) {
      zmq_ret = zmq_ret + ", " + "'_response': 'NUM_ORDERS_ERROR', 'response_value': 'MAX_NUMBER_OF_ORDERS_EXCEEDED'";
      return(-1);
   }
   
   if (_type == OP_BUY) 
      _price = MarketInfo(_symbol, MODE_ASK);
   else if (_type == OP_SELL) 
      _price = MarketInfo(_symbol, MODE_BID);

   
   double sl = 0.0;
   double tp = 0.0;
  
   if(!DMA_MODE) {
      int dir_flag = -1;
      
      if (_type == OP_BUY || _type == OP_BUYLIMIT || _type == OP_BUYSTOP)
         dir_flag = 1;
      
      double vpoint  = MarketInfo(_symbol, MODE_POINT);
      int    vdigits = (int)MarketInfo(_symbol, MODE_DIGITS);
      sl = NormalizeDouble(_price-_SL*dir_flag*vpoint, vdigits);
      tp = NormalizeDouble(_price+_TP*dir_flag*vpoint, vdigits);
   }
   
   if(_symbol == "NULL") _symbol = Symbol();
   ticket = OrderSend(_symbol, _type, _lots, _price, MaximumSlippage, sl, tp, _comment, _magic);
   if(ticket < 0) {
      // Failure
      error = GetLastError();
      zmq_ret = zmq_ret + ", " + "'_response': '" + IntegerToString(error) + "', 'response_value': '" + ErrorDescription(error) + "'";
      return(-1*error);
   }

   int tmpRet = OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES);
   
   zmq_ret = zmq_ret + ", '_symbol': '" + _symbol + "', '_magic': " + IntegerToString(_magic) + ", '_ticket': " + IntegerToString(OrderTicket()) + ", '_open_time': '" + TimeToStr(OrderOpenTime(),TIME_DATE|TIME_SECONDS) + "', '_open_price': " + DoubleToString(OrderOpenPrice());

   if(DMA_MODE) {
   
      int retries = 3;
      while(true) {
         retries--;
         if(retries < 0) return(0);
         
         if((_SL == 0 && _TP == 0) || (OrderStopLoss() == _SL && OrderTakeProfit() == _TP)) {
            return(ticket);
         }

         if(DWX_IsTradeAllowed(30, zmq_ret) == 1) {
            if(DWX_ModifyOrder(ticket, _price, _SL, _TP, retries, zmq_ret)) {
               return(ticket);
            }
            if(retries == 0) {
               zmq_ret = zmq_ret + ", '_response': 'ERROR_SETTING_SL_TP'";
               return(-11111);
            }
         }

         Sleep(MILLISECOND_TIMER);
      }

      zmq_ret = zmq_ret + ", '_response': 'ERROR_SETTING_SL_TP'";
      zmq_ret = zmq_ret + "}";
      return(-1);
   }

    // Send zmq_ret to Python Client
    zmq_ret = zmq_ret + "}";
    
   return(ticket);
}

//+------------------------------------------------------------------+
// SET SL/TP
bool DWX_ModifyOrder(int ticket, double _price, double _SL, double _TP, int retries, string &zmq_ret) {
   
   if (OrderSelect(ticket, SELECT_BY_TICKET) == true) {
      
      if (OrderType() == OP_BUY || OrderType() == OP_SELL || _price == 0.0) 
         _price = OrderOpenPrice();
      
      int dir_flag = -1;
      
      if (OrderType() == OP_BUY || OrderType() == OP_BUYLIMIT || OrderType() == OP_BUYSTOP)
         dir_flag = 1;
    
      double vpoint  = MarketInfo(OrderSymbol(), MODE_POINT);
      int    vdigits = (int)MarketInfo(OrderSymbol(), MODE_DIGITS);
      double mSL = NormalizeDouble(_price-_SL*dir_flag*vpoint, vdigits);
      double mTP = NormalizeDouble(_price+_TP*dir_flag*vpoint, vdigits);
      
      if(OrderModify(ticket, _price, mSL, mTP, 0, 0)) {
         zmq_ret = zmq_ret + ", '_sl': " + DoubleToString(mSL) + ", '_tp': " + DoubleToString(mTP);
         return(true);
      } else {
         int error = GetLastError();
         zmq_ret = zmq_ret + ", '_response': '" + IntegerToString(error) + "', '_response_value': '" + ErrorDescription(error) + "', '_sl_attempted': " + DoubleToString(mSL, vdigits) + ", '_tp_attempted': " + DoubleToString(mTP, vdigits);
   
         if(retries == 0) {
            RefreshRates();
            DWX_CloseAtMarket(-1, zmq_ret);
         }
         
         return(false);
      }
   } else {
      zmq_ret = zmq_ret + ", '_response': 'NOT_FOUND'";
   }
   
   return(false);
}

//+------------------------------------------------------------------+
// CLOSE AT MARKET
bool DWX_CloseAtMarket(double size, string &zmq_ret) {

   int error;

   int retries = 3;
   while(true) {
      retries--;
      if(retries < 0) return(false);

      if(DWX_IsTradeAllowed(30, zmq_ret) == 1) {
         if(DWX_ClosePartial(size, zmq_ret)) {
            // trade successfuly closed
            return(true);
         } else {
            error = GetLastError();
            zmq_ret = zmq_ret + ", '_response': '" + IntegerToString(error) + "', '_response_value': '" + ErrorDescription(error) + "'";
         }
      }

   }
   return(false);
}

//+------------------------------------------------------------------+
// CLOSE PARTIAL SIZE
bool DWX_ClosePartial(double size, string &zmq_ret, int ticket=0, bool externCall=false) {

   if(OrderType() != OP_BUY && OrderType() != OP_SELL) {
      return(true);
   }

   int error;
   bool close_ret = False;
   
   // If the function is called directly, setup init() JSON here and get OrderSelect.
   if(ticket != 0 || externCall) {
      zmq_ret = zmq_ret + "'_action': 'CLOSE', '_ticket': " + IntegerToString(ticket);
      
      if (OrderSelect(ticket, SELECT_BY_TICKET)) {
         zmq_ret = zmq_ret + ", '_response': 'CLOSE_PARTIAL'";
      } else {
         zmq_ret = zmq_ret + ", '_response': 'CLOSE_PARTIAL_FAILED'";
         return(false);
      }
   }
   
   RefreshRates();
   double priceCP = OrderClosePrice();
   
   if(size < 0.01 || size > OrderLots()) {
      size = OrderLots();
   }
   close_ret = OrderClose(OrderTicket(), size, priceCP, MaximumSlippage);
   
   if (close_ret == true) {
      zmq_ret = zmq_ret + ", '_close_price': " + DoubleToString(priceCP) + ", '_close_lots': " + DoubleToString(size);
   } else {
      error = GetLastError();
      zmq_ret = zmq_ret + ", '_response': '" + IntegerToString(error) + "', '_response_value': '" + ErrorDescription(error) + "'";
   }
      
   return(close_ret);
}

//+------------------------------------------------------------------+
// CLOSE ORDER (by Magic Number)
void DWX_CloseOrder_Magic(int _magic, string &zmq_ret) {

   bool found = false;

   zmq_ret = zmq_ret + "'_action': 'CLOSE_ALL_MAGIC'";
   zmq_ret = zmq_ret + ", '_magic': " + IntegerToString(_magic);
   
   zmq_ret = zmq_ret + ", '_responses': {";
   
   for(int i=OrdersTotal()-1; i >= 0; i--) {
      if (OrderSelect(i,SELECT_BY_POS)==true && OrderMagicNumber() == _magic) {
         found = true;
         
         zmq_ret = zmq_ret + IntegerToString(OrderTicket()) + ": {'_symbol':'" + OrderSymbol() + "'";
         
         if(OrderType() == OP_BUY || OrderType() == OP_SELL) {
            DWX_CloseAtMarket(-1, zmq_ret);
            zmq_ret = zmq_ret + ", '_response': 'CLOSE_MARKET'";
            
            if (i != 0)
               zmq_ret = zmq_ret + "}, ";
            else
               zmq_ret = zmq_ret + "}";
               
         } else {
            zmq_ret = zmq_ret + ", '_response': 'CLOSE_PENDING'";
            
            if (i != 0)
               zmq_ret = zmq_ret + "}, ";
            else
               zmq_ret = zmq_ret + "}";
               
            int tmpRet = OrderDelete(OrderTicket());
         }
      }
   }

   zmq_ret = zmq_ret + "}";
   
   if(found == false) {
      zmq_ret = zmq_ret + ", '_response': 'NOT_FOUND'";
   }
   else {
      zmq_ret = zmq_ret + ", '_response_value': 'SUCCESS'";
   }
}

//+------------------------------------------------------------------+
// CLOSE ORDER (by Ticket)
void DWX_CloseOrder_Ticket(int _ticket, string &zmq_ret) {

   bool found = false;

   zmq_ret = zmq_ret + "'_action': 'CLOSE', '_ticket': " + IntegerToString(_ticket);

   for(int i=0; i<OrdersTotal(); i++) {
      if (OrderSelect(i,SELECT_BY_POS)==true && OrderTicket() == _ticket) {
         found = true;

         if(OrderType() == OP_BUY || OrderType() == OP_SELL) {
            DWX_CloseAtMarket(-1, zmq_ret);
            zmq_ret = zmq_ret + ", '_response': 'CLOSE_MARKET'";
         } else {
            zmq_ret = zmq_ret + ", '_response': 'CLOSE_PENDING'";
            int tmpRet = OrderDelete(OrderTicket());
         }
      }
   }

   if(found == false) {
      zmq_ret = zmq_ret + ", '_response': 'NOT_FOUND'";
   }
   else {
      zmq_ret = zmq_ret + ", '_response_value': 'SUCCESS'";
   }
}

//+------------------------------------------------------------------+
// CLOSE ALL ORDERS
void DWX_CloseAllOrders(string &zmq_ret) {

   bool found = false;

   zmq_ret = zmq_ret + "'_action': 'CLOSE_ALL'";
   
   zmq_ret = zmq_ret + ", '_responses': {";
   
   for(int i=OrdersTotal()-1; i >= 0; i--) {
      if (OrderSelect(i,SELECT_BY_POS)==true) {
      
         found = true;
         
         zmq_ret = zmq_ret + IntegerToString(OrderTicket()) + ": {'_symbol':'" + OrderSymbol() + "', '_magic': " + IntegerToString(OrderMagicNumber());
         
         if(OrderType() == OP_BUY || OrderType() == OP_SELL) {
            DWX_CloseAtMarket(-1, zmq_ret);
            zmq_ret = zmq_ret + ", '_response': 'CLOSE_MARKET'";
            
            if (i != 0)
               zmq_ret = zmq_ret + "}, ";
            else
               zmq_ret = zmq_ret + "}";
               
         } else {
            zmq_ret = zmq_ret + ", '_response': 'CLOSE_PENDING'";
            
            if (i != 0)
               zmq_ret = zmq_ret + "}, ";
            else
               zmq_ret = zmq_ret + "}";
               
            int tmpRet = OrderDelete(OrderTicket());
         }
      }
   }

   zmq_ret = zmq_ret + "}";
   
   if(found == false) {
      zmq_ret = zmq_ret + ", '_response': 'NOT_FOUND'";
   }
   else {
      zmq_ret = zmq_ret + ", '_response_value': 'SUCCESS'";
   }
}

//+------------------------------------------------------------------+
// GET OPEN ORDERS
void DWX_GetOpenOrders(string &zmq_ret) {

   bool found = false;

   zmq_ret = zmq_ret + "'_action': 'OPEN_TRADES'";
   zmq_ret = zmq_ret + ", '_trades': {";
   
   for(int i=OrdersTotal()-1; i>=0; i--) {
      found = true;
      
      if (OrderSelect(i,SELECT_BY_POS)==true) {
      
         zmq_ret = zmq_ret + IntegerToString(OrderTicket()) + ": {";
         
         zmq_ret = zmq_ret + "'_magic': " + IntegerToString(OrderMagicNumber()) + ", '_symbol': '" + OrderSymbol() + "', '_lots': " + DoubleToString(OrderLots()) + ", '_type': " + IntegerToString(OrderType()) + ", '_open_price': " + DoubleToString(OrderOpenPrice()) + ", '_open_time': '" + TimeToStr(OrderOpenTime(),TIME_DATE|TIME_SECONDS) + "', '_SL': " + DoubleToString(OrderStopLoss()) + ", '_TP': " + DoubleToString(OrderTakeProfit()) + ", '_pnl': " + DoubleToString(OrderProfit()) + ", '_comment': '" + OrderComment() + "'";
         
         if (i != 0)
            zmq_ret = zmq_ret + "}, ";
         else
            zmq_ret = zmq_ret + "}";
      }
   }
   zmq_ret = zmq_ret + "}";

}

//+------------------------------------------------------------------+
// counts the number of orders with a given magic number. currently not used. 
int DWX_numOpenOrdersWithMagic(int _magic) {
   int n = 0;
   for(int i=OrdersTotal()-1; i >= 0; i--) {
      if (OrderSelect(i,SELECT_BY_POS)==true && OrderMagicNumber() == _magic) {
         n++;
      }
   }
   return n;
}

//+------------------------------------------------------------------+
// CHECK IF TRADE IS ALLOWED
int DWX_IsTradeAllowed(int MaxWaiting_sec, string &zmq_ret) {
    
    if(!IsTradeAllowed()) {
    
        int StartWaitingTime = (int)GetTickCount();
        zmq_ret = zmq_ret + ", " + "'_response': 'TRADE_CONTEXT_BUSY'";
        
        while(true) {
            
            if(IsStopped()) {
                zmq_ret = zmq_ret + ", " + "'_response_value': 'EA_STOPPED_BY_USER'";
                return(-1);
            }
            
            int diff = (int)(GetTickCount() - StartWaitingTime);
            if(diff > MaxWaiting_sec * 1000) {
                zmq_ret = zmq_ret + ", '_response': 'WAIT_LIMIT_EXCEEDED', '_response_value': " + IntegerToString(MaxWaiting_sec);
                return(-2);
            }
            // if the trade context has become free,
            if(IsTradeAllowed()) {
                zmq_ret = zmq_ret + ", '_response': 'TRADE_CONTEXT_NOW_FREE'";
                RefreshRates();
                return(1);
            }
            
          }
    } else {
        return(1);
    }
    return(1);
}

bool CheckServerStatus() {

   // Is _StopFlag == True, inform the client application
   if (IsStopped()) {
      InformPullClient(pullSocket, "{'_response': 'EA_IS_STOPPED'}");
      return(false);
   }
   
   // Default
   return(true);
}

string ErrorDescription(int error_code) {
   string error_string;
//----
   switch(error_code)
     {
      //---- codes returned from trade server
      case 0:
      case 1:   error_string="no error";                                                  break;
      case 2:   error_string="common error";                                              break;
      case 3:   error_string="invalid trade parameters";                                  break;
      case 4:   error_string="trade server is busy";                                      break;
      case 5:   error_string="old version of the client terminal";                        break;
      case 6:   error_string="no connection with trade server";                           break;
      case 7:   error_string="not enough rights";                                         break;
      case 8:   error_string="too frequent requests";                                     break;
      case 9:   error_string="malfunctional trade operation (never returned error)";      break;
      case 64:  error_string="account disabled";                                          break;
      case 65:  error_string="invalid account";                                           break;
      case 128: error_string="trade timeout";                                             break;
      case 129: error_string="invalid price";                                             break;
      case 130: error_string="invalid stops";                                             break;
      case 131: error_string="invalid trade volume";                                      break;
      case 132: error_string="market is closed";                                          break;
      case 133: error_string="trade is disabled";                                         break;
      case 134: error_string="not enough money";                                          break;
      case 135: error_string="price changed";                                             break;
      case 136: error_string="off quotes";                                                break;
      case 137: error_string="broker is busy (never returned error)";                     break;
      case 138: error_string="requote";                                                   break;
      case 139: error_string="order is locked";                                           break;
      case 140: error_string="long positions only allowed";                               break;
      case 141: error_string="too many requests";                                         break;
      case 145: error_string="modification denied because order too close to market";     break;
      case 146: error_string="trade context is busy";                                     break;
      case 147: error_string="expirations are denied by broker";                          break;
      case 148: error_string="amount of open and pending orders has reached the limit";   break;
      case 149: error_string="hedging is prohibited";                                     break;
      case 150: error_string="prohibited by FIFO rules";                                  break;
      //---- mql4 errors
      case 4000: error_string="no error (never generated code)";                          break;
      case 4001: error_string="wrong function pointer";                                   break;
      case 4002: error_string="array index is out of range";                              break;
      case 4003: error_string="no memory for function call stack";                        break;
      case 4004: error_string="recursive stack overflow";                                 break;
      case 4005: error_string="not enough stack for parameter";                           break;
      case 4006: error_string="no memory for parameter string";                           break;
      case 4007: error_string="no memory for temp string";                                break;
      case 4008: error_string="not initialized string";                                   break;
      case 4009: error_string="not initialized string in array";                          break;
      case 4010: error_string="no memory for array\' string";                             break;
      case 4011: error_string="too long string";                                          break;
      case 4012: error_string="remainder from zero divide";                               break;
      case 4013: error_string="zero divide";                                              break;
      case 4014: error_string="unknown command";                                          break;
      case 4015: error_string="wrong jump (never generated error)";                       break;
      case 4016: error_string="not initialized array";                                    break;
      case 4017: error_string="dll calls are not allowed";                                break;
      case 4018: error_string="cannot load library";                                      break;
      case 4019: error_string="cannot call function";                                     break;
      case 4020: error_string="expert function calls are not allowed";                    break;
      case 4021: error_string="not enough memory for temp string returned from function"; break;
      case 4022: error_string="system is busy (never generated error)";                   break;
      case 4050: error_string="invalid function parameters count";                        break;
      case 4051: error_string="invalid function parameter value";                         break;
      case 4052: error_string="string function internal error";                           break;
      case 4053: error_string="some array error";                                         break;
      case 4054: error_string="incorrect series array using";                             break;
      case 4055: error_string="custom indicator error";                                   break;
      case 4056: error_string="arrays are incompatible";                                  break;
      case 4057: error_string="global variables processing error";                        break;
      case 4058: error_string="global variable not found";                                break;
      case 4059: error_string="function is not allowed in testing mode";                  break;
      case 4060: error_string="function is not confirmed";                                break;
      case 4061: error_string="send mail error";                                          break;
      case 4062: error_string="string parameter expected";                                break;
      case 4063: error_string="integer parameter expected";                               break;
      case 4064: error_string="double parameter expected";                                break;
      case 4065: error_string="array as parameter expected";                              break;
      case 4066: error_string="requested history data in update state";                   break;
      case 4099: error_string="end of file";                                              break;
      case 4100: error_string="some file error";                                          break;
      case 4101: error_string="wrong file name";                                          break;
      case 4102: error_string="too many opened files";                                    break;
      case 4103: error_string="cannot open file";                                         break;
      case 4104: error_string="incompatible access to a file";                            break;
      case 4105: error_string="no order selected";                                        break;
      case 4106: error_string="unknown symbol";                                           break;
      case 4107: error_string="invalid price parameter for trade function";               break;
      case 4108: error_string="invalid ticket";                                           break;
      case 4109: error_string="trade is not allowed in the expert properties";            break;
      case 4110: error_string="longs are not allowed in the expert properties";           break;
      case 4111: error_string="shorts are not allowed in the expert properties";          break;
      case 4200: error_string="object is already exist";                                  break;
      case 4201: error_string="unknown object property";                                  break;
      case 4202: error_string="object is not exist";                                      break;
      case 4203: error_string="unknown object type";                                      break;
      case 4204: error_string="no object name";                                           break;
      case 4205: error_string="object coordinates error";                                 break;
      case 4206: error_string="no specified subwindow";                                   break;
      default:   error_string="unknown error";
      }
   return(error_string);
}
  
//+------------------------------------------------------------------+

double DWX_GetAsk(string symbol) {
   if(symbol == "NULL") {
      return(Ask);
   } else {
      return(MarketInfo(symbol,MODE_ASK));
   }
}

//+------------------------------------------------------------------+

double DWX_GetBid(string symbol) {
   if(symbol == "NULL") {
      return(Bid);
   } else {
      return(MarketInfo(symbol,MODE_BID));
   }
}
//+------------------------------------------------------------------+

void printArray(string &arr[]) {
   if (ArraySize(arr) == 0) Print("{}");
   string printStr = "{";
   int i;
   for (i=0; i<ArraySize(arr); i++) {
      if (i == ArraySize(arr)-1) printStr += arr[i];
      else printStr += arr[i] + ", ";
   }
   Print(printStr + "}");
}

//+------------------------------------------------------------------+