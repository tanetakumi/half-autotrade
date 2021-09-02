//+------------------------------------------------------------------+
//|                                                HalfAutotrade.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

//EAのエントリーに関する変数
input int MAGIC = 573294;//マジックナンバー
input int order_trial_num = 5;//注文試行回数
input int Slippage= 3;
input double Lots = 0.01;
//LINE通知に関する変数
input bool line_notify = false;//ラインに通知をするか
input string line_token = "<token>";//LINEのアクセストークン


//ボタンに関する設定
input int set_position = 5;//ボタン設置位置(現在足から)


int timer = -1;//アローの位置アップデート
int timer2 = -1;//ボタンの削除
bool comment_delete = true;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(){
   if(!TerminalInfoInteger(TERMINAL_DLLS_ALLOWED)){
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
   
   
   Label("object_name","オブジェクト:",10,30);
   Button("delete_objects","OBJの削除",180,30,80,30,clrDarkRed,CORNER_RIGHT_LOWER,8);
   Button("delete_arrows","矢印の削除",90,30,80,30,clrDarkRed,CORNER_RIGHT_LOWER,8);
   ChartSetInteger(0,CHART_EVENT_OBJECT_DELETE,true);
   EventSetTimer(1);
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason){

   ObjectDelete(0,"object_name");
   ObjectDelete(0,"delete_objects");
   ObjectDelete(0,"delete_arrows");
   ObjectsDeleteAll(0,"ArrowChangeButton");
   if(reason == REASON_REMOVE){
      for(int i=ObjectsTotal(0)-1;i>=0;i--){
         //ボタン削除
         if(StringFind(ObjectName(0,i),"arw",0)>0)ObjectDelete(0,ObjectName(0,i));
      }
   }
   if(comment_delete)Comment("");
   EventKillTimer();//--- destroy timer
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){
   if(Bars(_Symbol,_Period)<=0)return;
   static bool initialized =false;
   if(!initialized){
      timer = 60;
      Refresh();
      initialized=true;   
   }
   
   static double pre_close = iClose(NULL,0,0);
   
   for(int i=0;i<ObjectsTotal(0);i++){
      string obj_name = ObjectName(0,i);
      if(ObjectGetInteger(0, obj_name, OBJPROP_TYPE) == OBJ_ARROW){
         if(StringFind(obj_name,"_arw")>0){
            string str[];
            if(StringSplit(obj_name,'_',str)==2){
               if(ObjectFind(0,str[0])!=0)return;//なければエラー
               long line_type = ObjectGetInteger(0, str[0], OBJPROP_TYPE);//LINE or TREND or CHANNEL
               long arrow_code = ObjectGetInteger(0,obj_name,OBJPROP_ARROWCODE);
               double price = 0;
               if(str[1] == "arw"){
                  if(line_type == OBJ_HLINE){
                     price = ObjectGetDouble(0,str[0],OBJPROP_PRICE);
                  } else if(line_type == OBJ_TREND){
                     price = ObjectGetValueByTime(0, str[0], iTime(NULL,0,0));
                  }
               } else if(str[1]=="arw0" && line_type == OBJ_CHANNEL){
                  price = ObjectGetValueByTime(0, str[0], iTime(NULL,0,0),0);
               } else if(str[1]=="arw1" && line_type == OBJ_CHANNEL){
                  price = ObjectGetValueByTime(0, str[0], iTime(NULL,0,0),1);
               }
               if((pre_close-price)*(iClose(NULL,0,0)-price) <= 0 ){
               
                  if(arrow_code == 241 || arrow_code == 242){
                     //--- リクエストと結果の宣言と初期化
                     MqlTradeRequest request={};
                     MqlTradeResult  result={};
                     if(arrow_code == 241){
                     
                        request.action   =TRADE_ACTION_DEAL;                     // 取引操作タイプ
                        request.symbol   =Symbol();                              // シンボル
                        request.volume   =Lots;                                  // 0.1ロットのボリューム
                        request.type     =ORDER_TYPE_BUY;                        // 注文タイプ
                        request.price    =SymbolInfoDouble(Symbol(),SYMBOL_ASK); // 発注価格
                        request.deviation=Slippage;                              // 価格からの許容偏差
                        request.magic    =MAGIC;
                     } else if(arrow_code == 242){
                     
                        request.action   =TRADE_ACTION_DEAL;                     // 取引操作タイプ
                        request.symbol   =Symbol();                              // シンボル
                        request.volume   =Lots;                                  // 0.1ロットのボリューム
                        request.type     =ORDER_TYPE_SELL;                        // 注文タイプ
                        request.price    =SymbolInfoDouble(Symbol(),SYMBOL_BID); // 発注価格
                        request.deviation=Slippage;                              // 価格からの許容偏差
                        request.magic    =MAGIC;
                     }
                     for(int count = 0; count < order_trial_num ; count ++ ) {
                        if ( OrderSend(request,result) ){
                           int errorcode = GetLastError();      // エラーコード取得
                           PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
                           Sleep(1000);                                           // 1000msec待ち
                           //RefreshRates();                                        // レート更新
                        } else {    // 注文約定
                           Print("新規注文約定。 チケットNo=",result.order);
                           break;
                        }
                     }
                  }
                  //LINE notify
                  if(line_notify)LineNotify(line_token,"\n通貨:"+Symbol()
                     +"\n価格:"+DoubleToString(price,3)
                     +"\n説明:"+ObjectGetString(0,obj_name,OBJPROP_TEXT)
                     +"\nRSI-15m:"+DoubleToString(iRSI(NULL,PERIOD_M15,14,PRICE_CLOSE),1)
                     +"\nRSI-1h:"+DoubleToString(iRSI(NULL,PERIOD_H1,14,PRICE_CLOSE),1)
                     +"\nRSI-4h:"+DoubleToString(iRSI(NULL,PERIOD_H4,14,PRICE_CLOSE),1)
                     ,Symbol()+"ss.png");
                  ObjectDelete(NULL,obj_name);//オブジェクト削除
                  Sleep(3000);//3秒間は通知をしない
                  break;
               }
            }
         }
      }
   }
   pre_close=iClose(NULL,0,0);
}


void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam){
   if(id == CHARTEVENT_OBJECT_CLICK){
      //position_time = Time[0]+Period()*60*5;
      static string selected_object;//選択オブジェクト

      long obj_type = ObjectGetInteger(0, sparam, OBJPROP_TYPE);
      if(obj_type == OBJ_BUTTON){
         if (sparam == "delete_objects"){
            for(int i=ObjectsTotal(0)-1;i>=0;i--){
               long del_type = ObjectGetInteger(0, ObjectName(0,i), OBJPROP_TYPE);
               if(del_type == OBJ_HLINE || del_type == OBJ_TREND || del_type == OBJ_CHANNEL)ObjectDelete(NULL,ObjectName(0,i));
            }
         } else if (sparam == "delete_arrows"){
            for(int i=ObjectsTotal(0)-1;i>=0;i--){
               long del_type = ObjectGetInteger(0, ObjectName(0,i), OBJPROP_TYPE);
               if(del_type == OBJ_ARROW)ObjectDelete(NULL,ObjectName(0,i));
            }
         } else if(sparam == "ArrowChangeButton0"){
            if(ObjectGetString(NULL,"ArrowChangeButton0",OBJPROP_TEXT) == "0"){
               ObjectSetString(NULL,"ArrowChangeButton0",OBJPROP_TEXT,"1");
            } else {
               ObjectSetString(NULL,"ArrowChangeButton0",OBJPROP_TEXT,"0");
            }
         } else if(sparam == "ArrowChangeButton1"){
            ClickForArrowSet(selected_object,241);
         } else if(sparam == "ArrowChangeButton2"){
            ClickForArrowSet(selected_object,242);
         } else if(sparam == "ArrowChangeButton3"){
            ClickForArrowSet(selected_object,184);
         } else if(sparam == "ArrowChangeButton4"){
            long selected_object_type = ObjectGetInteger(0, selected_object, OBJPROP_TYPE);
            if(selected_object_type == OBJ_CHANNEL){
               //もし存在しなかったらエラー
               if(ObjectFind(NULL,"ArrowChangeButton0") != 0)return;
               if(ObjectGetString(NULL,"ArrowChangeButton0",OBJPROP_TEXT) == "0"){
                  ObjectDelete(NULL,selected_object+"_arw0");
               } else {
                  ObjectDelete(NULL,selected_object+"_arw1");
               }
            } else if(selected_object_type == OBJ_HLINE || selected_object_type == OBJ_TREND){
               ObjectDelete(NULL,selected_object+"_arw");
            }
         }
         Sleep(100);
         ObjectSetInteger(NULL,sparam,OBJPROP_STATE,false);      // オブジェクトの選択状態
      } else if(obj_type == OBJ_HLINE || obj_type == OBJ_TREND || obj_type == OBJ_CHANNEL){
         selected_object = sparam;
         ObjectsDeleteAll(NULL,"ArrowChangeButton");
         if(obj_type == OBJ_CHANNEL)Button("ArrowChangeButton0","0",30,50,20,20,clrDarkMagenta);
         Button("ArrowChangeButton1","Up",50,50,40,20,clrDarkRed);
         Button("ArrowChangeButton2","Down",90,50,40,20,clrDarkBlue);
         Button("ArrowChangeButton3","Timer",130,50,40,20,clrChocolate); 
         Button("ArrowChangeButton4","Del",170,50,40,20,clrDarkGray); 
         timer2 = 20;
      }
      
      ObjectSetString(NULL,"object_name",OBJPROP_TEXT,"オブジェクト:"+selected_object);
      
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
   if(timer > 0){
      timer--;
   } else if(timer == 0){
      //something to do
      for(int i=0;i<ObjectsTotal(0);i++){
         ButtonUpdate(ObjectName(0,i));
      }
      timer = 60;
   }
   //-------------------------------------------------------------------+
   if(timer2 > 0){
      timer2--;
   } else if(timer2 == 0){
      //something to do
      ObjectsDeleteAll(NULL,"ArrowChangeButton");
      ObjectSetString(NULL,"object_name",OBJPROP_TEXT,"オブジェクト:");
      timer2 = -1;
   }
 
}
//+------------------------------------------------------------------+

void ClickForArrowSet(string selected_object,int arrow_code){
   datetime position_time = iTime(NULL,0,0)+Period()*60*set_position;
   //Object Channel
   long obj_type = ObjectGetInteger(0, selected_object, OBJPROP_TYPE);
   if(obj_type == OBJ_CHANNEL){
      //もし存在しなかったらエラー
      if(ObjectFind(0,"ArrowChangeButton0") != 0)return;
      if(ObjectGetString(0,"ArrowChangeButton0",OBJPROP_TEXT) == "0"){
         if(ObjectFind(0,selected_object+"_arw0") == 0){
            ObjectSetInteger(0,selected_object+"_arw0",OBJPROP_ARROWCODE,arrow_code);
         } else {
            CreateArrow(selected_object+"_arw0",position_time,ObjectGetValueByTime(0,selected_object,position_time,0),arrow_code);
         }
      } else {
         if(ObjectFind(0,selected_object+"_arw1") == 0){
            ObjectSetInteger(0,selected_object+"_arw1",OBJPROP_ARROWCODE,arrow_code);
         } else {
            CreateArrow(selected_object+"_arw1",position_time,ObjectGetValueByTime(0,selected_object,position_time,1),arrow_code);
         }
      }
   } else if(obj_type == OBJ_HLINE){
      if(ObjectFind(0,selected_object+"_arw") == 0){
         ObjectSetInteger(0,selected_object+"_arw",OBJPROP_ARROWCODE,arrow_code);
      } else {
         CreateArrow(selected_object+"_arw",position_time,ObjectGetDouble(0,selected_object,OBJPROP_PRICE),arrow_code);
      }
   } else if(obj_type == OBJ_TREND){
      if(ObjectFind(0,selected_object+"_arw") == 0){
         ObjectSetInteger(0,selected_object+"_arw",OBJPROP_ARROWCODE,arrow_code);
      } else {
         CreateArrow(selected_object+"_arw",position_time,ObjectGetValueByTime(0,selected_object,position_time),arrow_code);
      }
   }
}


void Refresh(){
   for(int i=ObjectsTotal(0)-1;i>=0;i--){
      string obj_name = ObjectName(0,i);
      int string_posi = StringFind(obj_name,"_arw",0);
      if(string_posi>1){
         //ボタンに類するラインが存在しなかったら
         if(ObjectFind(0,StringSubstr(obj_name,0,string_posi))!=0){
            ObjectDelete(0,obj_name);
         }
      }
   }
   for(int i=0;i<ObjectsTotal(0);i++){
      ButtonUpdate(ObjectName(0,i));
   }
}


//drag -> move, create -> create, delete -> check and delete,create, change -> check and delete,create
void ButtonUpdate(string obj_name){
   datetime position_time = iTime(NULL,0,0)+Period()*60*set_position;
   //存在確認はメインチャートにあるかどうかなので0を使用する。
   long obj_type = ObjectGetInteger(0, obj_name, OBJPROP_TYPE);
   if(obj_type == OBJ_HLINE){
      if(ObjectFind(0,obj_name+"_arw")==0){
         ObjectMove(0,obj_name+"_arw",0,position_time,ObjectGetDouble(0,obj_name,OBJPROP_PRICE));
      }
   } else if(obj_type == OBJ_TREND){
      if(ObjectFind(0,obj_name+"_arw")==0){
         ObjectMove(0,obj_name+"_arw",0,position_time,ObjectGetValueByTime(0,obj_name,position_time));
      }
   } else if(obj_type == OBJ_CHANNEL){
      if(ObjectFind(0,obj_name+"_arw0")==0){
         ObjectMove(0,obj_name+"_arw0",0,position_time,ObjectGetValueByTime(0,obj_name,position_time,0));
      }
      if(ObjectFind(0,obj_name+"_arw1")==0){
         ObjectMove(0,obj_name+"_arw1",0,position_time,ObjectGetValueByTime(0,obj_name,position_time,1));
      }
   }
}

void CreateArrow(string name, datetime time, double price,int arrow_code, color c=clrWhite){
   ObjectCreate(0,name,OBJ_ARROW_DOWN,0,time,price);
   ObjectSetInteger(0,name,OBJPROP_COLOR,c);    // 色設定
   ObjectSetInteger(0,name,OBJPROP_WIDTH,3);             // 幅設定
   ObjectSetInteger(0,name,OBJPROP_BACK,true);           // オブジェクトの背景表示設定
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);     // オブジェクトの選択可否設定
   ObjectSetInteger(0,name,OBJPROP_SELECTED,false);      // オブジェクトの選択状態
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);         // オブジェクトリスト表示設定
   ObjectSetInteger(0,name,OBJPROP_ZORDER,0);     // オブジェクトのチャートクリックイベント優先順位
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_LEFT);   // アンカータイプ
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
   ObjectSetInteger(0,name,OBJPROP_ZORDER,10);            // オブジェクトのチャートクリックイベント優先順位
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
   string sep="-------Jyecslin9mp8RdKV";
   int res = 0;//length of data
   uchar   data[];  // Data array to send POST requests
   
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

