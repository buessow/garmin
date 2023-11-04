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
  private var sizes = {};
  var heartRateCollector = new DataFieldHeartRateCollector();

  
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
      var layoutId = layouts[sizeStr]["layout"];
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
        case "L3C_Bot_L": setLayout(Rez.Layouts.L3C_Bot_L(dc)); break;
        case "L3C_Bot_R": setLayout(Rez.Layouts.L3C_Bot_R(dc)); break;        
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

    Ui.requestUpdate();
  }

  private function setLabel(id as String, text as String) {
    var textView = findDrawableById(id) as Ui.Text?;
    if (textView != null) {
      textView.setColor(0xffffff & ~getBackgroundColor());
      textView.setText(text);
    }
  }

  function onUpdate(dc as Gfx.Dc) as Void {
    var light = getBackgroundColor() == Gfx.COLOR_WHITE;
    findDrawableById("BackgroundLight").setVisible(light);
    findDrawableById("BackgroundDark").setVisible(!light);
    
    BackgroundScheduler.schedule2(data.glucoseBuffer.getLastDateSec(), 2);
    heartRateCollector.sample();
    (findDrawableById("TitleLabel") as Ui.Text).setColor(0xffffff & ~getBackgroundColor());

    setLabel("GlucoseLabel", data.getGlucoseStr());
    setLabel("Data1Label", data.getGlucoseDeltaPerMinuteStr());
    setLabel("Data2Label", data.getGlucoseAgeStr());
    setLabel("Data3Label", data.getRemainingInsulinStr());
    setLabel("Data4Label", "20%");
 
    Ui.DataField.onUpdate(dc);
  }
}