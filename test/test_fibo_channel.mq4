//+------------------------------------------------------------------+
//|                                                   KoTAexpert.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include <stdlib.mqh>
//EAのエントリーに関する変数
input int MAGIC = 573294;//マジックナンバー
input int order_trial_num = 5;//注文試行回数
input int Slippage= 3;//スリップページ
input double Lots = 0.01;//ロット数
input int tp_point = 0;//利確幅(point)
input int sl_point = 0;//損切幅(point)


//LINE通知に関する変数
input string line_token = "<token>";//LINEのアクセストークン
input int x_ss = 1280;//スクショ　横
input int y_ss = 800;//スクショ　縦


//ボタンに関する設定
input int set_position = 5;//ボタン設置位置(現在足から)

input bool log_show = false;//ログの表示

double spread_tp = 0;
double spread_sl = 0; 
int timer = -1;//アローの位置アップデート
int timer2 = -1;//ボタンの削除
bool comment_delete = true;//コメントを削除すかどうか
string ltoken = "";//LINE token
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(){


   // token -----------
   ltoken = line_token;
   int filehandle = FileOpen("token.txt",FILE_WRITE | FILE_READ | FILE_TXT | FILE_ANSI);
   if ( filehandle == INVALID_HANDLE ) { // ファイルオープンエラー
        printf( "[%d]ファイルオープンエラー：" , __LINE__  );
   } else {
      string str_input = FileReadString(filehandle,0);
      if(str_input!="")ltoken = str_input;
   }
   FileClose(filehandle);
   Print("トークン: "+ltoken);
   // ----------------
   
   spread_sl = sl_point/(1/_Point);
	spread_tp = tp_point/(1/_Point);
	
	
	if(spread_sl!=0)TrendHline("HA_stoploss_line",iTime(NULL,0,5),iClose(NULL,0,0)-spread_sl,iTime(NULL,0,0),iClose(NULL,0,0)-spread_sl,STYLE_SOLID,clrYellowGreen);
	if(spread_tp!=0)TrendHline("HA_takeprofit_line",iTime(NULL,0,5),iClose(NULL,0,0)+spread_tp,iTime(NULL,0,0),iClose(NULL,0,0)+spread_tp,STYLE_SOLID,clrOrangeRed);
	// label ----------
   Label("HA_object_name","オブジェクト:",10,30);
   if(AccountInfoInteger(ACCOUNT_TRADE_MODE)==ACCOUNT_TRADE_MODE_DEMO){
      Label("HA_demo","口座タイプ:　デモ",120,30,clrWhite,CORNER_RIGHT_UPPER,10);
   } else {
      Label("HA_demo","口座タイプ:　リアル",120,30,clrWhite,CORNER_RIGHT_UPPER,10);
   }
   
   Label("HA_spread","Spread:",120,50,clrWhite,CORNER_RIGHT_UPPER,10);
   
   Label("HA_token","Token:　"+StringSubstr(ltoken,0,6)+"...",120,70,clrWhite,CORNER_RIGHT_UPPER,10);
   Label("HA_minlots","最小ロット:　"+DoubleToString(SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN),2),120,90,clrWhite,CORNER_RIGHT_UPPER,10);
   Label("HA_inputlots","設定ロット:　"+DoubleToString(Lots,2),120,110,clrWhite,CORNER_RIGHT_UPPER,10);
   
   Label("HA_pips","Point:　"+DoubleToString(_Point,_Digits),120,130,clrWhite,CORNER_RIGHT_UPPER,10);
   Label("HA_stoploss","SL:　"+DoubleToString(spread_sl,_Digits),120,150,clrWhite,CORNER_RIGHT_UPPER,10);
   Label("HA_takeprofit","TP:　"+DoubleToString(spread_tp,_Digits),120,170,clrWhite,CORNER_RIGHT_UPPER,10);
   // button ---------
   Button("HA_screenshot","SS",70,90,60,20,clrDarkOrange,CORNER_RIGHT_LOWER,8);
   Button("HA_refresh","Refresh",140,90,60,20,clrDarkMagenta,CORNER_RIGHT_LOWER,8);
   Button("delete_hline","HLINE",140,60,60,20,clrDarkRed,CORNER_RIGHT_LOWER,8);
   Button("delete_channel","CHANNEL",70,60,60,20,clrDarkRed,CORNER_RIGHT_LOWER,8);
   Button("delete_trend","TREND",140,30,60,20,clrDarkRed,CORNER_RIGHT_LOWER,8);
   Button("delete_rectangle","RECTANG",70,30,60,20,clrDarkRed,CORNER_RIGHT_LOWER,8);
   // ----------------
   
   ChartSetInteger(0,CHART_EVENT_OBJECT_DELETE,true);
   EventSetTimer(1);
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason){
   ObjectsDeleteAll(0,"HA_");
   ObjectsDeleteAll(0,"delete_");
   ObjectsDeleteAll(0,"ArrowChangeButton");
   if(reason == REASON_REMOVE){
      for(int i=ObjectsTotal()-1;i>=0;i--){
         //ボタン削除
         if(StringFind(ObjectName(0,i),"arw",0)>0)ObjectDelete(0,ObjectName(0,i));
      }
   }
   if(comment_delete)Comment("");
   EventKillTimer();//--- destroy timer
   EventKillTimer();
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){

   if(Bars(_Symbol,_Period)<100)return;
   static bool initialized =false;
   if(!initialized){
      timer = 60;
      Refresh();
      initialized=true;   
   }
   
   static double pre_close = iClose(NULL,0,0);
   
   for(int i=0;i<ObjectsTotal();i++){
      string obj_name = ObjectName(0,i);
      if(ObjectGetInteger(0, obj_name, OBJPROP_TYPE) == OBJ_ARROW && StringFind(obj_name,"_arw")>0){
         string str[];
         if(StringSplit(obj_name,'_',str)==2){
            if(ObjectFind(0,str[0])==0){
               long line_type = ObjectGetInteger(0, str[0], OBJPROP_TYPE);        //元のオブジェクトのタイプ
               long arrow_code = ObjectGetInteger(0,obj_name,OBJPROP_ARROWCODE); //矢印のタイプ
               double price = 0;
               
               switch((int)line_type){
                  case OBJ_HLINE:
                     if(str[1] == "arw")price = ObjectGetDouble(0,str[0],OBJPROP_PRICE);
                     break;
                  case OBJ_TREND:
                     if(str[1] == "arw")price = ObjectGetValueByTime(0,str[0],iTime(NULL,0,0));
                     break;
                  case OBJ_CHANNEL:
                     if(str[1]=="arw0")price = ObjectGetValueByTime(0,str[0],iTime(NULL,0,0),0);
                     else if(str[1]=="arw1")price = ObjectGetValueByTime2(0,str[0],iTime(NULL,0,0));
                     break;
                  case OBJ_RECTANGLE:
                     if(str[1]=="arw0")price = ObjectGetDouble(0,str[0],OBJPROP_PRICE,0);
                     else if(str[1]=="arw1")price = ObjectGetDouble(0,str[0],OBJPROP_PRICE,1);
                     break;
               }
               //======== エントリー　LINE送信 =========================
               if((pre_close-price)*(iClose(NULL,0,0)-price) <= 0 ){
                  Print("ラインにクロスしました。" );
                  string message = "\n通貨:"+_Symbol+"\n価格:"+DoubleToString(price,_Digits);
                  switch((int)arrow_code){
                     case 241://買い
                        if(OdrBuy(Lots, Slippage, MAGIC, spread_sl, spread_tp, order_trial_num)){
                           message +="\n買い注文成功";
                        } else {
                           message += "\n買い注文失敗";
                        }
                        break;
                        
                     case 242://売り
                        if(OdrSell(Lots, Slippage, MAGIC, spread_sl, spread_tp, order_trial_num)){
                           message += "\n売り注文成功";
                        } else {
                           message += "\n売り注文失敗";
                        }
                        break;
                        
                     case 184://LINE通知
                        message += "\nLINE Alert";
                        break;
                        
                     default:
                        message += "\n矢印コードがありませんでした。";
                        break;
                  }
                  ObjectDelete(0,obj_name);//オブジェクト削除
                  LineNotify(ltoken,message,_Symbol+"ss.png",x_ss,y_ss);
               }
               //==================================================
            }
         }
      }
   }
   ObjectSetString(0,"HA_spread",OBJPROP_TEXT,"Spread:　"+DoubleToString(SymbolInfoInteger(_Symbol,SYMBOL_SPREAD)/(1/_Point),_Digits));
   if(spread_sl!=0){
      ObjectMove(0,"HA_stoploss_line",0,iTime(NULL,0,5),iClose(NULL,0,0)-spread_sl);
      ObjectMove(0,"HA_stoploss_line",1,iTime(NULL,0,0),iClose(NULL,0,0)-spread_sl);
   }
   if(spread_tp!=0){
      ObjectMove(0,"HA_takeprofit_line",0,iTime(NULL,0,5),iClose(NULL,0,0)+spread_tp);
      ObjectMove(0,"HA_takeprofit_line",1,iTime(NULL,0,0),iClose(NULL,0,0)+spread_tp);
   }
   ChartRedraw(0);
   pre_close=iClose(NULL,0,0);
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer(){
   //-------------------------------------------------------------------+
   //１分に１回ボタンの更新
   if(timer > 0){
      timer--;
   } else if(timer == 0){
      //something to do
      Refresh();
      timer = 60;
   }
   //-------------------------------------------------------------------+
   //Arrowセットボタンの時間削除
   if(timer2 > 0){
      timer2--;
   } else if(timer2 == 0){
      //something to do
      ObjectsDeleteAll(0,"ArrowChangeButton");
      ObjectSetString(0,"HA_object_name",OBJPROP_TEXT,"オブジェクト:");
      timer2 = -1;
   }
}

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam){
   if(id == CHARTEVENT_OBJECT_CLICK){
      static string selected_object;//選択オブジェク
      long obj_type = ObjectGetInteger(0, sparam, OBJPROP_TYPE);//オブジェクトタイプ
      
      if(obj_type == OBJ_BUTTON){
         if(sparam == "delete_hline"){
            DelObjects(OBJ_HLINE);
         } else if(sparam == "delete_channel"){
            DelObjects(OBJ_CHANNEL);
         } else if(sparam == "delete_trend"){
            DelObjects(OBJ_TREND);
         } else if(sparam == "delete_rectangle"){
            DelObjects(OBJ_RECTANGLE);
         } else if(sparam == "ArrowChangeButton0"){
            if(ObjectGetString(NULL,"ArrowChangeButton0",OBJPROP_TEXT) == "0"){
               ObjectSetString(NULL,"ArrowChangeButton0",OBJPROP_TEXT,"1");
            } else {
               ObjectSetString(NULL,"ArrowChangeButton0",OBJPROP_TEXT,"0");
            }
         } 
         // High Entry
         else if(sparam == "ArrowChangeButton1"){
            ClickForArrowSet(selected_object,241);
         } 
         // Low Entry
         else if(sparam == "ArrowChangeButton2"){
            ClickForArrowSet(selected_object,242);
         } 
         // Alert ボタン
         else if(sparam == "ArrowChangeButton3"){
            ClickForArrowSet(selected_object,184);
         }
         // Del ボタン
         else if(sparam == "ArrowChangeButton4"){
            long selected_object_type = ObjectGetInteger(0,selected_object,OBJPROP_TYPE);
            if(selected_object_type == OBJ_CHANNEL || selected_object_type == OBJ_RECTANGLE){
               //もし存在しなかったらエラー
               if(ObjectFind(0,"ArrowChangeButton0") != 0)return;
               if(ObjectGetString(0,"ArrowChangeButton0",OBJPROP_TEXT) == "0"){
                  ObjectDelete(0,selected_object+"_arw0");
               } else {
                  ObjectDelete(0,selected_object+"_arw1");
               }
            } else if(selected_object_type == OBJ_HLINE || selected_object_type == OBJ_TREND){
               ObjectDelete(0,selected_object+"_arw");
            }
         } 
         else if(sparam == "HA_screenshot"){
            Print(ltoken);
            LineNotify(ltoken,"\n通貨:"+Symbol()+"\n価格:"+DoubleToString(iClose(NULL,0,0),_Digits),Symbol()+"ss.png",x_ss,y_ss);
         }
         else if(sparam == "HA_refresh"){
            Print("Refreshボタンが押されました。");
            timer = 0;
         }
         Sleep(100);
         ObjectSetInteger(0,sparam,OBJPROP_STATE,false);      // オブジェクトの選択状態
         
      } else if(obj_type == OBJ_HLINE || obj_type == OBJ_TREND || obj_type == OBJ_CHANNEL || obj_type == OBJ_RECTANGLE){
         selected_object = sparam;
         ObjectsDeleteAll(0,"ArrowChangeButton");
         if(obj_type == OBJ_CHANNEL || obj_type == OBJ_RECTANGLE)Button("ArrowChangeButton0","0",30,50,20,20,clrDarkMagenta);
         Button("ArrowChangeButton1","Buy",50,50,40,20,clrDarkRed);
         Button("ArrowChangeButton2","Sell",90,50,40,20,clrDarkBlue);
         Button("ArrowChangeButton3","Alert",130,50,40,20,clrChocolate); 
         Button("ArrowChangeButton4","Del",170,50,40,20,clrDarkGray);
         timer2 = 20;
      }
      
      ObjectSetString(0,"HA_object_name",OBJPROP_TEXT,"オブジェクト:"+selected_object);
      
   }
   
   if(id == CHARTEVENT_OBJECT_DRAG){
      PrintFormat("オブジェクト位置が変更されました。: %s", sparam);
      ButtonUpdate(sparam);
   }
   
   if(id == CHARTEVENT_OBJECT_DELETE){
      PrintFormat("オブジェクトが削除されました。: %s", sparam);
      Refresh();
   }
   
   ChartRedraw(0);
} 
//+------------------------------------------------------------------+
//| Order function                                                   |
//+------------------------------------------------------------------+
bool OdrBuy(double lots, int slipppage, int magic, double sp_sl, double sp_tp, int trial_num){
   //買い
   bool result = false;
   int ticket = -1;
   double stoploss = 0, takeprofit = 0;
   
   for(int count = 0; count < trial_num ; count ++ ) {
      if(sp_sl != 0)stoploss = Ask - sp_sl;
      if(sp_tp != 0)takeprofit = Ask + sp_tp;
      ticket = OrderSend(Symbol(), OP_BUY, lots, Ask, slipppage, stoploss, takeprofit, NULL, magic, 0, clrRed);
      if ( ticket == -1 ){ //ERROR
         int errorcode = GetLastError();      // エラーコード取得
         printf("エラーコード:%d , 詳細:%s ", errorcode , ErrorDescription(errorcode));
         Sleep(1000);                                           // 1000msec待ち
         RefreshRates();                                        // レート更新
      } else {    // 注文約定
         Print("新規注文約定。 チケットNo=",ticket);
         result = true;
         break;
      }
   }
   return result;
}

