import Toybox.Lang;

using Shared;
using Shared.BackgroundScheduler;
using Shared.Log;
using Shared.Util;
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

  
  function initialize(data as Shared.Data) {
    Ui.DataField.initialize();
    me.data = data;
  }

  function onLayout(dc as Gfx.Dc) as Void {
    var sizeStr = "L_" + dc.getWidth() + "x" + dc.getHeight() + "_" + getObscurityFlags();
    var log = !sizes.hasKey(sizeStr);
    sizes[sizeStr] = true;
    var layouts =  Application.loadResource(Rez.JsonData.Layouts);
    try {
      var layoutId = layouts[sizeStr]["layout"] as String?;
      if (log) { Log.i(TAG, "onLayout " + sizeStr + " " + layoutId); }
      switch(layoutId) {
        case "L1": setLayout(Rez.Layouts.L1(dc)); break;
        case "L2_3C_Top": setLayout(Rez.Layouts.L2_3C_Top(dc)); break;
        case "L2_Bot": setLayout(Rez.Layouts.L2_Bot(dc)); break;
        case "L3A_Top": setLayout(Rez.Layouts.L3A_Top(dc)); break;
        case "L3A_Mid": setLayout(Rez.Layouts.L3A_Mid(dc)); break;
        case "L3A_Bot": setLayout(Rez.Layouts.L3A_Bot(dc)); break;
        case "L3B_4B_Top": setLayout(Rez.Layouts.L3B_4B_Top(dc)); break;
        case "L3B_Mid": setLayout(Rez.Layouts.L3B_Mid(dc)); break;
        case "L3B_Midfr": setLayout(Rez.Layouts.L3B_Midfr(dc)); break;
        case "L3B_Bot": setLayout(Rez.Layouts.L3B_Bot(dc)); break;
        case "L3C_4C_Bot_L": setLayout(Rez.Layouts.L3C_4C_Bot_L(dc)); break;
        case "L3C_4C_Bot_R": setLayout(Rez.Layouts.L3C_4C_Bot_R(dc)); break;        
        case "L4A_Top": setLayout(Rez.Layouts.L4A_Top(dc)); break;
        case "L4A_Mid": setLayout(Rez.Layouts.L4A_Mid(dc)); break;
        case "L4A_Bot": setLayout(Rez.Layouts.L4A_Bot(dc)); break;
        case "L4B_Mid": setLayout(Rez.Layouts.L4B_Mid(dc)); break;
        case "L4B_Bot": setLayout(Rez.Layouts.L4B_Bot(dc)); break;
        case "L4C_Top": setLayout(Rez.Layouts.L4C_Top(dc)); break;
        case "L5_6_Mid_L": setLayout(Rez.Layouts.L5_6_Mid_L(dc)); break;
        case "L5_6_Mid_R": setLayout(Rez.Layouts.L5_6_Mid_R(dc)); break;
        default: throw new Exception();
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

  function onUpdate(dc as Gfx.Dc) as Void {
    var light = getBackgroundColor() == Gfx.COLOR_WHITE;
    findDrawableById("BackgroundLight").setVisible(light);
    findDrawableById("BackgroundDark").setVisible(!light);
    
    BackgroundScheduler.schedule2(data.glucoseBuffer.getLastDateSec(), 2);
    heartRateCollector.sample();
    (findDrawableById("TitleLabel") as Ui.Text).setColor(0xffffff & ~getBackgroundColor());

    setLabel("GlucoseLabel", data.getGlucoseStr());
    setLabel("Data2Label", data.getGlucoseAgeStr());

    if (data.errorMessage == null) {
      setLabel("Data1Label", data.getGlucoseDeltaPerMinuteStr());
      setLabel("Data3Label", data.getRemainingInsulinStr());
      setLabel("Data4Label", data.getBasalCorrectionStr());
      setLabel("ErrorLabel", null);
    } else {
      setLabel("Data1Label", null);
      setLabel("Data3Label", null);
      setLabel("Data4Label", null);
      setLabelColor("ErrorLabel", data.errorMessage, Gfx.COLOR_RED);
    }
 
    Ui.DataField.onUpdate(dc);
  }
}