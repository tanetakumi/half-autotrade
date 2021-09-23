//+------------------------------------------------------------------+
//|                                                HalfAutotrade.mq4 |
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
input int Slippage= 3;
input double Lots = 0.01;
input int tp_pips = 0;//利確pips
input int sl_pips = 20;//損切pips
input int max_position = 5;//最大ポジション数
//LINE通知に関する変数
input string line_token = "<token>";//LINEのアクセストークン


//ボタンに関する設定
input int set_position = 5;//ボタン設置位置(現在足から)

int digit = 0;
double pips = 0;
int timer = -1;//アローの位置アップデート
int timer2 = -1;//ボタンの削除
bool comment_delete = true;//コメントを削除すかどうか
string ltoken = "";//LINE token
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(){
   // DLL -------------
   if(!IsDllsAllowed()){
      Comment(
         "=================================\n"
         +"DLLの使用が許可されていません。\n"
         +"このEAを使用するときは「ツール->オプション->エキスパートアドバイザタブ」\n"
         +"よりDLLを使用するにチェックを入れてください。\n"
         +"EAはチャートから削除されました。\n"
         +"================================="
      );
      comment_delete = false;
      return 1;
   } else {
      Comment("");
   }
   // -----------------
   
   // token -----------
   ltoken = line_token;
   int filehandle = FileOpen("token.txt",FILE_WRITE | FILE_READ);
   if ( filehandle == INVALID_HANDLE ) { // ファイルオープンエラー
        printf( "[%d]ファイルオープンエラー：" , __LINE__  );
   } else {
      string str_input = FileReadString(filehandle,0);
      if(str_input!=NULL)ltoken = str_input;
   }
   FileClose(filehandle);
   // ----------------
   
   
   // pips -----------
   digit = (int)MarketInfo(Symbol(), MODE_DIGITS);
   double point=MarketInfo(Symbol(),MODE_POINT);
	if ( point==0.001 || point==0.00001 ) pips = point * 10;
	else pips = point;
	// ----------------
	
	// label ----------
   Label("HA_object_name","オブジェクト:",10,30);
   Label("HA_spread","Spread:",150,30,clrWhite,CORNER_RIGHT_UPPER);
   Label("HA_pips","Pips:",150,50,clrWhite,CORNER_RIGHT_UPPER);
   // button ---------
   Button("HA_screenshot","SS",70,90,60,20,clrDarkOrange,CORNER_RIGHT_LOWER,8);
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
         if(StringFind(ObjectName(i),"arw",0)>0)ObjectDelete(NULL,ObjectName(i));
      }
   }
   if(comment_delete)Comment("");
   EventKillTimer();//--- destroy timer
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){
   if(Bars<0)return;
   static bool initialized =false;
   if(!initialized){
      timer = 60;
      Refresh();
      initialized=true;   
   }
   
   static double pre_close = Close[0];
   
   for(int i=0;i<ObjectsTotal();i++){
      string obj_name = ObjectName(i);
      if(ObjectType(obj_name) == OBJ_ARROW && StringFind(obj_name,"_arw")>0){
         string str[];
         if(StringSplit(obj_name,'_',str)==2){
            if(ObjectFind(0,str[0])==0){
               int line_type = ObjectType(str[0]);                                  //元のオブジェクトのタイプ
               long arrow_code = ObjectGetInteger(0,obj_name,OBJPROP_ARROWCODE); //矢印のタイプ
               double price = 0;
               
               switch(line_type){
                  case OBJ_HLINE:
                     if(str[1] == "arw")price = ObjectGetDouble(0,str[0],OBJPROP_PRICE);
                     break;
                  case OBJ_TREND:
                     if(str[1] == "arw")price = ObjectGetValueByTime(0,str[0],Time[0]);
                     break;
                  case OBJ_CHANNEL:
                     if(str[1]=="arw0")price = ObjectGetValueByTime(0,str[0],Time[0],0);
                     else if(str[1]=="arw1")price = ObjectGetValueByTime(0,str[0],Time[0],1);
                     break;
                  case OBJ_RECTANGLE:
                     if(str[1]=="arw0")price = ObjectGetDouble(0,str[0],OBJPROP_PRICE,0);
                     else if(str[1]=="arw1")price = ObjectGetDouble(0,str[0],OBJPROP_PRICE,1);
                     break;
               }
               //======== エントリー　LINE送信 =========================
               if((pre_close-price)*(Close[0]-price) <= 0 ){
                  Print("Line Cross 　arrow code: ",arrow_code," OrdersTotal: ", OrdersTotal() );
                  switch((int)arrow_code){
                     case 241://買い
                        if(OdrBuy(Lots, Slippage, MAGIC, sl_pips, tp_pips, order_trial_num)){
                           LineNotify(ltoken,"\n通貨:"+Symbol()+"\n価格:"+DoubleToString(price,digit)+"\n買い注文成功",Symbol()+"ss.png");
                        } else {
                           LineNotify(ltoken,"\n通貨:"+Symbol()+"\n価格:"+DoubleToString(price,digit)+"\n買い注文失敗",Symbol()+"ss.png");
                        }
                        break;
                        
                     case 242://売り
                        if(OdrSell(Lots, Slippage, MAGIC, sl_pips, tp_pips, order_trial_num)){
                           LineNotify(ltoken,"\n通貨:"+Symbol()+"\n価格:"+DoubleToString(price,digit)+"\n売り注文成功",Symbol()+"ss.png");
                        } else {
                           LineNotify(ltoken,"\n通貨:"+Symbol()+"\n価格:"+DoubleToString(price,digit)+"\n売り注文失敗",Symbol()+"ss.png");
                        }
                        break;
                        
                     case 184://LINE通知
                        LineNotify(ltoken,"\n通貨:"+Symbol()+"\n価格:"+DoubleToString(price,digit),Symbol()+"ss.png");
                        break;
                        
                     case 222://買い Close
                        for(int j=0;j<OrdersTotal();j++){
                           if(OrderSelect(j,SELECT_BY_POS)){
                              if(OrderSymbol() == Symbol() && OrderMagicNumber() == MAGIC){
                                 if(OrderType() == OP_BUY){
                                    if(OdrClose(OrderTicket(),OrderLots(),OP_BUY,Slippage,order_trial_num)){
                                       LineNotify(ltoken,"\n通貨:"+Symbol()+"\n価格:"+DoubleToString(price,digit)+"\n買い注文決済成功",Symbol()+"ss.png");
                                    } else {
                                       LineNotify(ltoken,"\n通貨:"+Symbol()+"\n価格:"+DoubleToString(price,digit)+"\n買い注文決済失敗",Symbol()+"ss.png");
                                    }
                                 }
                              }
                           }
                        }
                        break;
                        
                     case 221://売り Close
                        for(int j=0;j<OrdersTotal();j++){
                           if(OrderSelect(j,SELECT_BY_POS)){
                              if(OrderSymbol() == Symbol() && OrderMagicNumber() == MAGIC){
                                 if(OrderType() == OP_SELL){
                                    if(OdrClose(OrderTicket(),OrderLots(),OP_SELL,Slippage,order_trial_num)){
                                       LineNotify(ltoken,"\n通貨:"+Symbol()+"\n価格:"+DoubleToString(price,digit)+"\n売り注文決済成功",Symbol()+"ss.png");
                                    } else {
                                       LineNotify(ltoken,"\n通貨:"+Symbol()+"\n価格:"+DoubleToString(price,digit)+"\n売り注文決済失敗",Symbol()+"ss.png");
                                    }
                                 }
                              }
                           }
                        }
                        break;
                        
                     case 219://すべて Close
                        for(int j=0;j<OrdersTotal();j++){
                           if(OrderSelect(j,SELECT_BY_POS)){
                              if(OrderSymbol() == Symbol() && OrderMagicNumber() == MAGIC){
                                 if(OdrClose(OrderTicket(),OrderLots(),OrderType(),Slippage,order_trial_num)){
                                    LineNotify(ltoken,"\n通貨:"+Symbol()+"\n価格:"+DoubleToString(price,digit)+"\n注文決済成功",Symbol()+"ss.png");
                                 } else {
                                    LineNotify(ltoken,"\n通貨:"+Symbol()+"\n価格:"+DoubleToString(price,digit)+"\n注文決済失敗",Symbol()+"ss.png");
                                 } 
                              }
                           }
                        }
                        break;
                  }
                  ObjectDelete(0,obj_name);//オブジェクト削除
               }
               //==================================================
            }
         }
      }
   }
   ObjectSetString(0,"HA_spread",OBJPROP_TEXT,"Spread:"+DoubleToString(MarketInfo(NULL, MODE_SPREAD)/MathPow(10,Digits()),Digits()));
   ObjectSetString(0,"HA_pips",OBJPROP_TEXT,"Pips:"+DoubleToString(pips,digit));
   
   pre_close=Close[0];
}

