import Toybox.Lang;

using Shared;
using Shared.BackgroundScheduler;
using Shared.Log;
using Shared.Util;
using Toybox.Activity;
using Toybox.Application;
using Toybox.Application.Properties;
using Toybox.Graphics as Gfx;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Lang;
using Toybox.WatchUi as Ui;

class LabelView extends Ui.DataField {
  private const TAG = "LabelView";
  private var data as Shared.Data;
  private var sizes as Dictionary<String, Boolean> = {};
  var heartRateCollector = new DataFieldHeartRateCollector();
  private var graph as Shared.Graph?;
  var onTimerStopCallback;

  private static var layoutSymbols as Dictionary<String, Symbol> = {
        "L1" => :L1,
        "L2_3C_Top" => :L2_3C_Top,
        "L2_Bot" => :L2_Bot,
        "L3A_Top" => :L3A_Top,
        "L3A_Mid" => :L3A_Mid,
        "L3A_Bot" => :L3A_Bot,
        "L3B_4B_Top" => :L3B_4B_Top,
        "L3B_Mid" => :L3B_Mid,
        "L3B_Midfr" => :L3B_Midfr,
        "L3B_Bot" => :L3B_Bot,
        "L3C_4C_Bot_L" => :L3C_4C_Bot_L,
        "L3C_4C_Bot_R" => :L3C_4C_Bot_R,        
        "L4A_Top" => :L4A_Top,
        "L4A_Mid" => :L4A_Mid,
        "L4A_Bot" => :L4A_Bot,
        "L4B_Mid" => :L4B_Mid,
        "L4B_Bot" => :L4B_Bot,
        "L4C_Top" => :L4C_Top,
        "L5_6_Mid_L" => :L5_6_Mid_L,
        "L5_6_Mid_R" => :L5_6_Mid_R,

        "Rect_1" => :Rect_1,
        "Rect_1_2" => :Rect_1_2,
        "Rect_1_3" => :Rect_1_3,
        "Rect_1_4" => :Rect_1_4,
        "Rect_2_5" => :Rect_2_5,
        "Rect_1_5" => :Rect_1_5,
        "Rect_1_10" => :Rect_1_10
  };
  
  function initialize(data as Shared.Data, onTimerStopCallback) {
    Ui.DataField.initialize();
    me.data = data;
    me.onTimerStopCallback = onTimerStopCallback;
  }

  function onLayout(dc as Gfx.Dc) as Void {
    var sizeStr = "L_" + dc.getWidth() + "x" + dc.getHeight() + "_" + getObscurityFlags();
    var log = !sizes.hasKey(sizeStr);
    sizes[sizeStr] = true;
    var layouts =  Application.loadResource(Rez.JsonData.Layouts);
    try {
      var layoutId = layouts[sizeStr]["layout"] as String?;
      var layoutSymbol = layoutSymbols[layoutId];
      var defined = Rez.Layouts has layoutSymbol ? "" : " undef";
      if (log) { Log.i(TAG, "onLayout " + sizeStr + " " + layoutId + " " + (layoutSymbol==null ? "??" : "ok") + defined); }

      if (Rez.Layouts has layoutSymbol) {
        var layout = new Method(Rez.Layouts, layoutSymbol);
        setLayout(layout.invoke(dc));
      }

    } catch (e) {
      if (log) { Log.i(TAG, "onLayout " + sizeStr + " not found"); }
    }  

    graph = findDrawableById("DateValueGraph") as Shared.Graph;
    if (graph != null) {
      graph.isMmolL = data.glucoseUnit == Shared.Data.mmoll;
      graph.setReadings(data.glucoseBuffer);
    }
    
    Ui.requestUpdate();
  }

  function onNewGlucose() {
    if (graph != null) {
      graph.isMmolL = data.glucoseUnit == Shared.Data.mmoll;
      graph.setReadings(data.glucoseBuffer);
    }
  }

  private function setLabelColor(id as String, text as String?, color as Number) as Void {
    var textView = findDrawableById(id) as Ui.Text or Ui.TextArea or Null;
    if (textView != null) {
      textView.setVisible(text != null);
      textView.setColor(color);
      textView.setText(Util.ifNull(text, ""));
    }
  }

  private function setLabel(id as String, text as String?) as Void {
    setLabelColor(id, text, 0xffffff & ~getBackgroundColor());
  }

  function compute(info as Activity.Info) as Void {
    BackgroundScheduler.schedule2(data.glucoseBuffer.getLastDateSec(), 2);
    heartRateCollector.sample(info);
  }

  function onTimerStop() as Void {
    onTimerStopCallback.invoke();
  }

  function onUpdate(dc as Gfx.Dc) as Void {
    var light = getBackgroundColor() == Gfx.COLOR_WHITE;
    findDrawableById("BackgroundLight").setVisible(light);
    findDrawableById("BackgroundDark").setVisible(!light);
    
    (findDrawableById("TitleLabel") as Ui.Text).setColor(0xffffff & ~getBackgroundColor());

// data.errorMessage = "Enable Garmin in AAPS config";
    setLabel("GlucoseLabel", data.getGlucoseStr());
    var connected = System.getDeviceSettings().phoneConnected;
    setLabelColor(
      "ConnectedLabel", 
      connected ? "C" : "D",
      connected ? Gfx.COLOR_GREEN : Gfx.COLOR_RED);
    setLabel("Data2Label", data.getGlucoseAgeStr());

    if (data.errorMessage == null) {
      setLabel("GlucoseUnitLabel", data.getGlucoseUnitStr());
      setLabel("Data1Label", data.getGlucoseDeltaPerMinuteStr());
      setLabel("Data3Label", data.getRemainingInsulinStr());
      setLabel("Data4Label", data.getBasalCorrectionStr());
      setLabel("ErrorLabel", null);
    } else {
      setLabel("GlucoseUnitLabel", null);
      setLabel("Data1Label", null);
      setLabel("Data3Label", null);
      setLabel("Data4Label", null);
      setLabelColor("ErrorLabel", data.errorMessage, Gfx.COLOR_RED);
    } 
    Ui.DataField.onUpdate(dc);
  }
}