bool OdrSell(double lots, int slipppage, int magic, double sp_sl, double sp_tp, int trial_num){
   //売り
   bool result = false;
   int ticket = -1;
   double stoploss = 0, takeprofit = 0;
   
   for(int count = 0; count < trial_num ; count ++ ) {
      if(sp_sl != 0)stoploss = Bid + sp_sl;
      if(sp_tp != 0)takeprofit = Bid - sp_tp;
      ticket = OrderSend(Symbol(), OP_SELL, lots, Bid, slipppage, stoploss, takeprofit, NULL, magic, 0, clrBlue);
      if ( ticket == -1 ){ //ERROR
         int errorcode = GetLastError();      // エラーコード取得
         printf("エラーコード:%d , 詳細:%s ", errorcode , ErrorDescription(errorcode));
         Sleep(1000);
         RefreshRates();
      } else {   // 注文約定
         Print("新規注文約定。 チケットNo=",ticket);
         result = true;
         break;
      }
   }
   return result;
}

void DelObjects(long type){
   for(int i=ObjectsTotal()-1;i>=0;i--){
      if(StringFind(ObjectName(0,i),"HA_")==-1){
         if(ObjectGetInteger(0, ObjectName(0,i), OBJPROP_TYPE)==type)ObjectDelete(0,ObjectName(0,i));
      }
   }
}

