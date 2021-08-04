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
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(){

   ChartSetInteger(NULL,CHART_EVENT_OBJECT_CREATE,true);
   ChartSetInteger(NULL,CHART_EVENT_OBJECT_DELETE,true);
   EventSetTimer(1);
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason){

   EventKillTimer();//--- destroy timer
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){
   if(timer > 0){
      timer--;
   } else if(timer == 0){
      //something to do
      
      timer = -1;
   }

}

void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam){
   if(id == CHARTEVENT_OBJECT_CLICK){

   }
   if(id == CHARTEVENT_OBJECT_DRAG){

   }
   if(id == CHARTEVENT_OBJECT_CREATE){
      int obj_type = ObjectType(sparam);
      if(obj_type == OBJ_CHANNEL){
         arrow(sparam+"arw",184,ObjectGet(sparam,OBJPROP_));
      }
      arrow(sparam);
   }
   if(id == CHARTEVENT_OBJECT_DELETE){

   }
   if(id == CHARTEVENT_OBJECT_CHANGE){

   }  
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer(){



}
//+------------------------------------------------------------------+


void arrow(string name,int arrow_code, datetime time, double price,color c=clrWhite){
   ObjectCreate(NULL,name,OBJ_ARROW_DOWN,0,time,price);
   ObjectSetInteger(NULL,name,OBJPROP_COLOR,c);    // 色設定
   ObjectSetInteger(NULL,name,OBJPROP_WIDTH,1);             // 幅設定
   ObjectSetInteger(NULL,name,OBJPROP_BACK,false);           // オブジェクトの背景表示設定
   ObjectSetInteger(NULL,name,OBJPROP_SELECTABLE,true);     // オブジェクトの選択可否設定
   ObjectSetInteger(NULL,name,OBJPROP_SELECTED,false);      // オブジェクトの選択状態
   ObjectSetInteger(NULL,name,OBJPROP_HIDDEN,true);         // オブジェクトリスト表示設定
   ObjectSetInteger(NULL,name,OBJPROP_ZORDER,0);     // オブジェクトのチャートクリックイベント優先順位
   ObjectSetInteger(NULL,name,OBJPROP_ANCHOR,ANCHOR_BOTTOM);   // アンカータイプ
   ObjectSetInteger(NULL,name,OBJPROP_ARROWCODE,arrow_code);      // アローコード
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
   string accept[1] = {"*/*"};//スラッシュを省いた
   
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