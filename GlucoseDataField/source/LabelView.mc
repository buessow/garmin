import Toybox.Lang;

using Shared;
using Shared.BackgroundScheduler;
using Shared.Log;
using Shared.Util;
using Shared.PartNumbers;
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
        "L1"           => :L1,
        "L1_fr265"     => :L1_fr,
        "L2_3C_Top"    => :L2_3C_Top,
        "L2_Bot"       => :L2_Bot,
        "L3A_Top"      => :L3A_Top,
        "L3A_Mid"      => :L3A_Mid,
        "L3A_Bot"      => :L3A_Bot,
        "L3B_4B_Top"   => :L3B_4B_Top,
        "L3B_Mid"      => :L3B_Mid,
        "L3B_Midfr"    => :L3B_Midfr,
        "L3B_Bot"      => :L3B_Bot,
        "L3C_4C_Bot_L" => :L3C_4C_Bot_L,
        "L3C_4C_Bot_R" => :L3C_4C_Bot_R,        
        "L4A_Top"      => :L4A_Top,
        "L4A_Mid"      => :L4A_Mid,
        "L4A_Bot"      => :L4A_Bot,
        "L4B_Mid"      => :L4B_Mid,
        "L4B_Bot"      => :L4B_Bot,
        "L4C_Top"      => :L4C_Top,
        "L5_6_Mid_L"   => :L5_6_Mid_L,
        "L5_6_Mid_R"   => :L5_6_Mid_R,
        "L6_Top"       => :L6_Top,
        "L7_Mid_S"     => :L7_Mid_S,
        "L7_Mid"       => :L7_Mid,
        "L7_Bot"       => :L7_Bot,
        "L9_Top"       => :L9_Top,
        "L9_Mid_R"     => :L9_Mid_R,
        "L9_Mid_L"     => :L9_Mid_L,
        "L9_Bot"       => :L9_Bot,

        "Rect_1"       => :Rect_1,
        "Rect_1_2"     => :Rect_1_2,
        "Rect_1_3"     => :Rect_1_3,
        "Rect_1_4"     => :Rect_1_4,
        "Rect_2_5"     => :Rect_2_5,
        "Rect_1_5"     => :Rect_1_5,
        "Rect_1_10"    => :Rect_1_10,

        "Rect_1_10_edge540" => :Rect_1_10_edgeX40,
        "Rect_1_10_edge840" => :Rect_1_10_edgeX40
  };
  
  function initialize(data as Shared.Data, onTimerStopCallback) {
    Ui.DataField.initialize();
    me.data = data;
    me.onTimerStopCallback = onTimerStopCallback;
  }

  function onLayout(dc as Gfx.Dc) as Void {
    var device = PartNumbers.map[System.getDeviceSettings().partNumber];
    var sizeStr = "L_" + dc.getWidth() + "x" + dc.getHeight() + "_" + getObscurityFlags();
    var log = !sizes.hasKey(sizeStr);
    sizes[sizeStr] = true;
    var layouts =  Application.loadResource(Rez.JsonData.Layouts);
    var layoutSymbol = null;
    try {
      var layoutId = layouts[sizeStr]["layout"] as String?;
      layoutSymbol = Util.ifNull(layoutSymbols[layoutId + "_" + device], layoutSymbols[layoutId]) as Symbol;
      var defined = Rez.Layouts has layoutSymbol ? "" : " undef";
      if (log) { Log.i(TAG, "onLayout " + sizeStr + " " + layoutId + "/" + device + " " + (layoutSymbol==null ? "??" : "ok") + defined); }
    } catch (e) {
      if (log) { Log.i(TAG, "onLayout " + sizeStr + " not found"); }
    }

    // Fallback in case we didn't find anything. Physical devices sometimes have different
    // field dimensions than simulator.
    if (layoutSymbol == null) {
      layoutSymbol = Rez.Layouts has :Rect_1_10 ? :Rect_1_10 : :L1;
    }

    if (Rez.Layouts has layoutSymbol) {
      var layout = new Method(Rez.Layouts, layoutSymbol);
      setLayout(layout.invoke(dc));
    }

    graph = findDrawableById("DateValueGraph") as Shared.Graph?;
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
      textView.setText(Util.ifNull(text, "") as String);
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