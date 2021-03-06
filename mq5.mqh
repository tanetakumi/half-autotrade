//+------------------------------------------------------------------+
//|                                                          mq5.mqh |
//|                                            Copyright 2021, KoTA. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, KoTA."
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2010
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex5"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Order function                                                   |
//+------------------------------------------------------------------+
//takeprofit と　stoploss は値幅

bool OdrBuy(double lots, int slipppage, int magic, double sp_sl, double sp_tp, int trial_num){
   
   bool res = false;

   for(int count = 0; count < trial_num ; count ++ ) {
   
      MqlTradeRequest request={};
      MqlTradeResult  result={};
      
      request.action   =TRADE_ACTION_DEAL;                     // 取引操作タイプ
      request.symbol   =_Symbol;                               // シンボル
      request.volume   =lots;                                  // 0.1ロットのボリューム
      request.type     =ORDER_TYPE_BUY;                        // 注文タイプ
      request.price    =SymbolInfoDouble(_Symbol,SYMBOL_ASK);  // 発注価格
      request.deviation=slipppage;                             // 価格からの許容偏差
      request.magic    =magic;                                 //MAGICナンバー
      if(sp_sl!=0)request.sl = request.price - sp_sl;             //stoploss
      if(sp_tp!=0)request.tp = request.price + sp_tp;             //takeprofit
   
      
      if(OrderSend(request,result)){
         if ( result.order == 0){
            PrintFormat("retcode=%u  deal=%I64u  order=%I64u %s",result.retcode,result.deal,result.order,getRetcodeMessage(result.retcode));
            Sleep(1000);                                           // 1000msec待ち
         } else {    // 注文約定
            Print("新規注文約定。 チケットNo=",result.order);
            res = true;
            break;
         }
      } else {
         PrintFormat("OrderSend ERROR: %d",GetLastError());
      }
   }
   return res;
}

bool OdrSell(double lots, int slipppage, int magic, double sp_sl, double sp_tp, int trial_num){
   
   bool res = false;
   
   for(int count = 0; count < trial_num ; count ++ ) {
   
      MqlTradeRequest request={};
      MqlTradeResult  result={};
      
      request.action   =TRADE_ACTION_DEAL;                     // 取引操作タイプ
      request.symbol   =_Symbol;                               // シンボル
      request.volume   =lots;                                  // 0.1ロットのボリューム
      request.type     =ORDER_TYPE_SELL;                        // 注文タイプ
      request.price    =SymbolInfoDouble(_Symbol,SYMBOL_BID);  // 発注価格
      request.deviation=slipppage;                             // 価格からの許容偏差
      request.magic    =magic;                                 //MAGICナンバー
      if(sp_sl!=0)request.sl = request.price + sp_sl;             //stoploss
      if(sp_tp!=0)request.tp = request.price - sp_tp;             //takeprofit
   
      if(OrderSend(request,result)){
         if ( result.order == 0){
            PrintFormat("retcode=%u  deal=%I64u  order=%I64u %s",result.retcode,result.deal,result.order,getRetcodeMessage(result.retcode));
            Sleep(1000);// 1000msec待ち
         } else {    // 注文約定
            Print("新規注文約定。 チケットNo=",result.order);
            res = true;
            break;
         }
      } else {
         PrintFormat("OrderSend ERROR: %d",GetLastError());
      }
   }
   return res;
}

int getObjectsCount(){
   return ObjectsTotal(0);
}

double ReObjectGetValueByTime(long chart_id, const string object_name, datetime time, int line_id = 0){
   return ObjectGetValueByTime(chart_id,object_name,time,line_id);
}



