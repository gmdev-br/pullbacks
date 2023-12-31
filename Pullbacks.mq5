//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "© GM, 2020, 2021, 2022, 2023"
#property description "Pullbacks"
#property indicator_chart_window

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum enum_modo {
   Manual,
   AutoMax,
   AutoMin,
};

enum enum_modo_forcado {
   ForceTypical, // Typical
   ForceOpen, // Open
   ForceClose, // Close
   ForceMax, // High
   ForceMin, // Low
   ForceArrow // Arrow
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input int                        id = 1;
input datetime                   DefaultInitialDate = "2022.10.13 14:30:00";          // Data inicial padrão
input bool                       shortMode = false;
input int                        input_start = 0;
input int                        input_end = 0;
input enum_modo                  modo = Manual;
input enum_modo_forcado          modo_forcado = ForceArrow;
input double                     percentual_inicial = 0.3;
input double                     percentualMaximo = 20;
input double                     inputIntervalo = 2.5;
input color                      corInicial = clrYellow;
input color                      corPrincipalTypical = clrRoyalBlue;
input color                      corPrincipalHigh = clrRed;
input color                      corPrincipalLow = clrLime;
input int                        largura = 3;
input int                        WaitMilliseconds = 300000;  // Timer (milliseconds) for recalculation
input bool                       showMainOnly = false;
input bool                       showPositiveOnly = false;
input bool                       showSub1 = false;
input bool                       extendLines = true;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime                         data_inicial;
int                              barFrom;
string                           uniqueId;
int                              qtdLinhas;
color                            corPrincipal, corSecundaria;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {

   uniqueId = "pullback_" + id + "_";

   data_inicial = DefaultInitialDate;
   barFrom = iBarShift(NULL, PERIOD_CURRENT, data_inicial);
   qtdLinhas = percentualMaximo / inputIntervalo;

   string name = uniqueId + "_arrow";
   datetime timeArrow = GetObjectTime1(name);
   if (timeArrow == 0) {
      ObjectCreate(0, name, OBJ_ARROW, 0, iTime(NULL, PERIOD_D1, 0), iClose(NULL, PERIOD_D1, 1));
      ObjectSetInteger(0, name, OBJPROP_ARROWCODE, 233);
      if (modo_forcado == ForceTypical) {
         ObjectSetInteger(0, name, OBJPROP_COLOR, corPrincipalTypical);
      } else if (modo_forcado == ForceMax) {
         ObjectSetInteger(0, name, OBJPROP_COLOR, corPrincipalHigh);
      } else if (modo_forcado == ForceMin) {
         ObjectSetInteger(0, name, OBJPROP_COLOR, corPrincipalLow);
      }
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, true);
      ObjectSetInteger(0, name, OBJPROP_SELECTED, true);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, false);
      ObjectSetInteger(0, name, OBJPROP_ZORDER, 100);
      ObjectSetInteger(0, name, OBJPROP_FILL, true);
   } else {
      ObjectSetInteger(0, name, OBJPROP_COLOR, corInicial);
   }

   corPrincipal = corPrincipalLow;
   corSecundaria = corPrincipalLow;

   _updateTimer = new MillisecondTimer(WaitMilliseconds, false);
   EventSetMillisecondTimer(WaitMilliseconds);

   ChartRedraw();

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   delete(_updateTimer);
   if(reason == REASON_REMOVE)
      ObjectsDeleteAll(0, uniqueId);
   ChartRedraw();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Update() {

   data_inicial = DefaultInitialDate;
   int primeiraBarra = WindowFirstVisibleBar();
   datetime dataPrimeiraBarra = iTime(NULL, PERIOD_CURRENT, primeiraBarra);
   datetime data_final = iTime(NULL, PERIOD_CURRENT, 0);
   barFrom = iBarShift(NULL, PERIOD_CURRENT, data_inicial);

//for(int i = 0; i <= qtdLinhas; i++) {
   ObjectsDeleteAll(0, uniqueId + "mid_");
   ObjectsDeleteAll(0, uniqueId + "up_");
   ObjectsDeleteAll(0, uniqueId + "down_");
//}

   ObjectDelete(0, uniqueId + "rect1");

   double preco, intervalo;
   int sinal = 1;

//+------------------------------------------------------------------+
//| Manual                                                           |
//+------------------------------------------------------------------+
   if (modo == Manual) {

      datetime dataSeta = ObjectGetInteger(0, uniqueId + "_arrow", OBJPROP_TIME);
      if (dataSeta > iTime(NULL, PERIOD_CURRENT, 0))
         return true;

      int barraSeta = iBarShift(_Symbol, PERIOD_CURRENT, dataSeta);
      double fech = iClose(NULL, PERIOD_CURRENT, 0);
      double fechSeta = iClose(NULL, PERIOD_CURRENT, barraSeta);

      if (modo_forcado == ForceTypical) {
         preco = (iHigh(NULL, PERIOD_CURRENT, barraSeta) + iLow(NULL, PERIOD_CURRENT, barraSeta) + iClose(NULL, PERIOD_CURRENT, barraSeta)) / 3;
         sinal = -1;
         corPrincipal = corPrincipalTypical;
         corSecundaria = corPrincipalTypical;
      } else if (modo_forcado == ForceMax) {
         preco = iHigh(NULL, PERIOD_CURRENT, barraSeta);
         sinal = -1;
         corPrincipal = corPrincipalHigh;
         corSecundaria = corPrincipalHigh;
      } else if (modo_forcado == ForceClose) {
         preco = iClose(NULL, PERIOD_CURRENT, barraSeta);
         sinal = -1;
      } else if (modo_forcado == ForceOpen) {
         preco = iOpen(NULL, PERIOD_CURRENT, barraSeta);
         sinal = -1;
      } else if (modo_forcado == ForceMin) {
         preco = iLow(NULL, PERIOD_CURRENT, barraSeta);
         sinal = -1;
         corPrincipal = corPrincipalLow;
         corSecundaria = corPrincipalLow;
      } else if (modo_forcado == ForceArrow) {
         preco = ObjectGetDouble(0, uniqueId + "_arrow", OBJPROP_PRICE);
         sinal = -1;
      } else {
         preco = iLow(NULL, PERIOD_CURRENT, barraSeta);
         sinal = 1;
      }

      intervalo = inputIntervalo / 100 * preco;
      //intervalo = 685;
      data_inicial = dataSeta;
      if (dataPrimeiraBarra >= data_inicial)
         data_inicial = dataPrimeiraBarra;

      ObjectCreate(0, uniqueId + "mid_0", OBJ_TREND, 0, data_inicial, preco, data_final, preco);

      if (!showPositiveOnly || (showPositiveOnly && modo_forcado == ForceMin)) {
         for(int i = 1; i <= qtdLinhas; i++) {
            //if (preco - i * intervalo * sinal <= fech * 1.005 || fech * 1.005 <= preco - i * intervalo * sinal)
            ObjectCreate(0, uniqueId + "up_" + i, OBJ_TREND, 0, data_inicial, preco - i * intervalo * sinal, data_final, preco - i * intervalo * sinal);
         }
      }

      if (!showPositiveOnly || (showPositiveOnly && modo_forcado == ForceMax)) {
         for(int i = 1; i <= qtdLinhas; i++) {
            //if (preco + i * intervalo * sinal <= fech || fech <= preco + i * intervalo * sinal)
            ObjectCreate(0, uniqueId + "down_" + i, OBJ_TREND, 0, data_inicial, preco + i * intervalo * sinal, data_final, preco + i * intervalo * sinal);
         }
      }

//      if (showSub1) {
//         if (!showPositiveOnly || (showPositiveOnly && modo_forcado == ForceMin)) {
//            ObjectCreate(0, uniqueId + "up_025", OBJ_TREND, 0, data_inicial, preco - percentual_inicial / 100 * preco * sinal, data_final, preco - percentual_inicial / 100 * preco * sinal);
//            //ObjectCreate(0, uniqueId + "up_050", OBJ_TREND, 0, data_inicial, preco - 0.5 / 100 * preco * sinal, data_final, preco - 0.5 / 100 * preco * sinal);
//            //ObjectCreate(0, uniqueId + "up_075", OBJ_TREND, 0, data_inicial, preco - 0.66 / 100 * preco * sinal, data_final, preco - 0.66 / 100 * preco * sinal);
//            ObjectCreate(0, uniqueId + "up_0100", OBJ_TREND, 0, data_inicial, preco - 0.01 * preco * sinal, data_final, preco - 0.01 * preco * sinal);
//            //ObjectCreate(0, uniqueId + "up_0150", OBJ_TREND, 0, data_inicial, preco - 0.015 * preco * sinal, data_final, preco - 0.015 * preco * sinal);
//
//            ObjectSetInteger(0, uniqueId + "up_025", OBJPROP_WIDTH, largura);
//            ObjectSetInteger(0, uniqueId + "up_050", OBJPROP_WIDTH, 1);
//            //ObjectSetInteger(0, uniqueId + "up_075", OBJPROP_WIDTH, 1);
//            ObjectSetInteger(0, uniqueId + "up_0100", OBJPROP_WIDTH, largura);
//            ObjectSetInteger(0, uniqueId + "up_0150", OBJPROP_WIDTH, largura);
//
//            ObjectSetString(0, uniqueId + "up_025", OBJPROP_TEXT, percentual_inicial);
//            ObjectSetString(0, uniqueId + "up_050", OBJPROP_TEXT, "0.5");
//            //ObjectSetString(0, uniqueId + "up_075", OBJPROP_TEXT, "0.66");
//            ObjectSetString(0, uniqueId + "up_0100", OBJPROP_TEXT, "1.0");
//            ObjectSetString(0, uniqueId + "up_0150", OBJPROP_TEXT, "1.5");
//
//            ObjectSetInteger(0, uniqueId + "up_025", OBJPROP_COLOR, corInicial);
//            ObjectSetInteger(0, uniqueId + "up_050", OBJPROP_COLOR, corPrincipal);
//            //ObjectSetInteger(0, uniqueId + "up_075", OBJPROP_COLOR, corPrincipal);
//            ObjectSetInteger(0, uniqueId + "up_0100", OBJPROP_COLOR, corPrincipal);
//            ObjectSetInteger(0, uniqueId + "up_0150", OBJPROP_COLOR, corPrincipal);
//
//            ObjectSetInteger(0, uniqueId + "up_025", OBJPROP_STYLE, STYLE_DOT);
//            ObjectSetInteger(0, uniqueId + "up_050", OBJPROP_STYLE, STYLE_DOT);
//            //ObjectSetInteger(0, uniqueId + "up_075", OBJPROP_STYLE, STYLE_DOT);
//            ObjectSetInteger(0, uniqueId + "up_0100", OBJPROP_STYLE, STYLE_SOLID);
//            ObjectSetInteger(0, uniqueId + "up_0150", OBJPROP_STYLE, STYLE_SOLID);
//
//            ObjectSetInteger(0, uniqueId + "up_025", OBJPROP_RAY_RIGHT, extendLines);
//            ObjectSetInteger(0, uniqueId + "up_050", OBJPROP_RAY_RIGHT, extendLines);
//            //ObjectSetInteger(0, uniqueId + "up_075", OBJPROP_RAY_RIGHT, extendLines);
//            ObjectSetInteger(0, uniqueId + "up_0100", OBJPROP_RAY_RIGHT, extendLines);
//            ObjectSetInteger(0, uniqueId + "up_0150", OBJPROP_RAY_RIGHT, extendLines);
//         }
//
//         if (!showPositiveOnly || (showPositiveOnly && modo_forcado == ForceMax)) {
//            ObjectCreate(0, uniqueId + "down_025", OBJ_TREND, 0, data_inicial, preco + percentual_inicial / 100 * preco * sinal, data_final, preco + percentual_inicial / 100 * preco * sinal);
//            //ObjectCreate(0, uniqueId + "down_050", OBJ_TREND, 0, data_inicial, preco + 0.5 / 100 * preco * sinal, data_final, preco + 0.5 / 100 * preco * sinal);
//            //ObjectCreate(0, uniqueId + "down_075", OBJ_TREND, 0, data_inicial, preco + 0.66 / 100 * preco * sinal, data_final, preco + 0.66 / 100 * preco * sinal);
//            ObjectCreate(0, uniqueId + "down_0100", OBJ_TREND, 0, data_inicial, preco + 0.01 * preco * sinal, data_final, preco + 0.01 * preco * sinal);
//            //ObjectCreate(0, uniqueId + "down_0150", OBJ_TREND, 0, data_inicial, preco + 0.015 * preco * sinal, data_final, preco + 0.015 * preco * sinal);
//
//            ObjectSetInteger(0, uniqueId + "down_025", OBJPROP_WIDTH, largura);
//            ObjectSetInteger(0, uniqueId + "down_050", OBJPROP_WIDTH, 1);
//            //ObjectSetInteger(0, uniqueId + "down_075", OBJPROP_WIDTH, 1);
//            ObjectSetInteger(0, uniqueId + "down_0100", OBJPROP_WIDTH, largura);
//            ObjectSetInteger(0, uniqueId + "down_0150", OBJPROP_WIDTH, largura);
//
//            ObjectSetString(0, uniqueId + "down_025", OBJPROP_TEXT, percentual_inicial);
//            ObjectSetString(0, uniqueId + "down_050", OBJPROP_TEXT, "0.5");
//            //ObjectSetString(0, uniqueId + "down_075", OBJPROP_TEXT, "0.66");
//            ObjectSetString(0, uniqueId + "down_0100", OBJPROP_TEXT, "1.0");
//            ObjectSetString(0, uniqueId + "down_0150", OBJPROP_TEXT, "1.5");
//
//
//            ObjectSetInteger(0, uniqueId + "down_025", OBJPROP_COLOR, corInicial);
//            ObjectSetInteger(0, uniqueId + "down_050", OBJPROP_COLOR, corPrincipal);
//            //ObjectSetInteger(0, uniqueId + "down_075", OBJPROP_COLOR, corPrincipal);
//            ObjectSetInteger(0, uniqueId + "down_0100", OBJPROP_COLOR, corPrincipal);
//            ObjectSetInteger(0, uniqueId + "down_0150", OBJPROP_COLOR, corPrincipal);
//
//            ObjectSetInteger(0, uniqueId + "down_025", OBJPROP_STYLE, STYLE_DOT);
//            ObjectSetInteger(0, uniqueId + "down_050", OBJPROP_STYLE, STYLE_DOT);
//            //ObjectSetInteger(0, uniqueId + "down_075", OBJPROP_STYLE, STYLE_DOT);
//            ObjectSetInteger(0, uniqueId + "down_0100", OBJPROP_STYLE, STYLE_SOLID);
//            ObjectSetInteger(0, uniqueId + "down_0150", OBJPROP_STYLE, STYLE_SOLID);
//
//            ObjectSetInteger(0, uniqueId + "down_025", OBJPROP_RAY_RIGHT, extendLines);
//            ObjectSetInteger(0, uniqueId + "down_050", OBJPROP_RAY_RIGHT, extendLines);
//            //ObjectSetInteger(0, uniqueId + "down_075", OBJPROP_RAY_RIGHT, extendLines);
//            ObjectSetInteger(0, uniqueId + "down_0100", OBJPROP_RAY_RIGHT, extendLines);
//            ObjectSetInteger(0, uniqueId + "down_0150", OBJPROP_RAY_RIGHT, extendLines);
//         }
//      }
      //}

      //ObjectCreate(0, uniqueId + 0, OBJ_TREND, 0, data_inicial, preco, data_final, preco);

//+------------------------------------------------------------------+
//| Auto max                                                         |
//+------------------------------------------------------------------+
   } else if (modo == AutoMax) {

      if (DefaultInitialDate > iTime(NULL, PERIOD_CURRENT, 0))
         return true;

      double arrayTemp[];
      int totalRates = SeriesInfoInteger(_Symbol, PERIOD_CURRENT, SERIES_BARS_COUNT);
      int teste = CopyHigh(NULL, PERIOD_CURRENT, 0, barFrom, arrayTemp);
      ArraySetAsSeries(arrayTemp, true);
      int indexTemp = ArrayMaximum(arrayTemp, 0, WHOLE_ARRAY);
      preco = iHigh(NULL, PERIOD_CURRENT, indexTemp);
      sinal = -1;
      corPrincipal = corPrincipalHigh;
      corSecundaria = corPrincipalHigh;

      intervalo = inputIntervalo / 100 * preco;
      data_inicial = iTime(NULL, PERIOD_CURRENT, indexTemp);
      if (dataPrimeiraBarra >= data_inicial)
         data_inicial = dataPrimeiraBarra;

      ObjectCreate(0, uniqueId + "mid_0", OBJ_TREND, 0, data_inicial, preco, data_final, preco);

      for(int i = 1; i <= qtdLinhas; i++) {
         ObjectCreate(0, uniqueId + "up_" + i, OBJ_TREND, 0, data_inicial, preco - i * intervalo * sinal, data_final, preco - i * intervalo * sinal);
      }
      if (!showPositiveOnly) {
         for(int i = 1; i <= qtdLinhas; i++) {
            ObjectCreate(0, uniqueId + "down_" + i, OBJ_TREND, 0, data_inicial, preco + i * intervalo * sinal, data_final, preco + i * intervalo * sinal);
         }
      }

//      if (showSub1) {
//         ObjectCreate(0, uniqueId + "up_025", OBJ_TREND, 0, data_inicial, preco - percentual_inicial / 100 * preco * sinal, data_final, preco - percentual_inicial / 100 * preco * sinal);
//         //ObjectCreate(0, uniqueId + "up_050", OBJ_TREND, 0, data_inicial, preco - 0.5 / 100 * preco * sinal, data_final, preco - 0.5 / 100 * preco * sinal);
//         //ObjectCreate(0, uniqueId + "up_075", OBJ_TREND, 0, data_inicial, preco - 0.66 / 100 * preco * sinal, data_final, preco - 0.66 / 100 * preco * sinal);
//         ObjectCreate(0, uniqueId + "up_0100", OBJ_TREND, 0, data_inicial, preco - 0.01 * preco * sinal, data_final, preco - 0.01 * preco * sinal);
//         //ObjectCreate(0, uniqueId + "up_0150", OBJ_TREND, 0, data_inicial, preco - 0.015 * preco * sinal, data_final, preco - 0.015 * preco * sinal);
//
//         ObjectSetInteger(0, uniqueId + "up_025", OBJPROP_WIDTH, largura);
//         ObjectSetInteger(0, uniqueId + "up_050", OBJPROP_WIDTH, 1);
//         //ObjectSetInteger(0, uniqueId + "up_075", OBJPROP_WIDTH, 1);
//         ObjectSetInteger(0, uniqueId + "up_0100", OBJPROP_WIDTH, largura);
//         ObjectSetInteger(0, uniqueId + "up_0150", OBJPROP_WIDTH, largura);
//
//         ObjectSetString(0, uniqueId + "up_025", OBJPROP_TEXT, percentual_inicial);
//         ObjectSetString(0, uniqueId + "up_050", OBJPROP_TEXT, "0.5");
//         //ObjectSetString(0, uniqueId + "up_075", OBJPROP_TEXT, "0.66");
//         ObjectSetString(0, uniqueId + "up_0100", OBJPROP_TEXT, "1.0");
//         ObjectSetString(0, uniqueId + "up_0150", OBJPROP_TEXT, "1.5");
//
//         ObjectSetInteger(0, uniqueId + "up_025", OBJPROP_COLOR, corInicial);
//         ObjectSetInteger(0, uniqueId + "up_050", OBJPROP_COLOR, corPrincipal);
//         //ObjectSetInteger(0, uniqueId + "up_075", OBJPROP_COLOR, corPrincipal);
//         ObjectSetInteger(0, uniqueId + "up_0100", OBJPROP_COLOR, corPrincipal);
//         ObjectSetInteger(0, uniqueId + "up_0150", OBJPROP_COLOR, corPrincipal);
//
//         ObjectSetInteger(0, uniqueId + "up_025", OBJPROP_STYLE, STYLE_DOT);
//         ObjectSetInteger(0, uniqueId + "up_050", OBJPROP_STYLE, STYLE_DOT);
//         //ObjectSetInteger(0, uniqueId + "up_075", OBJPROP_STYLE, STYLE_DOT);
//         ObjectSetInteger(0, uniqueId + "up_0100", OBJPROP_STYLE, STYLE_SOLID);
//         ObjectSetInteger(0, uniqueId + "up_0150", OBJPROP_STYLE, STYLE_SOLID);
//
//         ObjectSetInteger(0, uniqueId + "up_025", OBJPROP_RAY_RIGHT, extendLines);
//         ObjectSetInteger(0, uniqueId + "up_050", OBJPROP_RAY_RIGHT, extendLines);
//         //ObjectSetInteger(0, uniqueId + "up_075", OBJPROP_RAY_RIGHT, extendLines);
//         ObjectSetInteger(0, uniqueId + "up_0100", OBJPROP_RAY_RIGHT, extendLines);
//         ObjectSetInteger(0, uniqueId + "up_0150", OBJPROP_RAY_RIGHT, extendLines);
//
//         if (!showPositiveOnly) {
//            ObjectCreate(0, uniqueId + "down_025", OBJ_TREND, 0, data_inicial, preco + percentual_inicial / 100 * preco * sinal, data_final, preco + percentual_inicial / 100 * preco * sinal);
//            //ObjectCreate(0, uniqueId + "down_050", OBJ_TREND, 0, data_inicial, preco + 0.5 / 100 * preco * sinal, data_final, preco + 0.5 / 100 * preco * sinal);
//            //ObjectCreate(0, uniqueId + "down_075", OBJ_TREND, 0, data_inicial, preco + 0.66 / 100 * preco * sinal, data_final, preco + 0.66 / 100 * preco * sinal);
//            ObjectCreate(0, uniqueId + "down_0100", OBJ_TREND, 0, data_inicial, preco + 0.01 * preco * sinal, data_final, preco + 0.01 * preco * sinal);
//            //ObjectCreate(0, uniqueId + "down_0150", OBJ_TREND, 0, data_inicial, preco + 0.015 * preco * sinal, data_final, preco + 0.015 * preco * sinal);
//
//            ObjectSetInteger(0, uniqueId + "down_025", OBJPROP_WIDTH, largura);
//            ObjectSetInteger(0, uniqueId + "down_050", OBJPROP_WIDTH, 1);
//            //ObjectSetInteger(0, uniqueId + "down_075", OBJPROP_WIDTH, 1);
//            ObjectSetInteger(0, uniqueId + "down_0100", OBJPROP_WIDTH, largura);
//            ObjectSetInteger(0, uniqueId + "down_0150", OBJPROP_WIDTH, largura);
//
//            ObjectSetString(0, uniqueId + "down_025", OBJPROP_TEXT, percentual_inicial);
//            ObjectSetString(0, uniqueId + "down_050", OBJPROP_TEXT, "0.5");
//            //ObjectSetString(0, uniqueId + "down_075", OBJPROP_TEXT, "0.66");
//            ObjectSetString(0, uniqueId + "down_0100", OBJPROP_TEXT, "1.0");
//            ObjectSetString(0, uniqueId + "down_0150", OBJPROP_TEXT, "1.5");
//
//            ObjectSetInteger(0, uniqueId + "down_025", OBJPROP_COLOR, corInicial);
//            ObjectSetInteger(0, uniqueId + "down_050", OBJPROP_COLOR, corPrincipal);
//            //ObjectSetInteger(0, uniqueId + "down_075", OBJPROP_COLOR, corPrincipal);
//            ObjectSetInteger(0, uniqueId + "down_0100", OBJPROP_COLOR, corPrincipal);
//            ObjectSetInteger(0, uniqueId + "down_0150", OBJPROP_COLOR, corPrincipal);
//
//            ObjectSetInteger(0, uniqueId + "down_025", OBJPROP_STYLE, STYLE_DOT);
//            ObjectSetInteger(0, uniqueId + "down_050", OBJPROP_STYLE, STYLE_DOT);
//            //ObjectSetInteger(0, uniqueId + "down_075", OBJPROP_STYLE, STYLE_DOT);
//            ObjectSetInteger(0, uniqueId + "down_0100", OBJPROP_STYLE, STYLE_SOLID);
//            ObjectSetInteger(0, uniqueId + "down_0150", OBJPROP_STYLE, STYLE_SOLID);
//
//            ObjectSetInteger(0, uniqueId + "down_025", OBJPROP_RAY_RIGHT, extendLines);
//            ObjectSetInteger(0, uniqueId + "down_050", OBJPROP_RAY_RIGHT, extendLines);
//            //ObjectSetInteger(0, uniqueId + "down_075", OBJPROP_RAY_RIGHT, extendLines);
//            ObjectSetInteger(0, uniqueId + "down_0100", OBJPROP_RAY_RIGHT, extendLines);
//            ObjectSetInteger(0, uniqueId + "down_0150", OBJPROP_RAY_RIGHT, extendLines);
//         }
//      }
//+------------------------------------------------------------------+
//| Auto min                                                         |
//+------------------------------------------------------------------+
   } else if (modo == AutoMin) {

      if (DefaultInitialDate > iTime(NULL, PERIOD_CURRENT, 0))
         return true;

      double arrayTemp[];
      int totalRates = SeriesInfoInteger(_Symbol, PERIOD_CURRENT, SERIES_BARS_COUNT);
      int teste = CopyLow(NULL, PERIOD_CURRENT, 0, barFrom, arrayTemp);
      ArraySetAsSeries(arrayTemp, true);
      int indexTemp = ArrayMinimum(arrayTemp, 0, WHOLE_ARRAY);
      preco = iLow(NULL, PERIOD_CURRENT, indexTemp);
      sinal = -1;
      corPrincipal = corPrincipalLow;
      corSecundaria = corPrincipalLow;

      intervalo = inputIntervalo / 100 * preco;
      data_inicial = iTime(NULL, PERIOD_CURRENT, indexTemp);
      if (dataPrimeiraBarra >= data_inicial)
         data_inicial = dataPrimeiraBarra;

      ObjectCreate(0, uniqueId + 0, OBJ_TREND, 0, data_inicial, preco, data_final, preco);

      if (!showPositiveOnly || (showPositiveOnly && modo_forcado == ForceMin)) {
         for(int i = 1; i <= qtdLinhas; i++) {
            ObjectCreate(0, uniqueId + "up_" + i, OBJ_TREND, 0, data_inicial, preco - i * intervalo * sinal, data_final, preco - i * intervalo * sinal);
         }
      }

      if (!showPositiveOnly || (showPositiveOnly && modo_forcado == ForceMax)) {
         for(int i = 1; i <= qtdLinhas; i++) {
            ObjectCreate(0, uniqueId + "down_" + i, OBJ_TREND, 0, data_inicial, preco + i * intervalo * sinal, data_final, preco + i * intervalo * sinal);
         }
      }
   }
//+------------------------------------------------------------------+
//| Force Arrow                                                      |
//+------------------------------------------------------------------+
   if (modo_forcado == ForceArrow) {
      ObjectSetInteger(0, uniqueId + "mid_0", OBJPROP_COLOR, corInicial);
      ObjectSetInteger(0, uniqueId + "mid_0", OBJPROP_WIDTH, largura);
      ObjectSetInteger(0, uniqueId + "mid_0", OBJPROP_RAY_RIGHT, extendLines);

      for(int i = 1; i <= qtdLinhas; i++) {
         ObjectSetInteger(0, uniqueId + "up_" + i, OBJPROP_COLOR, corSecundaria);
         if (!showPositiveOnly)
            ObjectSetInteger(0, uniqueId + "down_" + i, OBJPROP_COLOR, corSecundaria);
      }

      for(int i = 2; i <= qtdLinhas; i = i + 2) {
         ObjectSetInteger(0, uniqueId + "up_" + i, OBJPROP_COLOR, corPrincipal);
         if (!showPositiveOnly)
            ObjectSetInteger(0, uniqueId + "down_" + i, OBJPROP_COLOR, corPrincipal);
      }

      if (showMainOnly) {
         for(int i = 0; i <= qtdLinhas; i++) {
            if (MathMod(i, 2) != 0 && i > 2) {
               ObjectDelete(0, uniqueId + "up_" + i);
               ObjectDelete(0, uniqueId + "down_" + i);
            }
         }
      }

      for(int i = 0; i <= qtdLinhas; i++) {
         ObjectSetInteger(0, uniqueId + "up_" + i, OBJPROP_WIDTH, 1);
         ObjectSetInteger(0, uniqueId + "up_" + i, OBJPROP_STYLE, STYLE_DOT);
         ObjectSetString(0, uniqueId + "up_" + i, OBJPROP_TEXT, DoubleToString(inputIntervalo * i, 2));
         ObjectSetInteger(0, uniqueId + "up_" + i, OBJPROP_RAY_RIGHT, extendLines);

         if (!showPositiveOnly) {
            ObjectSetInteger(0, uniqueId + "down_" + i, OBJPROP_WIDTH, 1);
            ObjectSetInteger(0, uniqueId + "down_" + i, OBJPROP_STYLE, STYLE_DOT);
            ObjectSetString(0, uniqueId + "down_" + i, OBJPROP_TEXT, DoubleToString(inputIntervalo * i, 2));
            ObjectSetInteger(0, uniqueId + "down_" + i, OBJPROP_RAY_RIGHT, extendLines);
         }
      }

      ObjectCreate(0, uniqueId + "up_0100", OBJ_TREND, 0, data_inicial, preco - 0.01 * preco * sinal, data_final, preco - 0.01 * preco * sinal);
      ObjectSetInteger(0, uniqueId + "up_0100", OBJPROP_WIDTH, largura);
      ObjectSetString(0, uniqueId + "up_0100", OBJPROP_TEXT, "1.0");
      ObjectSetInteger(0, uniqueId + "up_0100", OBJPROP_COLOR, corPrincipal);
      ObjectSetInteger(0, uniqueId + "up_0100", OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, uniqueId + "up_0100", OBJPROP_RAY_RIGHT, extendLines);

      ObjectCreate(0, uniqueId + "down_0100", OBJ_TREND, 0, data_inicial, preco + 0.01 * preco * sinal, data_final, preco + 0.01 * preco * sinal);
      ObjectSetInteger(0, uniqueId + "down_0100", OBJPROP_WIDTH, largura);
      ObjectSetString(0, uniqueId + "down_0100", OBJPROP_TEXT, "1.0");
      ObjectSetInteger(0, uniqueId + "down_0100", OBJPROP_COLOR, corPrincipal);
      ObjectSetInteger(0, uniqueId + "down_0100", OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, uniqueId + "down_0100", OBJPROP_RAY_RIGHT, extendLines);

//      if (showSub1) {
//         ObjectCreate(0, uniqueId + "up_025", OBJ_TREND, 0, data_inicial, preco - percentual_inicial / 100 * preco * sinal, data_final, preco - percentual_inicial / 100 * preco * sinal);
//         ObjectCreate(0, uniqueId + "up_050", OBJ_TREND, 0, data_inicial, preco - 0.5 / 100 * preco * sinal, data_final, preco - 0.5 / 100 * preco * sinal);
//         // ObjectCreate(0, uniqueId + "up_075", OBJ_TREND, 0, data_inicial, preco - 0.66 / 100 * preco * sinal, data_final, preco - 0.66 / 100 * preco * sinal);
//         //ObjectCreate(0, uniqueId + "up_0150", OBJ_TREND, 0, data_inicial, preco - 0.015 * preco * sinal, data_final, preco - 0.015 * preco * sinal);
//
//         ObjectSetInteger(0, uniqueId + "up_025", OBJPROP_WIDTH, largura);
//         ObjectSetInteger(0, uniqueId + "up_050", OBJPROP_WIDTH, largura);
//         //ObjectSetInteger(0, uniqueId + "up_075", OBJPROP_WIDTH, largura);
//         //ObjectSetInteger(0, uniqueId + "up_0150", OBJPROP_WIDTH, largura);
//
//         ObjectSetString(0, uniqueId + "up_025", OBJPROP_TEXT, percentual_inicial);
//         ObjectSetString(0, uniqueId + "up_050", OBJPROP_TEXT, "0.5");
//         //ObjectSetString(0, uniqueId + "up_075", OBJPROP_TEXT, "0.66");
//         //ObjectSetString(0, uniqueId + "up_0150", OBJPROP_TEXT, "1.5");
//
//         ObjectSetInteger(0, uniqueId + "up_025", OBJPROP_COLOR, corInicial);
//         ObjectSetInteger(0, uniqueId + "up_050", OBJPROP_COLOR, corPrincipal);
//         //ObjectSetInteger(0, uniqueId + "up_075", OBJPROP_COLOR, corPrincipal);
//         //ObjectSetInteger(0, uniqueId + "up_0150", OBJPROP_COLOR, corPrincipal);
//
//         ObjectSetInteger(0, uniqueId + "up_025", OBJPROP_STYLE, STYLE_DOT);
//         ObjectSetInteger(0, uniqueId + "up_050", OBJPROP_STYLE, STYLE_DOT);
//         //ObjectSetInteger(0, uniqueId + "up_075", OBJPROP_STYLE, STYLE_DOT);
//         //ObjectSetInteger(0, uniqueId + "up_0150", OBJPROP_STYLE, STYLE_DOT);
//
//         ObjectSetInteger(0, uniqueId + "up_025", OBJPROP_RAY_RIGHT, extendLines);
//         ObjectSetInteger(0, uniqueId + "up_050", OBJPROP_RAY_RIGHT, extendLines);
//         //ObjectSetInteger(0, uniqueId + "up_075", OBJPROP_RAY_RIGHT, extendLines);
//         ObjectSetInteger(0, uniqueId + "up_0100", OBJPROP_RAY_RIGHT, extendLines);
//         ObjectSetInteger(0, uniqueId + "up_0150", OBJPROP_RAY_RIGHT, extendLines);
//
//         if (!showPositiveOnly) {
//            ObjectCreate(0, uniqueId + "down_025", OBJ_TREND, 0, data_inicial, preco + percentual_inicial / 100 * preco * sinal, data_final, preco + percentual_inicial / 100 * preco * sinal);
//            ObjectCreate(0, uniqueId + "down_050", OBJ_TREND, 0, data_inicial, preco + 0.5 / 100 * preco * sinal, data_final, preco + 0.5 / 100 * preco * sinal);
//            //ObjectCreate(0, uniqueId + "down_075", OBJ_TREND, 0, data_inicial, preco + 0.66 / 100 * preco * sinal, data_final, preco + 0.66 / 100 * preco * sinal);
//            //ObjectCreate(0, uniqueId + "down_0150", OBJ_TREND, 0, data_inicial, preco + 0.015 * preco * sinal, data_final, preco + 0.015 * preco * sinal);
//
//            ObjectSetInteger(0, uniqueId + "down_025", OBJPROP_WIDTH, largura);
//            ObjectSetInteger(0, uniqueId + "down_050", OBJPROP_WIDTH, largura);
//            //ObjectSetInteger(0, uniqueId + "down_075", OBJPROP_WIDTH, largura);
//            //ObjectSetInteger(0, uniqueId + "down_0150", OBJPROP_WIDTH, largura);
//
//            ObjectSetString(0, uniqueId + "down_025", OBJPROP_TEXT, percentual_inicial);
//            ObjectSetString(0, uniqueId + "down_050", OBJPROP_TEXT, "0.5");
//            //ObjectSetString(0, uniqueId + "down_075", OBJPROP_TEXT, "0.66");
//            //ObjectSetString(0, uniqueId + "down_0150", OBJPROP_TEXT, "1.5");
//
//            ObjectSetInteger(0, uniqueId + "down_025", OBJPROP_COLOR, corInicial);
//            ObjectSetInteger(0, uniqueId + "down_050", OBJPROP_COLOR, corPrincipal);
//            ObjectSetInteger(0, uniqueId + "down_075", OBJPROP_COLOR, corPrincipal);
//            //ObjectSetInteger(0, uniqueId + "down_0150", OBJPROP_COLOR, corPrincipal);
//
//            ObjectSetInteger(0, uniqueId + "down_025", OBJPROP_RAY_RIGHT, extendLines);
//            ObjectSetInteger(0, uniqueId + "down_050", OBJPROP_RAY_RIGHT, extendLines);
//            //ObjectSetInteger(0, uniqueId + "down_075", OBJPROP_RAY_RIGHT, extendLines);
//            ObjectSetInteger(0, uniqueId + "down_0100", OBJPROP_RAY_RIGHT, extendLines);
//            //ObjectSetInteger(0, uniqueId + "down_0150", OBJPROP_RAY_RIGHT, extendLines);
//         }
//      }

//+------------------------------------------------------------------+
//| Typical, Open, High, Low, Close                                  |
//+------------------------------------------------------------------+
   } else {

      ObjectSetInteger(0, uniqueId + "mid_0", OBJPROP_COLOR, corInicial);
      ObjectSetInteger(0, uniqueId + "mid_0", OBJPROP_WIDTH, 3);

      for(int i = 1; i <= qtdLinhas; i++) {
         if (!showPositiveOnly || (showPositiveOnly && modo_forcado == ForceMin)) ObjectSetInteger(0, uniqueId + "up_" + i, OBJPROP_COLOR, corSecundaria);
         if (!showPositiveOnly || (showPositiveOnly && modo_forcado == ForceMax)) ObjectSetInteger(0, uniqueId + "down_" + i, OBJPROP_COLOR, corSecundaria);
      }

      for(int i = 2; i <= qtdLinhas; i = i + 2) {
         if (!showPositiveOnly || (showPositiveOnly && modo_forcado == ForceMin)) ObjectSetInteger(0, uniqueId + "up_" + i, OBJPROP_COLOR, corPrincipal);
         if (!showPositiveOnly || (showPositiveOnly && modo_forcado == ForceMax))  ObjectSetInteger(0, uniqueId + "down_" + i, OBJPROP_COLOR, corPrincipal);
      }

      if (showMainOnly) {
         for(int i = 0; i <= qtdLinhas; i++) {
            if (MathMod(i, 2) != 0 && i > 2) {
               ObjectDelete(0, uniqueId + "up_" + i);
               ObjectDelete(0, uniqueId + "down_" + i);
            }
         }
      }

      for(int i = 0; i <= qtdLinhas; i++) {
         if (!showPositiveOnly || (showPositiveOnly && modo_forcado == ForceMin)) {
            ObjectSetInteger(0, uniqueId + "up_" + i, OBJPROP_WIDTH, largura);
            ObjectSetString(0, uniqueId + "up_" + i, OBJPROP_TEXT, DoubleToString(inputIntervalo * i, 2));
         }

         if (!showPositiveOnly || (showPositiveOnly && modo_forcado == ForceMax)) {
            ObjectSetInteger(0, uniqueId + "down_" + i, OBJPROP_WIDTH, largura);
            ObjectSetString(0, uniqueId + "down_" + i, OBJPROP_TEXT, DoubleToString(inputIntervalo * i, 2));
         }
      }

      ObjectSetInteger(0, uniqueId + "up_025", OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, uniqueId + "up_050", OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, uniqueId + "up_075", OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, uniqueId + "up_0100", OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, uniqueId + "up_0150", OBJPROP_STYLE, STYLE_SOLID);

      ObjectSetInteger(0, uniqueId + "down_025", OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, uniqueId + "down_050", OBJPROP_STYLE, STYLE_DOT);
      //ObjectSetInteger(0, uniqueId + "down_075", OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, uniqueId + "down_0100", OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, uniqueId + "down_0150", OBJPROP_STYLE, STYLE_SOLID);

      ObjectSetInteger(0, uniqueId + "up_025", OBJPROP_WIDTH, 3);
      ObjectSetInteger(0, uniqueId + "up_050", OBJPROP_WIDTH, 1);
      //ObjectSetInteger(0, uniqueId + "up_075", OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, uniqueId + "up_0100", OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, uniqueId + "up_0150", OBJPROP_WIDTH, 2);

      ObjectSetInteger(0, uniqueId + "down_025", OBJPROP_WIDTH, 3);
      ObjectSetInteger(0, uniqueId + "down_050", OBJPROP_WIDTH, 1);
      //ObjectSetInteger(0, uniqueId + "down_075", OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, uniqueId + "down_0100", OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, uniqueId + "down_0150", OBJPROP_WIDTH, 2);

      ObjectSetInteger(0, uniqueId + "down_025", OBJPROP_RAY_RIGHT, extendLines);
      ObjectSetInteger(0, uniqueId + "down_050", OBJPROP_RAY_RIGHT, extendLines);
      //ObjectSetInteger(0, uniqueId + "down_075", OBJPROP_RAY_RIGHT, extendLines);
      ObjectSetInteger(0, uniqueId + "down_0100", OBJPROP_RAY_RIGHT, extendLines);
      ObjectSetInteger(0, uniqueId + "down_0150", OBJPROP_RAY_RIGHT, extendLines);

      ObjectSetInteger(0, uniqueId + "up_025", OBJPROP_RAY_RIGHT, extendLines);
      ObjectSetInteger(0, uniqueId + "up_050", OBJPROP_RAY_RIGHT, extendLines);
      //ObjectSetInteger(0, uniqueId + "up_075", OBJPROP_RAY_RIGHT, extendLines);
      ObjectSetInteger(0, uniqueId + "up_0100", OBJPROP_RAY_RIGHT, extendLines);
      ObjectSetInteger(0, uniqueId + "up_0150", OBJPROP_RAY_RIGHT, extendLines);
   }

   if (shortMode) {
      datetime start_time = iTime(_Symbol, PERIOD_CURRENT, 0) + PeriodSeconds() * input_start;
      datetime end_time = iTime(_Symbol, PERIOD_CURRENT, 0) + PeriodSeconds() * input_end;

      for(int i = 0; i <= qtdLinhas; i++) {
         double price = ObjectGetDouble(0, uniqueId + "up_" + i, OBJPROP_PRICE);
         ObjectMove(0, uniqueId + "up_" + i, 0, start_time, price);
         ObjectMove(0, uniqueId + "up_" + i, 1, end_time, price);
         price = ObjectGetDouble(0, uniqueId + "down_" + i, OBJPROP_PRICE);
         ObjectMove(0, uniqueId + "down_" + i, 0, start_time, price);
         ObjectMove(0, uniqueId + "down_" + i, 1, end_time, price);
      }
   }

   _lastOK = false;
   
   ChartRedraw();

   return true;
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const int begin, const double &price[]) {
   return (1);
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
   CheckTimer();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckTimer() {
   EventKillTimer();

   if(_updateTimer.Check() || !_lastOK) {
      _lastOK = Update();
      //Print("Pullbacks " + " " + _Symbol + ":" + GetTimeFrame(Period()) + " ok");

      EventSetMillisecondTimer(WaitMilliseconds);

      _updateTimer.Reset();
   } else {
      EventSetTimer(1);
   }
}

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
   //if(id == CHARTEVENT_CHART_CHANGE) {
   //   _lastOK = false;
   //   CheckTimer();
   //   ChartRedraw();
   //}

   if(sparam == uniqueId + "_arrow" && (id == CHARTEVENT_OBJECT_DRAG || id == CHARTEVENT_OBJECT_CHANGE)) {
      _lastOK = false;
      CheckTimer();
      ChartRedraw();
   }
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime GetBarTime(const int shift, ENUM_TIMEFRAMES period = PERIOD_CURRENT) {
   if(shift >= 0)
      return(miTime(_Symbol, period, shift));
   else
      return(miTime(_Symbol, period, 0) - shift * PeriodSeconds(period));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime miTime(string symbol, ENUM_TIMEFRAMES timeframe, int index) {
   if(index < 0)
      return(-1);

   datetime arr[];
   if(CopyTime(symbol, timeframe, index, 1, arr) <= 0)
      return(-1);

   return(arr[0]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class MillisecondTimer {

 private:
   int               _milliseconds;
 private:
   uint              _lastTick;

 public:
   void              MillisecondTimer(const int milliseconds, const bool reset = true) {
      _milliseconds = milliseconds;

      if(reset)
         Reset();
      else
         _lastTick = 0;
   }

 public:
   bool              Check() {
      uint now = getCurrentTick();
      bool stop = now >= _lastTick + _milliseconds;

      if(stop)
         _lastTick = now;

      return(stop);
   }

 public:
   void              Reset() {
      _lastTick = getCurrentTick();
   }

 private:
   uint              getCurrentTick() const {
      return(GetTickCount());
   }

};

//+---------------------------------------------------------------------+
//| GetTimeFrame function - returns the textual timeframe               |
//+---------------------------------------------------------------------+
string GetTimeFrame(int lPeriod) {
   switch(lPeriod) {
   case PERIOD_M1:
      return("M1");
   case PERIOD_M2:
      return("M2");
   case PERIOD_M3:
      return("M3");
   case PERIOD_M4:
      return("M4");
   case PERIOD_M5:
      return("M5");
   case PERIOD_M6:
      return("M6");
   case PERIOD_M10:
      return("M10");
   case PERIOD_M12:
      return("M12");
   case PERIOD_M15:
      return("M15");
   case PERIOD_M20:
      return("M20");
   case PERIOD_M30:
      return("M30");
   case PERIOD_H1:
      return("H1");
   case PERIOD_H2:
      return("H2");
   case PERIOD_H3:
      return("H3");
   case PERIOD_H4:
      return("H4");
   case PERIOD_H6:
      return("H6");
   case PERIOD_H8:
      return("H8");
   case PERIOD_H12:
      return("H12");
   case PERIOD_D1:
      return("D1");
   case PERIOD_W1:
      return("W1");
   case PERIOD_MN1:
      return("MN1");
   }
   return IntegerToString(lPeriod);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime GetObjectTime1(const string name) {
   datetime time;

   if(!ObjectGetInteger(0, name, OBJPROP_TIME, 0, time))
      return(0);

   return(time);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int WindowFirstVisibleBar() {
   return((int)ChartGetInteger(0, CHART_FIRST_VISIBLE_BAR));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool _lastOK = false;
MillisecondTimer *_updateTimer;
//+------------------------------------------------------------------+