//クリックした時の矢印セット関数
void ClickForArrowSet(string selected_object,int arrow_code){
   datetime position_time = iTime(NULL,0,0)+Period()*60*set_position;
   long object_type = ObjectGetInteger(0, selected_object, OBJPROP_TYPE);
   
   switch((int)object_type){
      case OBJ_CHANNEL:
         //0-1選択ボタン存在確認
         if(ObjectFind(0,"ArrowChangeButton0") == 0){
            if(ObjectGetString(0,"ArrowChangeButton0",OBJPROP_TEXT) == "0"){
               if(ObjectFind(0,selected_object+"_arw0") == 0){
                  ObjectSetInteger(0,selected_object+"_arw0",OBJPROP_ARROWCODE,arrow_code);
               } else {
                  Arrow(selected_object+"_arw0",position_time,ObjectGetValueByTime(0,selected_object,position_time,0),arrow_code);
               }
            } else {
               if(ObjectFind(0,selected_object+"_arw1") == 0){
                  ObjectSetInteger(0,selected_object+"_arw1",OBJPROP_ARROWCODE,arrow_code);
               } else {
                  Arrow(selected_object+"_arw1",position_time,ObjectGetValueByTime2(0,selected_object,position_time),arrow_code);
               }
            }
         }
         break;
      case OBJ_RECTANGLE:
         //0-1選択ボタン存在確認
         if(ObjectFind(0,"ArrowChangeButton0") == 0){
            if(ObjectGetString(0,"ArrowChangeButton0",OBJPROP_TEXT) == "0"){
               if(ObjectFind(0,selected_object+"_arw0") == 0){
                  ObjectSetInteger(0,selected_object+"_arw0",OBJPROP_ARROWCODE,arrow_code);
               } else {
                  Arrow(selected_object+"_arw0",position_time,ObjectGetDouble(0,selected_object,OBJPROP_PRICE,0),arrow_code);
               }
            } else {
               if(ObjectFind(0,selected_object+"_arw1") == 0){
                  ObjectSetInteger(0,selected_object+"_arw1",OBJPROP_ARROWCODE,arrow_code);
               } else {
                  Arrow(selected_object+"_arw1",position_time,ObjectGetDouble(0,selected_object,OBJPROP_PRICE,1),arrow_code);
               }
            }
         }
          
         break;
      case OBJ_HLINE:
         if(ObjectFind(0,selected_object+"_arw") == 0){
            ObjectSetInteger(0,selected_object+"_arw",OBJPROP_ARROWCODE,arrow_code);
         } else {
            Arrow(selected_object+"_arw",position_time,ObjectGetDouble(0,selected_object,OBJPROP_PRICE),arrow_code);
         }
         break;
      case OBJ_TREND:
         if(ObjectFind(0,selected_object+"_arw") == 0){
            ObjectSetInteger(0,selected_object+"_arw",OBJPROP_ARROWCODE,arrow_code);
         } else {
            Arrow(selected_object+"_arw",position_time,ObjectGetValueByTime(0,selected_object,position_time),arrow_code);
         }
         break;
      default:
         break;
   }
}