void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam){
   if(id == CHARTEVENT_OBJECT_CLICK){

      static string selected_object;//選択オブジェク
      int obj_type = ObjectType(sparam);//オブジェクトタイプ
      
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
            int selected_object_type = ObjectType(selected_object);
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
         // Close Buy Position
         else if(sparam == "ArrowChangeButton5"){
            ClickForArrowSet(selected_object,222);
         } 
         // Close Sell Position
         else if(sparam == "ArrowChangeButton6"){
            ClickForArrowSet(selected_object,221);
         } 
         // Close All Position
         else if(sparam == "ArrowChangeButton7"){
            ClickForArrowSet(selected_object,219);
         }
         else if(sparam == "HA_screenshot"){
            LineNotify(ltoken,"\n通貨:"+Symbol()+"\n価格:"+DoubleToString(Close[0],digit),Symbol()+"ss.png");
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
         Button("ArrowChangeButton5","CBuy",50,70,40,20,clrDarkOrange);
         Button("ArrowChangeButton6","CSell",90,70,40,20,clrDarkCyan);
         Button("ArrowChangeButton7","CAll",130,70,40,20,clrDarkMagenta); 
         timer2 = 20;
      }
      
      ObjectSetString(0,"HA_object_name",OBJPROP_TEXT,"オブジェクト:"+selected_object);
      
   }
   if(id == CHARTEVENT_OBJECT_DRAG){
      ButtonUpdate(sparam);
   }
   if(id == CHARTEVENT_OBJECT_CHANGE || id == CHARTEVENT_OBJECT_DELETE){
      Refresh();
   }
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
      for(int i=0;i<ObjectsTotal();i++){
         ButtonUpdate(ObjectName(i));
      }
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

void DelObjects(int type){
   for(int i=ObjectsTotal()-1;i>=0;i--){
      if(ObjectType(ObjectName(i))==type)ObjectDelete(0,ObjectName(i));
   }
}


void ClickForArrowSet(string selected_object,int arrow_code){
   datetime position_time = Time[0]+Period()*60*set_position;
   int object_type = ObjectType(selected_object);
   switch(object_type){
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
                  Arrow(selected_object+"_arw1",position_time,ObjectGetValueByTime(0,selected_object,position_time,1),arrow_code);
               }
            }
         }
         break;
      case OBJ_RECTANGLE:
         //0-1選択ボタン存在確認
         if(ObjectFind(0,"ArrowChangeButton0") == 0){
            if(ObjectGetString(0,"ArrowChangeButton0",OBJPROP_TEXT) == "0"){
               if(ObjectFind(0,selected_object+"_arw0") == 0){
                  ObjectSet(selected_object+"_arw0",OBJPROP_ARROWCODE,arrow_code);
               } else {
                  Arrow(selected_object+"_arw0",position_time,ObjectGetDouble(0,selected_object,OBJPROP_PRICE,0),arrow_code);
               }
            } else {
               if(ObjectFind(0,selected_object+"_arw1") == 0){
                  ObjectSet(selected_object+"_arw1",OBJPROP_ARROWCODE,arrow_code);
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
   for(int i=ObjectsTotal()-1;i>=0;i--){
      string obj_name = ObjectName(i);
      int string_posi = StringFind(obj_name,"_arw",0);
      if(string_posi>1){
         //ボタンに類するラインが存在しなかったら
         if(ObjectFind(0,StringSubstr(obj_name,0,string_posi))!=0){
            ObjectDelete(0,obj_name);
         }
      }
   }
   for(int i=0;i<ObjectsTotal();i++){
      ButtonUpdate(ObjectName(i));
   }
}

//--------------------------------------------------------------------
//drag -> move, create -> create, delete -> check and delete,create, change -> check and delete,create
void ButtonUpdate(string obj_name){
   datetime position_time = Time[0]+Period()*60*set_position;
   //存在確認はメインチャートにあるかどうかなので0を使用する。
   int obj_type = ObjectType(obj_name);
   switch(obj_type){
      case OBJ_HLINE:
         CheckArrow(obj_name+"_arw",1,ObjectGetDouble(0,obj_name,OBJPROP_PRICE),position_time);
         break;
      case OBJ_TREND:
         CheckArrow(obj_name+"_arw",ObjectGetValueByTime(0,obj_name,Time[0]),ObjectGetValueByTime(0,obj_name,position_time),position_time);
         break;
      case OBJ_CHANNEL:
         CheckArrow(obj_name+"_arw0",ObjectGetValueByTime(0,obj_name,Time[0],0),ObjectGetValueByTime(0,obj_name,position_time,0),position_time);
         CheckArrow(obj_name+"_arw1",ObjectGetValueByTime(0,obj_name,Time[0],1),ObjectGetValueByTime(0,obj_name,position_time,1),position_time);
         break;
      case OBJ_RECTANGLE:{
         //四角形の縦辺の間にあるか
         double flag = 0;
         if(ObjectGetInteger(0,obj_name,OBJPROP_TIME,0) <= Time[0] && Time[0] <= ObjectGetInteger(0,obj_name,OBJPROP_TIME,1))flag = 1;
         
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
      //現在のObjectの価格確認
      if(current_price>0){
         ObjectMove(0,arw_name,0,position_time,position_price);
      } else {
         ObjectDelete(0,arw_name);
      }
   }
}
//--------------------------------------------------------------------



//+------------------------------------------------------------------+
//| Order function                                                   |
//+------------------------------------------------------------------+
bool OdrBuy(double lots, int slipppage, int magic, int sl, int tp, int trial_num){
   //買い
   bool result = false;
   int ticket = -1;
   for(int count = 0; count < trial_num ; count ++ ) {
      ticket = OrderSend(Symbol(), OP_BUY, lots, Ask, slipppage, 0, 0, NULL, magic, 0, clrRed);
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
   if((tp !=0 || sl !=0) && ticket != -1){
      Sleep(300);
      result = OdrModify(ticket, sl, tp, trial_num);
   }
   return result;
}

bool OdrSell(double lots, int slipppage, int magic, int sl, int tp, int trial_num){
   //売り
   bool result = false;
   int ticket = -1;
   for(int count = 0; count < trial_num ; count ++ ) {
      ticket = OrderSend(Symbol(), OP_SELL, lots, Bid, slipppage, 0, 0, NULL, magic, 0, clrBlue);
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
   if((tp !=0 || sl !=0) && ticket != -1){
      Sleep(300);
      result = OdrModify(ticket, sl, tp, trial_num);
   }
   return result;
}

bool OdrModify(int ticket, int _sl, int _tp,  int trial_num){
   bool result = false;
   if(OrderSelect(ticket,SELECT_BY_TICKET)){
      double takeprofit = OrderTakeProfit();
      double stoploss = OrderStopLoss();
      
      if(OrderType()==OP_BUY){
         if(_tp != 0)takeprofit = OrderOpenPrice()+ _tp * pips;
         if(_sl != 0)stoploss = OrderOpenPrice() - _sl * pips; 
      } else if(OrderType()==OP_SELL){
         if(_tp != 0)takeprofit = OrderOpenPrice() - _tp * pips;
         if(_sl != 0)stoploss = OrderOpenPrice() + _sl * pips;
      }
      
      for(int count = 0; count < trial_num ; count ++ ) {
         if ( !OrderModify(OrderTicket(),OrderOpenPrice(), stoploss, takeprofit,0,clrNONE) ) { // ERROR
            Sleep(300);                         // 300msec待ち
            int errorcode = GetLastError();        // エラーコード取得
            printf( "%d回目：注文変更拒否。エラーコード:%d , 詳細:%s ",count+1, errorcode ,  ErrorDescription(errorcode));
         } else {                                 // 決済注文約定
            Print("注文変更完了。 チケットNo=", ticket);
            result = true;
            break;
         }
      }
   } else {
      Print("チケットの選択ができませんでした。チケットNo=", ticket);
   }
   return result;
}


bool OdrClose(int ticket, double lots, int cmd, int slippage, int trial_num){
   bool result = false;
   double close_price = -1;
   
   if(cmd == OP_BUY)close_price = Bid;
   else if(cmd == OP_SELL)close_price = Ask;
   else return false;
   
   for( int count = 0; count < trial_num; count ++ ) {
      if ( !OrderClose(ticket,lots,close_price,slippage,clrGreen) ){
         int errorcode = GetLastError();      // エラーコード取得
         printf("エラーコード:%d , 詳細:%s , 注文番号:%d", errorcode , ErrorDescription(errorcode),ticket);
         Sleep(1000);      // 1000msec待ち
         RefreshRates();   // レート更新
      } else {// 注文約定
         Print("OrderClose");
         result = true;
         break;
      }
   }
   return result;
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


#import "wininet.dll"
int InternetAttemptConnect(int x);
int InternetOpenW(string &sAgent,int lAccessType,string &sProxyName,string &sProxyBypass,int lFlags);
int InternetConnectW(int hInternet,string &lpszServerName,int nServerPort,string &lpszUsername,string &lpszPassword,int dwService,int dwFlags,int dwContext);
int HttpOpenRequestW(int hConnect,string &lpszVerb,string &lpszObjectName,string &lpszVersion,string lpszReferer,string &lplpszAcceptTypes[],uint dwFlags,int dwContext);
bool HttpSendRequestW(int hRequest,string &lpszHeaders,int dwHeadersLength,uchar &lpOptional[],int dwOptionalLength);
int HttpQueryInfoW(int hRequest,int dwInfoLevel,uchar &lpvBuffer[],int &lpdwBufferLength,int &lpdwIndex);
int InternetOpenUrlW(int hInternet,string &lpszUrl,string &lpszHeaders,int dwHeadersLength,int dwFlags,int dwContext);
int InternetReadFile(int hFile,uchar &sBuffer[],int lNumBytesToRead,int &lNumberOfBytesRead);
int InternetCloseHandle(int hInet);
#import

//To make it clear, we will use the constant names from wininet.h.
#define OPEN_TYPE_PRECONFIG        0        // use the configuration by default
#define INTERNET_SERVICE_HTTP      3        //HTTPサービス
#define HTTP_QUERY_CONTENT_LENGTH  5
#define DEFAULT_HTTPS_PORT         443

#define FLAG_KEEP_CONNECTION    0x00400000  // do not terminate the connection
#define FLAG_PRAGMA_NOCACHE     0x00000100  // no cashing of the page
#define FLAG_RELOAD             0x80000000  // receive the page from the server when accessing it
#define FLAG_SECURE             0x00800000  // use PCT/SSL if applicable (HTTP)
#define FLAG_NO_COOKIES         0x00080000  // no using cookies
#define FLAG_NO_CACHE_WRITE     0x04000000  // 

void LineNotify(string token,string message,string filename = NULL,int ss_x = 600, int ss_y = 400){
   if(token == "<token>" || token == ""){
      Print("LINE　トークンが設定されていません。 設定値: "+token);
      
   } else {
   
      string sep="-------Jyecslin9mp8RdKV";
      int res = 0;//length of data
      uchar data[];  // Data array to send POST requests
      
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
      Print(request("notify-api.line.me",DEFAULT_HTTPS_PORT,headers,"/api/notify",data));   
   }

}

/*
void DiscordNotify(string bot, string webhook,string message){
   string headers = "Content-Type: application/json\r\n";
   uchar post[];
   StringToCharArray("{\"username\":\""+bot+"\",\"content\":\""+message+"\"}", post, 0, WHOLE_ARRAY, CP_UTF8);
   Print(request("discordapp.com",DEFAULT_HTTPS_PORT,headers,StringSubstr(webhook,20),post));
}*/

string request(string host, int port, string headers, string object, uchar &post[]){
   //DLLの許可をOnInitにて確認する。
   if(host==""){
      return "Host is not specified";
   }
   string UserAgent = "Mozilla/5.0";
   string null    = "";
   string Vers    = "HTTP/1.1";
   string POST    = "POST";
   string accept[1] = {"*/*"};
   
   int session = InternetOpenW(UserAgent, 0, null, null, 0);
   if(session > 0){
      int connect = InternetConnectW(session, host, port, null, null, INTERNET_SERVICE_HTTP, 0, 0);
      if (connect > 0){
      //------------connection success------------------
         string result = "";
         int hRequest = HttpOpenRequestW(connect, POST, object, Vers, null, accept, FLAG_SECURE|FLAG_KEEP_CONNECTION|FLAG_RELOAD|FLAG_PRAGMA_NOCACHE|FLAG_NO_COOKIES|FLAG_NO_CACHE_WRITE, 0);
         if(hRequest > 0){
            bool hSend = HttpSendRequestW(hRequest, headers, StringLen(headers), post, ArraySize(post)-1);
            if(hSend){
               InternetCloseHandle(hSend);
               result += "POST data has been sent";
            } else {
               result += "HttpSendRequest error";
            }
            InternetCloseHandle(hRequest);
         } else {
            result +=  "HttpOpenRequest error";
         }
         InternetCloseHandle(connect);
         InternetCloseHandle(session);
         return result;
      //-----------------------------
      } else {
         InternetCloseHandle(session); 
         return "InternetConnect error. Connect:"+IntegerToString(connect);
      }
   } else{
      return "InternetOpen error";
   }
}