string getRetcodeMessage(int retcode){
   string message = "";
   switch(retcode){
      
      case 10004:
      
         //TRADE_RETCODE_REQUOTE
      
         message = "リクオート。";
         break;
         
      case 10006:
      
         //TRADE_RETCODE_REJECT
      
         message = "リクエストの拒否。";
         break;
      
      case 10007:
      
         //TRADE_RETCODE_CANCEL
      
         message = "トレーダーによるリクエストのキャンセル。";
         break;
      
      case 10008:
      
         //TRADE_RETCODE_PLACED
      
         message = "注文が出されました。";
         break;
      
      case 10009:
      
         //TRADE_RETCODE_DONE
      
         message = "リクエスト完了。";
         break;
      
      case 10010:
      
         //TRADE_RETCODE_DONE_PARTIAL
      
         message = "リクエストが一部のみ完了。";
         break;
      
      case 10011:
      
         //TRADE_RETCODE_ERROR
      
         message = "リクエスト処理エラー。";
         break;
      
      case 10012:
      
         //TRADE_RETCODE_TIMEOUT
      
         message = "リクエストが時間切れでキャンセル。";
         break;
      
      case 10013:
      
         //TRADE_RETCODE_INVALID
      
         message = "無効なリクエスト。";
         break;
      
      case 10014:
      
         //TRADE_RETCODE_INVALID_VOLUME
      
         message = "リクエスト内の無効なボリューム。";
         break;
      
      case 10015:
      
         //TRADE_RETCODE_INVALID_PRICE
      
         message = "リクエスト内の無効な価格。";
         break;
      
      case 10016:
      
         //TRADE_RETCODE_INVALID_STOPS
      
         message = "リクエスト内の無効なストップ。";
         break;
      
      case 10017:
      
         //TRADE_RETCODE_TRADE_DISABLED
      
         message = "取引が無効化されています。";
         break;
      
      case 10018:
      
         //TRADE_RETCODE_MARKET_CLOSED
      
         message = "市場が閉鎖中。";
         break;
      
      case 10019:
      
         //TRADE_RETCODE_NO_MONEY
      
         message = "リクエストを完了するのに資金が不充分。";
         break;
      
      case 10020:
      
         //TRADE_RETCODE_PRICE_CHANGED
      
         message = "価格変更。";
         break;
      
      case 10021:
      
         //TRADE_RETCODE_PRICE_OFF
      
         message = "リクエスト処理に必要な相場が不在。";
         break;
      
      case 10022:
      
         //TRADE_RETCODE_INVALID_EXPIRATION
      
         message = "リクエスト内の無効な注文有効期限。";
         break;
      
      case 10023:
      
         //TRADE_RETCODE_ORDER_CHANGED
      
         message = "注文状態の変化。";
         break;
      
      case 10024:
      
         //TRADE_RETCODE_TOO_MANY_REQUESTS
      
         message = "頻繁過ぎるリクエスト。";
         break;
      
      case 10025:
      
         //TRADE_RETCODE_NO_CHANGES
      
         message = "リクエストに変更なし。";
         break;
      
      case 10026:
      
         //TRADE_RETCODE_SERVER_DISABLES_AT
      
         message = "サーバが自動取引を無効化。";
         break;
      
      case 10027:
      
         //TRADE_RETCODE_CLIENT_DISABLES_AT
      
         message = "クライアント端末が自動取引を無効化。";
         break;
      
      case 10028:
      
         //TRADE_RETCODE_LOCKED
      
         message = "リクエストが処理のためにロック中。";
         break;
      
      case 10029:
      
         //TRADE_RETCODE_FROZEN
      
         message = "注文やポジションが凍結。";
         break;
      
      case 10030:
      
         //TRADE_RETCODE_INVALID_FILL
      
         message = "無効な注文充填タイプ。";
         break;
         
      case 10031:
      
         //TRADE_RETCODE_CONNECTION
      
         message = "取引サーバに未接続。";
         break;
      
      case 10032:
      
         //TRADE_RETCODE_ONLY_REAL
      
         message = "操作は、ライブ口座のみで許可。";
         break;
      
      case 10033:
      
         //TRADE_RETCODE_LIMIT_ORDERS
      
         message = "未決注文の数が上限に達しました。";
         break;
      
      case 10034:
      
         //TRADE_RETCODE_LIMIT_VOLUME
      
         message = "シンボルの注文やポジションのボリュームが限界に達しました。";
         break;
      
      case 10035:
      
         //TRADE_RETCODE_INVALID_ORDER
      
         message = "不正または禁止された注文の種類。";
         break;
      
      case 10036:
      
         //TRADE_RETCODE_POSITION_CLOSED
      
         message = "指定されたPOSITION_IDENTIFIER を持つポジションがすでに閉鎖。";
         break;
      
      case 10038:
      
         //TRADE_RETCODE_INVALID_CLOSE_VOLUME
      
         message = "決済ボリュームが現在のポジションのボリュームを超過。";
         break;
      
      case 10039:
      
         //TRADE_RETCODE_CLOSE_ORDER_EXIST
      
         message = "指定されたポジションの決済注文が既存。これは、ヘッジシステムでの作業中に発生する可能性があります。";
         break;
      
      case 10040:
      
         //TRADE_RETCODE_LIMIT_POSITIONS
      
         message = "アカウントに同時に存在するポジションの数は、サーバー設定によって制限されます。 限度に達すると、サーバーは出された注文を処理するときにTRADE_RETCODE_LIMIT_POSITIONSエラーを返します。 これは、ポジション会計タイプによって異なる動作につながります。";
         break;
      
      case 10041:
      
         //TRADE_RETCODE_REJECT_CANCEL
      
         message = "未決注文アクティベーションリクエストは却下され、注文はキャンセルされます。";
         break;
      
      case 10042:
      
         //TRADE_RETCODE_LONG_ONLY
      
         message = "銘柄にOnly long positions are allowed（買いポジションのみ）のルールが設定されているため、リクエストは却下されます。";
         break;
      
      case 10043:
      
         //TRADE_RETCODE_SHORT_ONLY
      
         message = "銘柄にOnly short positions are allowed（売りポジションのみ）のルールが設定されているため、リクエストは却下されます。";
         break;
      
      case 10044:
      
         //TRADE_RETCODE_CLOSE_ONLY
      
         message = "銘柄にOnly position closing is allowed（ポジション決済のみ）のルールが設定されているため、リクエストは却下されます。";
         break;
      
      case 10045:
      
         //TRADE_RETCODE_FIFO_CLOSE
      
         message = "取引口座にPosition closing is allowed only by FIFO rule（FIFOによるポジション決済のみ）のフラグが設定されているため、リクエストは却下されます。";
         break;
      
      case 10046:
      
         //TRADE_RETCODE_HEDGE_PROHIBITED
      
         message = "口座で「単一の銘柄の反対のポジションは無効にする」ルールが設定されているため、リクエストが拒否されます。たとえば、銘柄に買いポジションがある場合、売りポジションを開いたり、売り指値注文を出すことはできません。このルールは口座がヘッジ勘定の場合 (ACCOUNT_MARGIN_MODE=ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)のみ適用されます。";
         break;
         
      default:
      
         message = "該当するretcodeが見つかりません。";
         break;
   }
   return message;
}