void Refresh(){
   if(log_show)Print("Refresh");
   for(int i=ObjectsTotal()-1;i>=0;i--){
      string obj_name = ObjectName(0,i);
      int string_posi = StringFind(obj_name,"_arw",0);
      if(string_posi>1){
         //ボタンに類するラインが存在しなかったら
         if(ObjectFind(0,StringSubstr(obj_name,0,string_posi))!=0){
            ObjectDelete(0,obj_name);
         }
      }
   }
   for(int i=0;i<ObjectsTotal();i++){
      ButtonUpdate(ObjectName(0,i));
   }
}

void ButtonUpdate(string obj_name){
   datetime position_time = iTime(NULL,0,0)+Period()*60*set_position;
   //存在確認はメインチャートにあるかどうかなので0を使用する。
   long obj_type = ObjectGetInteger(0, obj_name, OBJPROP_TYPE);
   switch((int)obj_type){
      case OBJ_HLINE:
         CheckArrow(obj_name+"_arw",1,ObjectGetDouble(0,obj_name,OBJPROP_PRICE),position_time);
         break;
      case OBJ_TREND:
         CheckArrow(obj_name+"_arw",ObjectGetValueByTime(0,obj_name,iTime(NULL,0,0)),ObjectGetValueByTime(0,obj_name,position_time),position_time);
         break;
      case OBJ_CHANNEL:
         //PrintFormat("0: %.3f 1: %.3f 2: %.3f",ObjectGetValueByTime(0,obj_name,position_time,0),ObjectGetValueByTime(0,obj_name,position_time,1),ObjectGetValueByTime(0,obj_name,position_time,2));
         CheckArrow(obj_name+"_arw0",ObjectGetValueByTime(0,obj_name,iTime(NULL,0,0),0),ObjectGetValueByTime(0,obj_name,position_time,0),position_time);
         CheckArrow(obj_name+"_arw1",ObjectGetValueByTime2(0,obj_name,iTime(NULL,0,0)),ObjectGetValueByTime2(0,obj_name,position_time),position_time);
         break;
      case OBJ_RECTANGLE:{
         //四角形の縦辺の間にあるか
         double flag = 0;
         if(ObjectGetInteger(0,obj_name,OBJPROP_TIME,0) <= iTime(NULL,0,0) && iTime(NULL,0,0) <= ObjectGetInteger(0,obj_name,OBJPROP_TIME,1))flag = 1;
         
         CheckArrow(obj_name+"_arw0",flag,ObjectGetDouble(0,obj_name,OBJPROP_PRICE,0),position_time);
         CheckArrow(obj_name+"_arw1",flag,ObjectGetDouble(0,obj_name,OBJPROP_PRICE,1),position_time);
         break;}
      default:
         break;
   }
}

