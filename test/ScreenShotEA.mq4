//+------------------------------------------------------------------+
//|                                                 ScreenShotEA.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

input int x_ss = 1280;//スクショ　横
input int y_ss = 720;//スクショ　縦
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   Button("HA_screenshot","SS",70,30,60,20,clrDarkOrange,CORNER_RIGHT_LOWER,8);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason){
//---
   ObjectsDeleteAll(0,"HA_");
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
//---
   
}
//+------------------------------------------------------------------+


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

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam){
   if(id == CHARTEVENT_OBJECT_CLICK){
      if(sparam == "HA_screenshot"){
         LineNotify("wmaG9W8XTBC8k3x4VEy8bA1LOBnHbF5cA8h65OR1ufU","\n通貨:"+Symbol()+"\n価格:"+DoubleToString(iClose(NULL,0,0),_Digits),Symbol()+"ss.png",x_ss,y_ss);
         Sleep(100);
         ObjectSetInteger(0,sparam,OBJPROP_STATE,false);      // オブジェクトの選択状態
         ChartRedraw(0);
      }
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
      if(au==-1){ 
         Print("Error in WebRequest. Error code  =",GetLastError());  
      }
   }
}