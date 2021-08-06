//+------------------------------------------------------------------+
//|                                                HalfAutotrade.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

int timer = -1;
int timer2 = -1;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(){
   Label("object_name","オブジェクト:",10,30);
   
   ChartSetInteger(NULL,CHART_EVENT_OBJECT_CREATE,true);
   ChartSetInteger(NULL,CHART_EVENT_OBJECT_DELETE,true);
   EventSetTimer(1);
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason){
   ObjectDelete(NULL,"object_name");
   ObjectsDeleteAll(NULL,"ArrowChangeButton");
   Comment("");
   //ObjectsDeleteAll();
   EventKillTimer();//--- destroy timer
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){
   //+------------------------------------------------------------------+
   //| timer function                                                   |
   //+------------------------------------------------------------------+
   if(timer > 0){
      timer--;
   } else if(timer == 0){
      //something to do
      
      timer = -1;
   }
   //-------------------------------------------------------------------+
   if(timer2 > 0){
      timer2--;
   } else if(timer2 == 0){
      //something to do
      
      timer2 = -1;
   }

}

void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam){
   if(id == CHARTEVENT_OBJECT_CLICK){
      ObjectSetString(NULL,"object_name",OBJPROP_TEXT,"オブジェクト:"+sparam);
      
      static string selected_object;
      int obj_type = ObjectType(sparam);
      if(obj_type == OBJ_HLINE || obj_type == OBJ_TREND){
         selected_object = sparam;
         Button("ArrowChangeButton","Up",50,50,40,20,clrDarkRed);
         Button("ArrowChangeButton2","Down",90,50,40,20,clrDarkBlue);
         Button("ArrowChangeButton3","Timer",130,50,40,20,clrDarkOrange);
      } else if(obj_type == OBJ_CHANNEL){
         selected_object = sparam;
      }
      
      ObjectSet(sparam+"arw",OBJPROP_COLOR,clrYellow);
      
   }
   if(id == CHARTEVENT_OBJECT_DRAG){
      ButtonUpdate(sparam);
   }
   if(id == CHARTEVENT_OBJECT_CREATE){
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
   

}
//+------------------------------------------------------------------+


void Refresh(){
   for(int i=ObjectsTotal()-1;i>=0;i--){
      string obj_name = ObjectName(i);
      int string_posi = StringFind(obj_name,"arw",0);
      if(string_posi>1){
         //ボタンに類するラインが存在しなかったら
         if(ObjectFind(NULL,StringSubstr(obj_name,0,string_posi))!=0){
            ObjectDelete(NULL,obj_name);
         }
      }
   }
   for(int i=0;i<ObjectsTotal();i++){
      ButtonUpdate(ObjectName(i));
   }
}


//drag -> move, create -> create, delete -> check and delete,create, change -> check and delete,create
void ButtonUpdate(string obj_name){
   //存在確認はメインチャートにあるかどうかなので0を使用する。
   int obj_type = ObjectType(obj_name);
   datetime position_time = Time[0]+Period()*60*5;
   if(obj_type == OBJ_HLINE){
      if(ObjectFind(NULL,obj_name+"arw")==0){
         ObjectMove(NULL,obj_name+"arw",0,position_time,ObjectGet(obj_name,OBJPROP_PRICE1));
      } else {
         CreateArrow(obj_name+"arw",position_time,ObjectGet(obj_name,OBJPROP_PRICE1));
      }
   } else if(obj_type == OBJ_TREND){
      if(ObjectFind(NULL,obj_name+"arw")==0){
         ObjectMove(NULL,obj_name+"arw",0,(datetime)ObjectGet(obj_name,OBJPROP_TIME1),ObjectGet(obj_name,OBJPROP_PRICE1));
      } else {
         CreateArrow(obj_name+"arw",(datetime)ObjectGet(obj_name,OBJPROP_TIME1),ObjectGet(obj_name,OBJPROP_PRICE1));
      }
   } else if(obj_type == OBJ_CHANNEL){
      if(ObjectFind(NULL,obj_name+"arw0")==0){
         ObjectMove(NULL,obj_name+"arw0",0,(datetime)ObjectGet(obj_name,OBJPROP_TIME2),ObjectGet(obj_name,OBJPROP_PRICE2));
      } else {
         CreateArrow(obj_name+"arw0",(datetime)ObjectGet(obj_name,OBJPROP_TIME2),ObjectGet(obj_name,OBJPROP_PRICE2));
      }
      if(ObjectFind(NULL,obj_name+"arw1")==0){
         ObjectMove(NULL,obj_name+"arw1",0,(datetime)ObjectGet(obj_name,OBJPROP_TIME3),ObjectGet(obj_name,OBJPROP_PRICE3));
      } else {
         CreateArrow(obj_name+"arw1",(datetime)ObjectGet(obj_name,OBJPROP_TIME3),ObjectGet(obj_name,OBJPROP_PRICE3));
      }
   }
}


void CreateArrow(string name, datetime time, double price,color c=clrWhite){
   ObjectCreate(NULL,name,OBJ_ARROW_DOWN,0,time,price);
   ObjectSetInteger(NULL,name,OBJPROP_COLOR,c);    // 色設定
   ObjectSetInteger(NULL,name,OBJPROP_WIDTH,3);             // 幅設定
   ObjectSetInteger(NULL,name,OBJPROP_BACK,true);           // オブジェクトの背景表示設定
   ObjectSetInteger(NULL,name,OBJPROP_SELECTABLE,false);     // オブジェクトの選択可否設定
   ObjectSetInteger(NULL,name,OBJPROP_SELECTED,false);      // オブジェクトの選択状態
   ObjectSetInteger(NULL,name,OBJPROP_HIDDEN,true);         // オブジェクトリスト表示設定
   ObjectSetInteger(NULL,name,OBJPROP_ZORDER,0);     // オブジェクトのチャートクリックイベント優先順位
   ObjectSetInteger(NULL,name,OBJPROP_ANCHOR,ANCHOR_LEFT);   // アンカータイプ
   ObjectSetInteger(NULL,name,OBJPROP_ARROWCODE,184);      // アローコード
}

void Label(string name,string text, int x, int y,color c=clrWhite,int corner=CORNER_LEFT_UPPER,int font_size=12){
   ObjectCreate(NULL,name,OBJ_LABEL,0,0,0); 
   ObjectSetInteger(NULL,name,OBJPROP_COLOR,c);    // 色設定
   ObjectSetInteger(NULL,name,OBJPROP_BACK,true);           // オブジェクトの背景表示設定
   ObjectSetInteger(NULL,name,OBJPROP_SELECTABLE,false);     // オブジェクトの選択可否設定
   ObjectSetInteger(NULL,name,OBJPROP_SELECTED,false);      // オブジェクトの選択状態
   ObjectSetInteger(NULL,name,OBJPROP_HIDDEN,false);         // オブジェクトリスト表示設定
   ObjectSetInteger(NULL,name,OBJPROP_ZORDER,0);            // オブジェクトのチャートクリックイベント優先順位
   ObjectSetString(NULL,name,OBJPROP_TEXT,text);    // 表示するテキスト
   ObjectSetString(NULL,name,OBJPROP_FONT,"ＭＳ　ゴシック");  // フォント
   ObjectSetInteger(NULL,name,OBJPROP_FONTSIZE,font_size);                   // フォントサイズ
   ObjectSetInteger(NULL,name,OBJPROP_CORNER,corner);  // コーナーアンカー設定
   ObjectSetInteger(NULL,name,OBJPROP_XDISTANCE,x);                // X座標
   ObjectSetInteger(NULL,name,OBJPROP_YDISTANCE,y);                 // Y座標
}

void Button(string name,string text, int x ,int y,int x_size,int y_size ,color c=clrDarkBlue,int corner=CORNER_LEFT_UPPER,int font_size=10){
   ObjectCreate(NULL,name,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(NULL,name,OBJPROP_COLOR,clrWhite);    // text色設定
   ObjectSetInteger(NULL,name,OBJPROP_BACK,false);            // オブジェクトの背景表示設定
   ObjectSetInteger(NULL,name,OBJPROP_SELECTABLE,false);     // オブジェクトの選択可否設定
   ObjectSetInteger(NULL,name,OBJPROP_SELECTED,false);      // オブジェクトの選択状態
   ObjectSetInteger(NULL,name,OBJPROP_HIDDEN,true);         // オブジェクトリスト表示設定
   ObjectSetInteger(NULL,name,OBJPROP_ZORDER,0);            // オブジェクトのチャートクリックイベント優先順位
   ObjectSetString(NULL,name,OBJPROP_TEXT,text);            // 表示するテキスト
   ObjectSetString(NULL,name,OBJPROP_FONT,"ＭＳ　ゴシック");          // フォント
   ObjectSetInteger(NULL,name,OBJPROP_FONTSIZE,font_size);                   // フォントサイズ
   ObjectSetInteger(NULL,name,OBJPROP_CORNER,corner);  // コーナーアンカー設定
   ObjectSetInteger(NULL,name,OBJPROP_XDISTANCE,x);                // X座標
   ObjectSetInteger(NULL,name,OBJPROP_YDISTANCE,y);                 // Y座標
   ObjectSetInteger(NULL,name,OBJPROP_XSIZE,x_size);                    // ボタンサイズ幅
   ObjectSetInteger(NULL,name,OBJPROP_YSIZE,y_size);                     // ボタンサイズ高さ
   ObjectSetInteger(NULL,name,OBJPROP_BGCOLOR,c);              // ボタン色
   //ObjectSetInteger(NULL,name,OBJPROP_BORDER_COLOR,clrDarkRed);       // ボタン枠色
   ObjectSetInteger(NULL,name,OBJPROP_STATE,false);                  // ボタン押下状態
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


class Board{
private:
   string object_name;
   string button[6] = {"BoardButton0","BoardButton1","BoardButton2","BoardButton3","BoardButton4","BoardButton5"};
   
public:
   Board();
   int click(string obj_name);
   int buttonState();
   
   ~Board(){
      ObjectsDeleteAll(NULL,"Board");
   }
};


class Board{
private:
   string object_name_label;
   string button[6] = {"BoardButton0","BoardButton1","BoardButton2","BoardButton3","BoardButton4","BoardButton5"};
   
   void Button(string name,string text, int x ,int y,int x_size,int y_size ,color c=clrDarkBlue,int corner=CORNER_LEFT_UPPER,int font_size=10){
      ObjectCreate(NULL,name,OBJ_BUTTON,0,0,0);
      ObjectSetInteger(NULL,name,OBJPROP_COLOR,clrWhite);    // text色設定
      ObjectSetInteger(NULL,name,OBJPROP_BACK,false);            // オブジェクトの背景表示設定
      ObjectSetInteger(NULL,name,OBJPROP_SELECTABLE,false);     // オブジェクトの選択可否設定
      ObjectSetInteger(NULL,name,OBJPROP_SELECTED,false);      // オブジェクトの選択状態
      ObjectSetInteger(NULL,name,OBJPROP_HIDDEN,true);         // オブジェクトリスト表示設定
      ObjectSetInteger(NULL,name,OBJPROP_ZORDER,0);            // オブジェクトのチャートクリックイベント優先順位
      ObjectSetString(NULL,name,OBJPROP_TEXT,text);            // 表示するテキスト
      ObjectSetString(NULL,name,OBJPROP_FONT,"ＭＳ　ゴシック");          // フォント
      ObjectSetInteger(NULL,name,OBJPROP_FONTSIZE,font_size);                   // フォントサイズ
      ObjectSetInteger(NULL,name,OBJPROP_CORNER,corner);  // コーナーアンカー設定
      ObjectSetInteger(NULL,name,OBJPROP_XDISTANCE,x);                // X座標
      ObjectSetInteger(NULL,name,OBJPROP_YDISTANCE,y);                 // Y座標
      ObjectSetInteger(NULL,name,OBJPROP_XSIZE,x_size);                    // ボタンサイズ幅
      ObjectSetInteger(NULL,name,OBJPROP_YSIZE,y_size);                     // ボタンサイズ高さ
      ObjectSetInteger(NULL,name,OBJPROP_BGCOLOR,c);              // ボタン色
      //ObjectSetInteger(NULL,name,OBJPROP_BORDER_COLOR,clrDarkRed);       // ボタン枠色
      ObjectSetInteger(NULL,name,OBJPROP_STATE,false);                  // ボタン押下状態
   }
   
   void Label(string name,string text, int x, int y,color c=clrWhite,int corner=CORNER_RIGHT_UPPER,int font_size=12){
      ObjectCreate(NULL,name,OBJ_LABEL,0,0,0); 
      ObjectSetInteger(NULL,name,OBJPROP_COLOR,c);    // 色設定
      ObjectSetInteger(NULL,name,OBJPROP_BACK,true);           // オブジェクトの背景表示設定
      ObjectSetInteger(NULL,name,OBJPROP_SELECTABLE,false);     // オブジェクトの選択可否設定
      ObjectSetInteger(NULL,name,OBJPROP_SELECTED,false);      // オブジェクトの選択状態
      ObjectSetInteger(NULL,name,OBJPROP_HIDDEN,false);         // オブジェクトリスト表示設定
      //ObjectSetInteger(NULL,name,OBJPROP_ZORDER,0);            // オブジェクトのチャートクリックイベント優先順位 default 0
      ObjectSetString(NULL,name,OBJPROP_TEXT,text);    // 表示するテキスト
      ObjectSetString(NULL,name,OBJPROP_FONT,"ＭＳ　ゴシック");  // フォント
      ObjectSetInteger(NULL,name,OBJPROP_FONTSIZE,font_size);                   // フォントサイズ
      ObjectSetInteger(NULL,name,OBJPROP_CORNER,corner);  // コーナーアンカー設定
      ObjectSetInteger(NULL,name,OBJPROP_XDISTANCE,x);                // X座標
      ObjectSetInteger(NULL,name,OBJPROP_YDISTANCE,y);                 // Y座標
   }
public:

   Board(){
      
      Button("ArrowChangeButton",name1,50,50,40,20,clrDarkRed);
      Button("ArrowChangeButton2",name2,90,50,40,20,clrDarkBlue);
      Button("ArrowChangeButton3",name3,130,50,40,20,clrDarkOrange);
      
      if(selected == 1)ObjectSet(name1,OBJPROP_SELECTED,true);
      else if(selected == 2)ObjectSet(name2,OBJPROP_SELECTED,true);
      else if(selected == 2)ObjectSet(name3,OBJPROP_SELECTED,true);
   }
   int click(string obj){
      if(obj == name1 || obj == name2 || obj == name3){
         if(ObjectGet(obj,OBJPROP_SELECTED)){
         
         } else {
            ObjectSet(name1,OBJPROP_SELECTED,false);
            ObjectSet(name2,OBJPROP_SELECTED,false);
            ObjectSet(name3,OBJPROP_SELECTED,false);
            ObjectSet(obj,OBJPROP_SELECTED,true);
         }
      }
   }
   ~ConbinedButton(){
      ObjectDelete(NULL,name1);
      ObjectDelete(NULL,name2);
      ObjectDelete(NULL,name3);
   }
   
};