void CheckArrow(string arw_name, double current_price, double position_price, datetime position_time){
   //Arrowの存在確認
   if(ObjectFind(0,arw_name)==0){
      if(log_show)PrintFormat("矢印チェック NAME: %s   CURRENT: %.2f   POSISION: %.2f   TIME: %s",arw_name,current_price,position_price,TimeToString(position_time));
      //現在のObjectの価格確認
      if(current_price>0){
         ObjectMove(0,arw_name,0,position_time,position_price);
      } else {
         ObjectDelete(0,arw_name);
      }
   }
}




void TrendHline(string name, datetime time1, double price1, datetime time2,double price2, ENUM_LINE_STYLE style, color c=clrWhite){
   ObjectCreate(0,name,OBJ_TREND,0,time1,price1,time2,price2);
   ObjectSetInteger(0,name,OBJPROP_COLOR,c);    // 色設定
   ObjectSetInteger(0,name,OBJPROP_WIDTH,3);    // 幅設定
   ObjectSetInteger(0,name,OBJPROP_STYLE,style);    // 幅設定
   ObjectSetInteger(0,name,OBJPROP_BACK,true);  // オブジェクトの背景表示設定
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);     // オブジェクトの選択可否設定
   ObjectSetInteger(0,name,OBJPROP_SELECTED,false);      // オブジェクトの選択状態
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);         // オブジェクトリスト表示設定
   ObjectSetInteger(0,name,OBJPROP_ZORDER,0);     // オブジェクトのチャートクリックイベント優先順位
   ObjectSetInteger(0,name,OBJPROP_RAY_RIGHT,true);
}