void DiscordNotify(string bot, string webhook,string message){
   string headers = "Content-Type: application/json\r\n";
   uchar post[];
   StringToCharArray("{\"username\":\""+bot+"\",\"content\":\""+message+"\"}", post, 0, WHOLE_ARRAY, CP_UTF8);
   Print(request("discordapp.com",DEFAULT_HTTPS_PORT,headers,StringSubstr(webhook,20),post));
 
}

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
   //Print("session:"+IntegerToString(session));
   if(session > 0){
      int connect = InternetConnectW(session, host, port, null, null, INTERNET_SERVICE_HTTP, 0, 0);
      //Print("connect:"+IntegerToString(connect));
      if (connect > 0){
      //------------connection success------------------
         string result = "";
         int hRequest = HttpOpenRequestW(connect, POST, object, Vers, null, accept, FLAG_SECURE|FLAG_KEEP_CONNECTION|FLAG_RELOAD|FLAG_PRAGMA_NOCACHE|FLAG_NO_COOKIES|FLAG_NO_CACHE_WRITE, 0);
         //Print("Reques:"+IntegerToString(hRequest));
         if(hRequest > 0){
            bool hSend = HttpSendRequestW(hRequest, headers, StringLen(headers), post, ArraySize(post)-1);
            //Print("send:"+IntegerToString(hSend));
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