void Hline(string name, double price, ENUM_LINE_STYLE style, color c=clrWhite){
   ObjectCreate(0,name,OBJ_HLINE,0,0,price);
   ObjectSetInteger(0,name,OBJPROP_COLOR,c);    // 色設定
   ObjectSetInteger(0,name,OBJPROP_WIDTH,3);    // 幅設定
   ObjectSetInteger(0,name,OBJPROP_STYLE,style);    // 幅設定
   ObjectSetInteger(0,name,OBJPROP_BACK,true);  // オブジェクトの背景表示設定
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);     // オブジェクトの選択可否設定
   ObjectSetInteger(0,name,OBJPROP_SELECTED,false);      // オブジェクトの選択状態
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);         // オブジェクトリスト表示設定
   ObjectSetInteger(0,name,OBJPROP_ZORDER,0);     // オブジェクトのチャートクリックイベント優先順位
}

void Arrow(string name, datetime time, double price,int arrow_code,int anchor=ANCHOR_BOTTOM, color c=clrWhite){
   ObjectCreate(0,name,OBJ_ARROW,0,time,price);
   ObjectSetInteger(0,name,OBJPROP_COLOR,c);    // 色設定
   ObjectSetInteger(0,name,OBJPROP_WIDTH,3);             // 幅設定
   ObjectSetInteger(0,name,OBJPROP_BACK,true);           // オブジェクトの背景表示設定
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);     // オブジェクトの選択可否設定
   ObjectSetInteger(0,name,OBJPROP_SELECTED,false);      // オブジェクトの選択状態
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);         // オブジェクトリスト表示設定
   ObjectSetInteger(0,name,OBJPROP_ZORDER,0);     // オブジェクトのチャートクリックイベント優先順位
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,anchor);   // アンカータイプ
   ObjectSetInteger(0,name,OBJPROP_ARROWCODE,arrow_code);      // アローコード
}

void Label(string name,string text, int x, int y,color c=clrWhite,int corner=CORNER_LEFT_UPPER,int font_size=12){
   ObjectCreate(0,name,OBJ_LABEL,0,0,0); 
   ObjectSetInteger(0,name,OBJPROP_COLOR,c);            // 色設定
   ObjectSetInteger(0,name,OBJPROP_BACK,false);          // オブジェクトの背景表示設定
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);   // オブジェクトの選択可否設定
   ObjectSetInteger(0,name,OBJPROP_SELECTED,false);     // オブジェクトの選択状態
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,false);       // オブジェクトリスト表示設定
   ObjectSetInteger(0,name,OBJPROP_ZORDER,0);           // オブジェクトのチャートクリックイベント優先順位
   ObjectSetString(0,name,OBJPROP_TEXT,text);           // 表示するテキスト
   ObjectSetString(0,name,OBJPROP_FONT,"ＭＳ　ゴシック");        // フォント
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,font_size); // フォントサイズ
   ObjectSetInteger(0,name,OBJPROP_CORNER,corner);      // コーナーアンカー設定
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);        // X座標
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);        // Y座標
}

void Button(string name,string text, int x ,int y,int x_size,int y_size ,color c=clrDarkBlue,int corner=CORNER_LEFT_UPPER,int font_size=10){
   ObjectCreate(0,name,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clrWhite);    // text色設定
   ObjectSetInteger(0,name,OBJPROP_BACK,false);            // オブジェクトの背景表示設定
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);     // オブジェクトの選択可否設定
   ObjectSetInteger(0,name,OBJPROP_SELECTED,false);      // オブジェクトの選択状態
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);         // オブジェクトリスト表示設定
   ObjectSetInteger(0,name,OBJPROP_ZORDER,0);            // オブジェクトのチャートクリックイベント優先順位
   ObjectSetString(0,name,OBJPROP_TEXT,text);            // 表示するテキスト
   ObjectSetString(0,name,OBJPROP_FONT,"ＭＳ　ゴシック");          // フォント
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,font_size);                   // フォントサイズ
   ObjectSetInteger(0,name,OBJPROP_CORNER,corner);  // コーナーアンカー設定
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);                // X座標
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);                 // Y座標
   ObjectSetInteger(0,name,OBJPROP_XSIZE,x_size);                    // ボタンサイズ幅
   ObjectSetInteger(0,name,OBJPROP_YSIZE,y_size);                     // ボタンサイズ高さ
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,c);              // ボタン色
   //ObjectSetInteger(0,name,OBJPROP_BORDER_COLOR,clrDarkRed);       // ボタン枠色
   ObjectSetInteger(0,name,OBJPROP_STATE,false);                  // ボタン押下状態
}


double ObjectGetValueByTime2(long chart_id, const string object_name, datetime time, int line_id = 1){
   if(ObjectGetInteger(chart_id, object_name, OBJPROP_TYPE)==OBJ_CHANNEL){
      double price0 = ObjectGetDouble(chart_id,object_name,OBJPROP_PRICE,0);
      long time0 = ObjectGetInteger(chart_id,object_name,OBJPROP_TIME,0);
      double price1 = ObjectGetDouble(chart_id,object_name,OBJPROP_PRICE,1);
      long time1 = ObjectGetInteger(chart_id,object_name,OBJPROP_TIME,1);
      double price2 = ObjectGetDouble(chart_id,object_name,OBJPROP_PRICE,2);
      long time2 = ObjectGetInteger(chart_id,object_name,OBJPROP_TIME,2);
      
      if(time0 - time1 == 0)return 0;
      double trend = (price1 - price0) / (double)(time0 - time1);
      
      return price2 + trend * (time2 - time);
   } else {
      return -1;
   }
}


void LineNotify(string token,string message,string filename = NULL,int ss_x = 1280, int ss_y = 720){
   if(token == "<token>" || token == ""){
      Print("LINE　トークンが設定されていません。 設定値: "+token);
      
   } else {
   
      string sep="-------Jyecslin9mp8RdKV";
      int res = 0;//length of data
      uchar data[], result[];  // Data array to send POST requests
      
      string headers = "Authorization: Bearer " + token + "\r\n";
      headers += "Content-Type: multipart/form-data; boundary="+sep+"\r\n";
      
      string str="--"+sep+"\r\n";
      str+="Content-Disposition: form-data; name=\"message\"\r\n\r\n";
      str+=message;
      
      if(filename!=NULL && filename!=""){
         bool ss_result = ChartScreenShot(0,filename,ss_x,ss_y,ALIGN_RIGHT);
         int filehandle=FileOpen(filename,FILE_READ|FILE_BIN);
         if (filehandle != INVALID_HANDLE && ss_result) {
            uchar   file[];  // Read the image here
            FileReadArray(filehandle,file);
            FileClose(filehandle);
            str+="\r\n--"+sep+"\r\n";
            str+="Content-Disposition: form-data; name=\"imageFile\"; filename=\""+filename+"\"\r\n";
            str+="Content-Type: image/png\r\n\r\n";
            res+=StringToCharArray(str,data,0,WHOLE_ARRAY,CP_UTF8);
            res+=ArrayCopy(data,file,res-1,0);
            
         } else {
            Print("File open failed, error ",GetLastError());
            return;
         }
      } else {
         res+=StringToCharArray(str,data,0,WHOLE_ARRAY,CP_UTF8);
      }
      
      res+=StringToCharArray("\r\n--"+sep+"--\r\n",data,res-1);
      ArrayResize(data,ArraySize(data)-1);
      int au = WebRequest("POST", "https://notify-api.line.me/api/notify", headers, 0, data, result, headers);
      PrintFormat("webrequest rsult: %d  LastError: %s  ErrorLine: %d",au,ErrorDescription(GetLastError()),__LINE__);
      if(au==-1){ 
         Print("Error in WebRequest. Error code  =",GetLastError());  
      }
   }
}
